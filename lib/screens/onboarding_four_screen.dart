import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../design_system/colors.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../design_system/components/lesson/voice_bubble.dart';
import '../design_system/components/progress_bar_ring.dart';
import '../models/subject.dart';
import '../providers/content_provider.dart';
import '../providers/progress_provider.dart';
import '../utils/routes.dart';

class OnboardingFourScreen extends StatefulWidget {
  const OnboardingFourScreen({super.key});

  @override
  State<OnboardingFourScreen> createState() => _OnboardingFourScreenState();
}

class _OnboardingFourScreenState extends State<OnboardingFourScreen> {
  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<ContentProvider>().subjects;
    final provider = context.watch<ProgressProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                Column(
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
                          const Expanded(
                            child: HaffarProgressBar(progress: 0.2),
                          ),
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
                              message: 'اكثر مادتين محتاج تقويهم شنو ؟',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'اختر مادتين',
                              style: TextStyle(
                                fontFamily: 'DIN2014Rounded',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: HaffarColors.grey1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: subjects.isEmpty
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFD7202),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: subjects.length,
                              itemBuilder: (context, i) {
                                final s = subjects[i];
                                final selected = provider.selectedSubjectIds
                                    .contains(s.id);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _SubjectRow(
                                    subject: s,
                                    selected: selected,
                                    onTap: () =>
                                        provider.toggleSelectedSubject(s.id),
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
                          state: provider.selectedSubjectIds.length >= 2
                              ? HaffarPrimaryButtonState.enabled
                              : HaffarPrimaryButtonState.disabled,
                          label: 'استمر',
                          onPressed: provider.selectedSubjectIds.length >= 2
                              ? () => context.push(Routes.onboardingFive)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final Subject subject;
  final bool selected;
  final VoidCallback onTap;

  const _SubjectRow({
    required this.subject,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final asset = subject.imageAsset;
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
            if (asset != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                child: Image.asset(
                  asset,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 56,
                height: 56,
                color: HaffarColors.primary,
                child: Center(
                  child: Text(
                    subject.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  subject.name,
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
