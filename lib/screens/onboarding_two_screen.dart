import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_system/colors.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../design_system/components/lesson/voice_bubble.dart';
import '../utils/routes.dart';

class OnboardingTwoScreen extends StatelessWidget {
  const OnboardingTwoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      HaffarSpeechBubble(
                        message: 'مرحبا! أنا حفار',
                        tailPosition: BubbleTailPosition.center,
                      ),
                      const SizedBox(height: 12),
                      Image.asset(
                        'assets/character/character (10).png',
                        width: 220,
                        height: 220,
                      ),
                      const Spacer(flex: 3),
                      SizedBox(
                        width: double.infinity,
                        child: HaffarPrimaryButton(
                          label: 'استمر',
                          onPressed: () => context.push(Routes.onboardingThree),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 8,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: HaffarColors.grey5),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: HaffarColors.grey2,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
