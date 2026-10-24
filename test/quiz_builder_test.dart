import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/models/question.dart';
import 'package:haffar/services/quiz_builder.dart';

Question _q(String id, {List<String>? options, int correctIndex = 0}) =>
    Question(
      id: id,
      subjectId: 'math',
      lessonIndex: 0,
      type: QuestionType.multipleChoice,
      text: 'q $id',
      options: options ?? const ['a', 'b', 'c'],
      correctIndex: correctIndex,
    );

void main() {
  group('QuizBuilder.build', () {
    test('returns at most count questions', () {
      final pool = List.generate(10, (i) => _q('q$i'));
      final quiz = QuizBuilder.build(
        'lesson:0',
        pool,
        count: 3,
        random: Random(1),
      );
      expect(quiz.length, 3);
    });

    test('does not repeat questions when enough fresh ones exist', () {
      final pool = List.generate(10, (i) => _q('q$i'));
      final first = QuizBuilder.build(
        'repeat',
        pool,
        count: 3,
        random: Random(2),
      );
      final second = QuizBuilder.build(
        'repeat',
        pool,
        count: 3,
        random: Random(3),
      );
      final firstIds = first.map((q) => q.id).toSet();
      final overlap = second.where((q) => firstIds.contains(q.id));
      expect(overlap, isEmpty);
    });

    test('clamps count to pool size', () {
      final pool = [_q('only')];
      final quiz = QuizBuilder.build('tiny', pool, count: 5, random: Random(4));
      expect(quiz.length, 1);
    });

    test('empty pool returns an empty quiz instead of throwing', () {
      // Regression: `count.clamp(1, 0)` used to throw ArgumentError and
      // crashed the lesson screen when a lesson had no questions yet.
      final quiz = QuizBuilder.build(
        'empty',
        const [],
        count: 10,
        random: Random(1),
      );
      expect(quiz, isEmpty);
    });

    test('shuffles options and keeps correctIndex aligned', () {
      final original = _q(
        'mc',
        options: const ['right', 'wrong1', 'wrong2'],
        correctIndex: 0,
      );
      final pool = [original];
      final quiz = QuizBuilder.build(
        'shuffle',
        pool,
        count: 1,
        random: Random(7),
      );
      final built = quiz.first;
      expect(built.options.length, 3);
      expect(built.options[built.correctIndex], 'right');
    });

    test('ordering tiles shuffle while the correct sequence survives', () {
      final original = Question(
        id: 'ord',
        subjectId: 'math',
        lessonIndex: 0,
        type: QuestionType.ordering,
        text: 'رتب العناصر',
        options: const ['1', '2', '3'],
        correctWords: const ['3', '1', '2'],
      );
      var sawShuffle = false;
      for (var seed = 0; seed < 40; seed++) {
        final quiz = QuizBuilder.build(
          'ordering-seed-$seed',
          [original],
          count: 1,
          random: Random(seed),
        );
        final built = quiz.first;
        expect(built.options.toSet(), original.options.toSet());
        expect(built.correctWords, original.correctWords);
        if (built.options.join('|') != original.options.join('|')) {
          sawShuffle = true;
        }
      }
      expect(sawShuffle, isTrue);
    });
  });
}
