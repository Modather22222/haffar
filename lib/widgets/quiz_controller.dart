import 'dart:async';

import 'package:flutter/material.dart';

import '../models/question.dart';
import '../models/quiz_attempt.dart';
import '../utils/app_logger.dart';
import '../utils/game_constants.dart';

/// Outcome emitted by [QuizController.finish].
class QuizOutcome {
  final int xp;
  final int wrongCount;
  final Duration elapsed;
  final List<AttemptDetail> results;
  const QuizOutcome({
    required this.xp,
    required this.wrongCount,
    required this.elapsed,
    required this.results,
  });
}

/// Persistence hook injected by the screen (no Supabase in this file).
abstract class AttemptSaver {
  Future<void> save({
    required String subjectId,
    required String kind,
    required int refIndex,
    required List<AttemptDetail> details,
  });
}

/// Pure quiz state machine extracted from PracticeQuizScreen.
/// No BuildContext — the screen supplies hearts/subscription callbacks and
/// an [AttemptSaver].
class QuizController extends ChangeNotifier {
  QuizController({
    required this.questions,
    required this.subjectId,
    required this.attemptKind,
    required this.attemptRefIndex,
    required this.attemptSaver,
    this.onHeartsDepleted,
    this.onFinished,
  });

  final List<Question> questions;
  final String subjectId;
  final String attemptKind; // lesson | unit | review
  final int attemptRefIndex;
  final AttemptSaver attemptSaver;
  final void Function()? onHeartsDepleted;
  final void Function(QuizOutcome outcome)? onFinished;

  /// Heart gate supplied by the screen (remaining hearts / subscription).
  /// Used only for lesson/review attempts — unit uses [localHearts].
  int Function()? heartsProvider;
  bool Function()? isSubscribedProvider;

  /// Unit exams use a private 5-heart pool that resets every attempt and
  /// never touches the global EconomyProvider hearts.
  int localHearts = GameConstants.unitHearts;

  bool get isUnit => attemptKind == 'unit';

  /// Fix phase never spends hearts — only the main question pass does.
  /// Unit decrements [localHearts] inside [submitAnswer]; lessons ask the
  /// screen to call EconomyProvider only when this is true.
  bool get shouldSpendHeartOnWrong => !isFixPhase;

  int questionIndex = 0;
  bool answered = false;
  bool isCorrect = false;
  String? correctAnswerText;
  bool isFixPhase = false;
  bool showFixIntro = false;
  bool isHeartsDepleted = false;
  int initialMistakeCount = 0;
  int fixPhaseIndex = 0;
  List<String> fixPhaseQuestionIds = const [];

  /// Bumped when a fix-phase wrong retries the same question — screens use
  /// this to remount the question widget (clears submitted/fill state).
  int fixRetryCount = 0;
  final List<AttemptDetail> results = [];
  DateTime? startTime;
  late Question currentQuestion;

  int get correctCount => results.where((d) => d.isCorrect).length;
  int get totalQuestions => questions.length;

  Duration get elapsed =>
      startTime != null ? DateTime.now().difference(startTime!) : Duration.zero;

  int get baseXp => attemptKind == 'unit'
      ? GameConstants.unitXpBase
      : GameConstants.lessonXpBase;

  int get penaltyPerWrong => attemptKind == 'unit'
      ? GameConstants.unitWrongPenalty
      : GameConstants.lessonWrongPenalty;

  double get progress {
    if (isFixPhase) {
      if (fixPhaseQuestionIds.isEmpty) return 1.0;
      return fixPhaseIndex / fixPhaseQuestionIds.length;
    }
    if (totalQuestions == 0) return 0.0;
    return questionIndex / totalQuestions;
  }

  int get displayLessonNumber =>
      isFixPhase ? fixPhaseIndex + 1 : questionIndex + 1;

  void start() {
    startTime = DateTime.now();
    if (isUnit) localHearts = GameConstants.unitHearts;
    currentQuestion = questions.isNotEmpty
        ? questions.first
        : Question(
            id: '',
            subjectId: subjectId,
            lessonIndex: 0,
            type: QuestionType.multipleChoice,
            text: '',
          );
    notifyListeners();
  }

  void markHeartsDepleted() {
    isHeartsDepleted = true;
    // Unit fail: no XP (finish never runs) — skip attempt save so a failed
    // run doesn't look like a completed attempt in history.
    if (!isUnit) _saveAttempt();
    notifyListeners();
  }

