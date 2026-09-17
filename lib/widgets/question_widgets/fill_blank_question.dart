import '../../design_system/colors.dart';
import 'package:flutter/material.dart';
import 'question_base.dart';

class FillBlankQuestion extends StatefulWidget {
  final String pathTitle;
  final String questionText;
  final String? info;
  final List<String> correctWords;
  final int xpReward;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final void Function(bool, String?) onSubmitAnswer;
  final bool locked;

  const FillBlankQuestion({
    super.key,
    required this.pathTitle,
    required this.questionText,
    this.info,
    required this.correctWords,
    required this.xpReward,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
    required this.onSubmitAnswer,
    this.locked = false,
  });

  @override
  State<FillBlankQuestion> createState() => _FillBlankQuestionState();
}

class _FillBlankQuestionState extends State<FillBlankQuestion> {
  final TextEditingController _controller = TextEditingController();
  bool _submitted = false;
  bool _isCorrect = false;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  bool get _hasAnswer => _controller.text.trim().isNotEmpty;

  void _check() {
    if (_submitted || widget.locked) return;
    final answer = _controller.text.trim().toLowerCase();
    bool found = false;
    for (final cw in widget.correctWords) {
      if (cw.trim().toLowerCase() == answer) { found = true; break; }
    }
    _submitted = true;
    _isCorrect = found;
    widget.onSubmitAnswer(found, widget.correctWords.first);
  }

  @override
  Widget build(BuildContext context) {
    return QuestionBase(
      pathTitle: widget.pathTitle,
      questionText: widget.questionText,
      info: widget.info,
      xpReward: widget.xpReward,
      onBack: widget.onBack,
      onSkip: widget.onSkip,
      buildBody: (_) => Column(children: [
        TextField(
          controller: _controller,
          autofocus: true,
          enabled: !_submitted && !widget.locked,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 20, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'اكتب الإجابة...',
            hintStyle: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 16, color: HaffarColors.outline),
            filled: true,
            fillColor: _submitted ? (_isCorrect ? HaffarColors.primary.withValues(alpha: 0.1) : HaffarColors.error.withValues(alpha: 0.1)) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _submitted ? (_isCorrect ? HaffarColors.primary : HaffarColors.error) : HaffarColors.primary, width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: HaffarColors.outline.withValues(alpha: 0.3), width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: HaffarColors.primary, width: 2)),
          ),
          onSubmitted: (_submitted || widget.locked) ? null : (_) => _check(),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
          SizedBox(height: 52, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _hasAnswer && !_submitted && !widget.locked ? HaffarColors.primary : HaffarColors.surfaceHigh, foregroundColor: _hasAnswer && !_submitted && !widget.locked ? Colors.white : HaffarColors.textSecondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: _hasAnswer && !_submitted && !widget.locked ? _check : null,
            child: const Text('تحقق', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 18, fontWeight: FontWeight.w700)),
          )),
          const SizedBox(height: 8),
          TextButton(onPressed: !widget.locked && !_submitted ? widget.onSkip : null, child: const Text('تخطي', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 14, fontWeight: FontWeight.w500, color: HaffarColors.outline))),
        ])),
      ]),
    );
  }
}
