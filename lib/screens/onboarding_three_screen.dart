import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../design_system/components/lesson/voice_bubble.dart';
import 'onboarding_four_screen.dart';

class OnboardingThreeScreen extends StatelessWidget {
  const OnboardingThreeScreen({super.key});

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
                        tailPosition: BubbleTailPosition.center,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'فقط ',
                                style: TextStyle(
                                  fontFamily: 'DIN2014Rounded',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  height: 25 / 18,
                                  color: HaffarColors.grey1,
                                ),
                              ),
                              TextSpan(
                                text: '5 أسئلة سريعة',
                                style: TextStyle(
                                  fontFamily: 'DIN2014Rounded',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  height: 25 / 18,
                                  color: HaffarColors.grey1,
                                ),
                              ),
                              TextSpan(
                                text: ' قبل أن نبدأ درسك الأول!',
                                style: TextStyle(
                                  fontFamily: 'DIN2014Rounded',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  height: 25 / 18,
                                  color: HaffarColors.grey1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Image.asset(
                        'assets/character/character (2).png',
                        width: 220,
                        height: 220,
                      ),
                      const Spacer(flex: 3),
                      SizedBox(
                        width: double.infinity,
                        child: HaffarPrimaryButton(
                          label: 'استمر',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const OnboardingFourScreen(),
                              ),
                            );
                          },
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
