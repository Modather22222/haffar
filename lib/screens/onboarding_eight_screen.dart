import 'package:flutter/material.dart';

import '../design_system/colors.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../design_system/components/lesson/voice_bubble.dart';
import '../design_system/components/progress_bar_ring.dart';
import 'onboarding_nine_screen.dart';

class OnboardingEightScreen extends StatefulWidget {
  const OnboardingEightScreen({super.key});

  @override
  State<OnboardingEightScreen> createState() => _OnboardingEightScreenState();
}

class _OnboardingEightScreenState extends State<OnboardingEightScreen> {
  final _controller = TextEditingController();
  String _displayText = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                      const Expanded(child: HaffarProgressBar(progress: 0.5)),
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
                        child: HaffarSpeechBubble(tailPosition: BubbleTailPosition.bottomRight, 
                          message: 'اخر سؤال اسم مدرستك شنو؟',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.center,
                    onChanged: (v) => setState(() => _displayText = v),
                    onSubmitted: (v) => setState(() => _displayText = v),
                    style: const TextStyle(
                      fontFamily: 'DIN2014Rounded',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: HaffarColors.grey1,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: HaffarColors.grey6,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: HaffarColors.grey5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: HaffarColors.grey5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: HaffarColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: HaffarPrimaryButton(
                      state: _displayText.isNotEmpty
                          ? HaffarPrimaryButtonState.enabled
                          : HaffarPrimaryButtonState.disabled,
                      label: 'استمر',
                      onPressed: _displayText.isNotEmpty
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const OnboardingNineScreen(),
                                ),
                              );
                            }
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
