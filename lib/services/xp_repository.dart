import 'package:supabase_flutter/supabase_flutter.dart';

/// Server-side XP event tracking.
/// XP events are the source of truth for leaderboard calculations;
/// profile.xp is an aggregate maintained separately.
class XpRepository {
  final SupabaseClient _client;

  XpRepository(this._client);

  String? get _uid => _client.auth.currentUser?.id;

  /// Inserts an XP event and returns the event id.
  /// source must be one of: 'lesson', 'unit', 'review', 'bonus'.
  Future<void> insertEvent({
    required int amount,
    required String source,
    String? subjectId,
    int? lessonIndex,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('xp_events').insert({
      'user_id': uid,
      'amount': amount,
      'source': source,
      'subject_id': subjectId,
      'lesson_index': lessonIndex,
    });
  }

  /// Aggregates total XP earned this ISO week (Saturday 00:00 to Friday 23:59 Africa/Khartoum).
  Future<int> getWeeklyXp() async {
    final uid = _uid;
    if (uid == null) return 0;
    final result = await _client.rpc('weekly_xp_summary', params: {'p_user_id': uid});
    final rows = result as List<dynamic>;
    if (rows.isEmpty) return 0;
    return (rows.first['week_xp'] as num).toInt();
  }

  /// Top-20 leaderboard sorted by weekly XP descending.
  Future<List<Map<String, dynamic>>> getLeaderboard(int limit) async {
    final uid = _uid;
    if (uid == null) return [];

    final startOfWeek = _startOfCurrentWeek();

    // Sum all xp_events for this week per user, join with profiles for display data
    final result = await _client.rpc('get_weekly_leaderboard', params: {
      'p_start': startOfWeek,
      'p_limit': limit,
      'p_current_user_id': uid,
    });

    return (result as List<dynamic>)
        .map((row) => row as Map<String, dynamic>)
        .toList();
  }

  String _startOfCurrentWeek() {
    final now = DateTime.now();
    // Saturday is day 6 in ISO (Monday=1), or weekday=6
    // Find last Saturday 00:00 local time
    final dayOfWeek = now.weekday; // 1=Mon, 6=Sat, 7=Sun
    final daysSinceSaturday = (dayOfWeek + 1) % 7;
    final start = DateTime(now.year, now.month, now.day - daysSinceSaturday);
    return start.toUtc().toIso8601String();
  }
}
