import 'package:flutter/material.dart';

import '../design_system/colors.dart';
import '../design_system/components/lesson/voice_bubble.dart';
import '../services/subscription_celebration.dart';
import 'mascot.dart';

/// Shows the approved-subscription celebration — the first modal in the
/// اشتراك في حفار برو style (gradient card, onboarding speech bubble) but
/// with the celebrating character, surfaced wherever the user happens to be
/// when the approval is detected. Call on the root navigator context.
Future<void> showSubscriptionApprovedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    // Only the انطلاق button closes it (barrier + back are both blocked).
    barrierDismissible: false,
    builder: (_) => const SubscriptionApprovedDialog(),
  );
}

/// Gradient celebration card: speech bubble announcing the activation,
/// the celebrating mascot below it, and a single انطلاق CTA.
class SubscriptionApprovedDialog extends StatelessWidget {
  const SubscriptionApprovedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [HaffarColors.primary, HaffarColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: HaffarColors.primaryDark.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const HaffarSpeechBubble(
                tailPosition: BubbleTailPosition.center,
                child: Text(
                  'تم تفعيل اشتراكك بنجاح، أنت الآن حفار برو',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: HaffarColors.grey1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Mascot(pose: MascotPose.celebrate, size: 170),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  await SubscriptionCelebration.instance.dismiss();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'انطلاق',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: HaffarColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
