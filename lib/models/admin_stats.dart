// Typed models for the admin dashboard RPCs (admin_overview, admin_users,
// admin_user_detail, admin_content_stats, admin_activity). Parsing is kept
// here — pure Dart, unit-tested without a Supabase connection.

/// One day of the activity/overview series.
class AdminDayStat {
  final DateTime day;
  final int signups;
  final int lessons;
  final int attempts;
  final int xp;
  final int activeUsers;

  const AdminDayStat({
    required this.day,
    required this.signups,
    required this.lessons,
    required this.attempts,
    required this.xp,
    this.activeUsers = 0,
  });

  factory AdminDayStat.fromJson(Map<String, dynamic> json) => AdminDayStat(
    day: DateTime.parse(json['day'] as String),
    signups: (json['signups'] as num?)?.toInt() ?? 0,
    lessons: (json['lessons'] as num?)?.toInt() ?? 0,
    attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    xp: (json['xp'] as num?)?.toInt() ?? 0,
    activeUsers: (json['active_users'] as num?)?.toInt() ?? 0,
  );
}

/// Aggregated KPIs + 14-day series (admin_overview RPC).
class AdminOverview {
  final int totalUsers;
  final int newUsers7d;
  final int newUsers30d;
  final int activeToday;
  final int lessonsCompleted;
  final int unitExercisesCompleted;
  final int attempts;
  final double avgAccuracy;
  final int subjects;
  final int lessons;
  final int questions;
  final int pushTokens;
  final int notificationsToday;
  final List<AdminDayStat> series;

  const AdminOverview({
    required this.totalUsers,
    required this.newUsers7d,
    required this.newUsers30d,
    required this.activeToday,
    required this.lessonsCompleted,
    required this.unitExercisesCompleted,
    required this.attempts,
    required this.avgAccuracy,
    required this.subjects,
    required this.lessons,
    required this.questions,
    required this.pushTokens,
    required this.notificationsToday,
    required this.series,
  });

  factory AdminOverview.fromJson(Map<String, dynamic> json) => AdminOverview(
    totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
    newUsers7d: (json['new_users_7d'] as num?)?.toInt() ?? 0,
    newUsers30d: (json['new_users_30d'] as num?)?.toInt() ?? 0,
    activeToday: (json['active_today'] as num?)?.toInt() ?? 0,
    lessonsCompleted: (json['lessons_completed'] as num?)?.toInt() ?? 0,
    unitExercisesCompleted:
        (json['unit_exercises_completed'] as num?)?.toInt() ?? 0,
    attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    avgAccuracy: (json['avg_accuracy'] as num?)?.toDouble() ?? 0,
    subjects: (json['subjects'] as num?)?.toInt() ?? 0,
    lessons: (json['lessons'] as num?)?.toInt() ?? 0,
    questions: (json['questions'] as num?)?.toInt() ?? 0,
    pushTokens: (json['push_tokens'] as num?)?.toInt() ?? 0,
    notificationsToday: (json['notifications_today'] as num?)?.toInt() ?? 0,
    series: [
      for (final row in (json['series'] as List<dynamic>? ?? const []))
        AdminDayStat.fromJson(row as Map<String, dynamic>),
    ],
  );
}

/// One row of the searchable users list (admin_users RPC).
class AdminUserRow {
  final String id;
  final String email;
  final String displayName;
  final int xp;
  final int streak;
  final int gems;
  final int hearts;
  final String league;
  final bool isSubscribed;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime? lastStreakDate;
  final int lessonsDone;

  const AdminUserRow({
    required this.id,
    required this.email,
    required this.displayName,
    required this.xp,
    required this.streak,
    required this.gems,
    required this.hearts,
    required this.league,
    required this.isSubscribed,
    required this.isAdmin,
    required this.createdAt,
    required this.lastStreakDate,
    required this.lessonsDone,
  });

