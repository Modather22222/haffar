import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/hearts_repository.dart';
import '../services/xp_repository.dart';
import '../utils/app_logger.dart';
import '../utils/app_toast.dart';
import '../utils/game_constants.dart';
import '../utils/local_prefs.dart';

/// Hearts, XP, streak, league — the game economy.
/// All durable writes go through server RPCs; this provider only mirrors state.
class EconomyProvider extends ChangeNotifier {
  HeartsRepository? _heartsRepo;
  XpRepository? _xpRepo;
  Timer? _heartsRefreshTimer;
  bool remoteSyncEnabled = false;

  // ── Profile economy fields (hydrated from server) ────────────────────────
  int xp = 0;
  int streak = 0;
  int gems = 0;
  String league = 'bronze';
  bool isSubscribed = false;

  // ── Hearts ───────────────────────────────────────────────────────────────
  int hearts = GameConstants.maxHearts;
  DateTime? heartsUpdatedAt;
  Duration? _lastServerRemaining;
  DateTime? _lastFetchTime;

  /// Failed XP events awaiting retry: JSON strings {"a","s","si","li"}.
  final List<String> _pendingXpEvents = [];
  bool _pendingStreakBump = false;
  bool _pendingLoaded = false;

  Future<void> _loadPendingOutbox() async {
    if (_pendingLoaded) return;
    _pendingXpEvents
      ..clear()
      ..addAll(await LocalPrefs.readPendingXpEvents());
    _pendingStreakBump = await LocalPrefs.readPendingStreak();
    _pendingLoaded = true;
    if (_pendingXpEvents.isNotEmpty || _pendingStreakBump) {
      AppLog.info(
        'economy outbox loaded xp=${_pendingXpEvents.length} '
        'streak=$_pendingStreakBump',
      );
    }
  }

  void attachRepos({
    required HeartsRepository heartsRepo,
    required XpRepository xpRepo,
    required bool signedIn,
  }) {
    _heartsRepo = heartsRepo;
    _xpRepo = xpRepo;
    remoteSyncEnabled = signedIn;
    if (signedIn) _startHeartsRefreshTimer();
  }

  /// Public entry so SessionProvider can await outbox flush before hydrate.
  Future<void> prepareForHydrate() async {
    await _loadPendingOutbox();
    if (!remoteSyncEnabled || _xpRepo == null) return;

    if (_pendingStreakBump) {
      try {
        await updateStreakOnCompletion();
      } catch (e, st) {
        AppLog.error('outbox streak retry failed', e, st);
      }
    }

    final remaining = <String>[];
    for (final raw in List.of(_pendingXpEvents)) {
      try {
        final m = _parseXpEvent(raw);
        if (m == null) continue;
        await _xpRepo!.insertEvent(
          amount: m['a']! as int,
          source: m['s']! as String,
          subjectId: m['si'] as String?,
          lessonIndex: m['li'] as int?,
        );
        AppLog.info('outbox XP flushed amount=${m['a']}');
      } catch (e, st) {
        AppLog.error('outbox XP retry failed', e, st);
        remaining.add(raw);
      }
    }
    _pendingXpEvents
      ..clear()
      ..addAll(remaining);
    await LocalPrefs.writePendingXpEvents(_pendingXpEvents);
  }

  static String _encodeXpEvent({
    required int amount,
    required String source,
    String? subjectId,
    int? lessonIndex,
  }) {
    final si = subjectId ?? '';
    final li = lessonIndex?.toString() ?? '';
    return '$amount|$source|$si|$li';
  }

  static Map<String, dynamic>? _parseXpEvent(String raw) {
    final parts = raw.split('|');
    if (parts.length != 4) return null;
    final amount = int.tryParse(parts[0]);
    if (amount == null) return null;
    return {
      'a': amount,
      's': parts[1],
      'si': parts[2].isEmpty ? null : parts[2],
      'li': parts[3].isEmpty ? null : int.tryParse(parts[3]),
    };
  }

  void hydrateFromProfile(Map<String, dynamic> profile) {
    final serverXp = (profile['xp'] as int?) ?? xp;
    // Apply any XP still sitting in the outbox (not yet on the server) so a
    // failed add_xp_event is never wiped by the next hydrate.
    var pendingSum = 0;
    for (final raw in _pendingXpEvents) {
      final m = _parseXpEvent(raw);
      if (m != null) pendingSum += m['a']! as int;
    }
    xp = serverXp + pendingSum;
    streak = (profile['streak'] as int?) ?? streak;
    gems = (profile['gems'] as int?) ?? gems;
    league = (profile['league'] as String?) ?? league;
    isSubscribed = (profile['is_subscribed'] as bool?) ?? false;
    hearts = (profile['hearts'] as int?) ?? hearts;
    final hu = profile['hearts_updated_at'] as String?;
    if (hu != null) heartsUpdatedAt = DateTime.tryParse(hu)?.toUtc();
    notifyListeners();
  }

