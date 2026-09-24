import 'package:flutter/material.dart';
import '../../design_system/colors.dart';
import 'question_base.dart';

class TrueFalseQuestion extends StatefulWidget {
  final String pathTitle;
  final String questionText;
  final int xpReward;
  final bool correctAnswer;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final void Function(bool, String?) onSubmitAnswer;
  final bool locked;

  const TrueFalseQuestion({
    super.key,
    required this.pathTitle,
    required this.questionText,
    required this.xpReward,
    required this.correctAnswer,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
    required this.onSubmitAnswer,
    this.locked = false,
  });

  @override
  State<TrueFalseQuestion> createState() => _TrueFalseQuestionState();
}

class _TrueFalseQuestionState extends State<TrueFalseQuestion> {
  bool? _selected;

  void _select(bool value) {
    if (_selected != null || widget.locked) return;
    final correct = value == widget.correctAnswer;
    _selected = value;
    widget.onSubmitAnswer(correct, correct ? 'صواب' : 'خطأ');
  }

  @override
  Widget build(BuildContext context) {
    return QuestionBase(
      pathTitle: widget.pathTitle,
      questionText: widget.questionText,
      xpReward: widget.xpReward,
      onBack: widget.onBack,
      onSkip: widget.onSkip,
      buildBody: (_) => Column(
        children: [
          Row(
            children: [
              Expanded(child: _tfButton('صواب', Icons.check_circle, true)),
              const SizedBox(width: 12),
              Expanded(child: _tfButton('خطأ', Icons.cancel, false)),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.locked
                ? null
                : (_selected == null ? widget.onSkip : null),
            child: const Text(
              'تخطي',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: HaffarColors.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tfButton(String label, IconData icon, bool value) {
    final isSelected = _selected == value;
    Color textColor = HaffarColors.outline;
    Color bgColor = Colors.white;
    Color borderColor = HaffarColors.outline.withValues(alpha: 0.25);
    if (isSelected) {
      textColor = HaffarColors.primaryDark;
      bgColor = HaffarColors.primary.withValues(alpha: 0.1);
      borderColor = HaffarColors.primary;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.locked ? null : () => _select(value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: !isSelected
                ? [
                    BoxShadow(
                      color: HaffarColors.outline.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 28),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
