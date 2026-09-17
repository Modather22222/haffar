import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../design_system/colors.dart';
import '../providers/app_provider.dart';
import '../models/unit.dart';
import '../widgets/lesson_node.dart';
import 'lesson_detail_screen.dart';

/// Lesson path screen — shows the S-curve of lessons for the selected subject.
/// Each node represents one lesson (index 0–5), with progress tracked in AppProvider.
class LessonPathScreen extends StatelessWidget {
  const LessonPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjectId = GoRouterState.of(context).uri.queryParameters['subject'] ?? 'science';
    final unitIndex = int.tryParse(GoRouterState.of(context).uri.queryParameters['unit'] ?? '-1') ?? -1;
    final provider = context.watch<AppProvider>();
    final subject = provider.subjectById(subjectId);
    final totalLessons = provider.lessonCountOf(subjectId);
    final completedLessons = provider.subjectCompletedCount(subjectId);

    // Filter lessons by unit if unit is specified
    final startLesson = unitIndex >= 0 ? unitIndex * 3 : 0;
    final endLesson = unitIndex >= 0 ? (unitIndex + 1) * 3 : totalLessons;
    final relevantLessons = List.generate(endLesson - startLesson, (i) => startLesson + i);

    return Scaffold(
      appBar: AppBar(
        title: Text(unitIndex >= 0 ? 'الوحدة ${Unit.toArabicNumeral(unitIndex + 1)}' : 'مسار ${subject?.name ?? subjectId}'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Progress bar
            LinearProgressIndicator(
              value: relevantLessons.isEmpty ? 0 : relevantLessons.where((l) => l < completedLessons).length / relevantLessons.length,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(HaffarColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              unitIndex >= 0
                  ? 'الدرس ${relevantLessons.where((l) => l < completedLessons).length + 1} من ${relevantLessons.length}'
                  : 'الدرس ${completedLessons + 1} من $totalLessons',
              style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: HaffarColors.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Lesson nodes in S-curve layout
            Expanded(
              child: ListView.builder(
                itemCount: relevantLessons.length,
                itemBuilder: (context, index) {
                  final lessonIndex = relevantLessons[index];
                  final isCompleted = provider.isSubjectLessonCompleted(subjectId, lessonIndex);
                  final isCurrent = lessonIndex == completedLessons;
                  final isLocked = !provider.isSubjectLessonUnlocked(subjectId, lessonIndex);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Center(
                      child: LessonNode(
                        label: 'درس ${Unit.toArabicNumeral(lessonIndex + 1)}',
                        isCompleted: isCompleted,
                        isCurrent: isCurrent,
                        isLocked: isLocked,
                        onTap: isLocked
                            ? null
                            : () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonDetailScreen(subjectId: subjectId, lessonIndex: lessonIndex))),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
