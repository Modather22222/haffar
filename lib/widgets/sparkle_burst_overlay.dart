import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design_system/colors.dart';

/// Full-screen celebratory burst: sparkles pop out from the LEFT edge of the
/// screen, scatter toward the content, shrink and fade away. Wrap in
/// Positioned.fill + IgnorePointer at the call site.
class SparkleBurstOverlay extends StatefulWidget {
  final double originYFactor;

  const SparkleBurstOverlay({super.key, this.originYFactor = 0.38});

  @override
  State<SparkleBurstOverlay> createState() => _SparkleBurstOverlayState();
}

class _SparkleBurstOverlayState extends State<SparkleBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  Size _size = Size.zero;

  static const _colors = [
    HaffarColors.primary,
    Color(0xFFff9600),
    Color(0xFFffc800),
    HaffarColors.primaryLight,
    Color(0xFFa855f7),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..forward();
    final rnd = math.Random(11);
    _particles = List.generate(
      30,
      (i) => _Particle(
        angle: (rnd.nextDouble() - 0.5) * 2.2, // spread around +x direction
        distance: 140 + rnd.nextDouble() * 280,
        size: 7 + rnd.nextDouble() * 13,
        color: _colors[i % _colors.length],
        spin: (rnd.nextDouble() - 0.5) * 4,
        isDot: i % 4 == 3,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        _size = constraints.biggest;
        final origin = Offset(0, _size.height * widget.originYFactor);
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, _) {
            return Stack(
              children: [
                _buildShockwave(origin),
                ..._particles.map((p) => _buildParticle(p, origin)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildShockwave(Offset origin) {
    final t = _controller.value;
    final r = 130 * Curves.easeOutCubic.transform(t);
    return Positioned(
      left: origin.dx - r,
      top: origin.dy - r,
      child: Opacity(
        opacity: ((1 - t) * 0.5).clamp(0.0, 1.0),
        child: Container(
          width: r * 2,
          height: r * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFffc800), width: 3),
          ),
        ),
      ),
    );
  }

  Widget _buildParticle(_Particle p, Offset origin) {
    final t = _controller.value;
    final travel = Curves.easeOutCubic.transform(t);
    // fast pop-in with overshoot, then shrink away near the end
    final popIn = Curves.easeOutBack.transform((t / 0.22).clamp(0.0, 1.0));
    final shrink = t < 0.55 ? 1.0 : 1.0 - (((t - 0.55) / 0.45) * 0.7);
    final opacity = t < 0.45 ? 1.0 : (1 - ((t - 0.45) / 0.5)).clamp(0.0, 1.0);
    final pos =
        origin +
        Offset(math.cos(p.angle), math.sin(p.angle)) * p.distance * travel;

    Widget shape = p.isDot
        ? Container(
            width: p.size * 0.5,
            height: p.size * 0.5,
            decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
          )
        : Icon(Icons.auto_awesome, size: p.size, color: p.color);

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: p.spin * travel,
          child: Transform.scale(
            scale: (popIn * shrink).clamp(0.0, 1.5),
            child: shape,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final double spin;
  final bool isDot;

  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.spin,
    required this.isDot,
  });
}
