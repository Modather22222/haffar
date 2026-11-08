/// Unit definition — groups multiple lessons together. Loaded from Supabase.
class Unit {
  final String id;
  final String subjectId;
  final int index;
  final String title;

  /// Per-unit XP economy (admin-editable): [xpBase] is the unit exercise's
  /// base XP and [wrongPenalty] is deducted per main-pass mistake. Defaults
  /// mirror the DB column defaults so seed content keeps its economy.
  final int xpBase;
  final int wrongPenalty;

  /// Per-unit exercise delivery (admin-editable), see `units.quiz_size` /
  /// `units.quiz_ids`: [quizSize] caps questions per attempt (`null` =
  /// DB default 10); [quizIds] pins an explicit set in display order and,
  /// when non-empty, overrides [quizSize].
  final int? quizSize;
  final List<String> quizIds;

  const Unit({
    required this.id,
    required this.subjectId,
    required this.index,
    required this.title,
    this.xpBase = 150,
    this.wrongPenalty = 18,
    this.quizSize,
    this.quizIds = const [],
  });

  factory Unit.fromMap(Map<String, dynamic> map) => Unit(
    id: map['id'] as String,
    subjectId: map['subject_id'] as String,
    index: (map['unit_index'] as int?) ?? 0,
    title: map['title'] as String,
    xpBase: (map['xp_base'] as int?) ?? 150,
    wrongPenalty: (map['wrong_penalty'] as int?) ?? 18,
    quizSize: map['quiz_size'] as int?,
    quizIds: ((map['quiz_ids'] as List?) ?? const []).cast<String>(),
  );

  static String toArabicNumeral(int n) {
    final arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return String.fromCharCodes(
      n
          .toString()
          .split('')
          .map((c) => arabicDigits[int.parse(c)].codeUnitAt(0))
          .toList(),
    );
  }

  /// Arabic label for a lesson count ("درس واحد", "درسان", "N دروس", ...).
  static String lessonsCountLabel(int n) {
    if (n <= 0) return 'لا توجد دروس';
    if (n == 1) return 'درس واحد';
    if (n == 2) return 'درسان';
    if (n <= 10) return '$n دروس';
    return '$n درساً';
  }
}
