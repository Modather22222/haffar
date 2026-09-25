import '../../design_system/colors.dart';
import 'package:flutter/material.dart';
import 'question_base.dart';

/// سؤال: مسألة حسابية — either choice-based (options list) or free-entry
/// numeric answer (correctWords), with an optional formula card from [formula].
class CalculationQuestion extends StatefulWidget {
  final String pathTitle;
  final String questionText;
  final String? imageUrl;
  final String? hint;
  final String? formula;
  final List<String> options;
  final List<String> correctWords;
  final int correctIndex;
  final int xpReward;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final void Function(bool, String?) onSubmitAnswer;
  final bool locked;

  const CalculationQuestion({
    super.key,
    required this.pathTitle,
    required this.questionText,
    this.imageUrl,
    this.hint,
    this.formula,
    required this.options,
    required this.correctWords,
    required this.correctIndex,
    required this.xpReward,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
    required this.onSubmitAnswer,
    this.locked = false,
  });

  @override
  State<CalculationQuestion> createState() => _CalculationQuestionState();
}

class _CalculationQuestionState extends State<CalculationQuestion> {
  static const _arabicDigits = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  final TextEditingController _controller = TextEditingController();
  int? _selected;
  bool _submitted = false;
  bool _isCorrect = false;

  bool get _isChoiceMode => widget.options.isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Normalize answers: Arabic-Indic digits -> Latin, drop spaces/case.
  String _normalize(String raw) {
    final cleaned = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final buffer = StringBuffer();
    for (final ch in cleaned.runes) {
      final c = String.fromCharCode(ch);
      buffer.write(_arabicDigits[c] ?? c);
    }
    return buffer.toString();
  }

  bool get _canSubmit {
    if (_submitted || widget.locked) return false;
    return _isChoiceMode
        ? _selected != null
        : _normalize(_controller.text).isNotEmpty;
  }

  void _check() {
    if (!_canSubmit) return;
    if (_isChoiceMode) {
      final correct = _selected == widget.correctIndex;
      setState(() {
        _submitted = true;
        _isCorrect = correct;
      });
      widget.onSubmitAnswer(correct, widget.options[widget.correctIndex]);
    } else {
      final answer = _normalize(_controller.text);
      final found = widget.correctWords.any((cw) => _normalize(cw) == answer);
      setState(() {
        _submitted = true;
        _isCorrect = found;
      });
      widget.onSubmitAnswer(found, widget.correctWords.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return QuestionBase(
      pathTitle: widget.pathTitle,
      questionText: widget.questionText,
      imageUrl: widget.imageUrl,
      hint: widget.hint,
      xpReward: widget.xpReward,
      onBack: widget.onBack,
      onSkip: widget.onSkip,
      buildBody: (_) => Column(
        children: [
          if (widget.formula != null && !_isChoiceMode) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFc8e6ff).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: HaffarColors.primaryLight.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.functions,
                    size: 20,
                    color: Color(0xFF006590),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.formula!,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF006590),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_isChoiceMode)
            ...widget.options.asMap().entries.map((entry) {
              final idx = entry.key;
              final text = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CalcOption(
                  text: text,
                  isSelected: _selected == idx && !_submitted,
                  isCorrect: widget.locked && !_isChoiceMode
                      ? false
                      : _submitted && idx == widget.correctIndex,
                  isWrong:
                      _submitted &&
                      _selected == idx &&
                      idx != widget.correctIndex,
                  onTap: widget.locked || _submitted
                      ? null
                      : () => setState(() => _selected = idx),
                ),
              );
            })
          else
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_submitted && !widget.locked,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'اكتب الإجابة...',
                hintStyle: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 16,
                  color: HaffarColors.outline,
                ),
                filled: true,
                fillColor: _submitted
                    ? (_isCorrect
                          ? HaffarColors.primary.withValues(alpha: 0.1)
                          : HaffarColors.error.withValues(alpha: 0.1))
                    : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _submitted
                        ? (_isCorrect
                              ? HaffarColors.primary
                              : HaffarColors.error)
                        : HaffarColors.primary,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: HaffarColors.outline.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: HaffarColors.primary,
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: _canSubmit ? (_) => _check() : null,
              onChanged: (_) => setState(() {}),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Column(
              children: [
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canSubmit
                          ? HaffarColors.primary
                          : HaffarColors.surfaceHigh,
                      foregroundColor: _canSubmit
                          ? Colors.white
                          : HaffarColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _canSubmit ? _check : null,
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
                  onPressed: !widget.locked && !_submitted
                      ? widget.onSkip
                      : null,
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

class _CalcOption extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;

  const _CalcOption({
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
