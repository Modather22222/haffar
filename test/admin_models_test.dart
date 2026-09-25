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
      expect(o.series, hasLength(2));
      expect(o.series.first.day, DateTime(2026, 9, 12));
      expect(o.series.last.lessons, 6);
    });

    test('tolerates nulls and empty series', () {
      final o = AdminOverview.fromJson(const {});
      expect(o.totalUsers, 0);
      expect(o.avgAccuracy, 0);
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
}
