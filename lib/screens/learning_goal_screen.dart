import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../design_system/colors.dart';
import '../providers/content_provider.dart';
import '../providers/progress_provider.dart';
import '../utils/routes.dart';

/// Step 4 of onboarding — let user pick their primary learning subject
class LearningGoalScreen extends StatelessWidget {
  const LearningGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'ما هي مادتك المفضلة؟',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'اختر المادة التي تريد البدء بها أولاً',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 15,
                  color: HaffarColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: context.watch<ContentProvider>().subjects.map((
                    subject,
                  ) {
                    return InkWell(
                      onTap: () {
                        context.read<ProgressProvider>().selectSubject(
                          subject.id,
                        );
                        context.go(Routes.home);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: HaffarColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (subject.imageAsset != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  subject.imageAsset!,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Text(
                                subject.icon,
                                style: const TextStyle(fontSize: 40),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              subject.name,
                              style: const TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(Routes.home),
                child: const Text(
                  'ابدأ لاحقاً',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 14,
                    color: HaffarColors.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
