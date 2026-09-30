import 'unit.dart';

/// Subject definition — loaded from Supabase `subjects` + `units` tables.
class Subject {
  final String id;
  final String name;
  final int sortOrder;
  final List<Unit> units;

  Subject({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    List<Unit>? units,
  }) : units = units ?? const [];

  factory Subject.fromMap(Map<String, dynamic> map, {List<Unit>? units}) =>
      Subject(
        id: map['id'] as String,
        name: map['name'] as String,
        sortOrder: (map['sort_order'] as int?) ?? 0,
        units: units,
      );

  /// Returns the asset path for this subject's image, or null if unavailable.
  String? get imageAsset => imageAssetFor(id);

  /// Asset path for any subject id (used where only the id is available).
  static String? imageAssetFor(String id) => _imageAssets[id];

  static const Map<String, String> _imageAssets = {
    'science': 'assets/subjects/sience.jpg',
    'math': 'assets/subjects/math.jpg',
    'arabic': 'assets/subjects/arabic.jpg',
    'islamic': 'assets/subjects/islamic.jpg',
    'history': 'assets/subjects/history.jpg',
    'geography': 'assets/subjects/geography.jpg',
    'ict': 'assets/subjects/ICT.jpg',
    'english': 'assets/subjects/english.jpg',
    'technical': 'assets/subjects/technical.jpg',
  };

  static Subject? getById(List<Subject> subjects, String id) {
    for (final s in subjects) {
      if (s.id == id) return s;
    }
    return null;
  }
}
