/// Unit definition — groups multiple lessons together. Loaded from Supabase.
class Unit {
  final String id;
  final String subjectId;
  final int index;
  final String title;

  const Unit({
    required this.id,
    required this.subjectId,
    required this.index,
    required this.title,
  });

  factory Unit.fromMap(Map<String, dynamic> map) => Unit(
    id: map['id'] as String,
    subjectId: map['subject_id'] as String,
    index: (map['unit_index'] as int?) ?? 0,
    title: map['title'] as String,
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
