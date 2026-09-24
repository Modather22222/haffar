import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design_system/colors.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../design_system/components/lesson/voice_bubble.dart';
import '../design_system/components/progress_bar_ring.dart';
import '../utils/routes.dart';

class OnboardingFiveScreen extends StatefulWidget {
  const OnboardingFiveScreen({super.key});

  @override
  State<OnboardingFiveScreen> createState() => _OnboardingFiveScreenState();
}

class _OnboardingFiveScreenState extends State<OnboardingFiveScreen> {
  String? _selectedState;

  static const _locations = [
    'الخرطوم',
    'كسلا',
    'الجزيرة',
    'نهر النيل',
    'البحر الأحمر',
    'القضارف',
    'الشمالية',
    'سنار',
    'النيل الأبيض',
    'النيل الأزرق',
    'جنوب كردفان',
    'شمال كردفان',
    'غرب كردفان',
    'شمال دارفور',
    'وسط دارفور',
    'شرق دارفور',
    'جنوب دارفور',
    'غرب دارفور',
    'خارج السودان',
  ];

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
                      const Expanded(child: HaffarProgressBar(progress: 0.3)),
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
                          message: 'ممتحن من وين؟',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.4,
                        ),
                    itemCount: _locations.length,
                    itemBuilder: (context, index) {
                      final location = _locations[index];
                      final isSelected = _selectedState == location;
                      return InkWell(
                        onTap: () => setState(() => _selectedState = location),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? HaffarColors.primary.withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? HaffarColors.primary
                                  : HaffarColors.grey5,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 8,
                                  left: 12,
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  size: 22,
                                  color: isSelected
                                      ? HaffarColors.primary
                                      : HaffarColors.grey3,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontFamily: 'DIN2014Rounded',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? HaffarColors.grey1
                                        : HaffarColors.grey2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: HaffarPrimaryButton(
                      state: _selectedState != null
                          ? HaffarPrimaryButtonState.enabled
                          : HaffarPrimaryButtonState.disabled,
                      label: 'استمر',
                      onPressed: _selectedState != null
                          ? () => context.push(Routes.onboardingSix)
                          : null,
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
