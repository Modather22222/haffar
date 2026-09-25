import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../design_system/colors.dart';
import '../../models/admin_stats.dart';
import '../../services/admin_repository.dart';
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
      final data = await _repo.fetchOverview();
      if (!mounted) return;
      setState(() {
        _data = data;
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
            ],
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

  LineChartBarData _series(
    List<AdminDayStat> series,
    num Function(AdminDayStat) value,
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
        for (var i = 0; i < series.length; i++)
          FlSpot(i.toDouble(), value(series[i]).toDouble()),
      ],
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
