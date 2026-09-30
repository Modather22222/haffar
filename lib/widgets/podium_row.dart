import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../design_system/colors.dart';

/// Podium row for leaderboard ranks 1–3 with strong in-background effects
/// (mirrors the "elite leaderboard" VFX: liquid wave, shimmer sweep, rising
/// embers, pulsing plasma — all painted behind the row content, no glowing
/// borders):
///  - rank 1: gold liquid wave + shimmer sweep + rising ember particles
///  - rank 2: silver liquid wave drifting the other way
///  - rank 3: pulsing magma radial
class PodiumRow extends StatefulWidget {
  const PodiumRow({
    super.key,
    required this.rank,
    required this.child,
    this.onTap,
    this.borderColor,
  });

  /// 1, 2 or 3.
  final int rank;

  /// The row content (rank medal, avatar, name, score).
  final Widget child;

  final VoidCallback? onTap;

  /// Optional border override (e.g. current-user primary border).
  final Color? borderColor;

  @override
  State<PodiumRow> createState() => _PodiumRowState();
}

class _PodiumRowState extends State<PodiumRow>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  static const _durations = {
    1: Duration(milliseconds: 4200), // wave + embers loop
    2: Duration(milliseconds: 5600), // wave drift loop
    3: Duration(milliseconds: 2400), // magma pulse loop
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null && !MediaQuery.disableAnimationsOf(context)) {
      _controller = AnimationController(
        vsync: this,
        duration: _durations[widget.rank] ?? const Duration(seconds: 3),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PodiumPalette.forRank(widget.rank);
    final radius = BorderRadius.circular(14);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: radius,
        child: Stack(
          // Effects and medal borders are painted in the background layer;
          // let nothing bleed outside the card.
          clipBehavior: Clip.none,
          children: [
            // Base card: metallic medal tint + solid border.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: palette.bgColors,
                  ),
                  borderRadius: radius,
                  border: Border.all(
                    color: widget.borderColor ?? palette.borderColor,
                    width: 1.2,
                  ),
                ),
              ),
            ),
            // Background effects layer (wave / shimmer / embers / plasma).
            Positioned.fill(
              child: ClipRRect(
                borderRadius: radius,
                child: IgnorePointer(child: _buildEffects()),
              ),
            ),
            // Row content on top.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffects() {
    final controller = _controller;

    Widget paint(int rank) {
      if (controller == null) {
        return CustomPaint(painter: _BgEffectPainter(rank: rank, t: 0));
      }
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) => CustomPaint(
          painter: _BgEffectPainter(rank: rank, t: controller.value),
        ),
      );
    }

    switch (widget.rank) {
      case 1:
        return Stack(
          fit: StackFit.expand,
          children: [paint(1), _shimmerSweep()],
        );
      case 2:
        return paint(2);
      case 3:
        return paint(3);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Rank 1: skewed golden sheen sweeping across the background.
  Widget _shimmerSweep() {
    final band = Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: 0.55,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                const Color(0xFFFFDF7A).withValues(alpha: 0.75),
                const Color(0xFFFFF2C0).withValues(alpha: 0.55),
                Colors.transparent,
              ],
              stops: const [0, 0.45, 0.6, 1],
            ),
          ),
        ),
      ),
    );
    final skewed = Transform(transform: Matrix4.skewX(-0.45), child: band);
    if (_controller == null) return skewed;
    return skewed
        .animate(onPlay: (c) => c.loop())
        .slideX(
          begin: -1.2,
          end: 1.2,
          duration: const Duration(milliseconds: 2800),
          curve: Curves.easeInOut,
        );
  }
}

class _PodiumPalette {
  const _PodiumPalette({required this.bgColors, required this.borderColor});

  final List<Color> bgColors;
  final Color borderColor;

  static _PodiumPalette forRank(int rank) {
    switch (rank) {
      case 1:
        return const _PodiumPalette(
          bgColors: [Color(0xFFFFF6D6), Color(0xFFFFE7A3)],
          borderColor: Color(0xFFE6B800),
        );
      case 2:
        return const _PodiumPalette(
          bgColors: [Color(0xFFEFF3F8), Color(0xFFDCE4EE)],
          borderColor: Color(0xFF9AA4B3),
        );
      case 3:
        return const _PodiumPalette(
          bgColors: [Color(0xFFFCEEDD), Color(0xFFF4D6BB)],
          borderColor: HaffarColors.leagueBronze,
        );
      default:
        return const _PodiumPalette(
          bgColors: [Colors.white, Colors.white],
          borderColor: HaffarColors.outline,
        );
    }
  }
}

