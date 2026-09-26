import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';

/// One bank-transfer order for the حفار برو plan. Stored server-side in
/// `subscription_orders`; the admin reviews it on the الاشتراك screen.
class SubscriptionOrder {
  const SubscriptionOrder({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.operationNumber,
    required this.receiptPath,
    required this.priceSdg,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final String operationNumber;
  final String receiptPath;
  final int priceSdg;
  final String status;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get statusLabel => switch (status) {
    'approved' => 'مقبول',
    'rejected' => 'مرفوض',
    _ => 'قيد المراجعة',
  };

  factory SubscriptionOrder.fromJson(Map<String, dynamic> json) {
    return SubscriptionOrder(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      operationNumber: json['operation_number'] as String? ?? '',
      receiptPath: json['receipt_path'] as String? ?? '',
      priceSdg: (json['price_sdg'] as num?)?.toInt() ?? 49000,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String)?.toLocal(),
      reviewedAt: json['reviewed_at'] == null
          ? null
          : DateTime.tryParse(json['reviewed_at'] as String)?.toLocal(),
    );
  }
}

/// Manual bank-transfer subscription flow (no in-app payments):
/// user uploads رقم العملية + إيصال التحويل → admin approves → 1 month of
/// unlimited hearts.
///
/// Bank details are placeholders until the real account is provided —
/// see [bankName] / [accountHolder] / [accountNumber].
class SubscriptionRepository {
  SubscriptionRepository(this._client);

  final SupabaseClient _client;

  // ── Plan ──────────────────────────────────────────────────────────────────
  static const String planName = 'حفار برو';
  static const int planPriceSdg = 49000;
  static const String planPriceLabel = '49,000 SDG';

  // ── Receiving bank account (shown to the user) ────────────────────────────
  // TODO: replace these placeholders with the real account before release.
  static const String bankName = 'اسم البنك — يُضاف لاحقاً';
  static const String accountHolder = 'اسم صاحب الحساب — يُضاف لاحقاً';
  static const String accountNumber = '0000 0000 0000';

  String? get _uid => _client.auth.currentUser?.id;

  /// Latest own order (pending/approved/rejected), or null when none.
  Future<SubscriptionOrder?> fetchLatestOrder() async {
    final uid = _uid;
    if (uid == null) return null;
    final rows = await _client
        .from('subscription_orders')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return SubscriptionOrder.fromJson(Map<String, dynamic>.from(rows.first));
  }

  /// Uploads the transfer receipt to the private `receipts` bucket under the
  /// caller's own folder and returns its storage path (stored on the order —
  /// no public URL, admins read it through their own RLS grant).
  Future<String> uploadReceipt({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('not signed in');
    final ext = switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final ts = DateTime.now().microsecondsSinceEpoch;
    final path = '$uid/receipt_$ts.$ext';
    await _client.storage
        .from('receipts')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );
    return path;
  }

  /// Submits the order, then best-effort notifies the admins (the push
  /// failure never fails the submission — the order is already stored).
  Future<SubscriptionOrder> submit({
    required String operationNumber,
    required String receiptPath,
  }) async {
    final res = await _client.rpc(
      'submit_subscription_order',
      params: {
        'p_operation_number': operationNumber,
        'p_receipt_path': receiptPath,
      },
    );
    final orderId = (res as Map)['order_id']?.toString();
    await _notify(orderId: orderId, action: 'created');
    final order = await fetchLatestOrder();
    if (order == null) throw StateError('submitted order not found');
    return order;
  }

  /// Admin: accepts the transfer → user becomes subscribed for a month, then
  /// best-effort notifies the user.
  Future<void> approve({required String orderId}) async {
    await _client.rpc(
      'approve_subscription_order',
      params: {'p_order_id': orderId},
    );
    await _notify(orderId: orderId, action: 'approved');
  }

  /// Admin: rejects the transfer (no push — the user sees it next visit).
  Future<void> reject({required String orderId}) async {
    await _client.rpc(
      'reject_subscription_order',
      params: {'p_order_id': orderId},
    );
  }

  /// Admin: all orders newest-first (RPC is admin-gated server-side).
  Future<List<SubscriptionOrder>> fetchAdminOrders() async {
    final res = await _client.rpc('admin_subscription_orders');
    final list = (res as List).whereType<Map>();
    return list
        .map(
          (row) => SubscriptionOrder.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<void> _notify({
    required String? orderId,
    required String action,
  }) async {
    if (orderId == null || orderId.isEmpty) return;
    try {
      await _client.functions.invoke(
        'subscription-notify',
        body: {'order_id': orderId, 'action': action},
      );
    } catch (e, st) {
      // Best-effort: the order itself is already persisted/reviewed.
      AppLog.warn('subscription-notify($action) failed: $e');
      AppLog.error('subscription-notify', e, st);
    }
  }
}
