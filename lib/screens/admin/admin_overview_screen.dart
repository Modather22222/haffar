import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../design_system/colors.dart';
import '../../models/admin_stats.dart';
import '../../services/admin_repository.dart';
import '../../utils/routes.dart';
import 'admin_push_dialog.dart';
import 'admin_widgets.dart';

/// Tab 1 — KPI grid, 14-day lessons/attempts trend and content facts.
class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen>
    with AutomaticKeepAliveClientMixin {
  late final AdminRepository _repo;
  AdminOverview? _data;
  AdminPushHealth? _pushHealth;
  AdminClientErrorsPayload? _clientErrors;
  AdminRetentionPayload? _retention;
  Object? _error;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

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
      final results = await Future.wait([
        _repo.fetchOverview(),
        _repo.fetchPushHealth(),
        _repo.fetchClientErrors(),
        _repo.fetchRetention(),
      ]);
      if (!mounted) return;
      setState(() {
        _data = results[0] as AdminOverview;
        _pushHealth = results[1] as AdminPushHealth;
        _clientErrors = results[2] as AdminClientErrorsPayload;
        _retention = results[3] as AdminRetentionPayload;
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _data == null) return const AdminLoadingView();
    if (_error != null && _data == null) {
      return AdminErrorView(message: adminMessage(_error), onRetry: _load);
    }
    final data = _data!;
    final health = _pushHealth;
    final coverageColor = health == null
        ? HaffarColors.grey3
        : health.coveragePct < 30
        ? kChartRed
        : health.coveragePct < 60
        ? kChartOrange
        : kChartGreen;
    final dayLabels = [
      for (final d in data.series) DateFormat('MM/dd').format(d.day),
    ];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'تعذر التحديث: ${adminMessage(_error)}',
                style: const TextStyle(
                  fontFamily: kAdminFont,
                  fontSize: 12,
                  color: HaffarColors.error,
                ),
              ),
            ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              AdminStatCard(
                label: 'إجمالي المستخدمين',
                value: fmtInt(data.totalUsers),
                icon: Icons.people,
              ),
              AdminStatCard(
                label: 'نشطون اليوم',
                value: fmtInt(data.activeToday),
                icon: Icons.bolt,
                accent: kChartGreen,
              ),
              AdminStatCard(
                label: 'جدد (7 أيام)',
                value: fmtInt(data.newUsers7d),
                icon: Icons.person_add,
                accent: kChartBlue,
              ),
              AdminStatCard(
                label: 'متوسط الدقة',
                value: fmtPct(data.avgAccuracy),
                icon: Icons.track_changes,
                accent: kChartPurple,
              ),
              AdminStatCard(
                label: 'دروس مكتملة',
                value: fmtInt(data.lessonsCompleted),
                icon: Icons.check_circle,
                accent: kChartOrange,
              ),
              AdminStatCard(
                label: 'محاولات إجابة',
                value: fmtInt(data.attempts),
                icon: Icons.quiz,
                accent: kChartRed,
              ),
              AdminStatCard(
                label: 'المشتركون',
                value: fmtInt(data.subscribedUsers),
                icon: Icons.workspace_premium,
                accent: kChartPurple,
                onTap: () => context.push(Routes.adminSubscriptions),
              ),
              AdminStatCard(
                label: 'تغطية الإشعارات',
                value: fmtPct(health?.coveragePct ?? 0),
                icon: Icons.notifications_none,
                accent: coverageColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdminSectionCard(
            title: 'الدوريات',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in data.leagues.entries)
                  _factChip('${_leagueLabel(e.key)}: ${fmtInt(e.value)}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AdminSectionCard(
            title: 'إرسال إشعار',
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => showAdminPushDialog(
                  context: context,
                  repo: _repo,
                  title: 'إرسال إشعار للجميع',
                ),
                icon: const Icon(Icons.notifications_active_outlined, size: 18),
                label: const Text(
                  'إرسال إشعار لجميع المستخدمين',
                  style: TextStyle(fontFamily: kAdminFont),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AdminSectionCard(
            title: 'آخر 14 يوم',
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChartLegendDot(color: kChartBlue, label: 'دروس'),
                SizedBox(width: 10),
                ChartLegendDot(color: kChartOrange, label: 'محاولات'),
              ],
            ),
            child: SizedBox(
              height: 200,
              child: LineChart(
                duration: const Duration(milliseconds: 300),
                LineChartData(
                  minY: 0,
                  gridData: adminGrid(),
                  borderData: adminBorder(),
                  titlesData: axisTitlesFor(dayLabels, step: 2),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => [
                        for (final s in spots)
                          LineTooltipItem(
                            '${s.barIndex == 0 ? 'دروس' : 'محاولات'}: ${s.y.toInt()}',
                            const TextStyle(
                              fontFamily: kAdminFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: HaffarColors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    _series(data.series, (s) => s.lessons, kChartBlue),
                    _series(data.series, (s) => s.attempts, kChartOrange),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_retention != null) ...[
            _retentionCard(_retention!),
            const SizedBox(height: 16),
          ],
          if (_pushHealth != null) ...[
            _pushHealthCard(_pushHealth!),
            const SizedBox(height: 16),
          ],
          if (_clientErrors != null) ...[
            _clientErrorsCard(_clientErrors!),
            const SizedBox(height: 16),
          ],
          AdminSectionCard(
            title: 'المحتوى والكاش',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _factChip('المواد: ${fmtInt(data.subjects)}'),
                _factChip('الدروس: ${fmtInt(data.lessons)}'),
                _factChip('الأسئلة: ${fmtInt(data.questions)}'),
                _factChip(
                  'تمارين الوحدات: ${fmtInt(data.unitExercisesCompleted)}',
                ),
                _factChip('أجهزة Push: ${fmtInt(data.pushTokens)}'),
                _factChip('إشعارات اليوم: ${fmtInt(data.notificationsToday)}'),
                _factChip('جدد (30 يوم): ${fmtInt(data.newUsers30d)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _series<T>(
    List<T> items,
    num? Function(T) value,
    Color color,
  ) {
    return LineChartBarData(
      isCurved: true,
      preventCurveOverShooting: true,
      barWidth: 3,
      color: color,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
      spots: [
        for (var i = 0; i < items.length; i++)
          if (value(items[i]) != null)
            FlSpot(i.toDouble(), value(items[i])!.toDouble()),
      ],
    );
  }

  Widget _retentionCard(AdminRetentionPayload p) {
    final s = p.summary;
    final cohorts = p.cohorts;
    if (cohorts.length < 2) {
      return const AdminSectionCard(
        title: 'الاحتفاظ (D1 / D7 / D30)',
        child: AdminEmptyText('بيانات غير كافية بعد'),
      );
    }
    final labels = [
      for (final c in cohorts)
        c.date != null ? DateFormat('MM/dd').format(c.date!) : '—',
    ];
    return AdminSectionCard(
      title: 'الاحتفاظ (D1 / D7 / D30)',
      trailing: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChartLegendDot(color: kChartGreen, label: 'D1'),
          SizedBox(width: 8),
          ChartLegendDot(color: kChartBlue, label: 'D7'),
          SizedBox(width: 8),
          ChartLegendDot(color: kChartPurple, label: 'D30'),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _retentionRate('D1', s.d1, s.eligible1, kChartGreen),
              ),
              Expanded(
                child: _retentionRate('D7', s.d7, s.eligible7, kChartBlue),
              ),
              Expanded(
                child: _retentionRate('D30', s.d30, s.eligible30, kChartPurple),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${fmtInt(s.days)} يوم • ${fmtInt(s.users)} مستخدم جديد • '
            'الناضج: D1 ${fmtInt(s.eligible1)} / D7 ${fmtInt(s.eligible7)} / '
            'D30 ${fmtInt(s.eligible30)}',
            style: const TextStyle(
              fontFamily: kAdminFont,
              fontSize: 11,
              color: HaffarColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: LineChart(
              duration: const Duration(milliseconds: 300),
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: adminGrid(),
                borderData: adminBorder(),
                titlesData: axisTitlesFor(labels, step: 2),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => [
                      for (final spt in spots)
                        LineTooltipItem(
                          '${spt.barIndex == 0
                              ? 'D1'
                              : spt.barIndex == 1
                              ? 'D7'
                              : 'D30'}: '
                          '${spt.y.toStringAsFixed(1)}%',
                          const TextStyle(
                            fontFamily: kAdminFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: HaffarColors.white,
                          ),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  _series(cohorts, (c) => c.d1, kChartGreen),
                  _series(cohorts, (c) => c.d7, kChartBlue),
                  _series(cohorts, (c) => c.d30, kChartPurple),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _retentionRate(String label, double value, int eligible, Color color) {
    return Column(
      children: [
        Text(
          eligible == 0 ? '—' : fmtPct(value),
          style: TextStyle(
            fontFamily: kAdminFont,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: eligible == 0 ? HaffarColors.grey3 : color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: kAdminFont,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: HaffarColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _leagueLabel(String league) => switch (league) {
    'bronze' => 'برونزي',
    'silver' => 'فضي',
    'gold' => 'ذهبي',
    'mvp' => 'MVP',
    _ => league,
  };

  Widget _pushHealthCard(AdminPushHealth h) {
    final sends14d = h.log14d.fold<int>(0, (sum, e) => sum + e.sends);
    final coverageColor = h.coveragePct < 30
        ? kChartRed
        : h.coveragePct < 60
        ? kChartOrange
        : kChartGreen;
    final devices = h.devices.take(4).toList();
    return AdminSectionCard(
      title: 'صحة الإشعارات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                fmtPct(h.coveragePct),
                style: TextStyle(
                  fontFamily: kAdminFont,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: coverageColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تغطية التسجيل — ${fmtInt(h.tokensUsers)} مستخدم من '
                  '${fmtInt(h.usersTotal)} (${fmtInt(h.tokensTotal)} جهاز)',
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 12,
                    color: HaffarColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in h.platforms.entries)
                _factChip('${p.key}: ${fmtInt(p.value)}'),
              _factChip('رسائل (14 يوم): ${fmtInt(sends14d)}'),
              if (h.lastRegisteredAt != null)
                _factChip(
                  'آخر تسجيل: ${DateFormat('MM/dd').format(h.lastRegisteredAt!)}',
                ),
            ],
          ),
          if (devices.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'الأجهزة المسجلة:',
              style: TextStyle(
                fontFamily: kAdminFont,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: HaffarColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            for (final d in devices)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      d.platform == 'ios' ? Icons.phone_iphone : Icons.android,
                      size: 14,
                      color: HaffarColors.grey3,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${d.displayName.isEmpty ? '—' : d.displayName} • '
                        '${DateFormat('MM/dd HH:mm').format(d.updatedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: kAdminFont,
                          fontSize: 12,
                          color: HaffarColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (h.devices.length > devices.length)
              Text(
                '+${fmtInt(h.devices.length - devices.length)} جهاز آخر',
                style: const TextStyle(
                  fontFamily: kAdminFont,
                  fontSize: 11,
                  color: HaffarColors.grey3,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _clientErrorsCard(AdminClientErrorsPayload p) {
    final groups = p.groups.take(8).toList();
    return AdminSectionCard(
      title: 'أخطاء التطبيق',
      trailing: Text(
        '${fmtInt(p.totalEvents)} حدث',
        style: const TextStyle(
          fontFamily: kAdminFont,
          fontSize: 11,
          color: HaffarColors.textSecondary,
        ),
      ),
      child: p.groups.isEmpty
          ? const AdminEmptyText('لا توجد أخطاء مُبلَّغة')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final g in groups) ...[_errorTile(g)],
                if (p.groups.length > groups.length)
                  Text(
                    '+${fmtInt(p.groups.length - groups.length)} خطأ آخر',
                    style: const TextStyle(
                      fontFamily: kAdminFont,
                      fontSize: 11,
                      color: HaffarColors.grey3,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _errorTile(AdminErrorGroup g) {
    final meta = [
      if (g.appVersion != null && g.appVersion!.isNotEmpty) g.appVersion!,
      if (g.platform != null && g.platform!.isNotEmpty) g.platform!,
      '${fmtInt(g.users)} مستخدم',
      if (g.latestAt != null)
        DateFormat('MM/dd HH:mm').format(g.latestAt!.toLocal()),
    ].join(' • ');
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
        dense: true,
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: HaffarColors.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            fmtInt(g.count),
            style: const TextStyle(
              fontFamily: kAdminFont,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: HaffarColors.error,
            ),
          ),
        ),
        title: Text(
          g.message.isEmpty ? g.fingerprint : g.message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: kAdminFont,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: HaffarColors.textPrimary,
          ),
        ),
        subtitle: Text(
          meta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: kAdminFont,
            fontSize: 11,
            color: HaffarColors.textSecondary,
          ),
        ),
        children: [
          if (g.message.isNotEmpty && g.message.length > 40)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                g.message,
                style: const TextStyle(
                  fontFamily: kAdminFont,
                  fontSize: 11,
                  color: HaffarColors.textPrimary,
                ),
              ),
            ),
          if (g.stack.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HaffarColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  g.stack,
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 10,
                    color: HaffarColors.textSecondary,
                  ),
                ),
              ),
            ),
          if (g.device != null && g.device!.isNotEmpty)
            Text(
              'الجهاز: ${g.device}',
              style: const TextStyle(
                fontFamily: kAdminFont,
                fontSize: 10,
                color: HaffarColors.grey3,
              ),
            ),
          Text(
            'البصمة: ${g.fingerprint}',
            style: const TextStyle(
              fontFamily: kAdminFont,
              fontSize: 10,
              color: HaffarColors.grey3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _factChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: HaffarColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: kAdminFont,
          fontSize: 12,
          color: HaffarColors.textPrimary,
        ),
      ),
    );
  }
}