  factory AdminUserRow.fromJson(Map<String, dynamic> json) => AdminUserRow(
    id: (json['id'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    displayName: (json['display_name'] as String?) ?? '',
    xp: (json['xp'] as num?)?.toInt() ?? 0,
    streak: (json['streak'] as num?)?.toInt() ?? 0,
    gems: (json['gems'] as num?)?.toInt() ?? 0,
    hearts: (json['hearts'] as num?)?.toInt() ?? 0,
    league: (json['league'] as String?) ?? '',
    isSubscribed: (json['is_subscribed'] as bool?) ?? false,
    isAdmin: (json['is_admin'] as bool?) ?? false,
    createdAt:
        DateTime.tryParse((json['created_at'] as String?) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    lastStreakDate: json['last_streak_date'] == null
        ? null
        : DateTime.tryParse(json['last_streak_date'] as String),
    lessonsDone: (json['lessons_done'] as num?)?.toInt() ?? 0,
  );
}

/// Paged users list (admin_users RPC): total matches + this page.
class AdminUsersPage {
  final int total;
  final List<AdminUserRow> users;

  const AdminUsersPage({required this.total, required this.users});

  factory AdminUsersPage.fromJson(Map<String, dynamic> json) => AdminUsersPage(
    total: (json['total'] as num?)?.toInt() ?? 0,
    users: [
      for (final row in (json['users'] as List<dynamic>? ?? const []))
        AdminUserRow.fromJson(row as Map<String, dynamic>),
    ],
  );
}

/// Completed/total lessons for one subject (admin_user_detail).
class AdminSubjectProgress {
  final String subjectId;
  final String name;
  final int completed;
  final int total;

  const AdminSubjectProgress({
    required this.subjectId,
    required this.name,
    required this.completed,
    required this.total,
  });

  factory AdminSubjectProgress.fromJson(Map<String, dynamic> json) =>
      AdminSubjectProgress(
        subjectId: json['subject_id'] as String,
        name: (json['name'] as String?) ?? '',
        completed: (json['completed'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );
}

/// One recent quiz attempt (admin_user_detail).
class AdminAttempt {
  final String id;
  final String subjectId;
  final String kind;
  final int refIndex;
  final int total;
  final int correct;
  final DateTime createdAt;

  const AdminAttempt({
    required this.id,
    required this.subjectId,
    required this.kind,
    required this.refIndex,
    required this.total,
    required this.correct,
    required this.createdAt,
  });

  double get accuracy => total == 0 ? 0 : correct / total * 100;

  factory AdminAttempt.fromJson(Map<String, dynamic> json) => AdminAttempt(
    id: json['id'] as String,
    subjectId: (json['subject_id'] as String?) ?? '',
    kind: (json['kind'] as String?) ?? '',
    refIndex: (json['ref_index'] as num?)?.toInt() ?? 0,
    total: (json['total'] as num?)?.toInt() ?? 0,
    correct: (json['correct'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse((json['created_at'] as String?) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// One recent XP event (admin_user_detail).
class AdminXpEvent {
  final int amount;
  final String source;
  final DateTime createdAt;

  const AdminXpEvent({
    required this.amount,
    required this.source,
    required this.createdAt,
  });

  factory AdminXpEvent.fromJson(Map<String, dynamic> json) => AdminXpEvent(
    amount: (json['amount'] as num?)?.toInt() ?? 0,
    source: (json['source'] as String?) ?? '',
    createdAt:
        DateTime.tryParse((json['created_at'] as String?) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// One recent heart event (admin_user_detail).
class AdminHeartEvent {
  final int delta;
  final String reason;
  final DateTime createdAt;

  const AdminHeartEvent({
    required this.delta,
    required this.reason,
    required this.createdAt,
  });

  factory AdminHeartEvent.fromJson(Map<String, dynamic> json) =>
      AdminHeartEvent(
        delta: (json['delta'] as num?)?.toInt() ?? 0,
        reason: (json['reason'] as String?) ?? '',
        createdAt:
            DateTime.tryParse((json['created_at'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// Full detail payload for one user (admin_user_detail RPC).
class AdminUserDetail {
  final AdminUserRow profile;
  final int unitsDone;
  final int attempts;
  final double accuracy;
  final List<AdminSubjectProgress> bySubject;
  final List<AdminAttempt> recentAttempts;
  final List<AdminXpEvent> recentXp;
  final List<AdminHeartEvent> recentHearts;

  const AdminUserDetail({
    required this.profile,
    required this.unitsDone,
    required this.attempts,
    required this.accuracy,
    required this.bySubject,
    required this.recentAttempts,
    required this.recentXp,
    required this.recentHearts,
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final profile =
        json['profile'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return AdminUserDetail(
      profile: AdminUserRow.fromJson(profile),
      unitsDone: (profile['units_done'] as num?)?.toInt() ?? 0,
      attempts: (profile['attempts'] as num?)?.toInt() ?? 0,
      accuracy: (profile['accuracy'] as num?)?.toDouble() ?? 0,
      bySubject: [
        for (final row in (json['by_subject'] as List<dynamic>? ?? const []))
          AdminSubjectProgress.fromJson(row as Map<String, dynamic>),
      ],
      recentAttempts: [
        for (final row
            in (json['recent_attempts'] as List<dynamic>? ?? const []))
          AdminAttempt.fromJson(row as Map<String, dynamic>),
      ],
      recentXp: [
        for (final row in (json['recent_xp'] as List<dynamic>? ?? const []))
          AdminXpEvent.fromJson(row as Map<String, dynamic>),
      ],
      recentHearts: [
        for (final row in (json['recent_hearts'] as List<dynamic>? ?? const []))
          AdminHeartEvent.fromJson(row as Map<String, dynamic>),
      ],
    );
  }
}

/// Per-lesson completion counts inside a subject (admin_content_stats).
class AdminLessonStat {
  final int lessonIndex;
  final String title;
  final int completedBy;

  const AdminLessonStat({
    required this.lessonIndex,
    required this.title,
    required this.completedBy,
  });

  factory AdminLessonStat.fromJson(Map<String, dynamic> json) =>
      AdminLessonStat(
        lessonIndex: (json['lesson_index'] as num?)?.toInt() ?? 0,
        title: (json['title'] as String?) ?? '',
        completedBy: (json['completed_by'] as num?)?.toInt() ?? 0,
      );
}

/// One subject's content statistics (admin_content_stats RPC).
class AdminSubjectStat {
  final String id;
  final String name;
  final String? icon;
  final String? colorHex;
  final int sortOrder;
  final int units;
  final int lessons;
  final int questions;
  final int completions;
  final Map<String, int> questionTypes;
  final Map<String, int> difficulties;
  final List<AdminLessonStat> lessonsDetail;

  const AdminSubjectStat({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.sortOrder,
    required this.units,
    required this.lessons,
    required this.questions,
    required this.completions,
    required this.questionTypes,
    required this.difficulties,
    required this.lessonsDetail,
  });

  factory AdminSubjectStat.fromJson(Map<String, dynamic> json) {
    Map<String, int> asCountMap(Object? raw) {
      if (raw is! Map<String, dynamic>) return const {};
      return {
        for (final e in raw.entries) e.key: (e.value as num?)?.toInt() ?? 0,
      };
    }

    return AdminSubjectStat(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      icon: json['icon'] as String?,
      colorHex: json['color_hex'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      units: (json['units'] as num?)?.toInt() ?? 0,
      lessons: (json['lessons'] as num?)?.toInt() ?? 0,
      questions: (json['questions'] as num?)?.toInt() ?? 0,
      completions: (json['completions'] as num?)?.toInt() ?? 0,
      questionTypes: asCountMap(json['question_types']),
      difficulties: asCountMap(json['difficulties']),
      lessonsDetail: [
        for (final row
            in (json['lessons_detail'] as List<dynamic>? ?? const []))
          AdminLessonStat.fromJson(row as Map<String, dynamic>),
      ],
    );
  }
}

/// Result of an admin-push broadcast/send (admin-push edge function).
class AdminPushResult {
  final int sent;
  final int dropped;
  final int targets;

  const AdminPushResult({
    required this.sent,
    required this.dropped,
    required this.targets,
  });

  factory AdminPushResult.fromJson(Map<String, dynamic> json) =>
      AdminPushResult(
        sent: (json['sent'] as num?)?.toInt() ?? 0,
        dropped: (json['dropped'] as num?)?.toInt() ?? 0,
        targets: (json['targets'] as num?)?.toInt() ?? 0,
      );
}

/// Targets accepted by the admin_reset_user RPC.
enum AdminResetTarget { streak, hearts, progress }
