import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../design_system/colors.dart';
import '../../services/subscription_repository.dart';
import '../../utils/app_logger.dart';
import '../../utils/app_toast.dart';
import 'admin_widgets.dart';

/// الاشتراك — manual review of bank-transfer orders (رفع المستخدم إيصال
/// التحويل + رقم العملية، والدمن يراجع التحويل ويعتمده أو يرفضه).
/// Opened from the المشتركون KPI on the dashboard overview.
class AdminSubscriptionsScreen extends StatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  State<AdminSubscriptionsScreen> createState() =>
      _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends State<AdminSubscriptionsScreen> {
  late final SubscriptionRepository _repo;

  List<SubscriptionOrder> _orders = [];
  bool _loading = true;
  Object? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _repo = SubscriptionRepository(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _repo.fetchAdminOrders();
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (e, st) {
      AppLog.warn('fetchAdminOrders failed: $e');
      AppLog.error('fetchAdminOrders', e, st);
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(SubscriptionOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'اعتماد الاشتراك',
          style: TextStyle(fontFamily: kAdminFont, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'سيصبح ${order.displayName.isEmpty ? 'المستخدم' : order.displayName} '
          'مشتركاً لمدة شهر (من تاريخ الاعتماد) وتصله رسالة إشعار.',
          style: const TextStyle(fontFamily: kAdminFont, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: kAdminFont),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HaffarColors.primary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'اعتماد',
              style: TextStyle(
                fontFamily: kAdminFont,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyId = order.id);
    try {
      await _repo.approve(orderId: order.id);
      if (!mounted) return;
      AppToast.show('تم اعتماد الاشتراك ✅');
      await _load();
    } catch (e, st) {
      AppLog.warn('approve failed: $e');
      AppLog.error('approve subscription', e, st);
      if (mounted) AppToast.show(adminMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _reject(SubscriptionOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'رفض الطلب',
          style: TextStyle(fontFamily: kAdminFont, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'سيظهر للطلب كمرفوض ويمكنه إعادة الإرسال. رقم العملية: '
          '${order.operationNumber}',
          style: const TextStyle(fontFamily: kAdminFont, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: kAdminFont),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HaffarColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'رفض',
              style: TextStyle(
                fontFamily: kAdminFont,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyId = order.id);
    try {
      await _repo.reject(orderId: order.id);
      if (!mounted) return;
      AppToast.show('تم رفض الطلب');
      await _load();
    } catch (e, st) {
      AppLog.warn('reject failed: $e');
      AppLog.error('reject subscription', e, st);
      if (mounted) AppToast.show(adminMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _showReceipt(SubscriptionOrder order) async {
    showDialog<void>(
      context: context,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      final url = await Supabase.instance.client.storage
          .from('receipts')
          .createSignedUrl(order.receiptPath, 900);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // spinner
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                    errorBuilder: (_, _, _) => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'إغلاق',
                  style: TextStyle(
                    fontFamily: kAdminFont,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, st) {
      AppLog.warn('signed url failed: $e');
      AppLog.error('receipt signed url', e, st);
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // spinner
        AppToast.show('تعذّر فتح الإيصال', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: HaffarColors.bgPage,
        body: AdminLoadingView(),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: HaffarColors.bgPage,
        appBar: _appBar(),
        body: AdminErrorView(message: adminMessage(_error), onRetry: _load),
      );
    }

    final pending = _orders.where((o) => o.isPending).toList();
    final history = _orders.where((o) => !o.isPending).toList();

    return Scaffold(
      backgroundColor: HaffarColors.bgPage,
      appBar: _appBar(),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _sectionTitle('قيد المراجعة', count: pending.length),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              const AdminEmptyText('لا توجد طلبات اشتراك جديدة'),
            for (final order in pending) ...[
              _pendingCard(order),
              const SizedBox(height: 10),
            ],
            if (history.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle('سجل الطلبات', count: history.length),
              const SizedBox(height: 8),
              for (final order in history) ...[
                _historyRow(order),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: HaffarColors.bgPage,
      elevation: 0,
      title: const Text(
        'الاشتراك',
        style: TextStyle(
          fontFamily: kAdminFont,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: HaffarColors.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'تحديث',
          icon: const Icon(Icons.refresh, color: HaffarColors.textSecondary),
          onPressed: _loading ? null : _load,
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, {required int count}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: kAdminFont,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: HaffarColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: HaffarColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            fmtInt(count),
            style: const TextStyle(
              fontFamily: kAdminFont,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: HaffarColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pendingCard(SubscriptionOrder order) {
    final busy = _busyId == order.id;
    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: HaffarColors.primary.withValues(alpha: 0.15),
                child: Text(
                  order.displayName.trim().isEmpty
                      ? '؟'
                      : order.displayName.trim()[0],
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontWeight: FontWeight.w800,
                    color: HaffarColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.displayName.isEmpty
                          ? 'بدون اسم'
                          : order.displayName,
                      style: const TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: HaffarColors.textPrimary,
                      ),
                    ),
                    Text(
                      'أرسل طلب اشتراك',
                      style: TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 12,
                        color: HaffarColors.grey2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: HaffarColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${fmtInt(order.priceSdg)} SDG',
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: HaffarColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow('رقم العملية', order.operationNumber),
          _detailRow(
            'التاريخ',
            order.createdAt == null
                ? '—'
                : DateFormat('yyyy/MM/dd HH:mm').format(order.createdAt!),
          ),
          const SizedBox(height: 4),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: busy ? null : () => _showReceipt(order),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: HaffarColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _ReceiptThumb(path: order.receiptPath),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ايصال التحويل — اضغط للعرض',
                      style: TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: HaffarColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.zoom_in,
                    size: 18,
                    color: HaffarColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : () => _reject(order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HaffarColors.error,
                    side: BorderSide(
                      color: HaffarColors.error.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'رفض',
                          style: TextStyle(
                            fontFamily: kAdminFont,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: busy ? null : () => _approve(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HaffarColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'اعتماد الاشتراك',
                    style: TextStyle(
                      fontFamily: kAdminFont,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: kAdminFont,
              fontSize: 13,
              color: HaffarColors.grey2,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: kAdminFont,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: HaffarColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyRow(SubscriptionOrder order) {
    final color = order.isApproved ? HaffarColors.primary : HaffarColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: HaffarColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HaffarColors.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.displayName.isEmpty ? 'بدون اسم' : order.displayName,
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: HaffarColors.textPrimary,
                  ),
                ),
                Text(
                  'عملية ${order.operationNumber} · '
                  '${order.createdAt == null ? '' : DateFormat('yyyy/MM/dd').format(order.createdAt!)}',
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 12,
                    color: HaffarColors.grey2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              order.statusLabel,
              style: TextStyle(
                fontFamily: kAdminFont,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small signed-URL thumbnail for the transfer receipt (private bucket).
class _ReceiptThumb extends StatelessWidget {
  const _ReceiptThumb({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: Supabase.instance.client.storage
          .from('receipts')
          .createSignedUrl(path, 900),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done ||
            snap.hasError ||
            snap.data == null) {
          return Container(
            width: 44,
            height: 44,
            color: HaffarColors.grey6,
            child: const Icon(
              Icons.receipt_long,
              size: 20,
              color: HaffarColors.grey2,
            ),
          );
        }
        return Image.network(
          snap.data!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: 44,
            height: 44,
            color: HaffarColors.grey6,
            child: const Icon(
              Icons.receipt_long,
              size: 20,
              color: HaffarColors.grey2,
            ),
          ),
        );
      },
    );
  }
}
