import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../design_system/colors.dart';
import '../../models/admin_stats.dart';
import '../../services/admin_repository.dart';
import 'admin_widgets.dart';

/// Tab 4 — activity trends for the last 7/30 days (admin_activity RPC):
/// grouped bars for lessons+attempts, lines for signups+active users.
class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen>
    with AutomaticKeepAliveClientMixin {
  late final AdminRepository _repo;
  List<AdminDayStat>? _days;
  Object? _error;
  bool _loading = true;
  int _range = 7;

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
      final days = await _repo.fetchActivity(days: _range);
      if (!mounted) return;
      setState(() {
        _days = days;
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

  void _setRange(int days) {
    if (_range == days) return;
    setState(() => _range = days);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _days == null) return const AdminLoadingView();
    if (_error != null && _days == null) {
      return AdminErrorView(message: adminMessage(_error), onRetry: _load);
    }
    final days = _days!;
    final labels = [for (final d in days) DateFormat('MM/dd').format(d.day)];
    final step = days.length > 10 ? 3 : 1;

    int sum(int Function(AdminDayStat) pick) =>
        days.fold(0, (acc, d) => acc + pick(d));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 7,
                label: Text('7 أيام', style: TextStyle(fontFamily: kAdminFont)),
              ),
              ButtonSegment(
                value: 30,
                label: Text('30 يوم', style: TextStyle(fontFamily: kAdminFont)),
              ),
            ],
            selected: {_range},
            onSelectionChanged: (s) => _setRange(s.first),
            showSelectedIcon: false,
            style: ButtonStyle(
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontFamily: kAdminFont, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AdminSectionCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _sumChip('دروس', sum((d) => d.lessons)),
                _sumChip('محاولات', sum((d) => d.attempts)),
                _sumChip('تسجيلات', sum((d) => d.signups)),
                _sumChip('XP', sum((d) => d.xp)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AdminSectionCard(
            title: 'الدروس والمحاولات',
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
              child: BarChart(
                duration: const Duration(milliseconds: 300),
                BarChartData(
                  barGroups: [
                    for (var i = 0; i < days.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: days[i].lessons.toDouble(),
                            color: kChartBlue,
                            width: 5,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          BarChartRodData(
                            toY: days[i].attempts.toDouble(),
                            color: kChartOrange,
                            width: 5,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                  ],
                  gridData: adminGrid(),
                  borderData: adminBorder(),
                  titlesData: axisTitlesFor(labels, step: step),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                        '${ri == 0 ? 'دروس' : 'محاولات'}: ${rod.toY.toInt()}',
                        const TextStyle(
                          fontFamily: kAdminFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: HaffarColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AdminSectionCard(
            title: 'التسجيلات والنشطون',
            trailing: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChartLegendDot(color: kChartGreen, label: 'تسجيلات'),
                SizedBox(width: 10),
                ChartLegendDot(color: kChartPurple, label: 'نشطون'),
              ],
            ),
            child: SizedBox(
              height: 180,
              child: LineChart(
                duration: const Duration(milliseconds: 300),
                LineChartData(
                  minY: 0,
                  gridData: adminGrid(),
                  borderData: adminBorder(),
                  titlesData: axisTitlesFor(labels, step: step),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => [
                        for (final s in spots)
                          LineTooltipItem(
                            '${s.barIndex == 0 ? 'تسجيلات' : 'نشطون'}: ${s.y.toInt()}',
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
                    LineChartBarData(
                      isCurved: true,
                      barWidth: 3,
                      color: kChartGreen,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: kChartGreen.withValues(alpha: 0.08),
                      ),
                      spots: [
                        for (var i = 0; i < days.length; i++)
                          FlSpot(i.toDouble(), days[i].signups.toDouble()),
                      ],
                    ),
                    LineChartBarData(
                      isCurved: true,
                      barWidth: 3,
                      color: kChartPurple,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: kChartPurple.withValues(alpha: 0.08),
                      ),
                      spots: [
                        for (var i = 0; i < days.length; i++)
                          FlSpot(i.toDouble(), days[i].activeUsers.toDouble()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumChip(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: HaffarColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            fmtInt(value),
            style: const TextStyle(
              fontFamily: kAdminFont,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: HaffarColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: kAdminFont,
              fontSize: 11,
              color: HaffarColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
