import '../design_system/colors.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Circular node in a lesson path — completed, current, or locked
class LessonNode extends StatelessWidget {
  final String label;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;
  final VoidCallback? onTap;

  const LessonNode({
    super.key,
    required this.label,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? HaffarColors.primary
        : isCurrent
        ? HaffarColors.primary
        : HaffarColors.surfaceHigh;
    final icon = isCompleted
        ? Icons.check
        : isLocked
        ? Icons.lock
        : Icons.play_arrow;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isCurrent ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isCurrent)
                  Container(
                    width: AppConstants.nodeSize + 24,
                    height: AppConstants.nodeSize + 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFff9600),
                        width: 3,
                      ),
                    ),
                  ),
                Container(
                  width: AppConstants.nodeSize,
                  height: AppConstants.nodeSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLocked ? HaffarColors.surfaceHigh : color,
                    border: isCurrent
                        ? Border.all(color: const Color(0xFFff9600), width: 4.0)
                        : null,
                    boxShadow: isLocked
                        ? []
                        : [
                            BoxShadow(
                              color:
                                  (isCompleted
                                          ? HaffarColors.primary
                                          : HaffarColors.primary)
                                      .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isLocked ? HaffarColors.textSecondary : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isLocked
                    ? HaffarColors.textSecondary
                    : HaffarColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
