import '../design_system/colors.dart';
import 'package:flutter/material.dart';
import 'mascot.dart';
import 'xp_icon.dart';

/// Mascot celebration dialog — used for lesson/unit completion moments.
class CelebrationDialog extends StatelessWidget {
  final MascotPose pose;
  final String title;
  final String message;
  final String buttonLabel;
  final int xpGained;
  final Duration duration;

  /// When true, closing the dialog also pops the route beneath (the quiz).
  final bool popUnderneath;

  const CelebrationDialog({
    super.key,
    required this.pose,
    required this.title,
    required this.message,
    this.buttonLabel = 'استمرار',
    this.popUnderneath = false,
    this.xpGained = 0,
    this.duration = Duration.zero,
  });

  static Future<void> show(
    BuildContext context, {
    required MascotPose pose,
    required String title,
    required String message,
    String buttonLabel = 'استمرار',
    bool popUnderneath = false,
    int xpGained = 0,
    Duration duration = Duration.zero,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CelebrationDialog(
        pose: pose,
        title: title,
        message: message,
        buttonLabel: buttonLabel,
        popUnderneath: popUnderneath,
        xpGained: xpGained,
        duration: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Mascot(pose: pose, size: 100),
            const SizedBox(height: 16),
            if (xpGained >= 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: HaffarColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const XpIcon(size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$xpGained',
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: HaffarColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (duration > Duration.zero) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: HaffarColors.grey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer,
                            size: 16,
                            color: HaffarColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_toArabicNum(duration.inMinutes)}:${_toArabicNum(duration.inSeconds % 60).padLeft(2, '٠')}',
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 14,
                              color: HaffarColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (popUnderneath) Navigator.of(context).pop();
                },
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _toArabicNum(int n) {
    final arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => arabicDigits[int.parse(c)]).join();
  }
}
