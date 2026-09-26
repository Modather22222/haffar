import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/models/lesson.dart';
import 'package:haffar/models/unit.dart';
import 'package:haffar/services/lesson_unlocks.dart';

class _Lookup implements LessonUnlockLookup {
  final List<Lesson> lessons;
  _Lookup(this.lessons);

  @override
  List<Lesson> lessonsOf(String subjectId) => lessons;
}

Lesson _lesson({
  required int index,
  required int unitIndex,
  int position = 0,
  String id = '',
}) => Lesson(
  id: id.isEmpty ? 'l$index' : id,
  subjectId: 'math',
  index: index,
  unitIndex: unitIndex,
  position: position,
  title: 't$index',
);

void main() {
  group('Lesson model with dynamic indexes', () {
    test('fromMap parses position and defaults it to 0', () {
      final withPosition = Lesson.fromMap({
        'id': 'a',
        'subject_id': 'math',
        'unit_index': 2,
        'lesson_index': 7,
        'position': 3,
        'title': 't',
      });
      expect(withPosition.position, 3);
      expect(withPosition.index, 7);
      expect(withPosition.unitIndex, 2);

      final withoutPosition = Lesson.fromMap({
        'id': 'b',
        'subject_id': 'math',
        'unit_index': 0,
        'lesson_index': 1,
        'title': 't',
      });
      expect(withoutPosition.position, 0);
    });

    test('published defaults to true and parses explicit draft', () {
      final published = Lesson.fromMap({
        'id': 'c',
        'subject_id': 'math',
        'unit_index': 0,
        'lesson_index': 1,
        'title': 't',
      });
      expect(published.published, isTrue);

      final draft = Lesson.fromMap({
        'id': 'd',
        'subject_id': 'math',
        'unit_index': 0,
        'lesson_index': 2,
        'title': 't',
        'published': false,
      });
      expect(draft.published, isFalse);
    });
  });

  group('Unit.lessonsCountLabel', () {
    test('covers zero, dual, paucal and plural forms', () {
      expect(Unit.lessonsCountLabel(0), 'لا توجد دروس');
      expect(Unit.lessonsCountLabel(1), 'درس واحد');
      expect(Unit.lessonsCountLabel(2), 'درسان');
      expect(Unit.lessonsCountLabel(3), '3 دروس');
      expect(Unit.lessonsCountLabel(10), '10 دروس');
      expect(Unit.lessonsCountLabel(11), '11 درساً');
      expect(Unit.lessonsCountLabel(25), '25 درساً');
    });
  });

  group('LessonUnlocks with gaps and reordered positions', () {
    // Display order: unit0 [idx0, idx1], unit1 [idx5, idx4] — index order
    // and position order deliberately disagree inside unit1.
    final lessons = [
      _lesson(index: 0, unitIndex: 0, position: 0),
      _lesson(index: 1, unitIndex: 0, position: 1),
      _lesson(index: 5, unitIndex: 1, position: 0),
      _lesson(index: 4, unitIndex: 1, position: 1),
    ];
    final lookup = _Lookup(lessons);

    test('unit start follows display order, not index arithmetic', () {
      expect(LessonUnlocks.isUnitStart(lookup, 'math', 0), isTrue);
      expect(LessonUnlocks.isUnitStart(lookup, 'math', 1), isFalse);
      expect(LessonUnlocks.isUnitStart(lookup, 'math', 5), isTrue);
      // idx4 has the lower index but sits second in display order.
      expect(LessonUnlocks.isUnitStart(lookup, 'math', 4), isFalse);
    });

    test('missing lessons are never unlocked', () {
      expect(
        LessonUnlocks.isLessonUnlocked(
          lookup: lookup,
          isCompleted: (s, i) => true,
          subjectId: 'math',
          lessonIndex: 99,
        ),
        isFalse,
      );
      expect(LessonUnlocks.isUnitStart(lookup, 'math', 99), isFalse);
    });

    test('mid-unit lesson unlocks only after preceding display lessons', () {
      // idx1 needs idx0 (its own unit start).
      expect(
        LessonUnlocks.isLessonUnlocked(
          lookup: lookup,
          isCompleted: (s, i) => i == 0,
          subjectId: 'math',
          lessonIndex: 1,
        ),
        isTrue,
      );
      expect(
        LessonUnlocks.isLessonUnlocked(
          lookup: lookup,
          isCompleted: (s, i) => false,
          subjectId: 'math',
          lessonIndex: 1,
        ),
        isFalse,
      );
      // idx4 (second in unit1) needs its unit start AND earlier units done.
      expect(
        LessonUnlocks.isLessonUnlocked(
          lookup: lookup,
          isCompleted: (s, i) => i == 0 || i == 1 || i == 5,
          subjectId: 'math',
          lessonIndex: 4,
        ),
        isTrue,
      );
      expect(
        LessonUnlocks.isLessonUnlocked(
          lookup: lookup,
          isCompleted: (s, i) => i == 0 || i == 1,
          subjectId: 'math',
          lessonIndex: 4,
        ),
        isFalse,
      );
      // A unit start stays reachable even when the previous unit is undone.
      expect(
        LessonUnlocks.isLessonUnlocked(
          lookup: lookup,
          isCompleted: (s, i) => false,
          subjectId: 'math',
          lessonIndex: 5,
        ),
        isTrue,
      );
    });
  });
}
