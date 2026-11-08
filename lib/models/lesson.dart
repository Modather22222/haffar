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

  /// Per-lesson XP economy (admin-editable): [xpBase] is the attempt's base
  /// XP and [wrongPenalty] is deducted per main-pass mistake. Defaults mirror
  /// the DB column defaults so seed content keeps the classic economy.
  final int xpBase;
  final int wrongPenalty;

  /// Per-lesson exercise delivery (admin-editable), see
  /// `lessons.quiz_size` / `lessons.quiz_ids`:
  /// [quizSize] limits how many questions تمرين الدرس shows (`null` =
  /// built-in default: 3, or 10 for english). [quizIds] pins an explicit
  /// question set in display order and, when non-empty, overrides
  /// [quizSize].
  final int? quizSize;
  final List<String> quizIds;

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
    this.xpBase = 100,
    this.wrongPenalty = 5,
    this.quizSize,
    this.quizIds = const [],
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
    xpBase: (map['xp_base'] as int?) ?? 100,
    wrongPenalty: (map['wrong_penalty'] as int?) ?? 5,
    quizSize: map['quiz_size'] as int?,
    quizIds: ((map['quiz_ids'] as List?) ?? const []).cast<String>(),
  );
}
