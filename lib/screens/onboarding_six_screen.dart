import 'package:flutter/material.dart';

import '../design_system/colors.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../design_system/components/lesson/voice_bubble.dart';
import '../design_system/components/progress_bar_ring.dart';
import 'onboarding_seven_screen.dart';

class OnboardingSixScreen extends StatefulWidget {
  const OnboardingSixScreen({super.key});

  @override
  State<OnboardingSixScreen> createState() => _OnboardingSixScreenState();
}

class _OnboardingSixScreenState extends State<OnboardingSixScreen> {
  String? _selectedSource;

  static const _sources = [
    {'label': 'تيك توك',   'icon': 'assets/apps/tiktok.png'},
    {'label': 'فيسبوك',   'icon': 'assets/apps/facebook.png'},
    {'label': 'انستجرام', 'icon': 'assets/apps/instagram.png'},
    {'label': 'يوتيوب',  'icon': 'assets/apps/youtube.png'},
    {'label': 'متجر بلاي','icon': 'assets/apps/google-play.png'},
    {'label': 'واتساب',   'icon': 'assets/apps/whatsapp.png'},
    {'label': 'تلجرام',   'icon': 'assets/apps/telegram.png'},
    {'label': 'صديق/زميل','icon': 'assets/apps/people.png'},
    {'label': 'أخرى',     'icon': 'assets/apps/other.png'},
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
                      const Expanded(child: HaffarProgressBar(progress: 0.35)),
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
                          message: 'كيف سمعت عن حفار؟',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _sources.length,
                    itemBuilder: (context, i) {
                      final source = _sources[i];
                      final selected = _selectedSource == source['label'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SourceRow(
                          label: source['label'] as String,
                          iconPath: source['icon'] as String,
                          selected: selected,
                          onTap: () => setState(() => _selectedSource = source['label'] as String),
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
                      state: _selectedSource == null
                          ? HaffarPrimaryButtonState.disabled
                          : HaffarPrimaryButtonState.enabled,
                      label: 'استمر',
                      onPressed: _selectedSource == null
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const OnboardingSevenScreen(),
                                ),
                              );
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

class _SourceRow extends StatelessWidget {
  final String label;
  final String iconPath;
  final bool selected;
  final VoidCallback onTap;

  const _SourceRow({required this.label, required this.iconPath, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? HaffarColors.primary : HaffarColors.grey5, width: 2),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4, left: 12),
              child: Image.asset(iconPath, width: 28, height: 28),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'DIN2014Rounded',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: HaffarColors.grey1,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
