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

  /// NOTE: hearts/xp/streak/gems/league are owned by server RPCs — clients may
  /// only set onboarding identity fields via update_own_profile (profiles
  /// UPDATE is revoked). Null/empty values keep the stored value.
  Future<void> saveProfile({
    required String displayName,
    String? schoolName,
    String? fromState,
    String? referralSource,
    int? targetScore,
    String? planChoice,
    String? gender,
    List<String>? weakSubjectIds,
    bool? notificationsEnabled,
    bool? hasCompletedOnboarding,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.rpc(
      'update_own_profile',
      params: {
        'p_display_name': displayName,
        'p_school_name': schoolName,
        'p_from_state': fromState,
        'p_referral_source': referralSource,
        'p_target_score': targetScore,
        'p_plan_choice': planChoice,
        'p_gender': gender,
        'p_weak_subject_ids': weakSubjectIds,
        'p_notifications_enabled': notificationsEnabled,
        'p_has_completed_onboarding': hasCompletedOnboarding,
      },
    );
  }

  /// Completed lesson keys in "subjectId:lessonIndex" form.
  Future<List<String>> fetchCompletedLessons() async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _client
        .from('user_lesson_progress')
        .select('subject_id, lesson_index')
        .eq('user_id', uid);
    return rows.map((r) => '${r['subject_id']}:${r['lesson_index']}').toList();
  }

  /// Writes one completion through the validated RPC — the DB rejects
  /// unknown lessons, and direct inserts on the table are revoked.
  Future<void> saveCompletedLesson(String subjectId, int lessonIndex) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.rpc(
      'complete_lesson',
      params: {'p_subject_id': subjectId, 'p_lesson_index': lessonIndex},
    );
  }

  /// Completed unit-exercise keys in "subjectId:unitIndex" form.
  Future<List<String>> fetchCompletedUnitExercises() async {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = await _client
        .from('user_unit_exercises')
        .select('subject_id, unit_index')
        .eq('user_id', uid);
    return rows.map((r) => '${r['subject_id']}:${r['unit_index']}').toList();
  }

  Future<void> saveCompletedUnitExercise(
    String subjectId,
    int unitIndex,
  ) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('user_unit_exercises').upsert({
      'user_id': uid,
      'subject_id': subjectId,
      'unit_index': unitIndex,
    });
  }

  /// Server-side reset: clears completions and economy for the caller only.
  Future<void> clearAllProgress() async {
    final uid = _uid;
    if (uid == null) return;
    await _client.rpc('reset_progress');
  }
}
