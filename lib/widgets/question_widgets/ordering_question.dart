import '../../design_system/colors.dart';
import 'package:flutter/material.dart';
import 'question_base.dart';

class OrderingQuestion extends StatefulWidget {
  final String pathTitle;
  final String questionText;
  final List<String> options;
  final List<String> correctOrder;
  final int xpReward;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final void Function(bool, String?) onSubmitAnswer;
  final bool locked;

  const OrderingQuestion({
    super.key,
    required this.pathTitle,
    required this.questionText,
    required this.options,
    required this.correctOrder,
    required this.xpReward,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
    required this.onSubmitAnswer,
    this.locked = false,
  });

  @override
  State<OrderingQuestion> createState() => _OrderingQuestionState();
}

class _OrderingQuestionState extends State<OrderingQuestion> {
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.options);
  }

  bool get _isOrdered => _items.join('—') == widget.correctOrder.join('—');

  void _move(int from, int to) {
    if (widget.locked) return;
    if (to < 0 || to >= _items.length) return;
    setState(() {
      final item = _items.removeAt(from);
      _items.insert(to, item);
    });
  }

  void _check() {
    if (widget.locked) return;
    final correct = _isOrdered;
    widget.onSubmitAnswer(correct, widget.correctOrder.join(' ← '));
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
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          onReorder: (oldIdx, newIdx) => _move(oldIdx, newIdx),
          itemBuilder: (context, idx) {
            return _OrderItem(key: ValueKey(_items[idx]), index: idx + 1, text: _items[idx]);
          },
        ),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
          SizedBox(height: 52, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: HaffarColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: widget.locked ? null : _check,
            child: const Text('تحقق', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 18, fontWeight: FontWeight.w700)),
          )),
          const SizedBox(height: 8),
          TextButton(onPressed: widget.locked ? null : widget.onSkip, child: const Text('تخطي', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 14, fontWeight: FontWeight.w500, color: HaffarColors.outline))),
        ])),
      ]),
    );
  }
}

class _OrderItem extends StatelessWidget {
  final int index;
  final String text;
  const _OrderItem({super.key, required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: HaffarColors.outline.withValues(alpha: 0.2)), boxShadow: [BoxShadow(color: HaffarColors.outline.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 28, height: 28, decoration: const BoxDecoration(color: HaffarColors.primary, shape: BoxShape.circle),
          child: Center(child: Text('$index', style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)))),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 16, fontWeight: FontWeight.w500))),
        const Icon(Icons.drag_indicator, color: HaffarColors.outline),
      ]),
    );
  }
}