class _Ember {
  const _Ember(this.x, this.phase, this.size, this.color);

  final double x;
  final double phase;
  final double size;
  final Color color;
}

/// Paints the per-rank background motion behind the row content.
class _BgEffectPainter extends CustomPainter {
  const _BgEffectPainter({required this.rank, required this.t});

  /// 1, 2 or 3.
  final int rank;

  /// Loop progress 0..1.
  final double t;

  static const _embers = <_Ember>[
    _Ember(0.10, 0.00, 3.6, Color(0xFFFFC400)),
    _Ember(0.22, 0.42, 2.8, Color(0xFFFFE680)),
    _Ember(0.34, 0.75, 4.4, Color(0xFFFFA000)),
    _Ember(0.47, 0.18, 3.2, Color(0xFFFFFFFF)),
    _Ember(0.58, 0.60, 4.0, Color(0xFFFFC400)),
    _Ember(0.70, 0.30, 2.6, Color(0xFFFF9100)),
    _Ember(0.81, 0.85, 3.8, Color(0xFFFFE082)),
    _Ember(0.92, 0.50, 3.0, Color(0xFFFFB300)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    switch (rank) {
      case 1:
        _paintWave(
          canvas,
          size,
          phase: t * math.pi * 2,
          colors: const [Color(0x8FFFBB00), Color(0xA6FF8A00)],
        );
        _paintWave(
          canvas,
          size,
          phase: t * math.pi * 2 + math.pi / 2,
          colors: const [Color(0x59FFD54F), Color(0x80FFA726)],
          amplitude: 14,
          crestPct: 0.42,
          frequency: 1.6,
        );
        _paintEmbers(canvas, size);
      case 2:
        _paintWave(
          canvas,
          size,
          phase: -t * math.pi * 2,
          colors: const [Color(0xA69CB4D6), Color(0x8C6E86A8)],
          amplitude: 12,
          crestPct: 0.5,
          frequency: 1.3,
        );
        _paintWave(
          canvas,
          size,
          phase: -t * math.pi * 2 + math.pi / 2,
          colors: const [Color(0x66C7D4E8), Color(0x598FA8C8)],
          amplitude: 16,
          crestPct: 0.38,
          frequency: 2.0,
        );
      case 3:
        _paintPlasma(canvas, size);
    }
  }

  void _paintWave(
    Canvas canvas,
    Size size, {
    required double phase,
    required List<Color> colors,
    double amplitude = 10,
    double crestPct = 0.55,
    double frequency = 1.0,
  }) {
    final baseY = size.height * (1 - crestPct);
    final path = Path()..moveTo(0, size.height);
    const step = 4.0;
    for (double x = 0; x <= size.width + step; x += step) {
      final unit = (x / size.width).clamp(0.0, 1.0);
      final y =
          baseY +
          math.sin(unit * math.pi * 2 * frequency + phase) * amplitude +
          math.sin(unit * math.pi * 2 * frequency * 2 + phase) *
              (amplitude * 0.35);
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  void _paintEmbers(Canvas canvas, Size size) {
    for (final e in _embers) {
      final life = (t + e.phase) % 1.0;
      final y = size.height * (1.1 - life * 1.2);
      final x = size.width * e.x + math.sin((life + e.phase) * math.pi * 2) * 6;
      final fade = math.sin(life * math.pi);
      if (fade <= 0.02) continue;

      final glow = Paint()
        ..color = e.color.withValues(alpha: fade * 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), e.size, glow);

      final core = Paint()
        ..color = e.color.withValues(alpha: math.min(1, fade * 1.2));
      canvas.drawCircle(Offset(x, y), e.size * 0.5, core);
    }
  }

  void _paintPlasma(Canvas canvas, Size size) {
    // Pulse 0.35 → 1.0 with a seamless cosine loop.
    final pulse = 0.35 + 0.65 * (0.5 - 0.5 * math.cos(t * math.pi * 2));
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.15, 0.35),
        radius: 1.1,
        colors: [
          const Color(0xFFFF4D00).withValues(alpha: 0.5 * pulse),
          const Color(0xFFFF9E4D).withValues(alpha: 0.32 * pulse),
          const Color(0xFFCD7F32).withValues(alpha: 0.18 * pulse),
          Colors.transparent,
        ],
        stops: const [0, 0.35, 0.7, 1],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _BgEffectPainter old) =>
      old.t != t || old.rank != rank;
}
