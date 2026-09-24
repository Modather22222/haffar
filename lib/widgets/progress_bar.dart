import '../design_system/colors.dart';
import 'package:flutter/material.dart';

/// Glossy progress bar — fills right-to-left for RTL
class ProgressBar extends StatelessWidget {
  final double progress;
  final Color? color;
  final double height;

  const ProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = color ?? HaffarColors.primary;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return Stack(
          children: [
            Container(
              width: constraints.maxWidth,
              height: height,
              decoration: BoxDecoration(
                color: HaffarColors.surfaceHigh,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerRight,
              widthFactor: progress,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: fgColor,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
