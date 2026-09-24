import 'package:supabase_flutter/supabase_flutter.dart';

/// Server-side heart management via RPC.
/// All heart logic is authoritative on the server — this repo is a thin client.
class HeartsRepository {
  final SupabaseClient _client;

  HeartsRepository(this._client);

  String? get _uid => _client.auth.currentUser?.id;

  /// Result from get_hearts RPC with server-synced timing.
  /// [now] is server NOW() at call time, used to compute local offset.
  Future<HeartsInfo> getHeartsInfo() async {
    final uid = _uid;
    if (uid == null) {
      final now = DateTime.now().toUtc();
      return HeartsInfo(hearts: 7, updatedAt: now, serverNow: now);
    }
    final result = await _client.rpc('get_hearts', params: {'p_user_id': uid});
    final json = result as Map<String, dynamic>;
    final hearts = (json['hearts'] as num).toInt();
    final updatedAt =
        DateTime.tryParse(json['updated_at'] as String? ?? '')?.toUtc() ??
        DateTime.now().toUtc();
    final serverNow =
        DateTime.tryParse(json['now'] as String? ?? '')?.toUtc() ??
        DateTime.now().toUtc();
    return HeartsInfo(
      hearts: hearts,
      updatedAt: updatedAt,
      serverNow: serverNow,
    );
  }

  /// Fetches current heart count from the server (with server-side regeneration).
  Future<int> getHearts() async => (await getHeartsInfo()).hearts;

  /// Consumes one heart for a reason. Returns remaining hearts (0 if none left).
  Future<int> consumeHeart({required String reason}) async {
    final uid = _uid;
    if (uid == null) return 7;
    final result = await _client.rpc(
      'consume_heart',
      params: {'p_user_id': uid, 'p_reason': reason},
    );
    return (result as num).toInt();
  }

  /// Whether the user is currently a subscriber (loaded from profiles).
  bool get isSubscribed => false;

  /// Refreshes local hearts cache by calling the server.
  Future<int> refreshHearts() => getHearts();
}

class HeartsInfo {
  final int hearts;
  final DateTime updatedAt;
  final DateTime serverNow;
  const HeartsInfo({
    required this.hearts,
    required this.updatedAt,
    required this.serverNow,
  });
}
