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
  final int subscribedUsers;
  final Map<String, int> leagues;
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
    required this.subscribedUsers,
    required this.leagues,
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
    subscribedUsers: (json['subscribed_users'] as num?)?.toInt() ?? 0,
    leagues: _countMap(json['leagues']),
    series: [
      for (final row in (json['series'] as List<dynamic>? ?? const []))
        AdminDayStat.fromJson(row as Map<String, dynamic>),
    ],
  );

  static Map<String, int> _countMap(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final e in raw.entries)
        e.key.toString(): (e.value as num?)?.toInt() ?? 0,
    };
  }
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
  final DateTime? lastActiveAt;
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
    this.lastActiveAt,
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
    lastActiveAt: json['last_active_at'] == null
        ? null
        : DateTime.tryParse(json['last_active_at'] as String),
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

/// Per-lesson completion + accuracy stats inside a subject
/// (admin_content_stats RPC). `accuracy` is null when the lesson has no
/// quiz attempts yet.
class AdminLessonStat {
  final int lessonIndex;
  final String title;
  final int completedBy;
  final int attempts;
  final double? accuracy;

  const AdminLessonStat({
    required this.lessonIndex,
    required this.title,
    required this.completedBy,
    this.attempts = 0,
    this.accuracy,
  });

  factory AdminLessonStat.fromJson(Map<String, dynamic> json) =>
      AdminLessonStat(
        lessonIndex: (json['lesson_index'] as num?)?.toInt() ?? 0,
        title: (json['title'] as String?) ?? '',
        completedBy: (json['completed_by'] as num?)?.toInt() ?? 0,
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble(),
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

/// Targets accepted by the admin_grant_user RPC.
enum AdminGrantTarget { hearts, gems, xp }

/// Result of admin_grant_user: [applied] can be less than requested for
/// hearts (0..7 cap); balances are the post-grant profile values.
class AdminGrantResult {
  final AdminGrantTarget target;
  final int applied;
  final int hearts;
  final int gems;
  final int xp;

  const AdminGrantResult({
    required this.target,
    required this.applied,
    required this.hearts,
    required this.gems,
    required this.xp,
  });

  factory AdminGrantResult.fromJson(Map<String, dynamic> json) =>
      AdminGrantResult(
        target: AdminGrantTarget.values.firstWhere(
          (t) => t.name == (json['target'] as String?),
          orElse: () => AdminGrantTarget.hearts,
        ),
        applied: (json['applied'] as num?)?.toInt() ?? 0,
        hearts: (json['hearts'] as num?)?.toInt() ?? 0,
        gems: (json['gems'] as num?)?.toInt() ?? 0,
        xp: (json['xp'] as num?)?.toInt() ?? 0,
      );
}

/// One fingerprint group from the admin_client_errors RPC: [count] events
/// sharing a fingerprint, with the latest message/stack as representative.
class AdminErrorGroup {
  final String fingerprint;
  final int count;
  final int users;
  final String message;
  final String stack;
  final String? appVersion;
  final String? platform;
  final String? device;
  final DateTime? latestAt;

  const AdminErrorGroup({
    required this.fingerprint,
    required this.count,
    required this.users,
    required this.message,
    required this.stack,
    required this.appVersion,
    required this.platform,
    required this.device,
    required this.latestAt,
  });

  factory AdminErrorGroup.fromJson(Map<String, dynamic> json) =>
      AdminErrorGroup(
        fingerprint: json['fingerprint'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
        users: (json['users'] as num?)?.toInt() ?? 0,
        message: json['message'] as String? ?? '',
        stack: json['stack'] as String? ?? '',
        appVersion: json['app_version'] as String?,
        platform: json['platform'] as String?,
        device: json['device'] as String?,
        latestAt: json['latest_at'] is String
            ? DateTime.tryParse(json['latest_at'] as String)
            : null,
      );
}

/// Payload of admin_client_errors: [totalEvents] counts every stored event
/// (even when [groups] is truncated by p_limit).
class AdminClientErrorsPayload {
  final int totalEvents;
  final List<AdminErrorGroup> groups;

  const AdminClientErrorsPayload({
    required this.totalEvents,
    required this.groups,
  });

  factory AdminClientErrorsPayload.fromJson(Map<String, dynamic> json) {
    final raw = json['groups'] as List? ?? const [];
    return AdminClientErrorsPayload(
      totalEvents: (json['total_events'] as num?)?.toInt() ?? 0,
      groups: [
        for (final g in raw)
          if (g is Map) AdminErrorGroup.fromJson(Map<String, dynamic>.from(g)),
      ],
    );
  }
}

/// One signup-day cohort (admin_retention RPC). [d1]/[d7]/[d30] are percents
/// 0..100; null = cohort is too young to measure that horizon yet.
class AdminRetentionCohort {
  final DateTime? date;
  final int users;
  final double? d1;
  final double? d7;
  final double? d30;

  const AdminRetentionCohort({
    required this.date,
    required this.users,
    required this.d1,
    required this.d7,
    required this.d30,
  });

  factory AdminRetentionCohort.fromJson(Map<String, dynamic> json) =>
      AdminRetentionCohort(
        date: json['date'] is String
            ? DateTime.tryParse(json['date'] as String)
            : null,
        users: (json['users'] as num?)?.toInt() ?? 0,
        d1: (json['d1'] as num?)?.toDouble(),
        d7: (json['d7'] as num?)?.toDouble(),
        d30: (json['d30'] as num?)?.toDouble(),
      );
}

/// Pooled retention over mature cohorts only (eligibleN = users old enough
/// to measure horizon N; when 0 the UI should show '—', not 0%).
class AdminRetentionSummary {
  final double d1;
  final double d7;
  final double d30;
  final int eligible1;
  final int eligible7;
  final int eligible30;
  final int users;
  final int days;

  const AdminRetentionSummary({
    required this.d1,
    required this.d7,
    required this.d30,
    required this.eligible1,
    required this.eligible7,
    required this.eligible30,
    required this.users,
    required this.days,
  });

  factory AdminRetentionSummary.fromJson(Map<String, dynamic> json) =>
      AdminRetentionSummary(
        d1: (json['d1'] as num?)?.toDouble() ?? 0,
        d7: (json['d7'] as num?)?.toDouble() ?? 0,
        d30: (json['d30'] as num?)?.toDouble() ?? 0,
        eligible1: (json['eligible1'] as num?)?.toInt() ?? 0,
        eligible7: (json['eligible7'] as num?)?.toInt() ?? 0,
        eligible30: (json['eligible30'] as num?)?.toInt() ?? 0,
        users: (json['users'] as num?)?.toInt() ?? 0,
        days: (json['days'] as num?)?.toInt() ?? 0,
      );
}

/// Payload of admin_retention: pooled [summary] + per-cohort rows (newest
/// data is limited by p_days, 7..90).
class AdminRetentionPayload {
  final AdminRetentionSummary summary;
  final List<AdminRetentionCohort> cohorts;

  const AdminRetentionPayload({required this.summary, required this.cohorts});

  factory AdminRetentionPayload.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'];
    final cohorts = json['cohorts'] as List? ?? const [];
    return AdminRetentionPayload(
      summary: AdminRetentionSummary.fromJson(
        summary is Map ? Map<String, dynamic>.from(summary) : const {},
      ),
      cohorts: [
        for (final c in cohorts)
          if (c is Map)
            AdminRetentionCohort.fromJson(Map<String, dynamic>.from(c)),
      ],
    );
  }
}

/// One question's aggregated accuracy (admin_question_stats RPC).
/// `attempts` is answer count across all users (server pre-filters by
/// p_min_attempts), `users` = distinct answerers.
class AdminQuestionStat {
  final String questionId;
  final String subjectId;
  final String subjectName;
  final int lessonIndex;
  final String type;
  final String? difficulty;
  final String snippet;
  final int attempts;
  final int users;
  final int correct;
  final int wrong;
  final double accuracy;

  const AdminQuestionStat({
    required this.questionId,
    required this.subjectId,
    required this.subjectName,
    required this.lessonIndex,
    required this.type,
    required this.difficulty,
    required this.snippet,
    required this.attempts,
    required this.users,
    required this.correct,
    required this.wrong,
    required this.accuracy,
  });

  /// Triage thresholds (applied only where the server's min_attempts
  /// filter already passed — no single-answer noise).
  bool get isTooHard => accuracy < 40;
  bool get isTooEasy => accuracy > 95;

  factory AdminQuestionStat.fromJson(Map<String, dynamic> json) =>
      AdminQuestionStat(
        questionId: (json['question_id'] as String?) ?? '',
        subjectId: (json['subject_id'] as String?) ?? '',
        subjectName: (json['subject_name'] as String?) ?? '',
        lessonIndex: (json['lesson_index'] as num?)?.toInt() ?? 0,
        type: (json['type'] as String?) ?? '',
        difficulty: json['difficulty'] as String?,
        snippet: (json['snippet'] as String?) ?? '',
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        users: (json['users'] as num?)?.toInt() ?? 0,
        correct: (json['correct'] as num?)?.toInt() ?? 0,
        wrong: (json['wrong'] as num?)?.toInt() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      );
}

/// Full admin_question_stats payload: coverage summary + ranked rows
/// (hardest first, server-side order).
class AdminQuestionStatsPayload {
  final int questionsTotal;
  final int questionsAnswered;
  final int answersTotal;
  final int minAttempts;
  final List<AdminQuestionStat> questions;

  const AdminQuestionStatsPayload({
    required this.questionsTotal,
    required this.questionsAnswered,
    required this.answersTotal,
    required this.minAttempts,
    required this.questions,
  });

  factory AdminQuestionStatsPayload.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? const {};
    return AdminQuestionStatsPayload(
      questionsTotal: (summary['questions_total'] as num?)?.toInt() ?? 0,
      questionsAnswered: (summary['questions_answered'] as num?)?.toInt() ?? 0,
      answersTotal: (summary['answers_total'] as num?)?.toInt() ?? 0,
      minAttempts: (summary['min_attempts'] as num?)?.toInt() ?? 0,
      questions: [
        for (final row in (json['questions'] as List<dynamic>? ?? const []))
          AdminQuestionStat.fromJson(row as Map<String, dynamic>),
      ],
    );
  }
}

/// One registered push device (admin_push_health RPC). Raw FCM tokens are
/// never returned — only platform + registration recency.
class AdminPushDevice {
  final String userId;
  final String displayName;
  final String platform;
  final DateTime updatedAt;

