import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../../colors.dart';

/// Haffar voice — speech bubble with a tail pointing toward the character.
/// Shows a centred bubble containing [message].
class HaffarVoice extends StatelessWidget {
  final String message;
  final Widget? mascot;
  final double mascotSize;

  const HaffarVoice({
    super.key,
    required this.message,
    this.mascot,
    this.mascotSize = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HaffarSpeechBubble(message: message),
        const SizedBox(height: 8),
        mascot ??
            Image.asset(
              'assets/character/character (7).png',
              width: mascotSize,
              height: mascotSize,
            ),
      ],
    );
  }
}

/// Speech bubble with a tail pointing down toward the character.
/// Use [message] for plain text, or [child] for rich/mixed text.
class HaffarSpeechBubble extends StatelessWidget {
  final String? message;
  final Widget? child;
  final BubbleTailPosition tailPosition;

  const HaffarSpeechBubble({
    super.key,
    this.message,
    this.child,
    this.tailPosition = BubbleTailPosition.center,
  }) : assert(message != null || child != null, 'Provide message or child');

  static const Color _border = Color(0xFFE7E5E5);
  static const double _tailH = 12.0;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleTailPainter(border: _border, position: tailPosition),
      child: Container(
        padding: EdgeInsets.fromLTRB(28, 12, 16, 12 + _tailH),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border, width: 2),
        ),
        child:
            child ??
            Text(
              message!,
              style: TextStyle(
                fontFamily: HaffarTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 25 / 18,
                color: HaffarColors.grey1,
              ),
            ),
      ),
    );
  }
}

/// Position of the speech bubble tail.
enum BubbleTailPosition {
  /// Tail centered on the bottom edge — use when the character is directly below.
  center,

  /// Tail at the bottom-left corner — use when the character is below and to the left.
  left,

  /// Tail at the bottom-right corner — use when the character is below and to the right.
  right,

  /// Tail on the right vertical edge near the bottom — use when the character is to the right of the bubble.
  bottomRight,
}

/// Draws the tail of the speech bubble.
class _BubbleTailPainter extends CustomPainter {
  final Color border;
  final BubbleTailPosition position;

  const _BubbleTailPainter({required this.border, required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    const tailW = 14.0;
    const tailH = 12.0;

    switch (position) {
      case BubbleTailPosition.center:
        _drawBottomTail(
          canvas,
          size,
          x: size.width / 2,
          tailW: tailW,
          tailH: tailH,
        );
        break;
      case BubbleTailPosition.left:
        _drawBottomTail(canvas, size, x: tailW + 4, tailW: tailW, tailH: tailH);
        break;
      case BubbleTailPosition.right:
        _drawBottomTail(
          canvas,
          size,
          x: size.width - tailW - 4,
          tailW: tailW,
          tailH: tailH,
        );
        break;
      case BubbleTailPosition.bottomRight:
        _drawRightTail(
          canvas,
          size,
          y: size.height - tailW / 2 - 4,
          tailW: tailW,
          tailH: tailH,
        );
        break;
    }
  }

  void _drawBottomTail(
    Canvas canvas,
    Size size, {
    required double x,
    required double tailW,
    required double tailH,
  }) {
    final bottomY = size.height;
    final fillPath = Path()
      ..moveTo(x - tailW / 2, bottomY - 1)
      ..lineTo(x + tailW / 2, bottomY - 1)
      ..lineTo(x, bottomY + tailH)
      ..close();
    final borderPath = Path()
      ..moveTo(x - tailW / 2, bottomY - 2)
      ..lineTo(x, bottomY + tailH)
      ..lineTo(x + tailW / 2, bottomY - 2);
    canvas.drawPath(fillPath, Paint()..color = Colors.white);
    canvas.drawPath(
      borderPath,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawRightTail(
    Canvas canvas,
    Size size, {
    required double y,
    required double tailW,
    required double tailH,
  }) {
    final rightX = size.width;
    final fillPath = Path()
      ..moveTo(rightX - 1, y - tailW / 2)
      ..lineTo(rightX - 1, y + tailW / 2)
      ..lineTo(rightX + tailH, y)
      ..close();
    final borderPath = Path()
      ..moveTo(rightX - 2, y - tailW / 2)
      ..lineTo(rightX + tailH, y)
      ..lineTo(rightX - 2, y + tailW / 2);
    canvas.drawPath(fillPath, Paint()..color = Colors.white);
    canvas.drawPath(
      borderPath,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter old) =>
      old.border != border || old.position != position;
}
