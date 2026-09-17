import '../../design_system/colors.dart';
import 'package:flutter/material.dart';
import 'question_base.dart';

class ExplanationQuestion extends StatefulWidget {
  final String pathTitle;
  final String questionText;
  final String? passage;
  final int xpReward;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final void Function(bool, String?) onSubmitAnswer;
  final bool locked;

  const ExplanationQuestion({
    super.key,
    required this.pathTitle,
    required this.questionText,
    this.passage,
    required this.xpReward,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
    required this.onSubmitAnswer,
    this.locked = false,
  });

  @override
  State<ExplanationQuestion> createState() => _ExplanationQuestionState();
}

class _ExplanationQuestionState extends State<ExplanationQuestion> {
  final TextEditingController _controller = TextEditingController();
  int _charCount = 0;
  static const _minChars = 20;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _charCount = _controller.text.length));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  bool get _hasContent => _charCount >= _minChars;

  void _submit() {
    if (!_hasContent || widget.locked) return;
    widget.onSubmitAnswer(true, null);
  }

  @override
  Widget build(BuildContext context) {
    return QuestionBase(
      pathTitle: widget.pathTitle,
      questionText: widget.questionText,
      xpReward: widget.xpReward,
      onBack: widget.onBack,
      onSkip: widget.onSkip,
      buildBody: (_) => Column(children: [
        if (widget.passage != null) ...[
          Container(width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: HaffarColors.outline.withValues(alpha: 0.2))),
            child: Text(widget.passage!, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Color(0xFF3f4a36), height: 1.6))),
          const SizedBox(height: 12),
        ],
        TextField(controller: _controller, maxLines: null, minLines: 6,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 16, height: 1.7),
          decoration: InputDecoration(hintText: 'اكتب شرحك هنا...', hintStyle: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, color: HaffarColors.outline), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: HaffarColors.outline.withValues(alpha: 0.3))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: HaffarColors.outline.withValues(alpha: 0.3), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: HaffarColors.primary, width: 2)), counterText: '')),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('$_charCount حرف', style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: HaffarColors.outline)),
        ]),
        const SizedBox(height: 12),
        Column(children: [
          SizedBox(height: 52, width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _hasContent && !widget.locked ? HaffarColors.primary : HaffarColors.surfaceHigh, foregroundColor: _hasContent && !widget.locked ? Colors.white : HaffarColors.textSecondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: _hasContent && !widget.locked ? _submit : null,
            child: const Text('تحقق', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 18, fontWeight: FontWeight.w700)),
          )),
          if (!widget.locked) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: widget.onSkip, child: const Text('تخطي', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 14, fontWeight: FontWeight.w500, color: HaffarColors.outline))),
          ],
        ]),
      ]),
    );
  }
}
