import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../colors.dart';

/// Learn-mode top navigation — close, progress bar, hearts.
///
/// Ported from the Duolingo design system (`DuoNavigationTopLearn`), adapted
/// to Haffar assets (`assets/icons/`) and fonts (BeVietnamPro).
/// A 24px tall bar with a close icon, lesson progress bar, and hearts
/// counter. In this RTL app the row mirrors automatically: close lands on
/// the right, hearts on the left.
///
/// Usage:
/// ```dart
/// LearnTopBar(
///   progress: 0.15,
///   hearts: 5,
///   onClose: () {},
/// )
/// ```
class LearnTopBar extends StatelessWidget {
  final double progress;
  final int hearts;
  final double? width;
  final VoidCallback? onClose;

  const LearnTopBar({
    super.key,
    required this.progress,
    required this.hearts,
    this.width,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 24,
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: SvgPicture.asset(
              'assets/icons/close_small.svg',
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(child: _ProgressBar(progress: progress)),
          const SizedBox(width: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/heart_small.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 4),
              Text(
                hearts.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFED0C0C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(360),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                // Haffar brand: primary orange instead of the Duo-spec green.
                color: HaffarColors.primary,
                borderRadius: BorderRadius.circular(360),
              ),
            ),
          ),
          if (progress > 0)
            // Mirrored from the LTR original (`left: 14`): in RTL the fill
            // grows from the right, so the gloss sits near the leading edge.
            Positioned(
              right: 14,
              top: 3,
              child: Container(
                width: 16,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
