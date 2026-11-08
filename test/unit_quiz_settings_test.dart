import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/models/question.dart';
import 'package:haffar/models/unit.dart';
import 'package:haffar/services/lesson_unlocks.dart';

Question _q(String id) => Question(
  id: id,
  subjectId: 'math',
  lessonIndex: 0,
  type: QuestionType.multipleChoice,
  text: 'q $id',
  options: const ['a', 'b', 'c'],
  correctIndex: 0,
);

Unit _unit({int? quizSize, List<String> quizIds = const []}) => Unit(
  id: 'unit-1',
  subjectId: 'math',
  index: 0,
  title: 'وحدة',
  quizSize: quizSize,
  quizIds: quizIds,
);

void main() {
  group('buildUnitQuiz delivery config (DB-driven only — no built-ins)', () {
    test('an unconfigured unit yields an empty quiz', () {
      final quiz = buildUnitQuiz(
        subjectId: 'math',
        unitIndex: 0,
        unit: _unit(),
        pool: List.generate(20, (i) => _q('q$i')),
      );
      expect(quiz, isEmpty);
    });

    test('the configured count is the only source of the quiz size', () {
      final quiz = buildUnitQuiz(
        subjectId: 'math',
        unitIndex: 0,
        unit: _unit(quizSize: 6),
        pool: List.generate(20, (i) => _q('q$i')),
      );
      expect(quiz.length, 6);
    });

    test('the historical fixed count of 10 comes from unit config alone', () {
      final quiz = buildUnitQuiz(
        subjectId: 'math',
        unitIndex: 0,
        unit: _unit(quizSize: 10),
        pool: List.generate(20, (i) => _q('q$i')),
      );
      expect(quiz.length, 10);
    });

    test('a count larger than the pool is clamped to the pool', () {
      final quiz = buildUnitQuiz(
        subjectId: 'math',
        unitIndex: 0,
        unit: _unit(quizSize: 50),
        pool: [_q('only')],
      );
      expect(quiz.length, 1);
    });

    test('pinned quizIds win over the quizSize and keep display order', () {
      final quiz = buildUnitQuiz(
        subjectId: 'math',
        unitIndex: 0,
        pool: List.generate(20, (i) => _q('q$i')),
        unit: _unit(quizSize: 10, quizIds: ['q5', 'q2']),
      );
      expect(quiz.map((q) => q.id).toList(), ['q5', 'q2']);
    });

    test('pinned ids skip unknown questions but keep the known ones', () {
      final quiz = buildUnitQuiz(
        subjectId: 'math',
        unitIndex: 0,
        pool: List.generate(20, (i) => _q('q$i')),
        unit: _unit(quizIds: ['q9', 'MISSING', 'q3']),
      );
      expect(quiz.map((q) => q.id).toList(), ['q9', 'q3']);
    });

    test('a fully-stale pinned list falls through to the unit count', () {
      final quiz = buildUnitQuiz(
        subjectId: 'math',
        unitIndex: 0,
        pool: List.generate(20, (i) => _q('q$i')),
        unit: _unit(quizSize: 4, quizIds: ['gone-1', 'gone-2']),
      );
      expect(quiz.length, 4);
    });

    test('a fully-stale pinned list with no count yields an empty quiz', () {
      final quiz = buildUnitQuiz(
        subjectId: 'math',
        unitIndex: 0,
        pool: List.generate(20, (i) => _q('q$i')),
        unit: _unit(quizIds: ['gone-1']),
      );
      expect(quiz, isEmpty);
    });

    test('an empty pool never throws, whatever the config says', () {
      final quiz = buildUnitQuiz(
        subjectId: 'math',
        unitIndex: 0,
        unit: _unit(quizSize: 10),
        pool: const [],
      );
      expect(quiz, isEmpty);
    });
  });

  group('Unit.fromMap delivery fields', () {
    test('parses quiz_size and quiz_ids from the row payload', () {
      final unit = Unit.fromMap({
        'id': 'u1',
        'subject_id': 'math',
        'unit_index': 2,
        'title': 'وحدة',
        'quiz_size': 12,
        'quiz_ids': ['m_l1_q1', 'm_l2_q3'],
      });
      expect(unit.quizSize, 12);
      expect(unit.quizIds, ['m_l1_q1', 'm_l2_q3']);
    });

    test('missing columns keep the unconfigured defaults', () {
      final unit = Unit.fromMap({
        'id': 'u2',
        'subject_id': 'arabic',
        'unit_index': 0,
        'title': 'وحدة',
      });
      expect(unit.quizSize, isNull);
      expect(unit.quizIds, isEmpty);
    });
  });
}
