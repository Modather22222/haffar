import 'dart:math';

import '../models/question.dart';

/// Builds a randomized quiz attempt from a pool of questions.
class QuizBuilder {
  QuizBuilder._();

  /// Option order is only shuffled for types whose options are independent
  /// choices. matching/classification keep index pairing; ordering uses
  /// correctWords so its tiles are already order-free.
  static const _shufflableTypes = {
    QuestionType.multipleChoice,
    QuestionType.trueFalse,
    QuestionType.definition,
    QuestionType.reading,
    QuestionType.diagram,
  };

  /// Remembers each attempt's question ids so the next attempt on the same
  /// lesson/unit prefers unseen questions.
  static final _lastAttemptIds = <String, Set<String>>{};

  /// Builds a quiz of [count] questions from [pool] for the attempt [key].
  static List<Question> build(
    String key,
    List<Question> pool, {
    int count = 3,
    Random? random,
  }) {
    // Empty pools are valid (a lesson may have no questions yet): clamp
    // would throw ArgumentError(lowerLimit > upperLimit) below.
    if (pool.isEmpty) return const [];
    final rnd = random ?? Random();
    final seen = _lastAttemptIds[key] ?? const <String>{};
    final fresh = pool.where((q) => !seen.contains(q.id)).toList();
    // Only exclude seen questions when enough unseen ones remain.
    final candidates = fresh.length >= count ? fresh : List<Question>.of(pool);
    candidates.shuffle(rnd);
    final selected = candidates
        .take(count.clamp(1, candidates.length))
        .map((q) => _shuffleOptions(q, rnd))
        .toList();
    _lastAttemptIds[key] = selected.map((q) => q.id).toSet();
    return selected;
  }

  static Question _shuffleOptions(Question q, Random rnd) {
    if (!_shufflableTypes.contains(q.type) || q.options.length < 2) return q;
    final indices = List<int>.generate(q.options.length, (i) => i)
      ..shuffle(rnd);
    final remapped = indices.indexOf(q.correctIndex);
    return Question(
      id: q.id,
      subjectId: q.subjectId,
      lessonIndex: q.lessonIndex,
      sortOrder: q.sortOrder,
      type: q.type,
      text: q.text,
      passage: q.passage,
      hint: q.hint,
      options: indices.map((i) => q.options[i]).toList(),
      correctIndex: remapped == -1 ? q.correctIndex : remapped,
      correctWords: q.correctWords,
      itemCategories: q.itemCategories,
      xpReward: q.xpReward,
      imageUrl: q.imageUrl,
    );
  }
}
