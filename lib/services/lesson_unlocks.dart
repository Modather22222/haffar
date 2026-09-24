import '../models/lesson.dart';
import '../models/question.dart';
import 'quiz_builder.dart';

/// Unit-start / unlock rules shared by path, units, and detail screens.
/// Requires lesson lookup from a [ContentProvider]-like source.
abstract class LessonUnlockLookup {
  List<Lesson> lessonsOf(String subjectId);
}

/// Pure unlock logic — unit-testable without widgets or network.
class LessonUnlocks {
  LessonUnlocks._();

  /// True when [lessonIndex] is the first lesson of its unit.
  static bool isUnitStart(
    LessonUnlockLookup lookup,
    String subjectId,
    int lessonIndex,
  ) {
    final unitLessons = lookup
        .lessonsOf(subjectId)
        .where((l) => l.index == lessonIndex)
        .toList();
    if (unitLessons.isEmpty) return false;
    final unitIndex = unitLessons.first.unitIndex;
    return !lookup
        .lessonsOf(subjectId)
        .any((l) => l.unitIndex == unitIndex && l.index < lessonIndex);
  }

  /// A lesson is reachable when it starts a unit or all preceding lessons
  /// are completed.
  static bool isLessonUnlocked({
    required LessonUnlockLookup lookup,
    required bool Function(String subjectId, int lessonIndex) isCompleted,
    required String subjectId,
    required int lessonIndex,
  }) {
    if (isUnitStart(lookup, subjectId, lessonIndex)) return true;
    for (var i = 0; i < lessonIndex; i++) {
      if (!isCompleted(subjectId, i)) return false;
    }
    return true;
  }
}

/// Builds a lesson quiz via the shared [QuizBuilder].
List<Question> buildLessonQuiz({
  required String subjectId,
  required int lessonIndex,
  required List<Question> pool,
  int? count,
}) {
  final quizCount = count ?? (subjectId == 'english' ? 10 : 3);
  return QuizBuilder.build(
    'lesson:$subjectId:$lessonIndex',
    pool,
    count: quizCount,
  );
}

/// Builds a unit quiz from the unit's three lessons.
List<Question> buildUnitQuiz({
  required String subjectId,
  required int unitIndex,
  required List<Question> pool,
  int count = 9,
}) {
  return QuizBuilder.build('unit:$subjectId:$unitIndex', pool, count: count);
}
