import 'package:flutter/material.dart';

import '../tokens/tokens.dart';
import '../colors.dart';

/// Haffar progress bar — horizontal bar with glossy fill.
/// [progress] is 0.0..1.0.
class HaffarProgressBar extends StatelessWidget {
  final double progress;
  final bool withText;
  final Color color;

  const HaffarProgressBar({
    super.key,
    required this.progress,
    this.withText = false,
    this.color = HaffarColors.primary,
  }) : assert(progress >= 0 && progress <= 1);

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: double.infinity,
          decoration: BoxDecoration(
            color: HaffarColors.grey6,
            borderRadius: BorderRadius.circular(HaffarMetrics.radiusPill),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerRight,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(HaffarMetrics.radiusPill),
              ),
            ),
          ),
        ),
        if (withText) ...[
          const SizedBox(height: HaffarMetrics.space4),
          Text(
            '$pct%',
            style: HaffarTextStyles.smallBold.copyWith(color: color),
          ),
        ],
      ],
    );
  }
}