  /// Apply an answer. Returns true when correct.
  /// Unit wrong answers decrement the local 5-heart pool (never global).
  /// Fix-phase answers never spend hearts and are not re-logged to [results].
  bool submitAnswer(bool correct, String? correctAnswer) {
    answered = true;
    isCorrect = correct;
    correctAnswerText = correctAnswer;
    if (!isFixPhase) {
      results.add(
        AttemptDetail(questionId: currentQuestion.id, isCorrect: correct),
      );
      if (!correct) {
        initialMistakeCount++;
        if (isUnit && localHearts > 0) localHearts--;
      }
    }
    notifyListeners();
    return correct;
  }

  /// متابعة / next — may open fix phase, deplete hearts, or finish.
  /// Returns true if the UI should show the hearts-depleted screen.
  bool next() {
    if (isUnit) {
      // Unit: private 5-heart pool; subscribers are NOT immune.
      if (!isFixPhase && localHearts <= 0) {
        markHeartsDepleted();
        onHeartsDepleted?.call();
        return true;
      }
    } else {
      final hearts = heartsProvider?.call() ?? GameConstants.maxHearts;
      final subscribed = isSubscribedProvider?.call() ?? false;
      if (!isFixPhase && !subscribed && hearts <= 0) {
        markHeartsDepleted();
        onHeartsDepleted?.call();
        return true;
      }
    }
    if (isFixPhase) {
      _fixPhaseNext();
      return false;
    }
    if (questionIndex + 1 < questions.length) {
      questionIndex++;
      answered = false;
      isCorrect = false;
      correctAnswerText = null;
      currentQuestion = questions[questionIndex];
    } else if (initialMistakeCount > 0) {
      _enterFixPhase();
    } else {
      finish();
    }
    notifyListeners();
    return false;
  }

  Question questionById(String id, List<Question> fallbackPool) {
    for (final q in questions) {
      if (q.id == id) return q;
    }
    for (final q in fallbackPool) {
      if (q.id == id) return q;
    }
    return Question(
      id: id,
      subjectId: subjectId,
      lessonIndex: 0,
      type: QuestionType.multipleChoice,
      text: '',
    );
  }

  /// Acknowledge the fix-intro full-screen and show the first mistake.
  void beginFixPhaseQuestions() {
    showFixIntro = false;
    notifyListeners();
  }

  void _enterFixPhase() {
    isFixPhase = true;
    fixPhaseQuestionIds = results
        .where((d) => !d.isCorrect)
        .map((d) => d.questionId)
        .toList();
    fixPhaseIndex = 0;
    fixRetryCount = 0;
    answered = false;
    isCorrect = false;
    correctAnswerText = null;
    showFixIntro = true;
    if (fixPhaseQuestionIds.isNotEmpty) {
      currentQuestion = questionById(fixPhaseQuestionIds.first, questions);
    }
    notifyListeners();
  }

  /// Wrong in fix → repeat the same question. Correct → next mistake or finish.
  void _fixPhaseNext() {
    if (!isCorrect) {
      // Stay on fixPhaseIndex; remount widget so the user can try again.
      answered = false;
      isCorrect = false;
      correctAnswerText = null;
      fixRetryCount++;
      notifyListeners();
      return;
    }
    if (fixPhaseIndex + 1 < fixPhaseQuestionIds.length) {
      fixPhaseIndex++;
      fixRetryCount = 0;
      answered = false;
      isCorrect = false;
      correctAnswerText = null;
      currentQuestion = questionById(
        fixPhaseQuestionIds[fixPhaseIndex],
        questions,
      );
      notifyListeners();
    } else {
      finish();
    }
  }

  /// Computes XP, persists the attempt, and emits [onFinished].
  /// Unit: flat 150 − 18×wrong (no time bonus). Lesson: 100 − 5×wrong.
  /// Never called on hearts depletion — fail path grants 0 XP.
  QuizOutcome finish() {
    var finalXp = baseXp - (initialMistakeCount * penaltyPerWrong);
    finalXp = finalXp.clamp(0, 9999);
    _saveAttempt();
    final outcome = QuizOutcome(
      xp: finalXp,
      wrongCount: initialMistakeCount,
      elapsed: elapsed,
      results: List.unmodifiable(results),
    );
    onFinished?.call(outcome);
    return outcome;
  }

  void _saveAttempt() {
    if (results.isEmpty) return;
    unawaited(
      attemptSaver
          .save(
            subjectId: subjectId,
            kind: attemptKind,
            refIndex: attemptRefIndex,
            details: results,
          )
          .catchError((Object e, StackTrace st) {
            // Attempt history is non-critical — never block the quiz UX.
            AppLog.error('saveAttempt failed', e, st);
          }),
    );
  }
}
