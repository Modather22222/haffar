import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/models/lesson.dart';
import 'package:haffar/models/question.dart';
import 'package:haffar/services/content_admin_repository.dart';
import 'package:haffar/services/lesson_unlocks.dart';
import 'package:haffar/services/quiz_builder.dart';
import 'package:haffar/utils/content_validators.dart';

Question _q(String id) => Question(
  id: id,
  subjectId: 'math',
  lessonIndex: 0,
  type: QuestionType.multipleChoice,
  text: 'q $id',
  options: const ['a', 'b', 'c'],
  correctIndex: 0,
);

Lesson _lesson({int? quizSize, List<String> quizIds = const []}) => Lesson(
  id: 'lesson-1',
  subjectId: 'math',
  unitIndex: 0,
  index: 0,
  title: 'درس',
  quizSize: quizSize,
  quizIds: quizIds,
);

void main() {
  group('buildLessonQuiz delivery config (DB-driven only — no built-ins)', () {
    test('an unconfigured lesson yields an empty quiz', () {
      final quiz = buildLessonQuiz(
        subjectId: 'math',
        lessonIndex: 0,
        lesson: _lesson(), // quiz_size stays null and nothing pinned
        pool: List.generate(10, (i) => _q('q$i')),
      );
      expect(quiz, isEmpty);
    });

    test('the configured count is the only source of the quiz size', () {
      final quiz = buildLessonQuiz(
        subjectId: 'math',
        lessonIndex: 0,
        lesson: _lesson(quizSize: 7),
        pool: List.generate(12, (i) => _q('q$i')),
      );
      expect(quiz.length, 7);
    });

    test('english follows its lesson config, not a built-in override', () {
      final pool = List.generate(12, (i) => _q('q$i'));
      final configured = buildLessonQuiz(
        subjectId: 'english',
        lessonIndex: 0,
        lesson: _lesson(quizSize: 10),
        pool: pool,
      );
      expect(configured.length, 10);
      final reconfigured = buildLessonQuiz(
        subjectId: 'english',
        lessonIndex: 0,
        lesson: _lesson(quizSize: 4),
        pool: pool,
      );
      expect(reconfigured.length, 4);
    });

    test('a count larger than the pool is clamped to the pool', () {
      final quiz = buildLessonQuiz(
        subjectId: 'math',
        lessonIndex: 0,
        lesson: _lesson(quizSize: 50),
        pool: [_q('only')],
      );
      expect(quiz.length, 1);
    });

    test('pinned quizIds win over the quizSize and keep display order', () {
      final quiz = buildLessonQuiz(
        subjectId: 'math',
        lessonIndex: 0,
        pool: List.generate(10, (i) => _q('q$i')),
        lesson: _lesson(quizSize: 5, quizIds: ['q3', 'q1']),
      );
      expect(quiz.map((q) => q.id).toList(), ['q3', 'q1']);
    });

    test('pinned ids skip unknown questions but keep the known ones', () {
      final quiz = buildLessonQuiz(
        subjectId: 'math',
        lessonIndex: 0,
        pool: List.generate(10, (i) => _q('q$i')),
        lesson: _lesson(quizIds: ['q9', 'MISSING', 'q0']),
      );
      expect(quiz.map((q) => q.id).toList(), ['q9', 'q0']);
    });

    test('a fully-stale pinned list falls through to the lesson count', () {
      final quiz = buildLessonQuiz(
        subjectId: 'math',
        lessonIndex: 0,
        pool: List.generate(10, (i) => _q('q$i')),
        lesson: _lesson(quizSize: 2, quizIds: ['gone-1', 'gone-2']),
      );
      expect(quiz.length, 2);
    });

    test('a fully-stale pinned list with no count yields an empty quiz', () {
      final quiz = buildLessonQuiz(
        subjectId: 'math',
        lessonIndex: 0,
        pool: List.generate(10, (i) => _q('q$i')),
        lesson: _lesson(quizIds: ['gone-1', 'gone-2']),
      );
      expect(quiz, isEmpty);
    });

    test('an empty pool never throws, whatever the config says', () {
      final quiz = buildLessonQuiz(
        subjectId: 'math',
        lessonIndex: 0,
        lesson: _lesson(quizSize: 3),
        pool: const [],
      );
      expect(quiz, isEmpty);
    });
  });

  group('QuizBuilder.pinned', () {
    test('empty pool or empty ids yield an empty selection', () {
      expect(QuizBuilder.pinned(const [], ['a']), isEmpty);
      expect(QuizBuilder.pinned([_q('a')], const []), isEmpty);
    });

    test('deduplicates repeated ids', () {
      final pinned = QuizBuilder.pinned(List.generate(10, (i) => _q('q$i')), [
        'q1',
        'q1',
        'q2',
      ]);
      expect(pinned.map((q) => q.id).toList(), ['q1', 'q2']);
    });

    test('each pinned question id exists in the produced quiz', () {
      final pool = List.generate(10, (i) => _q('q$i'));
      final pinned = QuizBuilder.pinned(pool, ['q2', 'q7']);
      final poolIds = pool.map((q) => q.id).toSet();
      for (final q in pinned) {
        expect(poolIds.contains(q.id), isTrue);
      }
    });
  });

  group('LessonQuizSettings', () {
    test('usesPinnedQuestions reflects the quizIds semantics', () {
      expect(_settings(quizIds: const []).usesPinnedQuestions, isFalse);
      expect(_settings(quizIds: const ['q1']).usesPinnedQuestions, isTrue);
    });
  });

  group('validateQuizSize', () {
    test('accepts the whole 1..200 range', () {
      expect(validateQuizSize(1), isNull);
      expect(validateQuizSize(200), isNull);
    });

    test('rejects values outside the CHECK constraint range', () {
      expect(validateQuizSize(0), isNotNull);
      expect(validateQuizSize(201), isNotNull);
      expect(validateQuizSize(-5), isNotNull);
    });
  });
}

LessonQuizSettings _settings({required List<String> quizIds}) =>
    LessonQuizSettings(
      id: 'lesson-1',
      title: 't',
      quizSize: null,
      quizIds: quizIds,
    );
