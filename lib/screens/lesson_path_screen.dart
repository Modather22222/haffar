import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../providers/progress_provider.dart';
import '../design_system/colors.dart';
import '../models/unit.dart';
import '../utils/routes.dart';
import '../widgets/lesson_node.dart';

/// Lesson path screen — shows the S-curve of lessons for the selected subject.
/// Each node represents one lesson; lessons are dynamic (any count per unit)
/// and progress is tracked in ProgressProvider.
class LessonPathScreen extends StatelessWidget {
  const LessonPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjectId =
        GoRouterState.of(context).uri.queryParameters['subject'] ?? 'science';
    final unitIndex =
        int.tryParse(
          GoRouterState.of(context).uri.queryParameters['unit'] ?? '-1',
        ) ??
        -1;
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final subject = content.subjectById(subjectId);
    final totalLessons = content.lessonCountOf(subjectId);

    // Actual lessons: one unit, or the whole subject in display order.
    final relevantLessons = unitIndex >= 0
        ? content.lessonsOfUnit(subjectId, unitIndex)
        : content.lessonsOf(subjectId);
    final relevantIndexes = relevantLessons.map((l) => l.index).toList();
    final completedCount = relevantIndexes
        .where((l) => progress.isSubjectLessonCompleted(subjectId, l))
        .length;
    int? currentIndex;
    for (final lesson in relevantLessons) {
      if (!progress.isSubjectLessonCompleted(subjectId, lesson.index)) {
        currentIndex = lesson.index;
        break;
      }
    }

    // Unit display ordinal survives unit_index gaps (any unit is deletable).
    final units = subject?.units ?? const [];
    final unitPos = units.indexWhere((u) => u.index == unitIndex);
    final unitNumber = unitPos >= 0 ? unitPos + 1 : unitIndex + 1;
    final shownLesson = relevantIndexes.isEmpty
        ? 0
        : completedCount >= relevantIndexes.length
        ? relevantIndexes.length
        : completedCount + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          unitIndex >= 0
              ? 'الوحدة ${Unit.toArabicNumeral(unitNumber)}'
              : 'مسار ${subject?.name ?? subjectId}',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: relevantIndexes.isEmpty
                    ? 0
                    : completedCount / relevantIndexes.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  HaffarColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                unitIndex >= 0
                    ? 'الدرس $shownLesson من ${relevantIndexes.length}'
                    : 'الدرس ${completedCount >= totalLessons ? totalLessons : completedCount + 1} من $totalLessons',
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13,
                  color: HaffarColors.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Lesson nodes in S-curve layout
              Expanded(
                child: ListView.builder(
                  itemCount: relevantLessons.length,
                  itemBuilder: (context, i) {
                    final lesson = relevantLessons[i];
                    final lessonIndex = lesson.index;
                    final isCompleted = progress.isSubjectLessonCompleted(
                      subjectId,
                      lessonIndex,
                    );
                    final isCurrent = lessonIndex == currentIndex;
                    // All lessons are open — the user picks the order.
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Center(
                        child: LessonNode(
                          label: 'درس ${Unit.toArabicNumeral(i + 1)}',
                          isCompleted: isCompleted,
                          isCurrent: isCurrent,
                          isLocked: false,
                          onTap: () => context.push(
                            '${Routes.lessonDetail}'
                            '?subject=$subjectId&lesson=$lessonIndex',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
