import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/colors.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../design_system/components/lesson/voice_bubble.dart';
import '../design_system/components/progress_bar_ring.dart';
import '../utils/routes.dart';

class OnboardingTenScreen extends StatefulWidget {
  const OnboardingTenScreen({super.key});

  @override
  State<OnboardingTenScreen> createState() => _OnboardingTenScreenState();
}

class _OnboardingTenScreenState extends State<OnboardingTenScreen> {
  int? _selectedIndex;

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
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: HaffarColors.grey2,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(child: HaffarProgressBar(progress: 0.8)),
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
                          message: 'كيف تريد أن تبدأ؟',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedIndex = 0),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedIndex == 0
                                      ? HaffarColors.primary
                                      : HaffarColors.grey5,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'سوبر حفار',
                                    style: const TextStyle(
                                      fontFamily: 'DIN2014Rounded',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: HaffarColors.grey1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ميزات اضافية، بدون إعلانات',
                                    style: const TextStyle(
                                      fontFamily: 'DIN2014Rounded',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: HaffarColors.grey3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: -12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: const BoxDecoration(
                                  color: HaffarColors.primary,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'موصى به',
                                  style: TextStyle(
                                    fontFamily: 'DIN2014Rounded',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => setState(() => _selectedIndex = 1),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedIndex == 1
                                  ? HaffarColors.primary
                                  : HaffarColors.grey5,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تعلم مجاناُ',
                                style: const TextStyle(
                                  fontFamily: 'DIN2014Rounded',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: HaffarColors.grey1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'الميزات الأساسية، بدون إعلانات',
                                style: const TextStyle(
                                  fontFamily: 'DIN2014Rounded',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: HaffarColors.grey3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: HaffarPrimaryButton(
                      state: _selectedIndex == null
                          ? HaffarPrimaryButtonState.disabled
                          : HaffarPrimaryButtonState.enabled,
                      label: 'استمر',
                      onPressed: _selectedIndex == null
                          ? null
                          : () => context.push(Routes.onboardingTwelve),
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
