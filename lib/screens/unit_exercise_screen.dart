import '../design_system/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/question.dart';
import '../models/unit.dart';
import '../services/quiz_builder.dart';
import '../widgets/mascot.dart';
import 'practice_quiz_screen.dart';
import '../utils/game_constants.dart';

/// Full-screen "تمرين الوحدة" — opens after all lessons of the unit are done.
class UnitExerciseScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final int unitIndex;

  const UnitExerciseScreen({super.key, required this.subjectId, required this.subjectName, required this.unitIndex});

  @override
  State<UnitExerciseScreen> createState() => _UnitExerciseScreenState();
}

class _UnitExerciseScreenState extends State<UnitExerciseScreen> {
  late final List<Question> _questions;

  @override
  void initState() {
    super.initState();
    final pool = context.read<AppProvider>().getUnitQuestions(widget.subjectId, widget.unitIndex);
    _questions = QuizBuilder.build('unit:${widget.subjectId}:${widget.unitIndex}', pool, count: 6);
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    final hearts = context.watch<AppProvider>().hearts;
    return Scaffold(
      backgroundColor: const Color(0xFFfbf9f9),
      appBar: AppBar(title: Text('تمرين الوحدة ${Unit.toArabicNumeral(widget.unitIndex + 1)}')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: HaffarColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Container(width: 110, height: 110, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: HaffarColors.primary, width: 3)),
                  clipBehavior: Clip.antiAlias,
                  child: const Mascot(pose: MascotPose.celebrate, size: 96)),
                const SizedBox(height: 16),
                Text('تمرين الوحدة ${Unit.toArabicNumeral(widget.unitIndex + 1)}', style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 24, fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: HaffarColors.outline.withValues(alpha: 0.2))),
              child: Text('أكملت جميع دروس هذه الوحدة! اختبر معلوماتك في تمرين شامل يغطي كل ما تعلمته.', style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, height: 1.7, color: Color(0xFF3f4a36))),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: hearts <= 0 ? HaffarColors.error.withValues(alpha: 0.08) : HaffarColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(Icons.favorite, size: 22, color: hearts <= 0 ? HaffarColors.error : HaffarColors.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'الخمسة قلوب دي ليك كل غلط هيخسرك قلب حافظ عليهم، عشان تنجح في الوحدة',
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, height: 1.6, color: hearts <= 0 ? HaffarColors.error : HaffarColors.textSecondary),
                )),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _statCard(Icons.quiz, '${questions.length}', 'سؤالاً'),
              const SizedBox(width: 12),
              _statCard(Icons.menu_book, '٣', 'دروس'),
              const SizedBox(width: 12),
              _statCard(Icons.bolt, '+${GameConstants.unitXpBase}', 'XP'),
            ]),
            const SizedBox(height: 28),
            SizedBox(height: 56, child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: hearts > 0 || context.read<AppProvider>().isSubscribed ? HaffarColors.primary : HaffarColors.grey3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: (questions.isEmpty || (hearts <= 0 && !context.read<AppProvider>().isSubscribed))
                  ? null
                  : () => Navigator.push(context, MaterialPageRoute(builder: (_) => PracticeQuizScreen(
                    subjectId: widget.subjectId,
                    title: '${widget.subjectName} - تمرين الوحدة ${Unit.toArabicNumeral(widget.unitIndex + 1)}',
                    questions: questions,
                    attemptKind: 'unit',
                    attemptRefIndex: widget.unitIndex,
                    completionPose: MascotPose.celebrate,
                    completionTitle: 'ممتاز!',
                    completionMessage: 'أكملت تمرين الوحدة بنجاح واجتزت تحديها بالكامل',
                  ))),
              icon: const Icon(Icons.play_arrow, size: 26),
              label: Text(hearts <= 0 && !context.read<AppProvider>().isSubscribed
                  ? 'انتهت القلوب'
                  : 'ابدأ تمرين الوحدة',
                  style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: HaffarColors.outline.withValues(alpha: 0.2))),
      child: Column(children: [
        Icon(icon, size: 22, color: HaffarColors.primary),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 17, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: HaffarColors.textSecondary)),
      ]),
    ));
  }
}
