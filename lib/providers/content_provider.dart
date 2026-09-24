import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson.dart';
import '../models/question.dart';
import '../models/subject.dart';
import '../services/content_repository.dart';
import '../utils/app_logger.dart';

// ContentStatus lives here; AppProvider re-exports it for existing imports.
enum ContentStatus { loading, loaded, error }

/// Cached curriculum content (subjects, lessons, questions).
/// Loaded once at startup; read-only for the rest of the session.
class ContentProvider extends ChangeNotifier {
  ContentStatus status = ContentStatus.loading;
  List<Subject> _subjects = const [];
  Map<String, List<Lesson>> _lessonsBySubject = {};
  Map<String, List<Question>> _questionsBySubject = {};

  List<Subject> get subjects => _subjects;

  Subject? subjectById(String id) => Subject.getById(_subjects, id);

  List<Lesson> lessonsOf(String subjectId) =>
      _lessonsBySubject[subjectId] ?? const [];

  Lesson? lessonOf(String subjectId, int lessonIndex) {
    for (final lesson in lessonsOf(subjectId)) {
      if (lesson.index == lessonIndex) return lesson;
    }
    return null;
  }

  List<Question> questionsOf(String subjectId) =>
      _questionsBySubject[subjectId] ?? const [];

  List<Question> getQuestions(String subjectId, int lessonIndex) {
    final list =
        questionsOf(
            subjectId,
          ).where((q) => q.lessonIndex == lessonIndex).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  List<Question> getUnitQuestions(String subjectId, int unitIndex) {
    final start = unitIndex * 3;
    return questionsOf(subjectId)
        .where((q) => q.lessonIndex >= start && q.lessonIndex < start + 3)
        .toList()
      ..sort(
        (a, b) => a.lessonIndex != b.lessonIndex
            ? a.lessonIndex.compareTo(b.lessonIndex)
            : a.sortOrder.compareTo(b.sortOrder),
      );
  }

  int lessonCountOf(String subjectId) => lessonsOf(subjectId).length;

  int totalQuestionCount() =>
      _questionsBySubject.values.fold(0, (sum, list) => sum + list.length);

  Future<void> loadContent() async {
    status = ContentStatus.loading;
    notifyListeners();
    try {
      final repo = ContentRepository(Supabase.instance.client);
      final results = await Future.wait([
        repo.fetchSubjects(),
        repo.fetchLessons(),
        repo.fetchQuestions(),
      ]);
      _subjects = results[0] as List<Subject>;
      _lessonsBySubject = {};
      for (final lesson in results[1] as List<Lesson>) {
        _lessonsBySubject.putIfAbsent(lesson.subjectId, () => []).add(lesson);
      }
      _questionsBySubject = {};
      for (final question in results[2] as List<Question>) {
        _questionsBySubject
            .putIfAbsent(question.subjectId, () => [])
            .add(question);
      }
      status = ContentStatus.loaded;
    } catch (e, st) {
      AppLog.error('loadContent FAILED', e, st);
      status = ContentStatus.error;
    }
    notifyListeners();
  }
}
