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
  /// Base XP for completing a lesson quiz (no mistakes).
  static const int lessonXpBase = 100;

  /// Base XP for completing a unit exercise (no mistakes).
  static const int unitXpBase = 150;

  /// XP awarded for a review attempt (fixed amount).
  static const int reviewXp = 10;

  // ── Penalties ───────────────────────────────────────────────────────────
  /// XP deducted per wrong answer in a lesson exam.
  static const int lessonWrongPenalty = 5;

  /// XP deducted per wrong answer in a unit exam.
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
