import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/models/admin_stats.dart';

void main() {
  group('AdminDayStat', () {
    test('parses overview series rows', () {
      final stat = AdminDayStat.fromJson({
        'day': '2026-09-12',
        'signups': 3,
        'lessons': 10,
        'attempts': 42,
        'xp': 250,
      });
      expect(stat.day, DateTime(2026, 9, 12));
      expect(stat.signups, 3);
      expect(stat.lessons, 10);
      expect(stat.attempts, 42);
      expect(stat.xp, 250);
      expect(stat.activeUsers, 0);
    });

    test('parses activity rows with active_users', () {
      final stat = AdminDayStat.fromJson({
        'day': '2026-09-24',
        'signups': 0,
        'lessons': 1,
        'attempts': 0,
        'xp': 0,
        'active_users': 5,
      });
      expect(stat.activeUsers, 5);
    });

    test('missing numeric fields default to zero', () {
      final stat = AdminDayStat.fromJson({'day': '2026-01-01'});
      expect(stat.signups, 0);
      expect(stat.attempts, 0);
      expect(stat.xp, 0);
    });
  });

  group('AdminOverview', () {
    final json = <String, dynamic>{
      'total_users': 120,
      'new_users_7d': 4,
      'new_users_30d': 18,
      'active_today': 7,
      'lessons_completed': 900,
      'unit_exercises_completed': 210,
      'attempts': 5200,
      'avg_accuracy': 76.4,
      'subjects': 9,
      'lessons': 120,
      'questions': 1800,
      'push_tokens': 30,
      'notifications_today': 1,
      'subscribed_users': 5,
      'leagues': {'bronze': 115, 'mvp': 5},
      'series': [
        {
          'day': '2026-09-12',
          'signups': 1,
          'lessons': 4,
          'attempts': 20,
          'xp': 90,
        },
        {
          'day': '2026-09-13',
          'signups': 0,
          'lessons': 6,
          'attempts': 31,
          'xp': 120,
        },
      ],
    };

    test('parses full payload', () {
      final o = AdminOverview.fromJson(json);
      expect(o.totalUsers, 120);
      expect(o.newUsers7d, 4);
      expect(o.newUsers30d, 18);
      expect(o.activeToday, 7);
      expect(o.lessonsCompleted, 900);
      expect(o.unitExercisesCompleted, 210);
      expect(o.attempts, 5200);
      expect(o.avgAccuracy, 76.4);
      expect(o.subjects, 9);
      expect(o.lessons, 120);
      expect(o.questions, 1800);
      expect(o.pushTokens, 30);
      expect(o.notificationsToday, 1);
      expect(o.subscribedUsers, 5);
      expect(o.leagues, {'bronze': 115, 'mvp': 5});
      expect(o.series, hasLength(2));
      expect(o.series.first.day, DateTime(2026, 9, 12));
      expect(o.series.last.lessons, 6);
    });

    test('tolerates nulls and empty series', () {
      final o = AdminOverview.fromJson(const {});
      expect(o.totalUsers, 0);
      expect(o.avgAccuracy, 0);
      expect(o.subscribedUsers, 0);
      expect(o.leagues, isEmpty);
      expect(o.series, isEmpty);
    });
  });

  group('AdminUserRow / AdminUsersPage', () {
    final rowJson = <String, dynamic>{
      'id': 'ece10cce-1f20-4b3a-a62e-61b52c6fcdd2',
      'email': 'modather@example.com',
      'display_name': 'مدرثر',
      'xp': 190,
      'streak': 31,
      'gems': 12,
      'hearts': 5,
      'league': 'gold',
      'is_subscribed': false,
      'is_admin': true,
      'created_at': '2026-08-01T10:00:00+00:00',
      'last_streak_date': '2026-09-25',
      'last_active_at': '2026-09-25T12:44:12.514162+00:00',
      'lessons_done': 4,
    };

    test('parses a user row', () {
      final u = AdminUserRow.fromJson(rowJson);
      expect(u.id, 'ece10cce-1f20-4b3a-a62e-61b52c6fcdd2');
      expect(u.email, 'modather@example.com');
      expect(u.displayName, 'مدرثر');
      expect(u.xp, 190);
      expect(u.streak, 31);
      expect(u.isAdmin, isTrue);
      expect(u.isSubscribed, isFalse);
      expect(u.lastStreakDate, DateTime(2026, 9, 25));
      expect(u.lastActiveAt, isNotNull);
      expect(u.lastActiveAt!.hour, isNonNegative);
      expect(u.lessonsDone, 4);
    });

    test('nulls fall back to defaults', () {
      final u = AdminUserRow.fromJson({
        'id': 'u1',
        'created_at': '2026-01-01T00:00:00+00:00',
      });
      expect(u.email, '');
      expect(u.displayName, '');
      expect(u.league, '');
      expect(u.isAdmin, isFalse);
      expect(u.lastStreakDate, isNull);
      expect(u.lastActiveAt, isNull);
      expect(u.streak, 0);
    });

    test('parses a page with total', () {
      final page = AdminUsersPage.fromJson({
        'total': 120,
        'users': [rowJson],
      });
      expect(page.total, 120);
      expect(page.users, hasLength(1));
      expect(page.users.first.isAdmin, isTrue);
    });

    test('empty payload', () {
      final page = AdminUsersPage.fromJson(const {});
      expect(page.total, 0);
      expect(page.users, isEmpty);
    });
  });

  group('AdminUserDetail', () {
    final json = <String, dynamic>{
      'profile': {
        'id': 'u1',
        'email': 'a@b.c',
        'display_name': 'أحمد',
        'xp': 190,
        'streak': 1,
        'gems': 3,
        'hearts': 5,
        'league': 'bronze',
        'is_subscribed': false,
        'is_admin': false,
        'created_at': '2026-09-01T00:00:00+00:00',
        'last_streak_date': null,
        'lessons_done': 2,
        'units_done': 1,
        'attempts': 40,
        'accuracy': 70.5,
      },
      'by_subject': [
        {
          'subject_id': 'alphabet',
          'name': 'الحروف',
          'completed': 2,
          'total': 18,
        },
      ],
      'recent_attempts': [
        {
          'id': 'a1',
          'subject_id': 'alphabet',
          'kind': 'lesson',
          'ref_index': 3,
          'total': 5,
          'correct': 4,
          'created_at': '2026-09-20T12:00:00+00:00',
        },
      ],
      'recent_xp': [
        {
          'amount': 10,
          'source': 'lesson',
          'created_at': '2026-09-20T12:00:00+00:00',
        },
      ],
      'recent_hearts': [
        {
          'delta': -1,
          'reason': 'wrong',
          'created_at': '2026-09-20T12:00:00+00:00',
        },
      ],
    };

    test('parses nested detail payload', () {
      final d = AdminUserDetail.fromJson(json);
      expect(d.profile.displayName, 'أحمد');
      expect(d.unitsDone, 1);
      expect(d.attempts, 40);
      expect(d.accuracy, 70.5);
      expect(d.bySubject.single.name, 'الحروف');
      expect(d.bySubject.single.completed, 2);
      expect(d.recentAttempts.single.accuracy, 80);
      expect(d.recentXp.single.amount, 10);
      expect(d.recentHearts.single.delta, -1);
    });

    test('tolerates empty payload', () {
      final d = AdminUserDetail.fromJson(const {});
      expect(d.profile.id, '');
      expect(d.bySubject, isEmpty);
      expect(d.recentAttempts, isEmpty);
    });
  });

  group('AdminSubjectStat', () {
    test('parses content stats with type/difficulty maps and lessons', () {
      final s = AdminSubjectStat.fromJson({
        'id': 'alphabet',
        'name': 'الحروف',
        'icon': 'abc',
        'color_hex': '#4285F4',
        'sort_order': 1,
        'units': 2,
        'lessons': 18,
        'questions': 240,
        'completions': 56,
        'question_types': {'mcq': 100, 'listen_choose': 80, 'match': 60},
        'difficulties': {'easy': 120, 'medium': 80, 'hard': 40},
        'lessons_detail': [
          {'lesson_index': 0, 'title': 'الحروف الأولى', 'completed_by': 40},
          {'lesson_index': 1, 'title': 'الحروف الثانية', 'completed_by': 30},
        ],
      });
      expect(s.name, 'الحروف');
      expect(s.units, 2);
      expect(s.lessons, 18);
      expect(s.questions, 240);
      expect(s.completions, 56);
      expect(s.questionTypes['mcq'], 100);
      expect(s.difficulties['hard'], 40);
      expect(s.lessonsDetail, hasLength(2));
      expect(s.lessonsDetail.first.completedBy, 40);
    });

    test('missing maps become empty', () {
      final s = AdminSubjectStat.fromJson({'id': 'x', 'name': 'X'});
      expect(s.questionTypes, isEmpty);
      expect(s.lessonsDetail, isEmpty);
      expect(s.colorHex, isNull);
    });
  });

  group('AdminPushResult', () {
    test('parses edge function response', () {
      final r = AdminPushResult.fromJson({
        'sent': 2,
        'dropped': 1,
        'targets': 3,
      });
      expect(r.sent, 2);
      expect(r.dropped, 1);
      expect(r.targets, 3);
    });
  });

  group('AdminResetTarget', () {
    test('names match the RPC contract', () {
      expect(AdminResetTarget.streak.name, 'streak');
      expect(AdminResetTarget.hearts.name, 'hearts');
      expect(AdminResetTarget.progress.name, 'progress');
    });
  });

  group('AdminGrantTarget', () {
    test('names match the RPC contract', () {
      expect(AdminGrantTarget.hearts.name, 'hearts');
      expect(AdminGrantTarget.gems.name, 'gems');
      expect(AdminGrantTarget.xp.name, 'xp');
    });
  });

  group('AdminGrantResult', () {
    test('parses a full grant payload', () {
      final r = AdminGrantResult.fromJson(const {
        'ok': true,
        'target': 'gems',
        'applied': 7,
        'hearts': 3,
        'gems': 7,
        'xp': 215,
      });
      expect(r.target, AdminGrantTarget.gems);
      expect(r.applied, 7);
      expect(r.hearts, 3);
      expect(r.gems, 7);
      expect(r.xp, 215);
    });

    test('unknown target falls back to hearts, missing numbers to 0', () {
      final r = AdminGrantResult.fromJson(const {'target': 'bogus'});
      expect(r.target, AdminGrantTarget.hearts);
      expect(r.applied, 0);
      expect(r.hearts, 0);
      expect(r.gems, 0);
      expect(r.xp, 0);
    });

    test('parsed applied may be less than requested (hearts cap)', () {
      final r = AdminGrantResult.fromJson(const {
        'target': 'hearts',
        'applied': 4,
        'hearts': 7,
        'gems': 0,
        'xp': 190,
      });
      expect(r.applied, 4);
      expect(r.hearts, 7);
    });
  });

  group('AdminErrorGroup', () {
    test('parses a full grouped error row', () {
      final g = AdminErrorGroup.fromJson(const {
        'fingerprint': 'a1b2c3',
        'count': 2,
        'users': 1,
        'latest_at': '2026-09-25T18:17:08.012765+00:00',
        'message': 'TestError: boom',
        'stack': '#0 main',
        'app_version': '1.0.0',
        'platform': 'android',
        'device': 'sdk',
      });
      expect(g.fingerprint, 'a1b2c3');
      expect(g.count, 2);
      expect(g.users, 1);
      expect(g.message, 'TestError: boom');
      expect(g.stack, '#0 main');
      expect(g.appVersion, '1.0.0');
      expect(g.platform, 'android');
      expect(g.device, 'sdk');
      expect(g.latestAt, isNotNull);
      expect(g.latestAt!.toUtc().year, 2026);
    });

    test('missing optional fields fall back to defaults', () {
      final g = AdminErrorGroup.fromJson(const {'count': 5});
      expect(g.fingerprint, '');
      expect(g.count, 5);
      expect(g.users, 0);
      expect(g.message, '');
      expect(g.stack, '');
      expect(g.appVersion, isNull);
      expect(g.platform, isNull);
      expect(g.device, isNull);
      expect(g.latestAt, isNull);
    });

    test('invalid latest_at string parses as null', () {
      final g = AdminErrorGroup.fromJson(const {
        'fingerprint': 'x',
        'latest_at': 'not-a-date',
      });
      expect(g.latestAt, isNull);
    });
  });

  group('AdminClientErrorsPayload', () {
    test('parses total + groups', () {
      final p = AdminClientErrorsPayload.fromJson(const {
        'total_events': 3,
        'groups': [
          {'fingerprint': 'a', 'count': 2, 'users': 1, 'message': 'm'},
          {'fingerprint': 'b', 'count': 1, 'users': 1, 'message': 'n'},
        ],
      });
      expect(p.totalEvents, 3);
      expect(p.groups, hasLength(2));
      expect(p.groups.first.fingerprint, 'a');
      expect(p.groups.last.count, 1);
    });

    test('empty / partial payload tolerated', () {
      expect(AdminClientErrorsPayload.fromJson(const {}).totalEvents, 0);
      final p = AdminClientErrorsPayload.fromJson(const {
        'total_events': 7,
        'groups': [42, null],
      });
      expect(p.totalEvents, 7);
      expect(p.groups, isEmpty);
    });
  });

  group('AdminRetention', () {
    test('parses a mature cohort row', () {
      final c = AdminRetentionCohort.fromJson(const {
        'date': '2026-09-07',
        'users': 2,
        'd1': 50,
        'd7': 0,
        'd30': 33.3,
      });
      expect(c.date, DateTime(2026, 9, 7));
      expect(c.users, 2);
      expect(c.d1, 50);
      expect(c.d7, 0);
      expect(c.d30, 33.3);
    });

    test('immature cohort keeps null horizons', () {
      final c = AdminRetentionCohort.fromJson(const {
        'date': '2026-09-25',
        'users': 5,
        'd1': null,
        'd7': null,
        'd30': null,
      });
      expect(c.d1, isNull);
      expect(c.d7, isNull);
      expect(c.d30, isNull);
      expect(c.users, 5);
    });

    test('summary parses pooled rates + eligible counts', () {
      final s = AdminRetentionSummary.fromJson(const {
        'd1': 45.5,
        'd7': 0,
        'd30': 0,
        'eligible1': 11,
        'eligible7': 7,
        'eligible30': 0,
        'users': 16,
        'days': 30,
      });
      expect(s.d1, 45.5);
      expect(s.d7, 0);
      expect(s.eligible1, 11);
      expect(s.eligible30, 0);
      expect(s.users, 16);
      expect(s.days, 30);
    });

    test('payload parses summary + cohorts', () {
      final p = AdminRetentionPayload.fromJson(const {
        'summary': {'d1': 45.5, 'eligible1': 11},
        'cohorts': [
          {'date': '2026-08-27', 'users': 1, 'd1': 100, 'd7': 0, 'd30': null},
          {
            'date': '2026-09-25',
            'users': 5,
            'd1': null,
            'd7': null,
            'd30': null,
          },
        ],
      });
      expect(p.summary.d1, 45.5);
      expect(p.summary.eligible1, 11);
      expect(p.summary.days, 0);
      expect(p.cohorts, hasLength(2));
      expect(p.cohorts.first.d1, 100);
      expect(p.cohorts.last.d1, isNull);
    });

    test('missing summary / cohorts tolerated', () {
      final p = AdminRetentionPayload.fromJson(const {});
      expect(p.summary.users, 0);
      expect(p.summary.d1, 0);
      expect(p.cohorts, isEmpty);
      final p2 = AdminRetentionPayload.fromJson(const {
        'summary': 'not-a-map',
        'cohorts': [7],
      });
      expect(p2.summary.users, 0);
      expect(p2.cohorts, isEmpty);
    });
  });

  group('AdminLessonStat accuracy', () {
    test('parses attempts + accuracy when present', () {
      final l = AdminLessonStat.fromJson({
        'lesson_index': 0,
        'title': 'الخلية',
        'completed_by': 4,
        'attempts': 7,
        'accuracy': 28.6,
      });
      expect(l.attempts, 7);
      expect(l.accuracy, 28.6);
      expect(l.completedBy, 4);
    });

    test('accuracy is null and attempts 0 without attempts data', () {
      final l = AdminLessonStat.fromJson({
        'lesson_index': 1,
        'title': 'درس',
        'completed_by': 2,
        'accuracy': null,
      });
      expect(l.attempts, 0);
      expect(l.accuracy, isNull);
    });
  });

  group('AdminQuestionStat', () {
    final rowJson = <String, dynamic>{
      'question_id': 'ict_l1_q6',
      'subject_id': 'ict',
      'subject_name': 'تكنولوجيا المعلومات والاتصالات',
      'lesson_index': 0,
      'type': 'trueFalse',
      'difficulty': 'easy',
      'snippet': 'اللوحة الأم تربط مكونات الحاسوب ببعضها.',
      'attempts': 5,
      'users': 3,
      'correct': 0,
      'wrong': 5,
      'accuracy': 0.0,
    };

    test('parses a question row', () {
      final q = AdminQuestionStat.fromJson(rowJson);
      expect(q.questionId, 'ict_l1_q6');
      expect(q.subjectId, 'ict');
      expect(q.subjectName, 'تكنولوجيا المعلومات والاتصالات');
      expect(q.lessonIndex, 0);
      expect(q.type, 'trueFalse');
      expect(q.difficulty, 'easy');
      expect(q.attempts, 5);
      expect(q.users, 3);
      expect(q.wrong, 5);
      expect(q.accuracy, 0);
    });

    test('triage flags: <40% too hard, >95% too easy, in-between none', () {
      expect(AdminQuestionStat.fromJson(rowJson).isTooHard, isTrue);
      expect(AdminQuestionStat.fromJson(rowJson).isTooEasy, isFalse);

      final tooEasy = AdminQuestionStat.fromJson({
        ...rowJson,
        'correct': 97,
        'wrong': 3,
        'accuracy': 97.0,
      });
      expect(tooEasy.isTooEasy, isTrue);
      expect(tooEasy.isTooHard, isFalse);

      final healthy = AdminQuestionStat.fromJson({
        ...rowJson,
        'correct': 60,
        'wrong': 40,
        'accuracy': 60.0,
      });
      expect(healthy.isTooHard, isFalse);
      expect(healthy.isTooEasy, isFalse);
    });

    test('missing optional fields fall back to defaults', () {
      final q = AdminQuestionStat.fromJson(const {'question_id': 'q1'});
      expect(q.subjectName, '');
      expect(q.difficulty, isNull);
      expect(q.attempts, 0);
      expect(q.accuracy, 0);
    });
  });

  group('AdminQuestionStatsPayload', () {
    test('parses summary + ranked questions', () {
      final p = AdminQuestionStatsPayload.fromJson({
        'summary': {
          'questions_total': 348,
          'questions_answered': 213,
          'answers_total': 526,
          'min_attempts': 3,
        },
        'questions': [
          {
            'question_id': 'ict_l1_q6',
            'subject_id': 'ict',
            'subject_name': 'تكنولوجيا المعلومات والاتصالات',
            'lesson_index': 0,
            'type': 'trueFalse',
            'difficulty': 'easy',
            'snippet': 'اللوحة الأم…',
            'attempts': 5,
            'users': 3,
            'correct': 0,
            'wrong': 5,
            'accuracy': 0.0,
          },
        ],
      });
      expect(p.questionsTotal, 348);
      expect(p.questionsAnswered, 213);
      expect(p.answersTotal, 526);
      expect(p.minAttempts, 3);
      expect(p.questions, hasLength(1));
      expect(p.questions.single.isTooHard, isTrue);
    });

    test('tolerates empty payload', () {
      final p = AdminQuestionStatsPayload.fromJson(const {});
      expect(p.questionsTotal, 0);
      expect(p.minAttempts, 0);
      expect(p.questions, isEmpty);
    });
  });

  group('AdminPushHealth', () {
    test('parses coverage, platforms, devices and send log', () {
      final h = AdminPushHealth.fromJson({
        'users_total': 21,
        'tokens_total': 4,
        'tokens_users': 3,
        'coverage_pct': 14.3,
        'platforms': {'android': 4},
        'last_registered_at': '2026-09-25T16:55:39.115943+00:00',
        'devices': [
          {
            'user_id': 'u1',
            'display_name': 'modather',
            'platform': 'android',
            'updated_at': '2026-09-25T16:55:39.115943+00:00',
          },
        ],
        'log_14d': [
          {'day': '2026-09-25', 'kind': 'streak', 'sends': 2},
        ],
      });
      expect(h.usersTotal, 21);
      expect(h.tokensTotal, 4);
      expect(h.tokensUsers, 3);
      expect(h.coveragePct, 14.3);
      expect(h.platforms['android'], 4);
      expect(h.lastRegisteredAt, isNotNull);
      expect(h.devices, hasLength(1));
      expect(h.devices.single.displayName, 'modather');
      expect(h.devices.single.platform, 'android');
      expect(h.log14d.single.kind, 'streak');
      expect(h.log14d.single.sends, 2);
      expect(h.log14d.single.day.day, 25);
    });

    test('tolerates empty / partial payload', () {
      final h = AdminPushHealth.fromJson(const {});
      expect(h.usersTotal, 0);
      expect(h.coveragePct, 0);
      expect(h.platforms, isEmpty);
      expect(h.lastRegisteredAt, isNull);
      expect(h.devices, isEmpty);
      expect(h.log14d, isEmpty);
    });

    test('device rows tolerate missing display_name', () {
      final h = AdminPushHealth.fromJson({
        'devices': [
          {'user_id': 'u1', 'platform': 'ios'},
        ],
      });
      expect(h.devices.single.displayName, '');
      expect(h.devices.single.platform, 'ios');
      expect(
        h.devices.single.updatedAt,
        DateTime.fromMillisecondsSinceEpoch(0),
      );
    });
  });
}
