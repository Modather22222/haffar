import 'package:flutter/material.dart';

import '../buttons/button_general_primary.dart';

// Feedback sheets — ported from the Duolingo Duo modals, adapted to
// Haffar (BeVietnamPro typography, brand imagery removed per request).
// No mascot/images inside the sheets.

// ── Correct: green banner + white-check circle (Duo-spec greens) ─────────
const Color _correctBg = Color(0xFFEDFBE9);
const Color _correctHeading = Color(0xFF50A130);
const Color _correctButtonBg = Color(0xFF50A130);
const Color _correctFlagColor = Color(0xFF0E8A00);

// ── Wrong: Duo red banner + white-cross circle ───────────────────────────
const Color _wrongBg = Color(0xFFFBCECE);
const Color _wrongTextPrimary = Color(0xFFED0C0C);

class LessonCorrectFeedback extends StatelessWidget {
  final String heading;
  final String subText;
  final VoidCallback? onContinueTap;

  const LessonCorrectFeedback({
    super.key,
    required this.heading,
    required this.subText,
    this.onContinueTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _correctBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CorrectHeader(heading: heading),
            const SizedBox(height: 4),
            Text(
              subText,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _correctHeading,
              ),
            ),
            const SizedBox(height: 16),
            _CorrectContinueButton(onTap: onContinueTap),
          ],
        ),
      ),
    );
  }
}

class _CorrectHeader extends StatelessWidget {
  final String heading;

  const _CorrectHeader({required this.heading});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _CircleTickIcon(),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            heading,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _correctHeading,
            ),
          ),
        ),
        const _FlagIcon(color: _correctFlagColor),
      ],
    );
  }
}

class _CorrectContinueButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _CorrectContinueButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return HaffarPrimaryButton(
      label: 'متابعة',
      fullWidth: true,
      backgroundColor: _correctButtonBg,
      onPressed: onTap,
    );
  }
}

/// Green circle with white checkmark.
class _CircleTickIcon extends StatelessWidget {
  const _CircleTickIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _CircleTickPainter()),
    );
  }
}

class _CircleTickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.save();
    canvas.scale(s);
    final circle = Paint()..color = _correctButtonBg;
    canvas.drawCircle(const Offset(12, 12), 12, circle);
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.91698
      ..strokeCap = StrokeCap.round;
    final path = Path();
    path.moveTo(7.63721, 12.2579);
    path.lineTo(10.6095, 15.2302);
    path.lineTo(17.0677, 9.55493);
    canvas.drawPath(path, strokePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlagIcon extends StatelessWidget {
  final Color color;

  const _FlagIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _FlagPainter(color: color)),
    );
  }
}

class _FlagPainter extends CustomPainter {
  final Color color;

  const _FlagPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.save();
    canvas.scale(s);
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(10, 6);
    path.lineTo(10.72, 4.55);
    path.cubicTo(10.89, 4.21, 11.24, 4, 11.62, 4);
    path.lineTo(18, 4);
    path.cubicTo(18.55, 4, 19, 4.45, 19, 5);
    path.lineTo(19, 20);
    path.cubicTo(19, 20.55, 18.55, 21, 18, 21);
    path.lineTo(17, 21);
    path.lineTo(17, 14);
    path.lineTo(12, 14);
    path.lineTo(11.28, 15.45);
    path.cubicTo(11.1969, 15.6149, 11.0698, 15.7536, 10.9127, 15.8507);
    path.cubicTo(10.7556, 15.9478, 10.5747, 15.9994, 10.39, 16);
    path.lineTo(5, 16);
    path.cubicTo(4.45, 16, 4, 15.55, 4, 15);
    path.lineTo(4, 7);
    path.cubicTo(4, 6.45, 4.45, 6, 5, 6);
    path.lineTo(10, 6);
    path.close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Wrong banner ─────────────────────────────────────────────────────────

class LessonIncorrectFeedback extends StatelessWidget {
  final String correctAnswer;
  final VoidCallback? onContinueTap;

  const LessonIncorrectFeedback({
    super.key,
    required this.correctAnswer,
    this.onContinueTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _wrongBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WrongHeader(),
            const SizedBox(height: 16),
            _WrongAnswerSection(correctAnswer: correctAnswer),
            const SizedBox(height: 16),
            _WrongPrimaryButton(onTap: onContinueTap),
          ],
        ),
      ),
    );
  }
}

class _WrongHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _CircleCrossIcon(),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'إجابة غير صحيحة',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _wrongTextPrimary,
            ),
          ),
        ),
        _FlagIcon(color: _wrongTextPrimary),
      ],
    );
  }
}

/// Red circle with white X.
class _CircleCrossIcon extends StatelessWidget {
  const _CircleCrossIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _CircleCrossPainter()),
    );
  }
}

class _CircleCrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.save();
    canvas.scale(s);
    final circle = Paint()..color = const Color(0xFFED0C0C);
    canvas.drawCircle(const Offset(12, 12), 12, circle);
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final xPath = Path();
    xPath.moveTo(6, 6);
    xPath.lineTo(18, 18);
    xPath.moveTo(18, 6);
    xPath.lineTo(6, 18);
    canvas.drawPath(xPath, strokePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WrongAnswerSection extends StatelessWidget {
  final String correctAnswer;

  const _WrongAnswerSection({required this.correctAnswer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الإجابة الصحيحة',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _wrongTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          correctAnswer,
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _wrongTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _WrongPrimaryButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _WrongPrimaryButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return HaffarPrimaryButton(
      label: 'متابعة',
      fullWidth: true,
      backgroundColor: _wrongTextPrimary,
      onPressed: onTap,
    );
  }
}
