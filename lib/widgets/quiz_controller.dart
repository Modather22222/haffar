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
    this.isPracticeRun = false,
    this.onHeartsDepleted,
    this.onFinished,
    this.onReviewDone,
    int? baseXp,
    int? wrongPenalty,
  }) : _baseXpOverride = baseXp,
       _wrongPenaltyOverride = wrongPenalty;

  final List<Question> questions;
  final String subjectId;
  final String attemptKind; // lesson | unit | review
  final int attemptRefIndex;
  final AttemptSaver attemptSaver;

  /// True when this attempt pays only the practice share
  /// ([GameConstants.practiceXpRatio] of the full amount — currently 0,
  /// i.e. nothing): a replay of an already-completed lesson/unit exercise,
  /// or a review attempt.
  final bool isPracticeRun;

  /// Fired when the review (fix) run completes — after the result screen.
  /// XP and the attempt were already granted at the main-pass finish, so
  /// the screen only exits the quiz (or was skipped mid-review).
  final VoidCallback? onReviewDone;
  final void Function()? onHeartsDepleted;
  final void Function(QuizOutcome outcome)? onFinished;

  /// XP economy injected from the admin settings — lesson quizzes resolve
  /// `lessons.xp_base`/`wrong_penalty`, unit exams resolve the unit row's.
  /// Null keeps the GameConstants defaults: review attempts have no
  /// lesson/unit config and always use the default economy.
  final int? _baseXpOverride;
  final int? _wrongPenaltyOverride;

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

  int get baseXp =>
      _baseXpOverride ??
      (attemptKind == 'unit'
          ? GameConstants.unitXpBase
          : GameConstants.lessonXpBase);

  int get penaltyPerWrong =>
      _wrongPenaltyOverride ??
      (attemptKind == 'unit'
          ? GameConstants.unitWrongPenalty
          : GameConstants.lessonWrongPenalty);

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

  /// متابعة / next — a skipped (unanswered) question counts as wrong, so
  /// skipping can't farm the base XP. May open fix phase, deplete hearts,
  /// or finish. Returns true when the UI should show the hearts-depleted
  /// screen.
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
    // تخطى pressed without submitting — count it as a wrong answer so
    // skipping can't farm the base XP: the detail joins [results] (attempt
    // row + review), the mistake bumps the penalty. Hearts are untouched
    // (hearts flow through the screen's submit path only).
    if (!answered) {
      results.add(
        AttemptDetail(questionId: currentQuestion.id, isCorrect: false),
      );
      initialMistakeCount++;
      answered = true;
      isCorrect = false;
      correctAnswerText = null;
    }
    if (questionIndex + 1 < questions.length) {
      questionIndex++;
      answered = false;
      isCorrect = false;
      correctAnswerText = null;
      currentQuestion = questions[questionIndex];
    } else if (initialMistakeCount > 0) {
      // Result first: finish fires now (XP/grants come from the main pass
      // only) while the review intro waits underneath — استمرار on the
      // result screen reveals [showFixIntro].
      _enterFixPhase();
      finish();
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

  /// Wrong in fix → repeat the same question. Correct → next mistake, or
  /// end of review (fires [onReviewDone] — the result screen already ran).
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
      // Review complete — the result screen already granted XP and saved
      // the attempt at the main-pass end, so finishing again would
      // duplicate the grant. Hand control back to the screen to exit.
      onReviewDone?.call();
    }
  }

  /// Computes XP, persists the attempt, and emits [onFinished].
  /// XP = base + Σ per-question rewards of correct main-pass answers
  /// − penalty × wrong, clamped to 0..9999. Practice runs (replays of
  /// completed content, review attempts) earn
  /// [GameConstants.practiceXpRatio] of that — currently 0, so only the
  /// first completion pays out. Fix-phase corrections and failed
  /// (hearts-depleted) runs earn nothing. Review attempts use the
  /// default economy since no lesson/unit config applies to them.
  QuizOutcome finish() {
    var rewardSum = 0;
    for (final d in results) {
      if (!d.isCorrect) continue;
      for (final q in questions) {
        if (q.id == d.questionId) {
          rewardSum += q.xpReward;
          break;
        }
      }
    }
    var finalXp = baseXp + rewardSum - (initialMistakeCount * penaltyPerWrong);
    finalXp = finalXp.clamp(0, 9999);
    // Practice runs (replays of completed content, review attempts) earn
    // practiceXpRatio × the full amount; with the current policy (0) they
    // earn nothing — only the first completion pays out.
    if (isPracticeRun) {
      final ratio = GameConstants.practiceXpRatio;
      if (ratio <= 0 || finalXp <= 0) {
        finalXp = 0;
      } else {
        finalXp = ((finalXp * ratio).toInt()).clamp(1, 9999);
      }
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
          .catchError((Object e, StackTrace st) {
            // Attempt history is non-critical — never block the quiz UX.
            AppLog.error('saveAttempt failed', e, st);
          }),
    );
  }
}
