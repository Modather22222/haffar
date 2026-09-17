import '../../design_system/colors.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'question_base.dart';

/// سؤال: المزاوجة — two columns; picking one item from each side draws a
/// green connector line between the pair (Stitch سؤال علوم: المزاوجة).
/// Re-selecting either endpoint replaces its line. After checking, correct
/// lines stay green and wrong ones turn red.
class MatchingQuestion extends StatefulWidget {
  final String pathTitle;
  final String questionText;
  final List<String> leftItems;
  final List<String> rightItems;
  final int xpReward;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final void Function(bool, String?) onSubmitAnswer;
  final bool locked;

  const MatchingQuestion({
    super.key,
    required this.pathTitle,
    required this.questionText,
    required this.leftItems,
    required this.rightItems,
    required this.xpReward,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
    required this.onSubmitAnswer,
    this.locked = false,
  });

  @override
  State<MatchingQuestion> createState() => _MatchingQuestionState();
}

class _MatchingQuestionState extends State<MatchingQuestion> {
  final GlobalKey _containerKey = GlobalKey();
  late final List<GlobalKey> _leftKeys;
  late final List<GlobalKey> _rightKeys;

  /// display position of right column -> original (logical) right index,
  /// deterministically shuffled so answers aren't aligned by row.
  late final List<int> _rightOrder;

  int? _selectedLeft;
  int? _selectedRight;
  final Map<int, int> _connections = {};
  List<_PairLine> _lines = const [];

  static const _green = HaffarColors.primary;
  static const _red = HaffarColors.error;
  static const _selectedBg = Color(0xFFc8e6ff);

