import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../design_system/colors.dart';
import '../providers/app_provider.dart';
import '../models/question.dart';
import '../models/quiz_attempt.dart';
import '../services/attempt_repository.dart';
import '../widgets/question_widgets/question_widget_factory.dart';
import '../widgets/sparkle_burst_overlay.dart';
import '../widgets/mascot.dart';
import '../widgets/celebration_dialog.dart';
import '../utils/game_constants.dart';
import '../utils/sound_manager.dart';

/// Reusable full-screen practice quiz driving any ordered question list
/// (lesson quizzes and unit exercises).
class PracticeQuizScreen extends StatefulWidget {
  final String subjectId;
  final String title;
  final List<Question> questions;
  final VoidCallback? onComplete;

  /// Attempt bookkeeping — saved to quiz_attempts when the quiz finishes.
  final String attemptKind;
  final int attemptRefIndex;

  /// When set, finishing the quiz shows a mascot celebration dialog
  /// (lesson complete -> cheer, unit exercise -> celebrate).
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

class _PracticeQuizScreenState extends State<PracticeQuizScreen> with TickerProviderStateMixin {
  int _questionIndex = 0;
  bool _answered = false;
  bool _isCorrect = false;
  bool _showSparkles = false;
  String? _correctAnswerText;
  late AnimationController _animController;
  final List<AttemptDetail> _results = [];
  DateTime? _startTime;

  // Fix-phase state
  bool _isFixPhase = false;
  List<String> _fixPhaseQuestionIds = [];
  int _fixPhaseIndex = 0;
  int _initialMistakeCount = 0;

  late Question _currentQuestion;

  int get _correctCount => _results.where((d) => d.isCorrect).length;
  int get _totalQuestions => widget.questions.length;
  Duration get _elapsed => _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;

  /// Base XP for this exam type.
  int get _baseXp => widget.attemptKind == 'unit' ? GameConstants.unitXpBase : GameConstants.lessonXpBase;

  /// Penalty per wrong answer for this exam type.
  int get _penaltyPerWrong => widget.attemptKind == 'unit' ? GameConstants.unitWrongPenalty : GameConstants.lessonWrongPenalty;

  /// Max hearts for this exam type.
  // (used implicitly via _maxHearts in UI — kept for reference)

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _startTime = DateTime.now();
    _currentQuestion = widget.questions.isNotEmpty ? widget.questions.first : Question(id: '', subjectId: widget.subjectId, lessonIndex: 0, type: QuestionType.multipleChoice, text: '');
    _enterQuiz();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _enterQuiz() async {
    final provider = context.read<AppProvider>();
    await provider.syncHeartsFromServer();
    final hearts = provider.hearts;
    final isSubscribed = provider.isSubscribed;
    if (hearts <= 0 && !isSubscribed) {
      _showOutOfHeartsDialog();
      return;
    }
    if (mounted) setState(() {});
  }

  void _showOutOfHeartsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          const Mascot(pose: MascotPose.sleepy, size: 80),
          const SizedBox(height: 16),
          const Text('قلوبك خلصت!', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 20, fontWeight: FontWeight.w800, color: HaffarColors.textPrimary)),
          const SizedBox(height: 8),
          Text('استنى شوية وارجع، كل ${GameConstants.heartRegenInterval.inMinutes} دقيقة بيطلع قلب', style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: HaffarColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('⏱ 10:00', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 22, fontWeight: FontWeight.w800, color: HaffarColors.primary)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HaffarColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => context.pop(),
            child: const Text('استنى وارجع', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 16, fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    );
  }

  Future<void> _submitAnswer(bool correct, String? correctAnswerText) async {
    setState(() {
      _answered = true;
      _isCorrect = correct;
      _showSparkles = correct;
      _correctAnswerText = correctAnswerText;
    });
    _results.add(AttemptDetail(questionId: _currentQuestion.id, isCorrect: correct));
    _animController.forward();

    if (correct) {
      SoundManager.playCorrect(_currentQuestion.id);
      // XP per correct answer is no longer given individually — final XP computed at end
    } else {
      SoundManager.playWrong(_currentQuestion.id);
      if (!_isFixPhase) {
        _initialMistakeCount++;
        // Consume a heart for free users; subscribers skip the heart cost
        final provider = context.read<AppProvider>();
        final keptHearts = await provider.consumeHeartForExam(isUnitExam: widget.attemptKind == 'unit');
        if (!provider.isSubscribed && keptHearts <= 0) {
          // Out of hearts mid-exam — immediate fail
          _showHeartDepletedDialog();
          return;
        }
      }
    }
  }

