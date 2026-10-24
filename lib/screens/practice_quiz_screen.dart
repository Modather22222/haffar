import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../design_system/colors.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../design_system/components/lesson/voice_bubble.dart';
import '../design_system/components/lesson_complete_screen.dart';
import '../design_system/components/modal/lesson_feedback.dart';
import '../design_system/components/navigation/navigation_top_learn.dart';
import '../providers/content_provider.dart';
import '../providers/economy_provider.dart';
import '../providers/progress_provider.dart';
import '../models/question.dart';
import '../models/quiz_attempt.dart';
import '../services/attempt_repository.dart';
import '../widgets/question_widgets/question_widget_factory.dart';
import '../widgets/mascot.dart';
import '../widgets/quiz_controller.dart';
import '../utils/app_logger.dart';
import '../utils/app_toast.dart';
import '../utils/routes.dart';
import '../utils/sound_manager.dart';

/// Reusable full-screen practice quiz driving any ordered question list
/// (lesson quizzes and unit exercises). State machine lives in [QuizController].
class PracticeQuizScreen extends StatefulWidget {
  final String subjectId;
  final String title;
  final List<Question> questions;
  final VoidCallback? onComplete;

  final String attemptKind;
  final int attemptRefIndex;

  final MascotPose? completionPose;
  final String completionTitle;
  final String completionMessage;

  const PracticeQuizScreen({
    super.key,
    required this.subjectId,
    required this.title,
    required this.questions,
    this.onComplete,
    this.attemptKind = 'lesson',
    this.attemptRefIndex = 0,
    this.completionPose,
    this.completionTitle = 'أحسنت!',
    this.completionMessage = 'أكملت التمرين بنجاح',
  });

  @override
  State<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends State<PracticeQuizScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late QuizController _quiz;

  /// Unit exercises open with a full-screen hearts intro before Q1.
  late bool _unitIntroVisible;

  @override
  void initState() {
    super.initState();
    _unitIntroVisible = widget.attemptKind == 'unit';
    super.initState();
    // Resolve the admin-configured XP economy for this attempt (lesson quiz
    // → lesson row, unit exam → unit row). A missing ContentProvider — the
    // screen can be pumped standalone (tests) — or a missing row keeps
    // QuizController's default economy (GameConstants mirrors).
    int? baseXp;
    int? wrongPenalty;
    try {
      final content = context.read<ContentProvider>();
      switch (widget.attemptKind) {
        case 'lesson':
          final lesson = content.lessonOf(
            widget.subjectId,
            widget.attemptRefIndex,
          );
          if (lesson != null) {
            baseXp = lesson.xpBase;
            wrongPenalty = lesson.wrongPenalty;
          }
        case 'unit':
          for (final unit
              in content.subjectById(widget.subjectId)?.units ?? const []) {
            if (unit.index == widget.attemptRefIndex) {
              baseXp = unit.xpBase;
              wrongPenalty = unit.wrongPenalty;
            }
          }
        default:
          break;
      }
    } catch (_) {
      // No provider in scope — defaults keep the attempt playable.
    }
    // Practice tier: review attempts always earn the reduced share, and a
    // lesson/unit exercise replayed after its first completion does too.
    var isPractice = widget.attemptKind == 'review';
    try {
      final progress = context.read<ProgressProvider>();
      switch (widget.attemptKind) {
        case 'lesson':
          isPractice =
              isPractice ||
              progress.isSubjectLessonCompleted(
                widget.subjectId,
                widget.attemptRefIndex,
              );
        case 'unit':
          isPractice =
              isPractice ||
              progress.isUnitExerciseCompleted(
                widget.subjectId,
                widget.attemptRefIndex,
              );
        default:
          break;
      }
    } catch (_) {
      // No progress provider in scope — first-run full XP.
    }
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _quiz = QuizController(
      questions: widget.questions,
      subjectId: widget.subjectId,
      attemptKind: widget.attemptKind,
      attemptRefIndex: widget.attemptRefIndex,
      attemptSaver: _RepoAttemptSaver(),
      isPracticeRun: isPractice,
      baseXp: baseXp,
      wrongPenalty: wrongPenalty,
      onHeartsDepleted: () {
        if (mounted) setState(() {});
      },
      onFinished: _onFinished,
      onReviewDone: () {
        // Review finished (or skipped) — the result screen already granted
        // XP and recorded the attempt; return to the lesson/unit path.
        if (mounted) context.pop();
      },
    );
    _quiz.heartsProvider = () {
      if (widget.attemptKind == 'unit') return _quiz.localHearts;
      return context.read<EconomyProvider>().hearts;
    };
    _quiz.isSubscribedProvider = () =>
        context.read<EconomyProvider>().isSubscribed;
    _quiz.start();
    _enterQuiz();
  }

