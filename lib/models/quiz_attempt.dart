/// A saved quiz attempt with per-question results.
class QuizAttempt {
  final String id;
  final String subjectId;
  final String kind; // lesson | unit | review
  final int refIndex;
  final int total;
  final int correct;
  final List<AttemptDetail> details;
  final DateTime createdAt;

  const QuizAttempt({
    required this.id,
    required this.subjectId,
    required this.kind,
    required this.refIndex,
    required this.total,
    required this.correct,
    required this.details,
    required this.createdAt,
  });

  List<String> get wrongQuestionIds => details.where((d) => !d.isCorrect).map((d) => d.questionId).toList();

  factory QuizAttempt.fromMap(Map<String, dynamic> map) => QuizAttempt(
        id: map['id'] as String,
        subjectId: map['subject_id'] as String,
        kind: map['kind'] as String,
        refIndex: (map['ref_index'] as int?) ?? 0,
        total: (map['total'] as int?) ?? 0,
        correct: (map['correct'] as int?) ?? 0,
        details: ((map['details'] as List?) ?? const [])
            .map((d) => AttemptDetail.fromMap(d as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Per-question outcome inside an attempt.
class AttemptDetail {
  final String questionId;
  final bool isCorrect;

  const AttemptDetail({required this.questionId, required this.isCorrect});

  factory AttemptDetail.fromMap(Map<String, dynamic> map) => AttemptDetail(
        questionId: map['question_id'] as String,
        isCorrect: map['is_correct'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {'question_id': questionId, 'is_correct': isCorrect};
}