  void _showHeartDepletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Mascot(pose: MascotPose.sleepy, size: 80),
          const SizedBox(height: 16),
          const Text('خلصت القلوب!', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 20, fontWeight: FontWeight.w800, color: HaffarColors.error)),
          const SizedBox(height: 8),
          const Text('ما تقدر تكمل الآن. استنى القلوب وتنعش وارجع', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: HaffarColors.textSecondary)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HaffarColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => context.pop(),
            child: const Text('حسناً', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 16, fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    );
  }

  void _nextQuestion() {
    if (_isFixPhase) {
      _handleFixPhaseNext();
      return;
    }

    if (_questionIndex + 1 < widget.questions.length) {
      setState(() {
        _questionIndex++;
        _answered = false;
        _isCorrect = false;
        _showSparkles = false;
        _correctAnswerText = null;
      });
      _currentQuestion = widget.questions[_questionIndex];
    } else {
      // All questions answered — check if fix phase needed
      if (_initialMistakeCount > 0) {
        _enterFixPhase();
      } else {
        _finishQuiz();
      }
    }
  }

  void _enterFixPhase() {
    setState(() {
      _isFixPhase = true;
      _fixPhaseQuestionIds = _results
          .where((d) => !d.isCorrect)
          .map((d) => d.questionId)
          .toList();
      _fixPhaseIndex = 0;
      _answered = false;
      _isCorrect = false;
    });
    _showFixPhaseIntro();
  }

  void _showFixPhaseIntro() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Mascot(pose: MascotPose.sad, size: 80),
          const SizedBox(height: 16),
          const Text('يلا تعال نصلح أخطائك', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 18, fontWeight: FontWeight.w800, color: HaffarColors.textPrimary)),
          const SizedBox(height: 8),
          Text('وتظبط الفاتنا! ($_initialMistakeCount سؤال)', style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: HaffarColors.textSecondary)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HaffarColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => context.pop(),
            child: const Text('يلا!', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 16, fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    );
  }

  void _handleFixPhaseNext() {
    if (_fixPhaseIndex + 1 < _fixPhaseQuestionIds.length) {
      setState(() {
        _fixPhaseIndex++;
        _answered = false;
        _isCorrect = false;
        _showSparkles = false;
        _correctAnswerText = null;
      });
      _currentQuestion = _questionById(_fixPhaseQuestionIds[_fixPhaseIndex]);
    } else {
      _finishQuiz();
    }
  }

  Question _questionById(String id) {
    for (final q in widget.questions) {
      if (q.id == id) return q;
    }
    // Fallback: search all questions from provider
    final allQs = context.read<AppProvider>().questionsOf(widget.subjectId);
    for (final q in allQs) {
      if (q.id == id) return q;
    }
    return Question(id: id, subjectId: widget.subjectId, lessonIndex: 0, type: QuestionType.multipleChoice, text: '');
  }

  void _finishQuiz() {
    final totalWrong = _initialMistakeCount; // fix phase mistakes don't add penalty
    var finalXp = _baseXp - (totalWrong * _penaltyPerWrong);
    finalXp = finalXp.clamp(0, 9999);

    // Unit bonus: +15 XP if elapsed < 2 minutes
    if (widget.attemptKind == 'unit' && _elapsed < GameConstants.unitBonusTimeThreshold) {
      finalXp += GameConstants.unitBonusXp;
    }

    // Save attempt (with fix-phase results appended)
    _saveAttempt();

    // Record XP event
    context.read<AppProvider>().addXpEvent(
      amount: finalXp,
      source: widget.attemptKind,
      subjectId: widget.subjectId,
      lessonIndex: widget.attemptKind == 'lesson' ? widget.attemptRefIndex : null,
    );

    // Mark completion
    if (widget.attemptKind == 'unit') {
      context.read<AppProvider>().completeUnitExercise(widget.subjectId, widget.attemptRefIndex);
    } else {
      context.read<AppProvider>().completeSubjectLesson(widget.subjectId, widget.attemptRefIndex);
    }

    // Streak update via server RPC
    context.read<AppProvider>().updateStreakOnCompletion();

    final pose = _correctCount > _totalQuestions ~/ 2 ? MascotPose.cheer : MascotPose.sad;
    CelebrationDialog.show(
      context,
      pose: pose,
      title: '',
      message: '',
      popUnderneath: true,
      xpGained: finalXp,
      duration: _elapsed,
    );
  }

  void _saveAttempt() {
    if (_results.isEmpty) return;
    unawaited(
      AttemptRepository(Supabase.instance.client)
          .saveAttempt(subjectId: widget.subjectId, kind: widget.attemptKind, refIndex: widget.attemptRefIndex, details: _results)
          .catchError((_) {}),
    );
  }

  Widget _feedbackBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: _isCorrect ? const Color(0xFF58cc02) : HaffarColors.error,
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _isCorrect ? const Color(0xFF58cc02) : HaffarColors.error, width: 2)),
          clipBehavior: Clip.antiAlias,
          child: Mascot(pose: _isCorrect ? MascotPose.jump : MascotPose.sad, size: 46),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_isCorrect ? 'أحسنت! إجابة صحيحة' : 'إجابة خاطئة', style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
          if (!_isCorrect && _correctAnswerText != null) ...[const SizedBox(height: 2), Text('الإجابة الصحيحة: ${_correctAnswerText!}', style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Colors.white70))],
        ])),
        const SizedBox(width: 8),
        Material(color: Colors.transparent, child: InkWell(
          onTap: _nextQuestion, borderRadius: BorderRadius.circular(8),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(8))),
            child: Text(_isFixPhase ? 'التالي' : 'التالي', style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 15, fontWeight: FontWeight.w700, color: HaffarColors.primary))),
        )),
      ]),
    );
  }

  Widget _buildHeader() {
    final provider = context.watch<AppProvider>();
    final isUnit = widget.attemptKind == 'unit';
    final heartsToShow = isUnit ? GameConstants.unitHearts : provider.hearts;
    final progress = _questionIndex / _totalQuestions;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(children: [
        // Heart pill + X button
        Row(children: [
          // Close button
          const Spacer(),
          // Progress bar
          Expanded(
            child: Container(
              height: 12,
              decoration: BoxDecoration(color: HaffarColors.surfaceHigh, borderRadius: BorderRadius.circular(9999)),
              child: FractionallySizedBox(
                alignment: Alignment.centerRight, // RTL — progress fills from right
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(color: HaffarColors.primary, borderRadius: BorderRadius.circular(9999)),
                  height: 12,
                  width: progress * MediaQuery.of(context).size.width * 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Heart pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: HaffarColors.surfaceHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.favorite, size: 16, color: heartsToShow > 0 ? HaffarColors.primary : HaffarColors.error),
              const SizedBox(width: 4),
              Text('$heartsToShow ❤', style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        if (_isFixPhase) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: HaffarColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(
              'مرحلة تصحيح الأخطاء (${_fixPhaseIndex + 1}/$_fixPhaseQuestionIds.length)',
              style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 13, fontWeight: FontWeight.w700, color: HaffarColors.primary),
            ),
          ),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfbf9f9),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: _answered ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 32),
                    child: QuestionWidgetFactory.create(
                      question: _currentQuestion,
                      subjectName: widget.title,
                      lessonNumber: _isFixPhase ? _fixPhaseIndex + 1 : _questionIndex + 1,
                      customTitle: widget.title,
                      onBack: () => context.pop(),
                      onSkip: _nextQuestion,
                      onNext: _nextQuestion,
                      onSubmitAnswer: _submitAnswer,
                      locked: _answered,
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: _answered ? _feedbackBar() : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          if (_showSparkles) const Positioned.fill(child: IgnorePointer(child: SparkleBurstOverlay())),
        ],
      ),
    );
  }
}