  @override
  void initState() {
    super.initState();
    _leftKeys = List.generate(widget.leftItems.length, (_) => GlobalKey());
    _rightKeys = List.generate(widget.rightItems.length, (_) => GlobalKey());
    _rightOrder = List.generate(widget.rightItems.length, (i) => i);
    final seed = widget.leftItems.join('|').hashCode ^ widget.rightItems.join('#').hashCode;
    _rightOrder.shuffle(math.Random(seed));
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureLines());
  }

  bool get _allConnected => _connections.length == widget.leftItems.length;

  bool _isPairCorrect(int leftDisplay, int rightDisplay) => leftDisplay == _rightOrder[rightDisplay];

  void _tapItem({required bool isLeftColumn, required int idx}) {
    if (widget.locked) return;
    setState(() {
      if (isLeftColumn) {
        _selectedLeft = _selectedLeft == idx ? null : idx;
      } else {
        _selectedRight = _selectedRight == idx ? null : idx;
      }
      if (_selectedLeft != null && _selectedRight != null) {
        // replace any previous line touching either endpoint
        _connections.removeWhere((l, r) => l == _selectedLeft || r == _selectedRight);
        _connections[_selectedLeft!] = _selectedRight!;
        _selectedLeft = null;
        _selectedRight = null;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureLines());
  }

  void _measureLines() {
    final containerCtx = _containerKey.currentContext;
    if (containerCtx == null) return;
    final containerBox = containerCtx.findRenderObject() as RenderBox;
    RenderBox? boxOf(GlobalKey key) => key.currentContext?.findRenderObject() as RenderBox?;

    final lines = <_PairLine>[];
    _connections.forEach((l, r) {
      final lb = boxOf(_leftKeys[l]);
      final rb = boxOf(_rightKeys[r]);
      if (lb == null || rb == null || !lb.attached || !rb.attached) return;
      // RTL row: A-column renders visually right (inner edge = local x 0),
      // B-column renders visually left (inner edge = local x width)
      final start = lb.localToGlobal(Offset(0, lb.size.height / 2), ancestor: containerBox);
      final end = rb.localToGlobal(Offset(rb.size.width, rb.size.height / 2), ancestor: containerBox);
      lines.add(_PairLine(start: start, end: end, correct: _isPairCorrect(l, r)));
    });
    if (mounted) setState(() => _lines = lines);
  }

  void _submit() {
    if (widget.locked || !_allConnected) return;
    String? wrongAnswer;
    var allCorrect = true;
    for (var l = 0; l < widget.leftItems.length; l++) {
      if (!_isPairCorrect(l, _connections[l]!)) {
        allCorrect = false;
        wrongAnswer = widget.rightItems[l];
        break;
      }
    }
    widget.onSubmitAnswer(allCorrect, allCorrect ? null : wrongAnswer);
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
        SizedBox(
          key: _containerKey,
          width: double.infinity,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _ConnectorLinesPainter(lines: _lines, revealed: widget.locked)),
              ),
            ),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _column(widget.leftItems, _leftKeys, isLeftColumn: true)),
              const SizedBox(width: 40),
              Expanded(child: _column(widget.rightItems, _rightKeys, isLeftColumn: false)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 0), child: Column(children: [
          SizedBox(height: 52, width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _allConnected ? HaffarColors.primary : HaffarColors.surfaceHigh, foregroundColor: _allConnected ? Colors.white : HaffarColors.textSecondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: _allConnected && !widget.locked ? _submit : null,
            child: const Text('تحقق', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 18, fontWeight: FontWeight.w700)),
          )),
          const SizedBox(height: 8),
          TextButton(onPressed: widget.locked ? null : widget.onSkip, child: const Text('تخطي', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 14, fontWeight: FontWeight.w500, color: HaffarColors.outline))),
        ])),
      ]),
    );
  }

  Widget _column(List<String> items, List<GlobalKey> keys, {required bool isLeftColumn}) {
    return Column(children: items.asMap().entries.map((entry) {
      final idx = entry.key;
      final text = entry.value;
      final connectedRight = isLeftColumn ? null : _reverseLookup(idx);
      final isConnected = isLeftColumn ? _connections.containsKey(idx) : connectedRight != null;
      final isCorrectPair = widget.locked && isConnected && (isLeftColumn ? _isPairCorrect(idx, _connections[idx]!) : _isPairCorrect(_reverseLookup(idx)!, idx));
      final isSelected = isLeftColumn ? _selectedLeft == idx : _selectedRight == idx;
      return Padding(padding: const EdgeInsets.only(bottom: 12), child: KeyedSubtree(
        key: keys[idx],
        child: _MatchCard(
          text: text,
          isSelected: isSelected,
          isConnected: isConnected,
          revealedWrong: widget.locked && isConnected && !isCorrectPair,
          onTap: () => _tapItem(isLeftColumn: isLeftColumn, idx: idx),
        ),
      ));
    }).toList(),
    );
  }

  int? _reverseLookup(int rightDisplay) {
    for (final e in _connections.entries) {
      if (e.value == rightDisplay) return e.key;
    }
    return null;
  }
}

class _MatchCard extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isConnected;
  final bool revealedWrong;
  final VoidCallback onTap;

  const _MatchCard({required this.text, required this.isSelected, required this.isConnected, required this.revealedWrong, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    if (revealedWrong) {
      bgColor = HaffarColors.error.withValues(alpha: 0.08);
      borderColor = _MatchingQuestionState._red;
    } else if (isSelected) {
      bgColor = _MatchingQuestionState._selectedBg;
      borderColor = _MatchingQuestionState._green;
    } else if (isConnected) {
      bgColor = Colors.white;
      borderColor = _MatchingQuestionState._green;
    } else {
      bgColor = Colors.white;
      borderColor = HaffarColors.outline.withValues(alpha: 0.25);
    }
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor, width: 2),
          boxShadow: !isSelected && !isConnected && !revealedWrong ? [BoxShadow(color: HaffarColors.outline.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))] : []),
        alignment: Alignment.center,
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w500, height: 1.4))),
    ));
  }
}

class _PairLine {
  final Offset start;
  final Offset end;
  final bool correct;

  const _PairLine({required this.start, required this.end, required this.correct});
}

class _ConnectorLinesPainter extends CustomPainter {
  final List<_PairLine> lines;
  final bool revealed;

  _ConnectorLinesPainter({required this.lines, required this.revealed});

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final paint = Paint()
        ..color = revealed && !line.correct ? _MatchingQuestionState._red : _MatchingQuestionState._green
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(line.start, line.end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorLinesPainter oldDelegate) =>
      oldDelegate.lines != lines || oldDelegate.revealed != revealed;
}
