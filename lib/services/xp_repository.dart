import 'package:supabase_flutter/supabase_flutter.dart';

/// Server-side XP event tracking.
/// XP events are the source of truth for leaderboard calculations;
/// profile.xp is an aggregate maintained separately.
class XpRepository {
  final SupabaseClient _client;

  XpRepository(this._client);

  String? get _uid => _client.auth.currentUser?.id;

  /// Records an XP event via the validated add_xp_event RPC (also bumps
  /// profiles.xp atomically). source: lesson|unit|review|bonus.
  Future<void> insertEvent({
    required int amount,
    required String source,
    String? subjectId,
    int? lessonIndex,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.rpc(
      'add_xp_event',
      params: {
        'p_amount': amount,
        'p_source': source,
        'p_subject_id': subjectId,
        'p_lesson_index': lessonIndex,
      },
    );
  }

  /// Loads another user's public profile fields (SECURITY DEFINER RPC).
  Future<Map<String, dynamic>?> fetchPublicProfile(String userId) async {
    final result = await _client.rpc(
      'get_public_profile',
      params: {'p_user_id': userId},
    );
    final rows = result as List<dynamic>;
    if (rows.isEmpty) return null;
    return rows.first as Map<String, dynamic>;
  }

  /// Aggregates XP earned this league week (Saturday 00:00 → Friday 23:59:59
  /// Africa/Khartoum). The window is computed server-side.
  Future<int> getWeeklyXp() async {
    final uid = _uid;
    if (uid == null) return 0;
    final result = await _client.rpc(
      'weekly_xp_summary',
      params: {'p_user_id': uid},
    );
    final rows = result as List<dynamic>;
    if (rows.isEmpty) return 0;
    return (rows.first['week_xp'] as num).toInt();
  }

  /// Top-20 leaderboard for the current دوري حفّار week (Saturday 00:00 →
  /// Friday 23:59:59 Africa/Khartoum), sorted by week XP descending.
  /// The window is computed server-side; no client timezone input.
  Future<List<Map<String, dynamic>>> getLeaderboard(int limit) async {
    final uid = _uid;
    if (uid == null) return [];

    final result = await _client.rpc(
      'get_weekly_leaderboard',
      params: {'p_limit': limit, 'p_current_user_id': uid},
    );

    return (result as List<dynamic>)
        .map((row) => row as Map<String, dynamic>)
        .toList();
  }
}
