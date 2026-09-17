/// User profile and progress data
class User {
  final String id;
  final String name;
  int xp;
  int streak;
  int gems;
  String league;
  DateTime? lastActiveDate;
  final List<SubjectProgress> subjectProgress;

  User({
    required this.id,
    required this.name,
    this.xp = 0,
    this.streak = 0,
    this.gems = 0,
    this.league = 'bronze',
    this.lastActiveDate,
    this.subjectProgress = const [],
  });

  User copyWith({
    String? name,
    int? xp,
    int? streak,
    int? gems,
    String? league,
    DateTime? lastActiveDate,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      gems: gems ?? this.gems,
      league: league ?? this.league,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      subjectProgress: subjectProgress,
    );
  }
}

/// Per-subject learning progress
class SubjectProgress {
  final String subjectId;
  final int completedLessons;
  final int totalLessons;
  final int highestStreak;

  const SubjectProgress({
    required this.subjectId,
    this.completedLessons = 0,
    this.totalLessons = 0,
    this.highestStreak = 0,
  });

  double get completionPercent =>
      totalLessons > 0 ? completedLessons / totalLessons : 0.0;
}