  @override
  void dispose() {
    _animController.dispose();
    _quiz.dispose();
    super.dispose();
  }

  Future<void> _enterQuiz() async {
    // Unit exams use a private 5-heart pool — never gated on global hearts.
    if (widget.attemptKind == 'unit') {
      if (mounted) setState(() {});
      return;
    }
    final economy = context.read<EconomyProvider>();
    await economy.syncHeartsFromServer();
    if (!mounted) return;
    if (economy.hearts <= 0 && !economy.isSubscribed) {
      setState(() => _quiz.markHeartsDepleted());
      return;
    }
    setState(() {});
  }

  Future<void> _submitAnswer(bool correct, String? correctAnswerText) async {
    _quiz.submitAnswer(correct, correctAnswerText);
    setState(() {});
    _animController.forward();

    if (correct) {
      SoundManager.playCorrect(_quiz.currentQuestion.id);
    } else {
      SoundManager.playWrong(_quiz.currentQuestion.id);
      // Unit uses QuizController.localHearts (never global). Lessons only
      // spend a global heart on main-phase wrongs — fix phase is free.
      if (widget.attemptKind != 'unit' && _quiz.shouldSpendHeartOnWrong) {
        try {
          await context.read<EconomyProvider>().consumeHeartForExam(
            isUnitExam: false,
          );
        } catch (e, st) {
          AppLog.error('consumeHeart (screen)', e, st);
          AppToast.error(e, fallback: 'تعذر خصم القلب — حاول مجدداً');
        }
        if (mounted) setState(() {});
      }
    }
  }

  void _nextQuestion() {
    final economy = context.read<EconomyProvider>();
    _quiz.heartsProvider = () {
      if (widget.attemptKind == 'unit') return _quiz.localHearts;
      return economy.hearts;
    };
    _quiz.isSubscribedProvider = () => economy.isSubscribed;

    final beforeQuestion = _quiz.questionIndex;
    final beforeFix = _quiz.fixPhaseIndex;
    final wasFix = _quiz.isFixPhase;

    final depleted = _quiz.next();

    if (!mounted) return;
    if (depleted) {
      setState(() {});
      return;
    }

    final advanced =
        _quiz.questionIndex != beforeQuestion ||
        _quiz.fixPhaseIndex != beforeFix ||
        _quiz.isFixPhase != wasFix ||
        _quiz.answered == false && wasFix;
    if (_quiz.answered && wasFix && _quiz.isFixPhase) {
      // fix next sets answered=false already
    }
    if (!_quiz.answered || advanced || _quiz.isFixPhase != wasFix) {
      if (_quiz.answered) {
        setState(() {});
        return;
      }
      if (_quiz.showFixIntro) {
        setState(() {});
        return;
      }
      setState(() {});
      return;
    }
    setState(() {});
  }

  void _onFinished(QuizOutcome outcome) {
    if (!mounted) return;
    // Fail path never reaches here (finish not called on depletion).
    final economy = context.read<EconomyProvider>();
    final progress = context.read<ProgressProvider>();
    if (outcome.xp > 0) {
      economy.addXpEvent(
        amount: outcome.xp,
        source: widget.attemptKind,
        subjectId: widget.subjectId,
        lessonIndex: widget.attemptKind == 'lesson'
            ? widget.attemptRefIndex
            : null,
      );
    }
    if (widget.attemptKind == 'unit') {
      progress.completeUnitExercise(widget.subjectId, widget.attemptRefIndex);
    } else if (widget.attemptKind == 'lesson') {
      // A lesson counts only when its quiz is finished here — never from
      // review attempts.
      progress.completeSubjectLesson(widget.subjectId, widget.attemptRefIndex);
    }
    // Streak from a finished lesson quiz or a finished unit exam
    // (never from review attempts).
    if (widget.attemptKind == 'lesson' || widget.attemptKind == 'unit') {
      economy.updateStreakOnCompletion();
    }

    final pose =
        outcome.results.where((d) => d.isCorrect).length >
            widget.questions.length ~/ 2
        ? MascotPose.cheer
        : MascotPose.sad;
    final correct = outcome.results.where((d) => d.isCorrect).length;
    final total = widget.questions.length;
    final accuracy = total == 0 ? 0 : ((correct * 100) / total).round();
    final accuracyLabel = accuracy >= 80
        ? 'ممتاز'
        : accuracy >= 50
        ? 'جيد'
        : 'حاول مجدداً';
    final title = switch (widget.attemptKind) {
      'unit' =>
        _quiz.isPracticeRun
            ? 'أكملت تمرين الوحدة مرة أخرى!'
            : 'أكملت تمرين الوحدة!',
      'review' => 'راجعت بنجاح!',
      _ => _quiz.isPracticeRun ? 'أكملت الدرس مرة أخرى!' : 'أكملت الدرس!',
    };
    // Result first, then review: when a review intro is pending beneath
    // (set before finish fired), استمرار only dismisses this overlay —
    // the quiz screen stays on the fix intro with حسنا / تخطى. Without a
    // pending review, continuing closes the quiz route underneath too.
    final reviewPending = _quiz.showFixIntro;
    LessonCompleteScreen.show(
      context,
      pose: pose,
      title: title,
      xpGained: outcome.xp,
      accuracyPercent: accuracy,
      accuracyLabel: accuracyLabel,
      duration: outcome.elapsed,
      popUnderneath: !reviewPending,
    );
  }

