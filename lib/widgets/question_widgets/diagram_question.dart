import '../../design_system/colors.dart';
import 'package:flutter/material.dart';
import 'question_base.dart';

/// سؤال: الرسم والبيانات — a square diagram/image card with a "؟" label slot
/// pointing into the image. Picking an option fills the slot with that answer.
class DiagramQuestion extends StatefulWidget {
  final String pathTitle;
  final String questionText;
  final String imageUrl;
  final List<String> options;
  final int correctIndex;
  final int xpReward;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final void Function(bool, String?) onSubmitAnswer;
  final bool locked;

  const DiagramQuestion({
    super.key,
    required this.pathTitle,
    required this.questionText,
    required this.imageUrl,
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
  State<DiagramQuestion> createState() => _DiagramQuestionState();
}

class _DiagramQuestionState extends State<DiagramQuestion> {
  int? _selected;

  static const _secondary = HaffarColors.primaryLight;
  static const _slotBorderIdle = Color(0xFFbecbb1);
  static const _cardBg = Color(0xFFf5f3f3);

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
      xpReward: widget.xpReward,
      onBack: widget.onBack,
      onSkip: widget.onSkip,
      buildBody: (_) => Column(children: [
        _DiagramCard(
          imageUrl: widget.imageUrl,
          selectedText: _selected == null ? null : widget.options[_selected!],
        ),
        const SizedBox(height: 24),
        ...widget.options.asMap().entries.map((entry) {
          final idx = entry.key;
          final text = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionButton(
              text: text,
              isSelected: _selected == idx && !widget.locked,
              isCorrect: widget.locked && idx == widget.correctIndex,
              isWrong: widget.locked && _selected == idx && idx != widget.correctIndex,
              onTap: widget.locked ? null : () => setState(() => _selected = idx),
            ),
          );
        }),
        const SizedBox(height: 12),
        SizedBox(height: 52, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _selected != null ? HaffarColors.primary : HaffarColors.surfaceHigh, foregroundColor: _selected != null ? Colors.white : HaffarColors.textSecondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: _selected != null && !widget.locked ? _submit : null,
          child: const Text('تحقق', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 18, fontWeight: FontWeight.w700)),
        )),
      ]),
    );
  }
}

class _DiagramCard extends StatelessWidget {
  final String imageUrl;
  final String? selectedText;

  const _DiagramCard({required this.imageUrl, this.selectedText});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: _DiagramQuestionState._cardBg, borderRadius: BorderRadius.circular(24), border: Border.all(color: _DiagramQuestionState._slotBorderIdle, width: 2)),
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(builder: (_, constraints) {
          return Stack(children: [
            Center(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(color: HaffarColors.primary)),
              errorBuilder: (_, _, _) => const Center(child: Icon(Icons.image_not_supported_outlined, size: 48, color: HaffarColors.outline)),
            ))),
            Positioned(
              top: constraints.maxHeight * 0.18,
              right: constraints.maxWidth * 0.08,
              child: _LabelSlot(text: selectedText),
            ),
          ]);
        }),
      ),
    );
  }
}

class _LabelSlot extends StatelessWidget {
  final String? text;

  const _LabelSlot({this.text});

  @override
  Widget build(BuildContext context) {
    final filled = text != null;
    return Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
      // pointer line + dot reaching into the image (visual left of the chip)
      Transform.rotate(angle: -0.22, child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(width: 52, height: 2, margin: const EdgeInsets.only(right: 4), color: const Color(0xFF1b1c1c)),
        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1b1c1c), shape: BoxShape.circle)),
      ])),
      const SizedBox(width: 6),
      AnimatedContainer(duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        constraints: const BoxConstraints(minWidth: 100, minHeight: 40),
        decoration: ShapeDecoration(
          color: filled ? const Color(0xFF88ceff) : Colors.white,
          shape: DashedRoundedRectBorder(radius: 8, borderWidth: 2, color: filled ? const Color(0xFF006590) : _DiagramQuestionState._slotBorderIdle, dash: filled ? null : const [5, 4]),
        ),
        child: Center(child: Text(filled ? text! : '؟', style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: filled ? const Color(0xFF006590) : const Color(0xFF3f4a36)))),
      ),
    ]);
  }
}

class _OptionButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;

  const _OptionButton({required this.text, required this.isSelected, required this.isCorrect, required this.isWrong, this.onTap});

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
      bgColor = const Color(0xFFc8e6ff);
      borderColor = _DiagramQuestionState._secondary;
    } else {
      bgColor = Colors.white;
      borderColor = const Color(0xFFe3e2e2);
    }
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor, width: 2),
          boxShadow: !isSelected && !isCorrect && !isWrong ? [BoxShadow(color: HaffarColors.outline.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))] : []),
        alignment: Alignment.center,
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 18, fontWeight: FontWeight.w500))),
    ));
  }
}

/// Rounded-rect border; solid when [dash] is null, dashed otherwise.
class DashedRoundedRectBorder extends ShapeBorder {
  final double radius;
  final double borderWidth;
  final Color color;
  final List<double>? dash;

  const DashedRoundedRectBorder({required this.radius, required this.borderWidth, required this.color, this.dash});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderWidth);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect.deflate(borderWidth), Radius.circular(radius)));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final rrect = RRect.fromRectAndRadius(rect.deflate(borderWidth / 2), Radius.circular(radius));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    if (dash == null) {
      canvas.drawRRect(rrect, paint);
      return;
    }
    final path = getOuterPath(rect)..close();
    canvas.drawPath(_dashPath(path, dash!), paint);
  }

  Path _dashPath(Path source, List<double> dash) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final len = dash[draw ? 0 : 1];
        if (draw) {
          dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  ShapeBorder scale(double t) => DashedRoundedRectBorder(radius: radius * t, borderWidth: borderWidth * t, color: color, dash: dash);
}
