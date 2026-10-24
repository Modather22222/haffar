/// Central constants for the game system — hearts, XP, penalties, bonuses.
/// All numeric values are single-sourced here so screens and services share the same numbers.
abstract class GameConstants {
  GameConstants._();

  // ── Hearts ──────────────────────────────────────────────────────────────
  /// Maximum hearts available to any user.
  static const int maxHearts = 7;

  /// Default hearts for lesson exams (free users).
  static const int lessonHeartsFree = 7;

  /// Hearts allocated for unit exams (both free and subscribed).
  static const int unitHearts = 5;

  /// Time in minutes between each regenerated heart.
  static const Duration heartRegenInterval = Duration(minutes: 10);

  // ── XP Base Rewards ─────────────────────────────────────────────────────
  /// DEFAULT lesson base XP — mirrors the `lessons.xp_base` column default.
  /// Actual quiz XP uses the admin-set lesson/unit values when available.
  static const int lessonXpBase = 100;

  /// DEFAULT unit exercise base XP — mirrors the `units.xp_base` default.
  static const int unitXpBase = 150;

  // ── Practice (repeat) runs ──────────────────────────────────────────────
  /// Fraction of the full attempt XP granted for practice runs: replays of
  /// an already-completed lesson quiz / unit exam, and review attempts.
  /// CURRENT POLICY: 0 — replays and reviews earn nothing; only the first
  /// completion of a lesson/unit pays out. Streaks and attempt history
  /// still count. Raise this (e.g. 0.3) to re-enable a reduced practice
  /// share later.
  static const double practiceXpRatio = 0.0;

  // ── Penalties ───────────────────────────────────────────────────────────
  /// DEFAULT wrong-answer deduction — mirrors `lessons.wrong_penalty` default.
  static const int lessonWrongPenalty = 5;

  /// DEFAULT wrong-answer deduction — mirrors `units.wrong_penalty` default.
  static const int unitWrongPenalty = 18;

  // ── Bonus ───────────────────────────────────────────────────────────────
  /// Time threshold for bonus XP on unit exams (finish faster → bonus).
  static const Duration unitBonusTimeThreshold = Duration(minutes: 2);

  /// Bonus XP awarded when unit exam is finished under [unitBonusTimeThreshold].
  static const int unitBonusXp = 15;

  // ── Streak ──────────────────────────────────────────────────────────────
  /// Days between streak check intervals.
  static const Duration streakCheckInterval = Duration(days: 1);
}
