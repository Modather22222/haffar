import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads and saves the signed-in user's progress (profile stats, lesson and
/// unit-exercise completions). All methods are no-ops when not signed in.
class ProgressRepository {
  final SupabaseClient _client;

  ProgressRepository(this._client);

  String? get _uid => _client.auth.currentUser?.id;

  Future<Map<String, dynamic>?> fetchProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final rows = await _client.from('profiles').select().eq('id', uid).limit(1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> saveProfile({
    required String displayName,
    required int xp,
    required int streak,
    required int gems,
    required String league,
    bool isSubscribed = false,
    int hearts = 7,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('profiles').update({
      'display_name': displayName,
      'xp': xp,
      'streak': streak,
      'gems': gems,
      'league': league,
      'is_subscribed': isSubscribed,
      'hearts': hearts,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', uid);
  }

  /// Completed lesson keys in "subjectId:lessonIndex" form.
  Future<List<String>> fetchCompletedLessons() async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _client.from('user_lesson_progress').select('subject_id, lesson_index').eq('user_id', uid);
    return rows.map((r) => '${r['subject_id']}:${r['lesson_index']}').toList();
  }

  Future<void> saveCompletedLesson(String subjectId, int lessonIndex) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('user_lesson_progress').upsert({'user_id': uid, 'subject_id': subjectId, 'lesson_index': lessonIndex});
  }

  /// Completed unit-exercise keys in "subjectId:unitIndex" form.
  Future<List<String>> fetchCompletedUnitExercises() async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _client.from('user_unit_exercises').select('subject_id, unit_index').eq('user_id', uid);
    return rows.map((r) => '${r['subject_id']}:${r['unit_index']}').toList();
  }

  Future<void> saveCompletedUnitExercise(String subjectId, int unitIndex) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('user_unit_exercises').upsert({'user_id': uid, 'subject_id': subjectId, 'unit_index': unitIndex});
  }

  Future<void> clearAllProgress() async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('user_lesson_progress').delete().eq('user_id', uid);
    await _client.from('user_unit_exercises').delete().eq('user_id', uid);
    await _client.from('profiles').update({
      'xp': 0,
      'streak': 0,
      'gems': 0,
      'league': 'bronze',
      'hearts': 7,
    }).eq('id', uid);
  }
}