  void _startHeartsRefreshTimer() {
    _heartsRefreshTimer?.cancel();
    _heartsRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(refreshHearts());
    });
  }

  Future<void> refreshHearts() async {
    if (_heartsRepo == null) return;
    try {
      final info = await _heartsRepo!.getHeartsInfo();
      _storeHeartsFetch(info);
      notifyListeners();
    } catch (e, st) {
      // Background refresh — log only so timers don't spam snackbars.
      AppLog.warn('refreshHearts failed: $e');
      AppLog.error('refreshHearts', e, st);
    }
  }

  /// Server-authoritative heart refresh — re-reads and applies regeneration.
  Future<void> syncHeartsFromServer() async {
    if (!remoteSyncEnabled || _heartsRepo == null) return;
    await refreshHearts();
  }

  /// Consumes a heart for a wrong answer. Subscribers skip lesson hearts.
  /// Returns remaining hearts. On server failure, still decrements locally
  /// so the quiz never freezes, and surfaces a friendly error once.
  Future<int> consumeHeartForExam({required bool isUnitExam}) async {
    if (!remoteSyncEnabled || _heartsRepo == null) return hearts;
    if (isSubscribed && !isUnitExam) return hearts;
    try {
      final remaining = await _heartsRepo!.consumeHeart(
        reason: isUnitExam ? 'unit_wrong' : 'lesson_wrong',
      );
      hearts = remaining;
      unawaited(syncHeartsFromServer());
      notifyListeners();
      return remaining;
    } catch (e, st) {
      AppLog.error('consumeHeart failed', e, st);
      // Optimistic local decrement so the quiz keeps moving.
      if (hearts > 0) hearts--;
      notifyListeners();
      AppToast.error(
        e,
        fallback: 'تعذر خصم القلب من الخادم — تم الخصم محلياً',
        logContext: 'consumeHeart',
        st: st,
      );
      return hearts;
    }
  }

  /// Records an XP event server-side; mirrors the aggregate locally.
  /// On failure the event is queued in a local outbox and retried on the
  /// next session restore — local XP is never rolled back by hydrate.
  Future<void> addXpEvent({
    required int amount,
    required String source,
    String? subjectId,
    int? lessonIndex,
  }) async {
    if (amount <= 0) return; // RPC rejects amount <= 0
    if (!remoteSyncEnabled || _xpRepo == null) {
      xp += amount;
      notifyListeners();
      return;
    }
    try {
      await _xpRepo!.insertEvent(
        amount: amount,
        source: source,
        subjectId: subjectId,
        lessonIndex: lessonIndex,
      );
      xp += amount;
      notifyListeners();
    } catch (e, st) {
      AppLog.warn('addXpEvent server failed, queueing outbox: $e');
      AppLog.error('addXpEvent', e, st);
      await _loadPendingOutbox();
      _pendingXpEvents.add(
        _encodeXpEvent(
          amount: amount,
          source: source,
          subjectId: subjectId,
          lessonIndex: lessonIndex,
        ),
      );
      await LocalPrefs.writePendingXpEvents(_pendingXpEvents);
      xp += amount;
      notifyListeners();
    }
  }

  /// Server-side streak bump after a successful completion.
  /// Queues a local retry flag when the RPC fails.
  Future<void> updateStreakOnCompletion() async {
    if (!remoteSyncEnabled) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final newStreak =
          await Supabase.instance.client.rpc(
                'update_streak',
                params: {'p_user_id': uid},
              )
              as int;
      streak = newStreak;
      if (_pendingStreakBump) {
        _pendingStreakBump = false;
        await LocalPrefs.writePendingStreak(false);
      }
      notifyListeners();
    } catch (e, st) {
      AppLog.error('updateStreakOnCompletion', e, st);
      await _loadPendingOutbox();
      _pendingStreakBump = true;
      await LocalPrefs.writePendingStreak(true);
    }
  }

  /// Local-only XP bump (no server event). Prefer [addXpEvent].
  void addXp(int amount) {
    xp += amount;
    notifyListeners();
  }

  void updateStreak(int days) {
    streak = days;
    notifyListeners();
  }

  void addGems(int amount) {
    gems += amount;
    notifyListeners();
  }

  void setLeague(String l) {
    league = l;
    notifyListeners();
  }

  void resetLocal() {
    xp = 0;
    streak = 0;
    gems = 0;
    league = 'bronze';
    hearts = GameConstants.maxHearts;
    notifyListeners();
  }

  // ── Regen countdown (monotonic, server-anchored) ─────────────────────────

  /// Remaining time until next heart (null when full or unknown).
  Duration? get heartsRegenRemaining {
    if (hearts >= GameConstants.maxHearts) return null;
    final r = _lastServerRemaining;
    final f = _lastFetchTime;
    if (r == null || f == null) {
      final u = heartsUpdatedAt;
      if (u == null) return null;
      final next = u.add(GameConstants.heartRegenInterval);
      final rem = next.difference(DateTime.now().toUtc());
      if (rem.isNegative) return Duration.zero;
      return rem;
    }
    final elapsed = DateTime.now().toUtc().difference(f);
    final rem = r - elapsed;
    if (rem.isNegative) return Duration.zero;
    return rem;
  }

  /// Progress 0..1 of the current regen cycle.
  double get heartsRegenProgress {
    if (hearts >= GameConstants.maxHearts) return 1.0;
    final rem = heartsRegenRemaining;
    if (rem == null) return 0.0;
    final elapsed = GameConstants.heartRegenInterval - rem;
    return (elapsed.inMilliseconds /
            GameConstants.heartRegenInterval.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  void _storeHeartsFetch(HeartsInfo info) {
    hearts = info.hearts;
    heartsUpdatedAt = info.updatedAt;
    if (info.hearts >= GameConstants.maxHearts) {
      _lastServerRemaining = null;
      _lastFetchTime = null;
    } else {
      final next = info.updatedAt.add(GameConstants.heartRegenInterval);
      var rem = next.difference(info.serverNow);
      if (rem.isNegative) rem = Duration.zero;
      _lastServerRemaining = rem;
      _lastFetchTime = DateTime.now().toUtc();
    }
  }

  @override
  void dispose() {
    _heartsRefreshTimer?.cancel();
    super.dispose();
  }
}
