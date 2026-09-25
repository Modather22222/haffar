import '../../design_system/colors.dart';
import 'package:flutter/material.dart';
import '../markdown_text.dart';
import 'question_base.dart';

class DefinitionQuestion extends StatefulWidget {
  final String pathTitle;
  final String term;
  final String questionText;
  final String? imageUrl;
  final List<String> options;
  final int correctIndex;
  final int xpReward;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final void Function(bool, String?) onSubmitAnswer;
  final bool locked;

  const DefinitionQuestion({
    super.key,
    required this.pathTitle,
    required this.term,
    required this.questionText,
    this.imageUrl,
    required this.options,
    required this.correctIndex,
    required this.xpReward,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
    required this.onSubmitAnswer,
    this.locked = false,
  });

  @override
  State<DefinitionQuestion> createState() => _DefinitionQuestionState();
}

class _DefinitionQuestionState extends State<DefinitionQuestion> {
  int? _selected;

  void _submit() {
    if (_selected == null || widget.locked) return;
    final correct = _selected == widget.correctIndex;
    widget.onSubmitAnswer(correct, widget.options[widget.correctIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return QuestionBase(
      pathTitle: widget.pathTitle,
      questionText: widget.questionText,
      imageUrl: widget.imageUrl,
      xpReward: widget.xpReward,
      onBack: widget.onBack,
      onSkip: widget.onSkip,
      buildBody: (_) => Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: HaffarColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: HaffarColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: MarkdownText(
              widget.term,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: HaffarColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...widget.options.asMap().entries.map((entry) {
            final idx = entry.key;
            final text = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DefOption(
                text: text,
                isSelected: _selected == idx && !widget.locked,
                isCorrect: widget.locked && idx == widget.correctIndex,
                isWrong:
                    widget.locked &&
                    _selected == idx &&
                    idx != widget.correctIndex,
                onTap: widget.locked
                    ? null
                    : () => setState(() => _selected = idx),
              ),
            );
          }),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selected != null
                          ? HaffarColors.primary
                          : HaffarColors.surfaceHigh,
                      foregroundColor: _selected != null
                          ? Colors.white
                          : HaffarColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _selected != null && !widget.locked
                        ? _submit
                        : null,
                    child: const Text(
                      'تحقق',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.locked ? null : widget.onSkip,
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
          ),
        ],
      ),
    );
  }
}

class _DefOption extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;
  const _DefOption({
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    if (isCorrect) {
      bgColor = HaffarColors.primary.withValues(alpha: 0.15);
      borderColor = HaffarColors.primary;
    } else if (isWrong) {
      bgColor = HaffarColors.error.withValues(alpha: 0.08);
      borderColor = HaffarColors.error;
    } else if (isSelected) {
      bgColor = HaffarColors.primary.withValues(alpha: 0.1);
      borderColor = HaffarColors.primary;
    } else {
      bgColor = Colors.white;
      borderColor = HaffarColors.outline.withValues(alpha: 0.25);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: !isSelected && !isCorrect && !isWrong
                ? [
                    BoxShadow(
                      color: HaffarColors.outline.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isCorrect || isSelected
                      ? HaffarColors.primary
                      : isWrong
                      ? HaffarColors.error
                      : HaffarColors.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isWrong
                    ? const Icon(Icons.close, size: 14, color: Colors.white)
                    : (isCorrect || isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
