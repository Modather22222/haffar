/// Types of questions used across all subjects
enum QuestionType {
  multipleChoice, // 4 option cards
  trueFalse, // two large button cards صواب/خطأ
  fillBlank, // text input + info/hint card
  matching, // two-column tap-to-match
  definition, // large term card + definition options
  ordering, // reorderable list
  composition, // paragraph textarea
  reading, // passage card + MC
  calculation, // numeric input + formula hint card
  explanation, // text area + passage context
  diagram, // square image card + "؟" label slot pointing at image + choice options
  classification, // word-bank chips sorted into two category drop-zones
}

/// A single question with all data from Stitch screens
class Question {
  final String id;
  final String subjectId;
  final int lessonIndex;
  final QuestionType type;
  final String text;
  final String? passage; // reading context or explanation prompt
  final String? hint; // "تذكر: ..." tip card shown below question
  final List<String> options;
  final int correctIndex; // for MC, TF, definition, reading, matching
  final List<String>? correctWords; // for fill-blank / ordering
  final List<String>?
  itemCategories; // for classification: '0' (first zone) or '1' (second zone) per option
  final int xpReward;
  final String? imageUrl; // for chart/data questions
  final int sortOrder;
  final String difficulty; // easy | medium | hard

  const Question({
    required this.id,
    required this.subjectId,
    required this.lessonIndex,
    required this.type,
    required this.text,
    this.passage,
    this.hint,
    this.options = const [],
    this.correctIndex = 0,
    this.correctWords,
    this.itemCategories,
    this.xpReward = 5,
    this.imageUrl,
    this.sortOrder = 0,
    this.difficulty = 'medium',
  });

  static QuestionType _typeFromString(String value) =>
      QuestionType.values.firstWhere(
        (t) => t.name == value,
        orElse: () => QuestionType.multipleChoice,
      );

  factory Question.fromMap(Map<String, dynamic> map) => Question(
    id: map['id'] as String,
    subjectId: map['subject_id'] as String,
    lessonIndex: (map['lesson_index'] as int?) ?? 0,
    sortOrder: (map['sort_order'] as int?) ?? 0,
    type: _typeFromString(map['type'] as String? ?? 'multipleChoice'),
    text: map['text'] as String,
    passage: map['passage'] as String?,
    hint: map['hint'] as String?,
    options: ((map['options'] as List?) ?? const []).cast<String>(),
    correctIndex: (map['correct_index'] as int?) ?? 0,
    correctWords: ((map['correct_words'] as List?) ?? const []).cast<String>(),
    itemCategories: ((map['item_categories'] as List?) ?? const [])
        .cast<String>(),
    xpReward: (map['xp_reward'] as int?) ?? 5,
    imageUrl: map['image_url'] as String?,
    difficulty: (map['difficulty'] as String?) ?? 'medium',
  );

  /// Returns the correct answer text for display in feedback
  String? get correctAnswerText {
    if (correctWords != null && correctWords!.isNotEmpty) {
      return correctWords!.first;
    }
    if (options.isNotEmpty) return options[correctIndex];
    return null;
  }
}
