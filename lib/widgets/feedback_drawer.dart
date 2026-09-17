import '../design_system/colors.dart';
import 'package:flutter/material.dart';

/// Full-width bottom drawer for feedback (correct / incorrect)
class FeedbackDrawer extends StatelessWidget {
  final bool isCorrect;
  final String message;
  final String? correctAnswer;
  final VoidCallback onContinue;
  final String continueLabel;

  const FeedbackDrawer({super.key, required this.isCorrect, required this.message, this.correctAnswer, required this.onContinue, this.continueLabel = 'استمر'});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16),
      decoration: BoxDecoration(
        color: isCorrect ? HaffarColors.primary : HaffarColors.error,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: (isCorrect ? HaffarColors.primary : HaffarColors.error).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Text(isCorrect ? '✓' : '✗', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white), textAlign: TextAlign.center),
        if (correctAnswer != null && !isCorrect) ...[
          const SizedBox(height: 8),
          Text('الإجابة الصحيحة: $correctAnswer', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, color: Colors.white.withValues(alpha: 0.9)), textAlign: TextAlign.center),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: onContinue,
            child: Text(continueLabel, style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}
