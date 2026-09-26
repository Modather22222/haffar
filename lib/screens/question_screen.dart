import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../design_system/colors.dart';
import '../providers/content_provider.dart';
import '../providers/economy_provider.dart';
import '../models/question.dart';
import '../utils/routes.dart';
import '../widgets/question_widgets/question_widget_factory.dart';
import '../widgets/sparkle_burst_overlay.dart';
import '../utils/sound_manager.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen>
    with TickerProviderStateMixin {
  late String _subjectId;
  late String _subjectName;
  late int _lessonIndex;
  late int _lessonNumber;
  late int _questionIndex;
  late List<Question> _questions;
  late Question _question;
  bool _answered = false;
  bool _isCorrect = false;
  bool _showSparkles = false;
  String? _correctAnswerText;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final content = context.read<ContentProvider>();
    final uri = GoRouterState.of(context).uri;
    _subjectId = uri.queryParameters['subject'] ?? 'science';
    _subjectName = content.subjectById(_subjectId)?.name ?? _subjectId;
    _lessonIndex = int.tryParse(uri.queryParameters['lesson'] ?? '0') ?? 0;
    // Display ordinal — lesson_index may contain gaps in dynamic curricula.
    final lessons = content.lessonsOf(_subjectId);
    final lessonPos = lessons.indexWhere((l) => l.index == _lessonIndex);
    _lessonNumber = lessonPos >= 0 ? lessonPos + 1 : _lessonIndex + 1;
    _questionIndex = int.tryParse(uri.queryParameters['q'] ?? '0') ?? 0;
    _questions = content.getQuestions(_subjectId, _lessonIndex);
    _question = _questions.isNotEmpty
        ? (_questionIndex < _questions.length
              ? _questions[_questionIndex]
              : _questions.first)
        : const Question(
            id: '',
            subjectId: '',
            lessonIndex: 0,
            type: QuestionType.multipleChoice,
            text: '',
          );
  }

  void _submitAnswer(bool correct, String? correctAnswerText) {
    setState(() {
      _answered = true;
      _isCorrect = correct;
      _showSparkles = correct;
      _correctAnswerText = correctAnswerText;
    });
    _animController.forward();
    if (correct) {
      SoundManager.playCorrect(_question.id);
      // Sync via add_xp_event so this XP survives hydrate + shows on profile.
      context.read<EconomyProvider>().addXpEvent(
        amount: 3,
        source: 'bonus',
        subjectId: _subjectId,
        lessonIndex: _lessonIndex,
      );
    } else {
      SoundManager.playWrong(_question.id);
    }
  }

  void _nextQuestion() {
    if (_questionIndex + 1 < _questions.length) {
      setState(() {
        _questionIndex++;
        _answered = false;
        _isCorrect = false;
        _showSparkles = false;
        _correctAnswerText = null;
      });
      context.pushReplacement(
        '${Routes.question}?subject=$_subjectId&lesson=$_lessonIndex&q=$_questionIndex',
      );
    } else {
      context.pushReplacement(
        Routes.lessonPath,
        extra: {'subjectId': _subjectId},
      );
    }
  }

  void _skip() {
    context.pushReplacement(
      '${Routes.question}?subject=$_subjectId&lesson=$_lessonIndex&q=${_questionIndex + 1}',
    );
  }

  void _back() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HaffarColors.bgPage,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: _answered
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 32),
                    child: QuestionWidgetFactory.create(
                      question: _question,
                      subjectName: _subjectName,
                      lessonNumber: _lessonNumber,
                      onBack: _back,
                      onSkip: _skip,
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
          if (_showSparkles)
            const Positioned.fill(
              child: IgnorePointer(child: SparkleBurstOverlay()),
            ),
        ],
      ),
    );
  }

  Widget _feedbackBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: _isCorrect ? HaffarColors.primary : HaffarColors.error,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _isCorrect ? Icons.check_rounded : Icons.close_rounded,
                size: 24,
                color: _isCorrect ? HaffarColors.primary : HaffarColors.error,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCorrect ? 'أحسنت! إجابة صحيحة' : 'إجابة خاطئة',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (!_isCorrect && _correctAnswerText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'الإجابة الصحيحة: ${_correctAnswerText!}',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _nextQuestion,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: const Text(
                  'التالي',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: HaffarColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
