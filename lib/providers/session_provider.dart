import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/admin_repository.dart';
import '../services/auth_service.dart';
import '../services/hearts_repository.dart';
import '../services/progress_repository.dart';
import '../services/push_service.dart';
import '../services/xp_repository.dart';
import '../utils/app_error.dart';
import '../utils/app_logger.dart';
import '../utils/app_toast.dart';
import 'content_provider.dart';
import 'economy_provider.dart';
import 'progress_provider.dart';

/// Coordinates real email/password auth and one-shot hydration.
/// Not a state holder itself — delegates to Content/Economy/Progress.
class SessionProvider extends ChangeNotifier with WidgetsBindingObserver {
  final ContentProvider content;
  final EconomyProvider economy;
  final ProgressProvider progress;

  StreamSubscription<AuthState>? _authSub;

  SessionProvider({
    required this.content,
    required this.economy,
    required this.progress,
  }) {
    // Supabase may have failed to initialize — don't crash the provider tree.
    try {
      _authSub = AuthService(Supabase.instance.client).authStateChanges.listen(
        _onAuthState,
        onError: (Object e, StackTrace st) {
          AppLog.error('auth stream error', e, st);
        },
      );
    } catch (e, st) {
      AppLog.error('auth listener setup FAILED', e, st);
    }
    // Lifecycle observer — resume-from-background is another chance to catch
    // a subscription approval that happened while the app was closed-ish.
    WidgetsBinding.instance.addObserver(this);
  }

  // ── Approval watch — Realtime subscription on this user's profiles row ──
  // approve_subscription_order (and any manual admin grant) rewrites the row,
  // so an UPDATE event is the instant "subscription changed" signal. The
  // publication side was opened by migration realtime_profiles_publication.
  // Only the subscription columns decide whether we react: xp / streak /
  // last_active self-writes hit the same row constantly and are dropped here
  // without a single request. On resume the channel is re-armed and one
  // profile sweep runs as a net for anything missed while suspended.
  static const _minResumedPullGap = Duration(seconds: 30);

  RealtimeChannel? _profilesWatch;
  String? _profilesWatchUid;
  DateTime? _lastResumedPull;
  bool _pulling = false;