  const AdminPushDevice({
    required this.userId,
    required this.displayName,
    required this.platform,
    required this.updatedAt,
  });

  factory AdminPushDevice.fromJson(Map<String, dynamic> json) =>
      AdminPushDevice(
        userId: (json['user_id'] as String?) ?? '',
        displayName: (json['display_name'] as String?) ?? '',
        platform: (json['platform'] as String?) ?? '',
        updatedAt:
            DateTime.tryParse((json['updated_at'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// One push_log aggregation row: `sends` markers of `kind` on `day`.
class AdminPushLogDay {
  final DateTime day;
  final String kind;
  final int sends;

  const AdminPushLogDay({
    required this.day,
    required this.kind,
    required this.sends,
  });

  factory AdminPushLogDay.fromJson(Map<String, dynamic> json) =>
      AdminPushLogDay(
        day:
            DateTime.tryParse((json['day'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        kind: (json['kind'] as String?) ?? '',
        sends: (json['sends'] as num?)?.toInt() ?? 0,
      );
}

/// Push health payload (admin_push_health RPC): token coverage, platform
/// breakdown, devices and the last 14 days of send markers.
class AdminPushHealth {
  final int usersTotal;
  final int tokensTotal;
  final int tokensUsers;
  final double coveragePct;
  final Map<String, int> platforms;
  final DateTime? lastRegisteredAt;
  final List<AdminPushDevice> devices;
  final List<AdminPushLogDay> log14d;

  const AdminPushHealth({
    required this.usersTotal,
    required this.tokensTotal,
    required this.tokensUsers,
    required this.coveragePct,
    required this.platforms,
    required this.lastRegisteredAt,
    required this.devices,
    required this.log14d,
  });

  factory AdminPushHealth.fromJson(Map<String, dynamic> json) {
    Map<String, int> asCountMap(Object? raw) {
      if (raw is! Map<String, dynamic>) return const {};
      return {
        for (final e in raw.entries) e.key: (e.value as num?)?.toInt() ?? 0,
      };
    }

    return AdminPushHealth(
      usersTotal: (json['users_total'] as num?)?.toInt() ?? 0,
      tokensTotal: (json['tokens_total'] as num?)?.toInt() ?? 0,
      tokensUsers: (json['tokens_users'] as num?)?.toInt() ?? 0,
      coveragePct: (json['coverage_pct'] as num?)?.toDouble() ?? 0,
      platforms: asCountMap(json['platforms']),
      lastRegisteredAt: DateTime.tryParse(
        (json['last_registered_at'] as String?) ?? '',
      ),
      devices: [
        for (final row in (json['devices'] as List<dynamic>? ?? const []))
          AdminPushDevice.fromJson(row as Map<String, dynamic>),
      ],
      log14d: [
        for (final row in (json['log_14d'] as List<dynamic>? ?? const []))
          AdminPushLogDay.fromJson(row as Map<String, dynamic>),
      ],
    );
  }
}
