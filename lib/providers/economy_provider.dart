import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/hearts_repository.dart';
import '../services/xp_repository.dart';
import '../utils/game_constants.dart';

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

  void hydrateFromProfile(Map<String, dynamic> profile) {
    xp = (profile['xp'] as int?) ?? xp;
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
    } catch (_) {}
  }

  /// Server-authoritative heart refresh — re-reads and applies regeneration.
  Future<void> syncHeartsFromServer() async {
    if (!remoteSyncEnabled || _heartsRepo == null) return;
    await refreshHearts();
  }

  /// Consumes a heart for a wrong answer. Subscribers skip lesson hearts.
  /// Returns remaining hearts.
  Future<int> consumeHeartForExam({required bool isUnitExam}) async {
    if (!remoteSyncEnabled || _heartsRepo == null) return hearts;
    if (isSubscribed && !isUnitExam) return hearts;
    final remaining = await _heartsRepo!.consumeHeart(
      reason: isUnitExam ? 'unit_wrong' : 'lesson_wrong',
    );
    hearts = remaining;
    unawaited(syncHeartsFromServer());
    notifyListeners();
    return remaining;
  }

  /// Records an XP event server-side; mirrors the aggregate locally.
  Future<void> addXpEvent({
    required int amount,
    required String source,
    String? subjectId,
    int? lessonIndex,
  }) async {
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
    } catch (_) {
      xp += amount;
      notifyListeners();
    }
  }

  /// Server-side streak bump after a successful completion.
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
      notifyListeners();
    } catch (_) {}
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
