import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/colors.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../design_system/components/lesson/voice_bubble.dart';
import '../design_system/components/progress_bar_ring.dart';
import '../utils/routes.dart';

class OnboardingNineScreen extends StatelessWidget {
  const OnboardingNineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: HaffarColors.grey2,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(child: HaffarProgressBar(progress: 0.7)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/character/character (12).png',
                          width: 100,
                          height: 140,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: HaffarSpeechBubble(
                            tailPosition: BubbleTailPosition.bottomRight,
                            message:
                                'حفار يساعدك تبني طريق واضح نحو هدفك، وتعرف كل يوم وين وصلت وشنو باقي ليك.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _FeatureItem(
                    icon: 'assets/icons/plan.png',
                    iconBg: const Color(0xFFE8F8EE),
                    title: 'خطة مذاكرة تناسب هدفك',
                  ),
                  const SizedBox(height: 16),
                  _FeatureItem(
                    icon: 'assets/icons/study.png',
                    iconBg: const Color(0xFFE3F2FD),
                    title: 'دراسة الدروس الأساسية',
                  ),
                  const SizedBox(height: 16),
                  _FeatureItem(
                    icon: 'assets/icons/progress.png',
                    iconBg: const Color(0xFFFFF8E1),
                    title: 'متابعة تقدمك ومستواك',
                  ),
                  const SizedBox(height: 16),
                  _FeatureItem(
                    icon: 'assets/icons/challenges.png',
                    iconBg: const Color(0xFFFFEBEE),
                    title: 'تحديات يومية تساعدك تستمر',
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: HaffarPrimaryButton(
                        state: HaffarPrimaryButtonState.enabled,
                        label: 'استمر',
                        onPressed: () => context.push(Routes.onboardingTen),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String title;

  const _FeatureItem({
    required this.icon,
    required this.iconBg,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(icon, width: 28, height: 28),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'DIN2014Rounded',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: HaffarColors.grey1,
            ),
          ),
        ],
      ),
    );
  }
}
