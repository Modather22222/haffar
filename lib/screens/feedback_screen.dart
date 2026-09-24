import '../design_system/colors.dart';
import '../widgets/xp_icon.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/routes.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = GoRouterState.of(context).extra as FeedbackRouteArgs?;
    final isCorrect = args?.correct ?? true;
    final correctAnswer = args?.correctAnswer;
    final questionArgs = args?.questionArgs;

    void goHome() => context.go(Routes.home);
    void nextQuestion() {
      if (questionArgs != null) {
        context.push(
          '${Routes.question}?subject=${questionArgs.subjectId}&lesson=${questionArgs.lessonIndex}&q=${questionArgs.questionIndex + 1}',
        );
      } else {
        goHome();
      }
    }

    return Scaffold(
      body: Column(
        children: [
          // Top colored bar — matches Stitch exactly
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCorrect ? HaffarColors.primary : HaffarColors.error,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close (X) button
                const Icon(Icons.close, color: Colors.white, size: 22),
                // XP badge on the left (RTL)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCorrect) ...[
                      const XpIcon(size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        '+10',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          // Icon circle — white bg, colored border
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCorrect ? HaffarColors.primary : HaffarColors.error,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: isCorrect
                      ? HaffarColors.primary.withValues(alpha: 0.35)
                      : HaffarColors.error.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                isCorrect ? Icons.check_rounded : Icons.close_rounded,
                size: 64,
                color: isCorrect ? HaffarColors.primary : HaffarColors.error,
              ),
            ),
          ),
          const SizedBox(height: 28),
          // Title
          Text(
            isCorrect ? 'أحسنت! إجابة صحيحة' : 'إجابة خاطئة',
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          // Correct answer shown only on wrong
          if (!isCorrect && correctAnswer != null) ...[
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: HaffarColors.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الإجابة الصحيحة:',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 13,
                      color: HaffarColors.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    correctAnswer,
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: HaffarColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(flex: 2),
          // Continue button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCorrect
                      ? HaffarColors.primary
                      : HaffarColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: nextQuestion,
                child: Text(
                  questionArgs != null ? 'السؤال التالي' : 'استمرار',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
