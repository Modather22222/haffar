import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_system/colors.dart';
import '../design_system/tokens/text_styles.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../design_system/components/buttons/button_general_secondary.dart';
import '../utils/routes.dart';

class OnboardingOneScreen extends StatelessWidget {
  const OnboardingOneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  Image.asset(
                    'assets/character/character (7).png',
                    width: 220,
                    height: 220,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'حفار',
                    style: TextStyle(
                      fontFamily: HaffarTextStyles.fontFamily,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: HaffarColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'احفر طريقك نحو النجاح',
                    style: TextStyle(
                      fontFamily: HaffarTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: HaffarColors.grey2,
                    ),
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    child: HaffarPrimaryButton(
                      label: 'ابدأ الآن',
                      onPressed: () => context.push(Routes.onboardingTwo),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: HaffarSecondaryButton(
                      label: 'لدي حساب بالفعل',
                      onPressed: () => context.push(Routes.signIn),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
