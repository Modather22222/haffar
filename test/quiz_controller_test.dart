import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/models/lesson.dart';
import 'package:haffar/models/question.dart';
import 'package:haffar/models/quiz_attempt.dart';
import 'package:haffar/services/lesson_unlocks.dart';
import 'package:haffar/utils/game_constants.dart';
import 'package:haffar/widgets/quiz_controller.dart';

class _Lookup implements LessonUnlockLookup {
  final List<Lesson> lessons;
  _Lookup(this.lessons);

  @override
  List<Lesson> lessonsOf(String subjectId) => lessons;
}

class _FakeSaver implements AttemptSaver {
  int calls = 0;
  List<AttemptDetail> lastDetails = const [];

  @override
  Future<void> save({
    required String subjectId,
    required String kind,
    required int refIndex,
    required List<AttemptDetail> details,
  }) async {
    calls++;
    lastDetails = details;
  }
}

Question _q(String id) => Question(
  id: id,
  subjectId: 'math',
  lessonIndex: 0,
  type: QuestionType.multipleChoice,
  text: 'q $id',
  options: const ['a', 'b'],
  correctIndex: 0,
);

Lesson _lesson(String id, int index, int unitIndex) => Lesson(
  id: id,
  subjectId: 'math',
  index: index,
  unitIndex: unitIndex,
  title: 't$id',
);

