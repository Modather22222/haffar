import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../providers/progress_provider.dart';
import '../design_system/colors.dart';
import '../models/lesson.dart';
import '../models/subject.dart';
import '../models/unit.dart';
import '../utils/routes.dart';
import '../services/lesson_unlocks.dart';

/// Units screen — shows units for a subject, each containing lessons
class UnitsScreen extends StatelessWidget {
  final String subjectId;
  final Subject subject;

  const UnitsScreen({
    super.key,
    required this.subjectId,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final unlockLookup = _ContentLookup(content);
    final completedCount = progress.subjectCompletedCount(subjectId);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (subject.imageAsset != null)
              Image.asset(
                subject.imageAsset!,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            if (subject.imageAsset != null) const SizedBox(width: 8),
            Text(subject.name),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _progress(progress, content, subjectId),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                  backgroundColor: HaffarColors.grey6,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    HaffarColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(_progressPercent(progress, content, subjectId))}%',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 12,
                    color: HaffarColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subject.units.length,
          itemBuilder: (context, unitIndex) {
            final unit = subject.units[unitIndex];
            final unitLessons = List.generate(3, (i) => unitIndex * 3 + i);
            final isUnlocked = unitLessons.any(
              (l) => _isLessonUnlocked(progress, unlockLookup, subjectId, l),
            );
            final isCompleted = unitLessons.every(
              (l) => progress.isSubjectLessonCompleted(subjectId, l),
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: HaffarColors.outline.withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Unit header
                  InkWell(
                    onTap: isUnlocked
                        ? () => context.push(
                            '${Routes.lessonPath}?subject=$subjectId&unit=$unitIndex',
                          )
                        : null,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? HaffarColors.primary
                                  : isUnlocked
                                  ? HaffarColors.primary
                                  : HaffarColors.surfaceHigh,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.check
                                  : isUnlocked
                                  ? Icons.book
                                  : Icons.lock,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  unit.title,
                                  style: const TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '٣ دروس',
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 13,
                                    color: isUnlocked
                                        ? HaffarColors.outline
                                        : HaffarColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isUnlocked
                                ? Icons.arrow_forward_ios
                                : Icons.lock_outline,
                            size: 16,
                            color: isUnlocked
                                ? HaffarColors.primary
                                : HaffarColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Lessons list
                  if (isUnlocked) ...[
                    const Divider(height: 1),
                    ...unitLessons.map((lessonIndex) {
                      final isLessonCompleted = progress
                          .isSubjectLessonCompleted(subjectId, lessonIndex);
                      final isLessonCurrent = lessonIndex == completedCount;
                      return InkWell(
                        onTap:
                            _isLessonUnlocked(
                              progress,
                              unlockLookup,
                              subjectId,
                              lessonIndex,
                            )
                            ? () => context.push(
                                '${Routes.lessonDetail}'
                                '?subject=$subjectId&lesson=$lessonIndex',
                              )
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isLessonCompleted
                                      ? HaffarColors.primary
                                      : isLessonCurrent
                                      ? HaffarColors.primary
                                      : HaffarColors.surfaceHigh,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isLessonCompleted
                                      ? Icons.check
                                      : _iconForLesson(
                                          progress,
                                          content,
                                          unlockLookup,
                                          subjectId,
                                          lessonIndex,
                                          isLessonCurrent,
                                        ),
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'درس ${Unit.toArabicNumeral(lessonIndex + 1)}',
                                  style: const TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                  // Unit exercise — unlocks after all lessons of the unit are done
                  if (isUnlocked) ...[
                    const Divider(height: 1),
                    Builder(
                      builder: (_) {
                        final allLessonsDone = unitLessons.every(
                          (l) =>
                              progress.isSubjectLessonCompleted(subjectId, l),
                        );
                        final exerciseDone = progress.isUnitExerciseCompleted(
                          subjectId,
                          unitIndex,
                        );
                        return InkWell(
                          onTap: allLessonsDone
                              ? () => context.push(
                                  '${Routes.unitExercise}'
                                  '?subject=$subjectId'
                                  '&name=${Uri.encodeComponent(subject.name)}'
                                  '&unit=$unitIndex',
                                )
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: exerciseDone
                                        ? HaffarColors.primary
                                        : allLessonsDone
                                        ? HaffarColors.primary
                                        : HaffarColors.surfaceHigh,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    exerciseDone
                                        ? Icons.check
                                        : Icons.emoji_events,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'تمرين الوحدة',
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: allLessonsDone
                                          ? HaffarColors.textPrimary
                                          : HaffarColors.textSecondary,
                                    ),
                                  ),
                                ),
                                if (exerciseDone)
                                  const Icon(
                                    Icons.check_circle,
                                    color: HaffarColors.primary,
                                    size: 20,
                                  )
                                else if (!allLessonsDone)
                                  const Icon(
                                    Icons.lock_outline,
                                    size: 16,
                                    color: HaffarColors.textSecondary,
                                  )
                                else
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: HaffarColors.primary,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isLessonUnlocked(
    ProgressProvider progress,
    _ContentLookup lookup,
    String subjectId,
    int lessonIndex,
  ) {
    return LessonUnlocks.isLessonUnlocked(
      lookup: lookup,
      isCompleted: progress.isSubjectLessonCompleted,
      subjectId: subjectId,
      lessonIndex: lessonIndex,
    );
  }

  double _progress(
    ProgressProvider progress,
    ContentProvider content,
    String sid,
  ) {
    final total = content.lessonCountOf(sid);
    if (total == 0) return 0.0;
    return progress.subjectCompletedCount(sid) / total;
  }

  int _progressPercent(
    ProgressProvider progress,
    ContentProvider content,
    String sid,
  ) {
    final total = content.lessonCountOf(sid);
    if (total == 0) return 0;
    return ((progress.subjectCompletedCount(sid) / total) * 100).round();
  }

  IconData _iconForLesson(
    ProgressProvider progress,
    ContentProvider content,
    _ContentLookup lookup,
    String subjectId,
    int lessonIndex,
    bool isCurrent,
  ) {
    if (!_isLessonUnlocked(progress, lookup, subjectId, lessonIndex)) {
      return Icons.lock;
    }
    if (isCurrent) return Icons.play_arrow;
    if (_isFirstInUnit(content, subjectId, lessonIndex)) {
      return Icons.play_arrow;
    }
    return Icons.check;
  }

  bool _isFirstInUnit(
    ContentProvider content,
    String subjectId,
    int lessonIndex,
  ) {
    final lessons = content.lessonsOf(subjectId);
    final unitLessons = lessons.where((l) => l.index == lessonIndex).toList();
    if (unitLessons.isEmpty) return false;
    final unitIdx = unitLessons.first.unitIndex;
    return !lessons.any((l) => l.unitIndex == unitIdx && l.index < lessonIndex);
  }
}

class _ContentLookup implements LessonUnlockLookup {
  final ContentProvider content;
  const _ContentLookup(this.content);

  @override
  List<Lesson> lessonsOf(String subjectId) => content.lessonsOf(subjectId);
}
