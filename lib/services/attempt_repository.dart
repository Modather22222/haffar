import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_attempt.dart';

/// Saves and reads quiz attempts for the signed-in user.
class AttemptRepository {
  final SupabaseClient _client;

  AttemptRepository(this._client);

  String? get _uid => _client.auth.currentUser?.id;

  Future<void> saveAttempt({
    required String subjectId,
    required String kind,
    required int refIndex,
    required List<AttemptDetail> details,
  }) async {
    final uid = _uid;
    if (uid == null || details.isEmpty) return;
    final correct = details.where((d) => d.isCorrect).length;
    await _client.from('quiz_attempts').insert({
      'user_id': uid,
      'subject_id': subjectId,
      'kind': kind,
      'ref_index': refIndex,
      'total': details.length,
      'correct': correct,
      'details': details.map((d) => d.toMap()).toList(),
    });
  }

  Future<QuizAttempt?> fetchLastAttempt(
    String subjectId,
    String kind,
    int refIndex,
  ) async {
    final uid = _uid;
    if (uid == null) return null;
    final rows = await _client
        .from('quiz_attempts')
        .select()
        .eq('user_id', uid)
        .eq('subject_id', subjectId)
        .eq('kind', kind)
        .eq('ref_index', refIndex)
        .order('created_at', ascending: false)
        .limit(1);
    return rows.isEmpty ? null : QuizAttempt.fromMap(rows.first);
  }
}
