import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../design_system/colors.dart';
import '../../models/admin_stats.dart';
import '../../services/admin_repository.dart';
import '../../utils/app_toast.dart';
import 'admin_widgets.dart';

/// One user's full profile: stats, per-subject progress, recent activity
/// and the admin actions (targeted push + streak/hearts/progress resets).
/// Route: `adminUser` with an `id` query parameter.
class AdminUserDetailScreen extends StatefulWidget {
  final String userId;

  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late final AdminRepository _repo;
  AdminUserDetail? _detail;
  Object? _error;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _repo = AdminRepository(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _repo.fetchUserDetail(widget.userId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _runGuarded(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmReset(AdminResetTarget target, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تأكيد: $label',
          style: const TextStyle(
            fontFamily: kAdminFont,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'سيتم $label لهذا المستخدم. لا يمكن التراجع.',
          style: const TextStyle(
            fontFamily: kAdminFont,
            fontSize: 14,
            color: HaffarColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: kAdminFont),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: kAdminFont,
                color: HaffarColors.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runGuarded(() async {
      try {
        await _repo.resetUser(userId: widget.userId, target: target);
        await _load();
        if (mounted) AppToast.success('تم: $label');
      } catch (e) {
        if (mounted) {
          AppToast.error(
            e,
            fallback: 'تعذر تنفيذ العملية',
            logContext: 'admin_reset',
          );
        }
      }
    });
  }

  Future<void> _sendPushDialog() async {
    final ctrl = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'إرسال إشعار لهذا المستخدم',
          style: TextStyle(
            fontFamily: kAdminFont,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'نص الإشعار…',
            hintStyle: TextStyle(fontFamily: kAdminFont, fontSize: 14),
          ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'إرسال',
              style: TextStyle(fontFamily: kAdminFont),
            ),
          ),
        ],
      ),
    );
    if (sent != true || ctrl.text.trim().isEmpty || !mounted) return;
    final body = ctrl.text.trim();
    await _runGuarded(() async {
      try {
        final result = await _repo.sendNotification(
          body: body,
          userId: widget.userId,
        );
        if (mounted) {
          AppToast.success('تم الإرسال إلى ${result.targets} جهاز');
        }
      } catch (e) {
        if (mounted) {
          AppToast.error(
            e,
            fallback: 'تعذر إرسال الإشعار',
            logContext: 'admin_push',
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _detail == null) {
      return Scaffold(appBar: _appBar(), body: const AdminLoadingView());
    }
    if (_error != null && _detail == null) {
      return Scaffold(
        appBar: _appBar(),
        body: AdminErrorView(message: adminMessage(_error), onRetry: _load),
      );
    }
    final d = _detail!;
    final p = d.profile;
    return Scaffold(
      appBar: _appBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _headerCard(d),
              const SizedBox(height: 12),
              _statsCard(d),
              const SizedBox(height: 12),
              _actionsCard(),
              const SizedBox(height: 12),
              _subjectsCard(d),
              const SizedBox(height: 12),
              _attemptsCard(d),
              if (p.isAdmin) ...[
                const SizedBox(height: 12),
                const AdminSectionCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: HaffarColors.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'هذا المستخدم أدمن — العمليات مسموحة له من الخادم',
                        style: TextStyle(
                          fontFamily: kAdminFont,
                          fontSize: 13,
                          color: HaffarColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    title: const Text('تفاصيل المستخدم'),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).maybePop(),
    ),
  );

  Widget _headerCard(AdminUserDetail d) {
    final p = d.profile;
    final name = p.displayName.isEmpty ? p.email : p.displayName;
    return AdminSectionCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: HaffarColors.primary.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0] : '؟',
              style: const TextStyle(
                fontFamily: kAdminFont,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: HaffarColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: HaffarColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 12,
                    color: HaffarColors.grey2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'انضم ${DateFormat('yyyy/MM/dd').format(p.createdAt)}',
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 11,
                    color: HaffarColors.grey2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsCard(AdminUserDetail d) {
    final p = d.profile;
    final items = <(String, String, IconData, Color)>[
      ('XP', fmtInt(p.xp), Icons.star, kChartOrange),
      ('السلسلة', fmtInt(p.streak), Icons.local_fire_department, kChartRed),
      ('الجواهر', fmtInt(p.gems), Icons.diamond, kChartPurple),
      ('الأرواح', fmtInt(p.hearts), Icons.favorite, kChartRed),
      ('الدروس', fmtInt(p.lessonsDone), Icons.school, kChartBlue),
      ('الوحدات', fmtInt(d.unitsDone), Icons.grid_view, kChartGreen),
      ('المحاولات', fmtInt(d.attempts), Icons.quiz, kChartBlue),
      ('الدقة', fmtPct(d.accuracy), Icons.track_changes, kChartPurple),
    ];
    return AdminSectionCard(
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
        children: [
          for (final (label, value, icon, color) in items)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: HaffarColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: kAdminFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: HaffarColors.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: kAdminFont,
                      fontSize: 9,
                      color: HaffarColors.grey2,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionsCard() {
    return AdminSectionCard(
      title: 'إجراءات أدمن',
      child: AbsorbPointer(
        absorbing: _busy,
        child: Opacity(
          opacity: _busy ? 0.6 : 1,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendPushDialog,
                  icon: const Icon(Icons.notifications_active, size: 18),
                  label: const Text(
                    'إرسال إشعار',
                    style: TextStyle(fontFamily: kAdminFont),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _confirmReset(
                        AdminResetTarget.streak,
                        'تصفير السلسلة',
                      ),
                      child: const Text(
                        'تصفير السلسلة',
                        style: TextStyle(fontFamily: kAdminFont, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _confirmReset(
                        AdminResetTarget.hearts,
                        'استعادة الأرواح',
                      ),
                      child: const Text(
                        'استعادة الأرواح',
                        style: TextStyle(fontFamily: kAdminFont, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _confirmReset(
                    AdminResetTarget.progress,
                    'مسح التقدم كاملاً',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HaffarColors.error,
                    side: const BorderSide(color: HaffarColors.error),
                  ),
                  child: const Text(
                    'مسح التقدم كاملاً',
                    style: TextStyle(fontFamily: kAdminFont, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subjectsCard(AdminUserDetail d) {
    if (d.bySubject.isEmpty) {
      return const AdminSectionCard(
        title: 'التقدم حسب المادة',
        child: AdminEmptyText('لا يوجد تقدم بعد'),
      );
    }
    return AdminSectionCard(
      title: 'التقدم حسب المادة',
      child: Column(
        children: [
          for (final s in d.bySubject) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.name,
                    style: const TextStyle(
                      fontFamily: kAdminFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${fmtInt(s.completed)}/${fmtInt(s.total)}',
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 12,
                    color: HaffarColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: s.total == 0 ? 0 : s.completed / s.total,
                minHeight: 8,
                backgroundColor: HaffarColors.surfaceHigh,
                valueColor: const AlwaysStoppedAnimation(HaffarColors.primary),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _attemptsCard(AdminUserDetail d) {
    final attempts = d.recentAttempts;
    final xp = d.recentXp;
    final hearts = d.recentHearts;
    return AdminSectionCard(
      title: 'آخر النشاط',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (attempts.isEmpty && xp.isEmpty && hearts.isEmpty)
            const AdminEmptyText('لا يوجد نشاط حديث'),
          for (final a in attempts)
            _activityRow(
              icon: Icons.quiz,
              color: kChartBlue,
              title: '${a.kind} #${a.refIndex} — ${fmtPct(a.accuracy)}',
              subtitle: '${a.correct} من ${a.total} • ${_date(a.createdAt)}',
            ),
          for (final e in xp)
            _activityRow(
              icon: Icons.star,
              color: kChartOrange,
              title: '+${fmtInt(e.amount)} XP — ${e.source}',
              subtitle: _date(e.createdAt),
            ),
          for (final h in hearts)
            _activityRow(
              icon: h.delta >= 0 ? Icons.favorite : Icons.favorite_border,
              color: kChartRed,
              title:
                  '${h.delta >= 0 ? '+' : ''}${fmtInt(h.delta)} روح — ${h.reason}',
              subtitle: _date(h.createdAt),
            ),
        ],
      ),
    );
  }

  Widget _activityRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: HaffarColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 11,
                    color: HaffarColors.grey2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _date(DateTime dt) => DateFormat('yyyy/MM/dd HH:mm').format(dt);
}
