import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../design_system/colors.dart';

/// Shared building blocks for the admin dashboard screens: KPI cards,
/// section cards, loading/error states and fl_chart axis helpers.

const String kAdminFont = 'BeVietnamPro';

/// Western digits with thousands separators (Arabic locale, Latin numerals).
String fmtInt(int value) => NumberFormat.decimalPattern('en').format(value);

String fmtPct(double value) => '${value.toStringAsFixed(1)}%';

/// Maps a caught RPC/network error to a short Arabic message.
String adminMessage(Object? error) {
  final s = error?.toString() ?? '';
  if (s.contains('not authorized')) return 'غير مصرح — هذه العملية للأدمن فقط';
  if (s.contains('SocketException') ||
      s.contains('TimeoutException') ||
      s.contains('timeout') ||
      s.contains('Failed host')) {
    return 'تحقق من الاتصال بالإنترنت';
  }
  return 'تعذر تحميل البيانات';
}

/// Compact chart colors that read well on the warm off-white background.
const Color kChartBlue = Color(0xFF3B82F6);
const Color kChartOrange = Color(0xFFF59E0B);
const Color kChartGreen = Color(0xFF10B981);
const Color kChartPurple = Color(0xFF8B5CF6);
const Color kChartRed = Color(0xFFEF4444);

/// A single KPI tile (label + big value + icon). [onTap] makes the whole
/// tile pressable (e.g. المشتركون → الاشتراك screen).
class AdminStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = HaffarColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HaffarColors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
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
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: kAdminFont,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: HaffarColors.textPrimary,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

/// White rounded card with an optional title, used for every dashboard
/// section (charts, lists, action groups).
class AdminSectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const AdminSectionCard({
    super.key,
    this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: HaffarColors.white,
        borderRadius: BorderRadius.circular(16),
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
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: const TextStyle(
                      fontFamily: kAdminFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: HaffarColors.textPrimary,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Full-size centered spinner.
class AdminLoadingView extends StatelessWidget {
  const AdminLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Error state with retry — used by every tab body.
class AdminErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AdminErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 42,
              color: HaffarColors.grey2,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: kAdminFont,
                fontSize: 14,
                color: HaffarColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontFamily: kAdminFont),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Nothing here yet" text used inside list sections.
class AdminEmptyText extends StatelessWidget {
  final String message;

  const AdminEmptyText(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: kAdminFont,
          fontSize: 13,
          color: HaffarColors.grey2,
        ),
      ),
    );
  }
}

/// Horizontal legend chip used above/below charts.
class ChartLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const ChartLegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: kAdminFont,
            fontSize: 12,
            color: HaffarColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Bottom x-axis titles for a chart whose categories map 1:1 to
/// [labels] (index = spot/bar x). [step] shows every n-th label so long
/// ranges stay readable.
FlTitlesData axisTitlesFor(
  List<String> labels, {
  int step = 1,
  bool showY = true,
}) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: showY
        ? const AxisTitles(sideTitles: SideTitles(showTitles: true))
        : const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        interval: 1,
        getTitlesWidget: (value, meta) {
          final i = value.toInt();
          if (i < 0 || i >= labels.length || i % step != 0) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              labels[i],
              style: const TextStyle(
                fontFamily: kAdminFont,
                fontSize: 10,
                color: HaffarColors.grey2,
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Subtle horizontal-only grid (dates on x, counts on y).
FlGridData adminGrid() => FlGridData(
  show: true,
  drawVerticalLine: false,
  horizontalInterval: null,
  getDrawingHorizontalLine: (_) =>
      FlLine(color: HaffarColors.grey6, strokeWidth: 1),
);

FlBorderData adminBorder() => FlBorderData(show: true, border: const Border());
