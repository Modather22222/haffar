import 'package:supabase_flutter/supabase_flutter.dart';

/// Server-side heart management via RPC.
/// All heart logic is authoritative on the server — this repo is a thin client.
class HeartsRepository {
  final SupabaseClient _client;

  HeartsRepository(this._client);

  String? get _uid => _client.auth.currentUser?.id;

  /// Fetches current heart count from the server (with server-side regeneration).
  Future<int> getHearts() async {
    final uid = _uid;
    if (uid == null) return 7;
    final result = await _client.rpc('get_hearts', params: {'p_user_id': uid});
    final json = result as Map<String, dynamic>;
    return (json['hearts'] as num).toInt();
  }

  /// Consumes one heart for a reason. Returns remaining hearts (0 if none left).
  Future<int> consumeHeart({required String reason}) async {
    final uid = _uid;
    if (uid == null) return 7;
    final result = await _client.rpc('consume_heart', params: {
      'p_user_id': uid,
      'p_reason': reason,
    });
    return (result as num).toInt();
  }

  /// Whether the user is currently a subscriber (loaded from profiles).
  bool get isSubscribed => false;

  /// Refreshes local hearts cache by calling the server.
  Future<int> refreshHearts() => getHearts();
}