void main() {
  group('LessonUnlocks', () {
    final lessons = [
      _lesson('l0', 0, 0),
      _lesson('l1', 1, 0),
      _lesson('l3', 3, 1),
    ];
    final lookup = _Lookup(lessons);

    test('first lesson of unit is always unlocked as unit start', () {
      expect(LessonUnlocks.isUnitStart(lookup, 'math', 0), isTrue);
      expect(LessonUnlocks.isUnitStart(lookup, 'math', 3), isTrue);
      expect(LessonUnlocks.isUnitStart(lookup, 'math', 1), isFalse);
    });

    test('lesson unlocks after all preceding are completed', () {
      expect(
        LessonUnlocks.isLessonUnlocked(
          lookup: lookup,
          isCompleted: (s, i) => i == 0,
          subjectId: 'math',
          lessonIndex: 1,
        ),
        isTrue,
      );
      expect(
        LessonUnlocks.isLessonUnlocked(
          lookup: lookup,
          isCompleted: (s, i) => false,
          subjectId: 'math',
          lessonIndex: 1,
        ),
        isFalse,
      );
      expect(
        LessonUnlocks.isLessonUnlocked(
          lookup: lookup,
          isCompleted: (s, i) => false,
          subjectId: 'math',
          lessonIndex: 3,
        ),
        isTrue,
      );
    });
  });

  group('QuizBuilder helpers in lesson_unlocks', () {
    test('buildLessonQuiz respects english count override', () {
      final pool = List.generate(12, (i) => _q('e$i'));
      final quiz = buildLessonQuiz(
        subjectId: 'english',
        lessonIndex: 0,
        pool: pool,
      );
      expect(quiz.length, 10);
    });

    test('buildUnitQuiz builds requested count', () {
      final pool = List.generate(20, (i) => _q('u$i'));
      final quiz = buildUnitQuiz(
        subjectId: 'math',
        unitIndex: 0,
        pool: pool,
        count: 9,
      );
      expect(quiz.length, 9);
    });
  });

  group('QuizController unit exam', () {
    QuizController makeUnit({
      required List<Question> questions,
      _FakeSaver? saver,
      void Function()? onHeartsDepleted,
      void Function(QuizOutcome)? onFinished,
    }) {
      final s = saver ?? _FakeSaver();
      final c = QuizController(
        questions: questions,
        subjectId: 'math',
        attemptKind: 'unit',
        attemptRefIndex: 0,
        attemptSaver: s,
        onHeartsDepleted: onHeartsDepleted,
        onFinished: onFinished,
      );
      // Unit ignores global hearts / subscription.
      c.heartsProvider = () => 0;
      c.isSubscribedProvider = () => true;
      c.start();
      return c;
    }

    test('starts with a fresh 5-heart local pool', () {
      final c = makeUnit(questions: [_q('a')]);
      expect(c.localHearts, GameConstants.unitHearts);
    });

    test('start() resets local hearts to 5', () {
      final c = makeUnit(questions: [_q('a')]);
      c.submitAnswer(false, 'b');
      expect(c.localHearts, GameConstants.unitHearts - 1);
      c.start();
      expect(c.localHearts, GameConstants.unitHearts);
    });

    test('subscriber does not get unit heart immunity', () {
      var depleted = false;
      final c = makeUnit(
        questions: List.generate(6, (i) => _q('q$i')),
        onHeartsDepleted: () => depleted = true,
      );
      for (var i = 0; i < 5; i++) {
        c.submitAnswer(false, 'x');
        final hit = c.next();
        if (i < 4) {
          expect(hit, isFalse);
        } else {
          expect(hit, isTrue);
        }
      }
      expect(depleted, isTrue);
      expect(c.isHeartsDepleted, isTrue);
      expect(c.localHearts, 0);
    });

    test('5 wrong answers deplete without finishing (no XP)', () {
      var finished = false;
      QuizOutcome? out;
      final c = makeUnit(
        questions: List.generate(6, (i) => _q('q$i')),
        onFinished: (o) {
          finished = true;
          out = o;
        },
      );
      for (var i = 0; i < 5; i++) {
        c.submitAnswer(false, 'x');
        c.next();
      }
      expect(c.isHeartsDepleted, isTrue);
      expect(finished, isFalse);
      expect(out, isNull);
      expect(c.localHearts, 0);
    });

    test('unit XP is 150 flat minus 18 per wrong (no time bonus)', () {
      final c = makeUnit(questions: [_q('a')]);
      c.submitAnswer(false, 'b');
      final out = c.finish();
      // 1 wrong → 150 − 18
      expect(out.xp, GameConstants.unitXpBase - GameConstants.unitWrongPenalty);
      expect(out.wrongCount, 1);
    });

    test('all-correct unit finishes with full 150 XP', () {
      QuizOutcome? out;
      final c = makeUnit(
        questions: [_q('a'), _q('b')],
        onFinished: (o) => out = o,
      );
      c.submitAnswer(true, 'a');
      c.next();
      c.submitAnswer(true, 'a');
      c.next();
      expect(out, isNotNull);
      expect(out!.xp, GameConstants.unitXpBase);
      expect(c.isFixPhase, isFalse);
    });

    test('unit with mistakes enters fix phase (يلا نصحح الاخطاء)', () {
      final c = makeUnit(questions: [_q('a'), _q('b')]);
      c.submitAnswer(false, 'b');
      c.next();
      c.submitAnswer(true, 'a');
      c.next();
      expect(c.isFixPhase, isTrue);
      expect(c.showFixIntro, isTrue);
      expect(c.initialMistakeCount, 1);
    });

    test('unit depleted does not save attempt', () async {
      final saver = _FakeSaver();
      final c = makeUnit(
        questions: List.generate(6, (i) => _q('q$i')),
        saver: saver,
      );
      for (var i = 0; i < 5; i++) {
        c.submitAnswer(false, 'x');
        c.next();
      }
      await Future<void>.delayed(Duration.zero);
      expect(saver.calls, 0);
    });

    test('fix phase does not spend unit hearts', () {
      final c = makeUnit(questions: [_q('a'), _q('b')]);
      c.submitAnswer(false, 'x');
      c.next();
      final afterMain = c.localHearts;
      expect(afterMain, GameConstants.unitHearts - 1);

      c.submitAnswer(true, 'a');
      c.next();
      expect(c.isFixPhase, isTrue);
      expect(c.shouldSpendHeartOnWrong, isFalse);

      // Wrong answers during fix must not touch the private pool.
      c.beginFixPhaseQuestions();
      c.submitAnswer(false, 'x');
      expect(c.localHearts, afterMain);
      expect(c.isHeartsDepleted, isFalse);

      // next() during fix also must not deplete even if pool is empty.
      final c2 = makeUnit(
        questions: [_q('a'), _q('b')],
        onHeartsDepleted: () => fail('fix phase must not deplete'),
      );
      c2.submitAnswer(false, 'x');
      c2.next();
      c2.submitAnswer(true, 'a');
      c2.next();
      expect(c2.isFixPhase, isTrue);
      c2.localHearts = 0;
      c2.beginFixPhaseQuestions();
      expect(c2.next(), isFalse);
      expect(c2.isHeartsDepleted, isFalse);
    });

    test('fix phase wrong repeats the same question until correct', () {
      final c = makeUnit(questions: [_q('a'), _q('b')]);
      c.submitAnswer(false, 'x');
      c.next();
      c.submitAnswer(true, 'a');
      c.next();
      expect(c.isFixPhase, isTrue);
      expect(c.showFixIntro, isTrue);
      c.beginFixPhaseQuestions();
      expect(c.currentQuestion.id, 'a');
      expect(c.fixPhaseIndex, 0);

      // Wrong → stay on same question, bump retry key, still in fix.
      c.submitAnswer(false, 'y');
      c.next();
      expect(c.isFixPhase, isTrue);
      expect(c.fixPhaseIndex, 0);
      expect(c.currentQuestion.id, 'a');
      expect(c.answered, isFalse);
      expect(c.isCorrect, isFalse);
      expect(c.fixRetryCount, 1);

      // Wrong again → still stuck on the same question.
      c.submitAnswer(false, 'z');
      c.next();
      expect(c.fixPhaseIndex, 0);
      expect(c.currentQuestion.id, 'a');
      expect(c.fixRetryCount, 2);

      // Correct → advance (only one mistake → finish).
      var finished = false;
      QuizOutcome? out;
      final c2 = makeUnit(
        questions: [_q('a'), _q('b')],
        onFinished: (o) {
          finished = true;
          out = o;
        },
      );
      c2.submitAnswer(false, 'x');
      c2.next();
      c2.submitAnswer(true, 'a');
      c2.next();
      c2.beginFixPhaseQuestions();
      c2.submitAnswer(false, 'y');
      c2.next();
      expect(finished, isFalse);
      c2.submitAnswer(true, 'a');
      c2.next();
      expect(finished, isTrue);
      expect(out!.wrongCount, 1);
      expect(
        out!.xp,
        GameConstants.unitXpBase - GameConstants.unitWrongPenalty,
      );
    });
  });

  group('QuizController', () {
    QuizController make({
      required List<Question> questions,
      int hearts = GameConstants.maxHearts,
      bool subscribed = false,
      _FakeSaver? saver,
      void Function()? onHeartsDepleted,
    }) {
      final s = saver ?? _FakeSaver();
      final c = QuizController(
        questions: questions,
        subjectId: 'math',
        attemptKind: 'lesson',
        attemptRefIndex: 0,
        attemptSaver: s,
        onHeartsDepleted: onHeartsDepleted,
      );
      c.heartsProvider = () => hearts;
      c.isSubscribedProvider = () => subscribed;
      c.start();
      return c;
    }

    test('all correct answers finish with no fix phase', () {
      final questions = [_q('a'), _q('b'), _q('c')];
      final c = make(questions: questions);
      for (var i = 0; i < 3; i++) {
        c.submitAnswer(true, 'a');
        c.next();
      }
      expect(c.isFixPhase, isFalse);
      expect(c.results.length, 3);
      expect(c.correctCount, 3);
      expect(c.initialMistakeCount, 0);
    });

    test('wrong answers enter fix phase after last question', () {
      final questions = [_q('a'), _q('b')];
      final c = make(questions: questions);
      c.submitAnswer(false, 'b');
      c.next();
      c.submitAnswer(true, 'a');
      c.next();
      expect(c.isFixPhase, isTrue);
      expect(c.showFixIntro, isTrue);
      expect(c.fixPhaseQuestionIds, ['a']);
      expect(c.initialMistakeCount, 1);
    });

    test('hearts depletion stops before advancing when not subscribed', () {
      var depleted = false;
      final c = make(
        questions: [_q('a')],
        hearts: 0,
        onHeartsDepleted: () => depleted = true,
      );
      c.submitAnswer(false, 'b');
      final hit = c.next();
      expect(hit, isTrue);
      expect(depleted, isTrue);
      expect(c.isHeartsDepleted, isTrue);
    });

    test('lesson fix phase wrong repeats until correct', () {
      var finished = false;
      final c = make(questions: [_q('a'), _q('b')]);
      c.submitAnswer(false, 'x');
      c.next();
      c.submitAnswer(true, 'a');
      c.next();
      expect(c.isFixPhase, isTrue);
      c.beginFixPhaseQuestions();
      expect(c.currentQuestion.id, 'a');

      c.submitAnswer(false, 'y');
      c.next();
      expect(c.isFixPhase, isTrue);
      expect(c.fixPhaseIndex, 0);
      expect(c.answered, isFalse);
      expect(c.fixRetryCount, 1);
      expect(c.currentQuestion.id, 'a');

      // One mistake → correct finishes lesson quiz.
      var xp = -1;
      final c2 = QuizController(
        questions: [_q('a'), _q('b')],
        subjectId: 'math',
        attemptKind: 'lesson',
        attemptRefIndex: 0,
        attemptSaver: _FakeSaver(),
        onFinished: (o) {
          finished = true;
          xp = o.xp;
        },
      );
      c2.heartsProvider = () => GameConstants.maxHearts;
      c2.isSubscribedProvider = () => false;
      c2.start();
      c2.submitAnswer(false, 'x');
      c2.next();
      c2.submitAnswer(true, 'a');
      c2.next();
      c2.beginFixPhaseQuestions();
      c2.submitAnswer(false, 'y');
      c2.next();
      expect(finished, isFalse);
      c2.submitAnswer(true, 'a');
      c2.next();
      expect(finished, isTrue);
      expect(xp, GameConstants.lessonXpBase - GameConstants.lessonWrongPenalty);
    });

    test('subscriber ignores lesson heart depletion', () {
      final c = make(questions: [_q('a')], hearts: 0, subscribed: true);
      c.submitAnswer(false, 'b');
      final hit = c.next();
      expect(hit, isFalse);
      expect(c.isFixPhase, isTrue);
    });

    test('XP clamps and applies wrong penalty', () {
      final c = make(questions: [_q('a')]);
      c.submitAnswer(false, 'b');
      final out = c.finish();
      final expected =
          (GameConstants.lessonXpBase - GameConstants.lessonWrongPenalty).clamp(
            0,
            9999,
          );
      expect(out.xp, expected);
      expect(out.wrongCount, 1);
    });

    test('attempt is saved on finish', () async {
      final saver = _FakeSaver();
      final c = make(questions: [_q('a')], saver: saver);
      c.submitAnswer(true, 'a');
      c.finish();
      await Future<void>.delayed(Duration.zero);
      expect(saver.calls, 1);
      expect(saver.lastDetails.single.isCorrect, isTrue);
    });

    test('fix phase does not spend lesson hearts', () {
      var hearts = 3;
      final c = make(questions: [_q('a'), _q('b')], hearts: hearts);
      // Main-phase wrong: screen would consume (flag true).
      c.submitAnswer(false, 'x');
      expect(c.shouldSpendHeartOnWrong, isTrue);
      hearts--; // mirror PracticeQuizScreen consume
      c.heartsProvider = () => hearts;
      c.next();

      c.submitAnswer(true, 'a');
      c.next();
      expect(c.isFixPhase, isTrue);
      expect(c.shouldSpendHeartOnWrong, isFalse);

      // Fix-phase wrong: flag stays false → screen skips consumeHeartForExam.
      c.beginFixPhaseQuestions();
      c.submitAnswer(false, 'x');
      expect(c.shouldSpendHeartOnWrong, isFalse);
      expect(hearts, 2);

      // next() during fix must not deplete even at 0 hearts.
      hearts = 0;
      c.heartsProvider = () => hearts;
      expect(c.next(), isFalse);
      expect(c.isHeartsDepleted, isFalse);
    });
  });
}
