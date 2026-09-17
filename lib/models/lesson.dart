/// A lesson within a subject — loaded from Supabase `lessons` table.
class Lesson {
  final String id;
  final String subjectId;
  final int unitIndex;
  final int index;
  final String title;
  final String summary;
  final List<String> keyPoints;

  const Lesson({
    required this.id,
    required this.subjectId,
    required this.unitIndex,
    required this.index,
    required this.title,
    this.summary = '',
    this.keyPoints = const [],
  });

  factory Lesson.fromMap(Map<String, dynamic> map) => Lesson(
        id: map['id'] as String,
        subjectId: map['subject_id'] as String,
        unitIndex: (map['unit_index'] as int?) ?? 0,
        index: (map['lesson_index'] as int?) ?? 0,
        title: map['title'] as String,
        summary: (map['summary'] as String?) ?? '',
        keyPoints: ((map['key_points'] as List?) ?? const []).cast<String>(),
      );
}
