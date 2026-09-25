import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_stats.dart';

/// Client for the admin-only RPCs and the admin-push edge function.
///
/// Every RPC is a security-definer function gated server-side by
/// fn_is_admin() — the client can only call them; it cannot read other
/// users' rows directly (RLS stays own-rows-only). Being logged in as a
/// non-admin yields a `not authorized` PostgresException from every call.
class AdminRepository {
  final SupabaseClient _client;

  AdminRepository(this._client);

  /// The signed-in user's is_admin flag (own profile row, RLS-readable).
  /// Used by SessionProvider to show/hide the dashboard button — display
  /// only; the server re-checks on every admin call.
  Future<bool> fetchIsAdmin() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    final row = await _client
        .from('profiles')
        .select('is_admin')
        .eq('id', uid)
        .maybeSingle();
    return (row?['is_admin'] as bool?) ?? false;
  }

  Future<AdminOverview> fetchOverview() async {
    final result = await _client.rpc('admin_overview');
    return AdminOverview.fromJson(result as Map<String, dynamic>);
  }

  Future<AdminUsersPage> fetchUsers({
    String search = '',
    int limit = 50,
    int offset = 0,
  }) async {
    final result = await _client.rpc(
      'admin_users',
      params: {'p_search': search, 'p_limit': limit, 'p_offset': offset},
    );
    return AdminUsersPage.fromJson(result as Map<String, dynamic>);
  }

  Future<AdminUserDetail> fetchUserDetail(String userId) async {
    final result = await _client.rpc(
      'admin_user_detail',
      params: {'p_user_id': userId},
    );
    return AdminUserDetail.fromJson(result as Map<String, dynamic>);
  }

  Future<List<AdminSubjectStat>> fetchContentStats() async {
    final result = await _client.rpc('admin_content_stats');
    return [
      for (final row in (result as List<dynamic>))
        AdminSubjectStat.fromJson(row as Map<String, dynamic>),
    ];
  }

  Future<List<AdminDayStat>> fetchActivity({int days = 30}) async {
    final result = await _client.rpc(
      'admin_activity',
      params: {'p_days': days},
    );
    return [
      for (final row in (result as List<dynamic>))
        AdminDayStat.fromJson(row as Map<String, dynamic>),
    ];
  }

  /// Server-side targeted reset (admin_reset_user RPC).
  Future<void> resetUser({
    required String userId,
    required AdminResetTarget target,
  }) async {
    await _client.rpc(
      'admin_reset_user',
      params: {'p_user_id': userId, 'p_target': target.name},
    );
  }

  /// Sends a push via the admin-push edge function (verify_jwt + server-side
  /// is_admin check). Omit [userId] to broadcast to all devices.
  Future<AdminPushResult> sendNotification({
    required String body,
    String? userId,
  }) async {
    final payload = <String, dynamic>{'body': body};
    if (userId != null) {
      payload['user_id'] = userId;
    }
    final response = await _client.functions.invoke(
      'admin-push',
      body: payload,
    );
    return AdminPushResult.fromJson(response.data as Map<String, dynamic>);
  }
}
