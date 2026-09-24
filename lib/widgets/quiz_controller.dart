import 'dart:async';

import 'package:flutter/material.dart';

import '../models/question.dart';
import '../models/quiz_attempt.dart';
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
  int Function()? heartsProvider;
  bool Function()? isSubscribedProvider;

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
    _saveAttempt();
    notifyListeners();
  }

  /// Apply an answer. Returns true when correct.
  bool submitAnswer(bool correct, String? correctAnswer) {
    answered = true;
    isCorrect = correct;
    correctAnswerText = correctAnswer;
    results.add(
      AttemptDetail(questionId: currentQuestion.id, isCorrect: correct),
    );
    if (!correct && !isFixPhase) initialMistakeCount++;
    notifyListeners();
    return correct;
  }

  /// متابعة / next — may open fix phase, deplete hearts, or finish.
  /// Returns true if the UI should show the hearts-depleted screen.
  bool next() {
    final hearts = heartsProvider?.call() ?? GameConstants.maxHearts;
    final subscribed = isSubscribedProvider?.call() ?? false;
    if (!isFixPhase && !subscribed && hearts <= 0) {
      markHeartsDepleted();
      onHeartsDepleted?.call();
      return true;
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
    answered = false;
    isCorrect = false;
    showFixIntro = true;
    notifyListeners();
  }

  void _fixPhaseNext() {
    if (fixPhaseIndex + 1 < fixPhaseQuestionIds.length) {
      fixPhaseIndex++;
      answered = false;
      isCorrect = false;
      correctAnswerText = null;
      notifyListeners();
    } else {
      finish();
    }
  }

  /// Computes XP, persists the attempt, and emits [onFinished].
  QuizOutcome finish() {
    var finalXp = baseXp - (initialMistakeCount * penaltyPerWrong);
    finalXp = finalXp.clamp(0, 9999);
    if (attemptKind == 'unit' &&
        elapsed < GameConstants.unitBonusTimeThreshold) {
      finalXp += GameConstants.unitBonusXp;
    }
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
          .catchError((_) {}),
    );
  }
}
