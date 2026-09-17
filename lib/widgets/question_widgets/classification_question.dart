import '../../design_system/colors.dart';
import 'package:flutter/material.dart';
import 'question_base.dart';

/// سؤال: تصنيف المكونات — word-bank chips sorted into two category zones
/// (e.g. جهاز إدخال / جهاز إخراج). Tap a chip to select it, tap a zone to
/// place it; tap a placed chip to send it back. تحقق unlocks when all placed.
class ClassificationQuestion extends StatefulWidget {
  final String pathTitle;
  final String questionText;
  final List<String> items;
  final List<String> itemCategories;
  final String zoneOneLabel;
  final String zoneTwoLabel;
  final int xpReward;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final void Function(bool, String?) onSubmitAnswer;
  final bool locked;

  const ClassificationQuestion({
    super.key,
    required this.pathTitle,
    required this.questionText,
    required this.items,
    required this.itemCategories,
    this.zoneOneLabel = 'جهاز إدخال',
    this.zoneTwoLabel = 'جهاز إخراج',
    required this.xpReward,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
    required this.onSubmitAnswer,
    this.locked = false,
  });

  @override
  State<ClassificationQuestion> createState() => _ClassificationQuestionState();
}

class _ClassificationQuestionState extends State<ClassificationQuestion> {
  static const _green = HaffarColors.primary;
  static const _greenText = HaffarColors.primaryDark;
  static const _blue = HaffarColors.primaryLight;
  static const _blueText = Color(0xFF006590);
  static const _red = HaffarColors.error;

  int? _selectedItem;
  final Map<int, int> _placements = {}; // itemIndex -> zoneIndex (0 / 1)
  bool _submitted = false;

  bool get _interactive => !widget.locked && !_submitted;
  bool get _allPlaced => _placements.length == widget.items.length;

  void _tapBankChip(int idx) {
    if (!_interactive) return;
    setState(() => _selectedItem = _selectedItem == idx ? null : idx);
  }

  void _tapZone(int zone) {
    if (!_interactive || _selectedItem == null) return;
    setState(() {
      _placements[_selectedItem!] = zone;
      _selectedItem = null;
    });
  }

  void _tapPlacedChip(int idx) {
    if (!_interactive) return;
    setState(() {
      _placements.remove(idx);
      _selectedItem = null;
    });
  }

  void _check() {
    if (!_allPlaced || !_interactive) return;
    var correct = true;
    String? hint;
    for (var i = 0; i < widget.items.length; i++) {
      final expected = widget.itemCategories[i];
      if (_placements[i].toString() != expected) {
        correct = false;
        hint ??= '${widget.items[i]}: ${expected == '0' ? widget.zoneOneLabel : widget.zoneTwoLabel}';
      }
    }
    setState(() => _submitted = true);
    widget.onSubmitAnswer(correct, correct ? null : hint);
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
        // Word bank — unplaced chips
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: HaffarColors.outline.withValues(alpha: 0.2))),
          child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            for (var i = 0; i < widget.items.length; i++)
              if (!_placements.containsKey(i))
                _chip(i, inBank: true),
          ]),
        ),
        const SizedBox(height: 20),
        // Two classification zones
        Row(children: [
          Expanded(child: _zone(0)),
          const SizedBox(width: 12),
          Expanded(child: _zone(1)),
        ]),
        const SizedBox(height: 20),
        SizedBox(height: 52, width: double.infinity, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _allPlaced && _interactive ? HaffarColors.primary : HaffarColors.surfaceHigh, foregroundColor: _allPlaced && _interactive ? Colors.white : HaffarColors.textSecondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: _allPlaced && _interactive ? _check : null,
          child: const Text('تحقق', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 18, fontWeight: FontWeight.w700)),
        )),
        if (_interactive) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: widget.onSkip, child: const Text('تخطي', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 14, fontWeight: FontWeight.w500, color: HaffarColors.outline))),
        ],
      ]),
    );
  }

  Widget _zone(int zone) {
    final isGreen = zone == 0;
    final accent = isGreen ? _green : _blue;
    final textColor = isGreen ? _greenText : _blueText;
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Text(isGreen ? widget.zoneOneLabel : widget.zoneTwoLabel, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
      ),
      const SizedBox(height: 8),
      InkWell(
        onTap: () => _tapZone(zone),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(duration: const Duration(milliseconds: 150),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 140),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFefeded),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _selectedItem != null && _interactive ? accent.withValues(alpha: 0.7) : accent.withValues(alpha: 0.25), width: _selectedItem != null && _interactive ? 2 : 1.5),
          ),
          alignment: Alignment.topCenter,
          child: _placements.entries.where((e) => e.value == zone).isEmpty
              ? Center(child: Text(_selectedItem != null && _interactive ? 'اضغط للوضع هنا' : '', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: textColor.withValues(alpha: 0.6))))
              : Wrap(spacing: 8, runSpacing: 8, children: [for (final e in _placements.entries) if (e.value == zone) _chip(e.key, inBank: false)]),
        ),
      ),
    ]);
  }

  Widget _chip(int idx, {required bool inBank}) {
    final selectedInBank = inBank && _selectedItem == idx;
    Color bg = selectedInBank ? HaffarColors.surfaceHigh : Colors.white;
    Color border = selectedInBank ? HaffarColors.primary : HaffarColors.outline.withValues(alpha: 0.3);
    if (!inBank && _submitted) {
      final expected = widget.itemCategories[idx];
      final ok = _placements[idx].toString() == expected;
      bg = (ok ? _green : _red).withValues(alpha: 0.12);
      border = ok ? _green : _red;
    }
    return GestureDetector(onTap: inBank ? () => _tapBankChip(idx) : () => _tapPlacedChip(idx), child: AnimatedContainer(duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: selectedInBank || (!inBank && _submitted) ? 2 : 1.5),
        boxShadow: selectedInBank ? [BoxShadow(color: HaffarColors.primary.withValues(alpha: 0.2), blurRadius: 5, offset: const Offset(0, 2))] : []),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (!inBank && _submitted) ...[
          Icon(_placements[idx].toString() == widget.itemCategories[idx] ? Icons.check_circle : Icons.cancel, size: 15, color: bg == Colors.white ? _green : border),
          const SizedBox(width: 6),
        ],
        Text(widget.items[idx], style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w600, color: HaffarColors.textPrimary)),
      ]),
    ));
  }
}
