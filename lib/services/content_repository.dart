import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../models/subject.dart';
import '../models/unit.dart';

/// Fetches all learning content from Supabase.
class ContentRepository {
  final SupabaseClient _client;

  ContentRepository(this._client);

  Future<List<Subject>> fetchSubjects() async {
    final subjectRows = await _client
        .from('subjects')
        .select()
        .order('sort_order');
    final unitRows = await _client.from('units').select().order('unit_index');
    final unitsBySubject = <String, List<Unit>>{};
    for (final row in unitRows) {
      final unit = Unit.fromMap(row);
      unitsBySubject.putIfAbsent(unit.subjectId, () => []).add(unit);
    }
    return subjectRows.map((row) {
      final subject = Subject.fromMap(
        row,
        units: unitsBySubject[row['id']] ?? const [],
      );
      return subject;
    }).toList();
  }

  Future<List<Lesson>> fetchLessons() async {
    final rows = await _client
        .from('lessons')
        .select()
        .order('unit_index')
        .order('position');
    return rows.map(Lesson.fromMap).toList();
  }

  Future<List<Question>> fetchQuestions() async {
    final rows = await _client.from('questions').select().order('sort_order');
    return rows.map(Question.fromMap).toList();
  }
}
