/// A lesson within a subject — loaded from Supabase `lessons` table.
///
/// [index] (`lesson_index`) is the lesson's stable per-subject identity: it
/// never changes, so progress keys built from it stay valid (gaps allowed).
/// [position] orders lessons inside their unit and is the only field that
/// changes when lessons are added, removed, or reordered.
/// [published] marks content-complete lessons: drafts are invisible to
/// students (RLS + query filter) until the admin saves/publishes them.
class Lesson {
  final String id;
  final String subjectId;
  final int unitIndex;
  final int index;
  final int position;
  final String title;
  final String summary;
  final List<String> keyPoints;
  final bool published;

  const Lesson({
    required this.id,
    required this.subjectId,
    required this.unitIndex,
    required this.index,
    this.position = 0,
    required this.title,
    this.summary = '',
    this.keyPoints = const [],
    this.published = true,
  });

  factory Lesson.fromMap(Map<String, dynamic> map) => Lesson(
    id: map['id'] as String,
    subjectId: map['subject_id'] as String,
    unitIndex: (map['unit_index'] as int?) ?? 0,
    index: (map['lesson_index'] as int?) ?? 0,
    position: (map['position'] as int?) ?? 0,
    title: map['title'] as String,
    summary: (map['summary'] as String?) ?? '',
    keyPoints: ((map['key_points'] as List?) ?? const []).cast<String>(),
    published: (map['published'] as bool?) ?? true,
  );
}
