import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design_system/colors.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../design_system/components/lesson/voice_bubble.dart';
import '../providers/app_provider.dart';
import '../utils/routes.dart';

class OnboardingElevenScreen extends StatelessWidget {
  const OnboardingElevenScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: HaffarSpeechBubble(tailPosition: BubbleTailPosition.center, message: 'لقد اكملت جميع الخطوات، لنبدأ الان'),
                ),
                const SizedBox(height: 16),
                Image.asset('assets/character/character (12).png', width: 160, height: 200),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: HaffarPrimaryButton(
                      state: HaffarPrimaryButtonState.enabled,
                      label: 'ابدأ',
                      onPressed: () {
                        context.read<AppProvider>().completeOnboarding();
                        context.go(Routes.home);
                      },
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