  Widget _heartsDepletedBody() {
    // Unit pool is private per attempt — no regen countdown, and the
    // حفار برو plan doesn't change unit hearts, so no CTA either.
    if (widget.attemptKind == 'unit') {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Mascot(pose: MascotPose.sleepy, size: 120),
              const SizedBox(height: 24),
              const Text(
                'قلوب التمرين خلصت!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: HaffarColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'غلطت 5 مرات — ارجع وحاول من جديد',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: HaffarColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Lesson: title, then the gradient card fills the rest of the area
    // between the progress bar and the bottom buttons.
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24, 4, 24, 12),
          child: Text(
            'قلوبك خلصت!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: HaffarColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _HeartsProCtaCard(),
          ),
        ),
      ],
    );
  }

  Widget _heartsDepletedButton() {
    final isUnit = widget.attemptKind == 'unit';
    if (isUnit) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: HaffarPrimaryButton(
          label: 'ارجع للتمرين',
          fullWidth: true,
          onPressed: () => context.pop(),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HaffarPrimaryButton(
            label: 'احصل على حفار برو',
            fullWidth: true,
            onPressed: () => context.push(Routes.subscription),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'لاحقا',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: HaffarColors.grey2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fixIntroBody() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const HaffarSpeechBubble(
                message: 'يلا تعال نصلح اخطائك ونظبط الفاتنا!',
                tailPosition: BubbleTailPosition.center,
              ),
              const SizedBox(height: 12),
              Image.asset(
                'assets/character/character (7).png',
                width: 220,
                height: 220,
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fixIntroButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HaffarPrimaryButton(
            label: 'حسنا',
            fullWidth: true,
            // currentQuestion already points at the first review question
            // (set when the review was entered) — just reveal the questions.
            onPressed: () {
              setState(() => _quiz.beginFixPhaseQuestions());
            },
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'تخطى',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: HaffarColors.grey2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitIntroHeader() {
    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: HaffarColors.grey2,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unitIntroBody() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const HaffarSpeechBubble(
                message:
                    'الخمسة قلوب دي ليك كل غلط حيخسرك قلب حافظ عليهم ، '
                    'عشان تنجح في الوحدة',
                tailPosition: BubbleTailPosition.center,
              ),
              const SizedBox(height: 12),
              Image.asset(
                'assets/character/holding_hearts.png',
                width: 260,
                height: 260,
                fit: BoxFit.contain,
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _unitIntroButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: HaffarPrimaryButton(
        label: 'حسنا',
        fullWidth: true,
        onPressed: () => setState(() => _unitIntroVisible = false),
      ),
    );
  }

  Widget _feedbackBar() {
    if (_quiz.correctAnswerText == null && !_quiz.isCorrect) {
      return LessonIncorrectFeedback(
        correctAnswer: '',
        onContinueTap: _nextQuestion,
      );
    }
    if (_quiz.isCorrect) {
      return LessonCorrectFeedback(
        heading: 'أحسنت! إجابة صحيحة',
        subText: '',
        onContinueTap: _nextQuestion,
      );
    }
    return LessonIncorrectFeedback(
      correctAnswer: _quiz.correctAnswerText ?? '',
      onContinueTap: _nextQuestion,
    );
  }

  Widget _buildHeader() {
    final economy = context.watch<EconomyProvider>();
    final isUnit = widget.attemptKind == 'unit';
    final heartsToShow = isUnit ? _quiz.localHearts : economy.hearts;
    // Subscribers get unlimited hearts on lessons/review (unit pool is private).
    final showInfinite = economy.isSubscribed && !isUnit;
    final questionLabel = _questionCountLabel;
    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            LearnTopBar(
              progress: _quiz.progress,
              hearts: heartsToShow,
              showInfinite: showInfinite,
              onClose: () => context.pop(),
            ),
            if (questionLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                questionLabel,
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: HaffarColors.grey2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// "Question 3 of 10" — or its fix-phase equivalent — shown under the
  /// progress bar so students always know where they are in the quiz.
  String? get _questionCountLabel {
    if (_quiz.isFixPhase) {
      final total = _quiz.fixPhaseQuestionIds.length;
      if (total == 0) return null;
      return 'تصحيح الأخطاء ${_quiz.fixPhaseIndex + 1} من $total';
    }
    if (_quiz.totalQuestions == 0) return null;
    return 'السؤال ${_quiz.questionIndex + 1} من ${_quiz.totalQuestions}';
  }

  @override
  Widget build(BuildContext context) {
    if (_unitIntroVisible) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _unitIntroHeader(),
            Expanded(child: _unitIntroBody()),
            SafeArea(top: false, child: _unitIntroButton()),
          ],
        ),
      );
    }
    if (_quiz.isHeartsDepleted) {
      return Scaffold(
        backgroundColor: HaffarColors.bgPage,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(child: _heartsDepletedBody()),
            SafeArea(top: false, child: _heartsDepletedButton()),
          ],
        ),
      );
    }
    if (_quiz.showFixIntro) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(child: _fixIntroBody()),
            SafeArea(top: false, child: _fixIntroButton()),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: HaffarColors.bgPage,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: _quiz.answered
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 32),
                    // Key remounts the question on fix-phase retry so
                    // submitted/fill/order state resets for a fresh answer.
                    child: KeyedSubtree(
                      key: ValueKey(
                        _quiz.isFixPhase
                            ? 'fix:${_quiz.currentQuestion.id}:'
                                  '${_quiz.fixRetryCount}'
                            : 'main:${_quiz.currentQuestion.id}:'
                                  '${_quiz.questionIndex}',
                      ),
                      child: QuestionWidgetFactory.create(
                        question: _quiz.currentQuestion,
                        subjectName: widget.title,
                        lessonNumber: _quiz.displayLessonNumber,
                        customTitle: widget.title,
                        onBack: () => context.pop(),
                        onSkip: _nextQuestion,
                        onNext: _nextQuestion,
                        onSubmitAnswer: _submitAnswer,
                        locked: _quiz.answered,
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: ClipRect(
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    offset: _quiz.answered ? Offset.zero : const Offset(0, 1),
                    child: _quiz.answered
                        ? _feedbackBar()
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Delegates attempt persistence to [AttemptRepository].
class _RepoAttemptSaver implements AttemptSaver {
  @override
  Future<void> save({
    required String subjectId,
    required String kind,
    required int refIndex,
    required List<AttemptDetail> details,
  }) {
    return AttemptRepository(Supabase.instance.client).saveAttempt(
      subjectId: subjectId,
      kind: kind,
      refIndex: refIndex,
      details: details,
    );
  }
}

/// Gradient حفار برو upsell shown on the lesson out-of-hearts screen —
/// fills the space between the progress bar and the action buttons, with
/// the hearts mascot + voice bubble (onboarding style) on the left.
class _HeartsProCtaCard extends StatelessWidget {
  const _HeartsProCtaCard();

  static const _benefits = [
    'قلوب غير محدودة في كل الدروس',
    'ذاكر من غير ما توقف',
    'امتحن على راحتك من غير خوف',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [HaffarColors.primary, HaffarColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: HaffarColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Features on the right (RTL), vertically centred.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final b in _benefits)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b,
                            style: const TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Mascot + voice bubble on the left (RTL).
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HaffarSpeechBubble(
                tailPosition: BubbleTailPosition.center,
                child: Text(
                  'اشترك في حفار برو',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: HaffarColors.grey1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 170,
                height: 170,
                child: Image.asset(
                  'assets/character/holding_hearts.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
