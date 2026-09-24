import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design_system/colors.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../design_system/components/lesson/voice_bubble.dart';
import '../providers/progress_provider.dart';
import '../utils/routes.dart';

/// Onboarding — display name ("حفار حيناديك بي منو").
class OnboardingThirteenScreen extends StatefulWidget {
  const OnboardingThirteenScreen({super.key});

  @override
  State<OnboardingThirteenScreen> createState() =>
      _OnboardingThirteenScreenState();
}

class _OnboardingThirteenScreenState extends State<OnboardingThirteenScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    context.read<ProgressProvider>().login(name);
    context.push(Routes.onboardingFourteen);
  }

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
                      const HaffarSpeechBubble(
                        message: 'حفار حيناديك بي منو',
                        tailPosition: BubbleTailPosition.center,
                      ),
                      const SizedBox(height: 12),
                      Image.asset(
                        'assets/character/character (7).png',
                        width: 220,
                        height: 220,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _controller,
                        textAlign: TextAlign.center,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _continue(),
                        decoration: const InputDecoration(
                          hintText: 'اكتب اسمك',
                          hintStyle: TextStyle(
                            fontFamily: 'DIN2014Rounded',
                            color: HaffarColors.grey3,
                          ),
                          filled: true,
                          fillColor: HaffarColors.grey6,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const Spacer(flex: 3),
                      SizedBox(
                        width: double.infinity,
                        child: HaffarPrimaryButton(
                          state: _controller.text.trim().isEmpty
                              ? HaffarPrimaryButtonState.disabled
                              : HaffarPrimaryButtonState.enabled,
                          label: 'استمر',
                          onPressed: _controller.text.trim().isEmpty
                              ? null
                              : _continue,
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
                    onTap: () => context.pop(),
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