  void _startProfilesWatch() {
    if (!remoteSyncEnabled) return;
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) return;
      if (_profilesWatch != null && _profilesWatchUid == uid) return;
      _teardownProfilesWatch();
      final channel = client
          .channel('profiles-watch-$uid')
          // Server-side filter — only this user's own row updates are sent,
          // and postgres_changes authorizes against the user's own JWT.
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'profiles',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: uid,
            ),
            callback: (payload) => unawaited(_onProfilesRealtime(payload)),
          )
          .subscribe((status, error) {
            if (error != null) {
              AppLog.warn('profiles watch $status: $error');
            } else {
              AppLog.info('profiles watch $status');
            }
          });
      _profilesWatch = channel;
      _profilesWatchUid = uid;
      AppLog.info('profiles realtime watch ON uid=$uid');
    } catch (e, st) {
      AppLog.error('profiles realtime watch setup FAILED', e, st);
    }
  }

  void _teardownProfilesWatch() {
    final channel = _profilesWatch;
    if (channel != null) {
      try {
        Supabase.instance.client.removeChannel(channel);
      } catch (e, st) {
        AppLog.error('removeChannel FAILED', e, st);
      }
    }
    _profilesWatch = null;
    _profilesWatchUid = null;
  }

  /// Fetches the fresh profile and lets hydrateFromProfile (plus the approval
  /// celebration detector inside it) apply the change. Duplicates cost nothing:
  /// hydrate is idempotent and SubscriptionCelebration dedupes by period.
  Future<void> _onProfilesRealtime(PostgresChangePayload payload) async {
    try {
      final row = payload.newRecord;
      final subscribed = (row['is_subscribed'] as bool?) ?? false;
      final untilMs = DateTime.tryParse(
        (row['subscribed_until'] as String?) ?? '',
      )?.toUtc().millisecondsSinceEpoch;
      final currentMs = economy.subscriptionExpiresAt?.millisecondsSinceEpoch;
      if (subscribed == economy.isSubscribed && untilMs == currentMs) return;
      AppLog.info('profiles realtime: subscription fields changed');
    } catch (e, st) {
      AppLog.error('profiles realtime parse FAILED', e, st);
    }
    // Real events bypass the sweep gap — the change is already confirmed.
    await _pullProfile(reason: 'realtime', force: true);
  }

  /// Profile-only fetch feeding economy. Never toasts — background hygiene.
  Future<void> _pullProfile({
    required String reason,
    bool force = false,
  }) async {
    if (!remoteSyncEnabled || _pulling) return;
    if (!force) {
      final now = DateTime.now();
      final last = _lastResumedPull;
      if (last != null && now.difference(last) < _minResumedPullGap) return;
      _lastResumedPull = now;
    }
    _pulling = true;
    try {
      final client = Supabase.instance.client;
      final profile = await ProgressRepository(client).fetchProfile();
      if (profile != null) economy.hydrateFromProfile(profile);
    } catch (e, st) {
      AppLog.warn('profile pull ($reason) failed: $e');
      AppLog.error('pullProfile($reason)', e, st);
    } finally {
      _pulling = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Backgrounded sockets stall on mobile — re-arm the channel and run one
      // debounced sweep as a safety net for anything missed while away.
      _startProfilesWatch();
      unawaited(_pullProfile(reason: 'resumed'));
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Drop the socket cleanly; re-armed on resume, hydrate or sign-in.
      _teardownProfilesWatch();
    }
  }

  bool remoteSyncEnabled = false;

  /// Whether the signed-in user is an admin (own profiles.is_admin row).
  /// Display gating only — every admin RPC/function re-checks server-side.
  bool isAdmin = false;

  /// Last hydration failure message (Arabic), if any. Cleared on success.
  String? lastInitError;

  bool get isSignedIn {
    try {
      return AuthService(Supabase.instance.client).isSignedIn;
    } catch (_) {
      return false;
    }
  }

  void _onAuthState(AuthState state) {
    final event = state.event;
    AppLog.info('auth event=${event.name} session=${state.session != null}');
    if (event == AuthChangeEvent.signedOut) {
      remoteSyncEnabled = false;
      isAdmin = false;
      _teardownProfilesWatch();
      notifyListeners();
      return;
    }
    if (state.session != null &&
        (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.initialSession)) {
      // Fire-and-forget hydrate; initUserData is also awaited by callers.
      unawaited(initUserData());
    }
  }

  /// Restore an existing session (if any) and hydrate economy + progress.
  /// Does NOT create anonymous sessions — unauthenticated users stay signed out.
  Future<void> initUserData() async {
    try {
      final client = Supabase.instance.client;
      final authService = AuthService(client);
      final progressRepo = ProgressRepository(client);
      final heartsRepo = HeartsRepository(client);
      final xpRepo = XpRepository(client);

      final signedIn = await authService.restoreSession();
      remoteSyncEnabled = signedIn;
      economy.attachRepos(
        heartsRepo: heartsRepo,
        xpRepo: xpRepo,
        signedIn: signedIn,
      );
      progress.attachRepo(progressRepo, signedIn: signedIn);
      if (!signedIn) {
        lastInitError = null;
        isAdmin = false;
        notifyListeners();
        return;
      }

      // Own-row is_admin read (RLS allows it). Kept out of the main try so a
      // failure here can't fail hydration — the flag simply stays false.
      try {
        isAdmin = await AdminRepository(client).fetchIsAdmin();
      } catch (e, st) {
        isAdmin = false;
        AppLog.error('fetchIsAdmin FAILED', e, st);
      }

      // Flush local outbox (failed XP/streak/lesson writes) BEFORE reading
      // the profile so hydrate sees the post-flush server state.
      await economy.prepareForHydrate();
      await progress.flushPending();

      final results = await Future.wait([
        progressRepo.fetchProfile(),
        progressRepo.fetchCompletedLessons(),
        progressRepo.fetchCompletedUnitExercises(),
      ]);
      final profile = results[0] as Map<String, dynamic>?;
      if (profile != null) economy.hydrateFromProfile(profile);
      progress.hydrate(
        profile: profile,
        completedLessonKeys: results[1] as List<String>,
        completedUnitKeys: results[2] as List<String>,
      );
      await economy.syncHeartsFromServer();
      // Missed-day guard: zero the streak on the server (and locally) if the
      // last completion was more than a day ago, right after hydrating.
      await economy.refreshStreakFromServer();
      // Register this device for push (FCM token → push_tokens).
      unawaited(PushService.instance.register());
      lastInitError = null;
      AppLog.info('initUserData OK hearts=${economy.hearts} xp=${economy.xp}');
      // Realtime watch takes over from here — from now on an admin approval
      // (or any grant that rewrites this row) is caught the moment it lands.
      _startProfilesWatch();
    } catch (e, st) {
      AppLog.error('initUserData FAILED', e, st);
      remoteSyncEnabled = false;
      lastInitError = AppError.userMessage(e, fallback: AppError.network);
      // Only surface when the user is signed in (silent on first launch).
      if (isSignedIn) {
        AppToast.error(
          e,
          fallback: 'تعذر تحميل بياناتك — تحقق من الإنترنت',
          logContext: 'initUserData',
          st: st,
        );
      }
    }
    notifyListeners();
  }

  /// Returns true when sign-out completed (local clear always happens).
  Future<bool> signOut() async {
    try {
      // Drop the device token first — RLS needs the still-signed-in uid.
      await PushService.instance.unregister();
      await AuthService(Supabase.instance.client).signOut();
      return true;
    } catch (e, st) {
      AppLog.error('signOut FAILED', e, st);
      AppToast.error(
        e,
        fallback: 'تعذر تسجيل الخروج من الخادم — تحقق من الإنترنت',
        logContext: 'signOut',
        st: st,
      );
      return false;
    } finally {
      remoteSyncEnabled = false;
      isAdmin = false;
      lastInitError = null;
      _teardownProfilesWatch();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _teardownProfilesWatch();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
