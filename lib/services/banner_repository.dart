import 'package:supabase_flutter/supabase_flutter.dart';

/// Server-computed per-banner unlocks (get_my_banners RPC).
/// The حسابي banner grid treats this as authoritative; the local
/// streak/lesson thresholds in the screen are only a fallback while this
/// fetch is pending or fails.
class BannerRepository {
  /// banner_key → asset path (keys stored in profiles.selected_banner).
  static const Map<String, String> assets = {
    'first': 'assets/banners/first_banner.jpg',
    'second': 'assets/banners/second_banner.jpg',
    'third': 'assets/banners/third_banner_v1.jpg',
    'fourth': 'assets/banners/third_banner_v2.jpg',
  };

  /// Every banner asset shares this ratio (2658×984 ≈ 2.70:1) — lock the
  /// rendering boxes to it so the whole image is visible without cropping.
  static const double aspectRatio = 2658 / 984;

  final SupabaseClient _client;

  BannerRepository(this._client);

  String? get _uid => _client.auth.currentUser?.id;

  /// banner_key → unlocked, e.g. {'first': true, 'second': false, …}.
  Future<Map<String, bool>> getUnlocks() async {
    final uid = _uid;
    if (uid == null) return {};
    final result = await _client.rpc(
      'get_my_banners',
      params: {'p_user_id': uid},
    );
    final rows = result as List<dynamic>;
    return {
      for (final row in rows)
        ((row as Map<String, dynamic>)['banner_key'] as String):
            row['unlocked'] as bool,
    };
  }

  /// Persists the chosen banner (server re-validates it is unlocked).
  Future<void> setSelected(String bannerKey) async {
    await _client.rpc('set_selected_banner', params: {'p_banner': bannerKey});
  }
}
