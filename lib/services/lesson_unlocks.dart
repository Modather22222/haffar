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

  /// True when [lessonIndex] is the first lesson of its unit in display
  /// order (lessons are dynamic: gaps in lesson_index are normal).
  static bool isUnitStart(
    LessonUnlockLookup lookup,
    String subjectId,
    int lessonIndex,
  ) {
    final lessons = lookup.lessonsOf(subjectId);
    for (var i = 0; i < lessons.length; i++) {
      if (lessons[i].index != lessonIndex) continue;
      final unitIndex = lessons[i].unitIndex;
      // Lists are sorted by (unit, position): any earlier row of the same
      // unit means this is not the unit's first lesson.
      return !lessons.take(i).any((l) => l.unitIndex == unitIndex);
    }
    return false;
  }

  /// A lesson is reachable when it starts a unit or every lesson before it
  /// in display order is completed. Missing indexes are skipped naturally
  /// because the walk follows actual lessons, not arithmetic.
  static bool isLessonUnlocked({
    required LessonUnlockLookup lookup,
    required bool Function(String subjectId, int lessonIndex) isCompleted,
    required String subjectId,
    required int lessonIndex,
  }) {
    if (isUnitStart(lookup, subjectId, lessonIndex)) return true;
    for (final lesson in lookup.lessonsOf(subjectId)) {
      if (lesson.index == lessonIndex) return true;
      if (!isCompleted(subjectId, lesson.index)) return false;
    }
    return false;
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

/// Builds a unit quiz from the unit's questions (any lesson count).
List<Question> buildUnitQuiz({
  required String subjectId,
  required int unitIndex,
  required List<Question> pool,
  int count = 10,
}) {
  return QuizBuilder.build('unit:$subjectId:$unitIndex', pool, count: count);
}
