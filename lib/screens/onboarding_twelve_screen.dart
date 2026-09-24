import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design_system/colors.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../design_system/components/lesson/voice_bubble.dart';
import '../providers/progress_provider.dart';
import '../utils/routes.dart';

/// Onboarding — pick student type (طالب / طالبة).
class OnboardingTwelveScreen extends StatelessWidget {
  const OnboardingTwelveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final selected = progress.gender;

    return Scaffold(
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
                        onTap: () => context.pop(),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: HaffarColors.grey2,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Spacer(flex: 3),
                        const HaffarSpeechBubble(
                          message: 'اختار',
                          tailPosition: BubbleTailPosition.center,
                        ),
                        const SizedBox(height: 12),
                        Image.asset(
                          'assets/character/character (10).png',
                          width: 220,
                          height: 220,
                        ),
                        const SizedBox(height: 24),
                        _GenderCard(
                          label: 'طالب',
                          icon: Icons.person_outline,
                          selected: selected == 'male',
                          onTap: () => context
                              .read<ProgressProvider>()
                              .setGender('male'),
                        ),
                        const SizedBox(height: 12),
                        _GenderCard(
                          label: 'طالبة',
                          icon: Icons.person_outline,
                          selected: selected == 'female',
                          onTap: () => context
                              .read<ProgressProvider>()
                              .setGender('female'),
                        ),
                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: HaffarPrimaryButton(
                      state: selected == null
                          ? HaffarPrimaryButtonState.disabled
                          : HaffarPrimaryButtonState.enabled,
                      label: 'استمر',
                      onPressed: selected == null
                          ? null
                          : () => context.push(Routes.onboardingThirteen),
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

class _GenderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? HaffarColors.primary : HaffarColors.grey5,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              icon,
              size: 24,
              color: selected ? HaffarColors.primary : HaffarColors.grey2,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'DIN2014Rounded',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: selected ? HaffarColors.primary : HaffarColors.grey1,
                ),
              ),
            ),
            if (selected)
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Icon(
                  Icons.check_circle,
                  color: HaffarColors.primary,
                  size: 22,
                ),
              )
            else
              const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
