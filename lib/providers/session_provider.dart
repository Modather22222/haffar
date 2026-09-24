import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/hearts_repository.dart';
import '../services/progress_repository.dart';
import '../services/xp_repository.dart';
import '../utils/app_error.dart';
import '../utils/app_logger.dart';
import '../utils/app_toast.dart';
import 'content_provider.dart';
import 'economy_provider.dart';
import 'progress_provider.dart';

/// Coordinates real email/password auth and one-shot hydration.
/// Not a state holder itself — delegates to Content/Economy/Progress.
class SessionProvider extends ChangeNotifier {
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
  }

  bool remoteSyncEnabled = false;

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
        notifyListeners();
        return;
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
      lastInitError = null;
      AppLog.info('initUserData OK hearts=${economy.hearts} xp=${economy.xp}');
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
      lastInitError = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
