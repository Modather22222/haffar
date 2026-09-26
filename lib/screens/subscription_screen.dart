import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design_system/colors.dart';
import '../design_system/components/buttons/button_general_primary.dart';
import '../providers/economy_provider.dart';
import '../services/subscription_repository.dart';
import '../utils/app_logger.dart';
import '../utils/app_toast.dart';

/// حفار برو — manual bank-transfer subscription.
///
/// The user transfers 49,000 SDG to our account, uploads the receipt
/// (ايصال التحويل) and enters the transaction number (رقم العملية); the admin
/// then reviews and approves it from the الاشتراك screen.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late final SubscriptionRepository _repo;
  final _opController = TextEditingController();
  final _picker = ImagePicker();

  bool _loading = true;
  bool _submitting = false;
  SubscriptionOrder? _order;
  Uint8List? _receiptBytes;
  String? _receiptMime;

  @override
  void initState() {
    super.initState();
    _repo = SubscriptionRepository(Supabase.instance.client);
    _load();
  }

  @override
  void dispose() {
    _opController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // Re-hydrate the profile so the screen reflects a just-approved
      // subscription without waiting for the next app restart.
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid != null) {
        final rows = await client
            .from('profiles')
            .select()
            .eq('id', uid)
            .limit(1);
        if (rows.isNotEmpty && mounted) {
          context.read<EconomyProvider>().hydrateFromProfile(
            Map<String, dynamic>.from(rows.first),
          );
        }
      }
    } catch (e, st) {
      AppLog.warn('subscription profile refresh failed: $e');
      AppLog.error('subscription profile refresh', e, st);
    }
    try {
      final order = await _repo.fetchLatestOrder();
      if (mounted) setState(() => _order = order);
    } catch (e, st) {
      AppLog.warn('fetchLatestOrder failed: $e');
      AppLog.error('fetchLatestOrder', e, st);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickReceipt() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      // Bytes only — nothing touches storage until the subscribe tap.
      final bytes = await file.readAsBytes();
      setState(() {
        _receiptBytes = bytes;
        _receiptMime = file.mimeType ?? 'image/jpeg';
      });
    } catch (e, st) {
      AppLog.warn('receipt pick failed: $e');
      AppLog.error('receipt pick', e, st);
      if (mounted) AppToast.show('تعذّر فتح الصورة', isError: true);
    }
  }

  Future<void> _submit() async {
    final op = _opController.text.trim();
    if (op.length < 3) {
      AppToast.show('أدخل رقم العملية', isError: true);
      return;
    }
    if (op.length > 64) {
      AppToast.show('رقم العملية طويل جداً', isError: true);
      return;
    }
    if (_receiptBytes == null || _receiptMime == null) {
      AppToast.show('ارفع صورة إيصال التحويل', isError: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final path = await _repo.uploadReceipt(
        bytes: _receiptBytes!,
        mimeType: _receiptMime!,
      );
      final order = await _repo.submit(operationNumber: op, receiptPath: path);
      if (!mounted) return;
      setState(() {
        _order = order;
        _receiptBytes = null;
        _receiptMime = null;
        _opController.clear();
      });
      AppToast.show('تم إرسال طلب الاشتراك ✅');
    } catch (e, st) {
      AppLog.warn('subscription submit failed: $e');
      AppLog.error('subscription submit', e, st);
      if (mounted) {
        final msg =
            e is PostgrestException &&
                (e.message.contains('pending') ||
                    e.message.contains('subscribed'))
            ? 'عندك طلب قيد المراجعة أو اشتراك فعّال بالفعل'
            : 'تعذّر إرسال الطلب — حاول مرة أخرى';
        AppToast.show(msg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyProvider>();
    final subscribed = economy.isSubscribed;
    final expiresAt = economy.subscriptionExpiresAt;
    final order = _order;

    return Scaffold(
      backgroundColor: HaffarColors.bgPage,
      appBar: AppBar(
        backgroundColor: HaffarColors.bgPage,
        elevation: 0,
        title: Text(
          'اشتراك ${SubscriptionRepository.planName}',
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: HaffarColors.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (subscribed)
                    _activeCard(expiresAt)
                  else if (order != null && order.isPending)
                    _pendingCard(order)
                  else ...[
                    if (order != null && order.isRejected) ...[
                      _rejectedNote(order),
                      const SizedBox(height: 12),
                    ],
                    _planCard(),
                    const SizedBox(height: 12),
                    _stepsCard(),
                    const SizedBox(height: 12),
                    _bankCard(),
                    const SizedBox(height: 16),
                    _formCard(),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'الاشتراك بيتفعّل يدوياً بعد مراجعة التحويل — خلال ٢٤ ساعة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      color: HaffarColors.grey2,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── States ────────────────────────────────────────────────────────────────

  Widget _activeCard(DateTime? expiresAt) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [HaffarColors.primary, HaffarColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 56),
          const SizedBox(height: 12),
          Text(
            'أنت مشترك في ${SubscriptionRepository.planName} 🎉',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'قلوب غير محدودة — ذاكر على راحتك',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          if (expiresAt != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'صالح حتى ${DateFormat('yyyy/MM/dd').format(expiresAt)}',
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pendingCard(SubscriptionOrder order) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: HaffarColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HaffarColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hourglass_top,
            color: HaffarColors.primary,
            size: 52,
          ),
          const SizedBox(height: 12),
          const Text(
            'طلبك قيد المراجعة ⏳',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: HaffarColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'بنراجع التحويل وبنبلغك بإشعار فور الاعتماد',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: HaffarColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: HaffarColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: HaffarColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                _infoRow('رقم العملية', order.operationNumber),
                const SizedBox(height: 8),
                _infoRow(
                  'تاريخ الإرسال',
                  order.createdAt == null
                      ? '—'
                      : DateFormat('yyyy/MM/dd HH:mm').format(order.createdAt!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 14,
            color: HaffarColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: HaffarColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _rejectedNote(SubscriptionOrder order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HaffarColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HaffarColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: HaffarColors.error, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'تم رفض الطلب السابق (رقم العملية ${order.operationNumber}) — تأكد من التحويل وأعد الإرسال',
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HaffarColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form pieces ───────────────────────────────────────────────────────────

  Widget _planCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [HaffarColors.primary, HaffarColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: HaffarColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: HaffarColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    SubscriptionRepository.planName,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'قلوب غير محدودة',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    SubscriptionRepository.planPriceLabel,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'شهرياً',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          _benefit('قلوب غير محدودة في كل الدروس'),
          const SizedBox(height: 10),
          _benefit('ذاكر من غير ما توقف ولا تستنى القلوب'),
          const SizedBox(height: 10),
          _benefit('امتحن على راحتك من غير خوف تغلط'),
        ],
      ),
    );
  }

  Widget _benefit(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepsCard() {
    const steps = [
      'حوّل قيمة الاشتراك (49,000 جنيه) إلى الحساب البنكي أدناه',
      'صوّر إيصال التحويل وسجّل رقم العملية',
      'أرسل الطلب — نراجعه ونفعّل اشتراكك خلال ٢٤ ساعة',
    ];
    return _whiteCard(
      title: 'كيف تشترك؟',
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: HaffarColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps[i],
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 14,
                      height: 1.5,
                      color: HaffarColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (i != steps.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _bankCard() {
    return _whiteCard(
      title: 'بيانات الحساب البنكي',
      child: Column(
        children: [
          _bankRow(
            Icons.account_balance,
            'البنك',
            SubscriptionRepository.bankName,
          ),
          const Divider(height: 20),
          _bankRow(
            Icons.person_outline,
            'صاحب الحساب',
            SubscriptionRepository.accountHolder,
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Icon(Icons.numbers, size: 20, color: HaffarColors.grey2),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'رقم الحساب',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        color: HaffarColors.grey2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      SubscriptionRepository.accountNumber,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: HaffarColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'نسخ',
                icon: const Icon(
                  Icons.copy,
                  size: 20,
                  color: HaffarColors.primary,
                ),
                onPressed: () async {
                  await Clipboard.setData(
                    const ClipboardData(
                      text: SubscriptionRepository.accountNumber,
                    ),
                  );
                  if (mounted) AppToast.show('تم نسخ رقم الحساب');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bankRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: HaffarColors.grey2),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 12,
                  color: HaffarColors.grey2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: HaffarColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _formCard() {
    final hasReceipt = _receiptBytes != null;
    return _whiteCard(
      title: 'بيانات التحويل',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'رقم العملية',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: HaffarColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _opController,
            maxLength: 64,
            keyboardType: TextInputType.text,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              counterText: '',
              hintText: 'مثال: TRX-000123',
              filled: true,
              fillColor: HaffarColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ايصال التحويل (صورة)',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: HaffarColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (!hasReceipt)
            GestureDetector(
              onTap: _submitting ? null : _pickReceipt,
              child: Container(
                height: 110,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HaffarColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HaffarColors.grey5),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 32,
                      color: HaffarColors.primary,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'اضغط لاختيار صورة الإيصال من المعرض',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: HaffarColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'تُرفع الصورة عند إرسال الطلب فقط',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        color: HaffarColors.grey2,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full-size preview so the user can confirm the right photo
                // before subscribing (bytes stay local until the tap).
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: HaffarColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: HaffarColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Image.memory(
                    _receiptBytes!,
                    height: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 120,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: HaffarColors.grey2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: HaffarColors.primary,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'تأكد إن الصورة واضحة ومقروءة قبل الإرسال',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: HaffarColors.textSecondary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _submitting ? null : _pickReceipt,
                      child: const Text(
                        'تغيير الصورة',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: HaffarColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 20),
          HaffarPrimaryButton(
            label: _submitting ? 'جارٍ الإرسال…' : 'إرسال طلب الاشتراك',
            fullWidth: true,
            state: _submitting
                ? HaffarPrimaryButtonState.disabled
                : HaffarPrimaryButtonState.enabled,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _whiteCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HaffarColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HaffarColors.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: HaffarColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
