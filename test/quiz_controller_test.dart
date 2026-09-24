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
  });
}
