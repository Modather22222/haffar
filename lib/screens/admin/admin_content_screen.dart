import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../design_system/colors.dart';
import '../../models/admin_stats.dart';
import '../../services/admin_repository.dart';
import '../../utils/routes.dart';
import 'admin_widgets.dart';

/// Tab 3 — content inventory per subject: unit/lesson/question counts,
/// question-type split (pie chart), difficulty split and per-lesson
/// completion bars (admin_content_stats RPC).
class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen>
    with AutomaticKeepAliveClientMixin {
  late final AdminRepository _repo;
  List<AdminSubjectStat>? _subjects;
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
      final subjects = await _repo.fetchContentStats();
      if (!mounted) return;
      setState(() {
        _subjects = subjects;
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
    if (_loading && _subjects == null) return const AdminLoadingView();
    if (_error != null && _subjects == null) {
      return AdminErrorView(message: adminMessage(_error), onRetry: _load);
    }
    final subjects = _subjects!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subjects.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return const Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _ContentEditorEntry(),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _QuestionAuditEntry(),
                ),
              ],
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SubjectCard(stat: subjects[i - 1]),
          );
        },
      ),
    );
  }
}

/// Entry tile for the full content editor (/admin/content/editor).
class _ContentEditorEntry extends StatelessWidget {
  const _ContentEditorEntry();

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push(Routes.adminContentEditor),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HaffarColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit_note_outlined,
                  size: 20,
                  color: HaffarColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'محرر المحتوى',
                      style: TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: HaffarColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'إضافة وتعديل المواد والوحدات والدروس والأسئلة بصيغة غنية',
                      style: TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 11,
                        color: HaffarColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: HaffarColors.grey3),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entry tile for the per-question accuracy audit (/admin/questions).
class _QuestionAuditEntry extends StatelessWidget {
  const _QuestionAuditEntry();

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push(Routes.adminQuestions),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HaffarColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  size: 20,
                  color: HaffarColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'فحص الأسئلة',
                      style: TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: HaffarColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'دقة كل سؤال حسب إجابات الطلاب — اكتشف المفاتيح الخاطئة',
                      style: TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 11,
                        color: HaffarColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: HaffarColors.grey3),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final AdminSubjectStat stat;

  const _SubjectCard({required this.stat});

  static const _pieColors = [
    kChartBlue,
    kChartOrange,
    kChartGreen,
    kChartPurple,
    kChartRed,
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF6366F1),
  ];

  Color get _accent {
    final hex = stat.colorHex;
    if (hex != null && hex.length == 7 && hex.startsWith('#')) {
      final value = int.tryParse(hex.substring(1), radix: 16);
      if (value != null) return Color(0xFF00000000 | value);
    }
    return HaffarColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final types = stat.questionTypes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var maxLesson = 1;
    for (final l in stat.lessonsDetail) {
      if (l.completedBy > maxLesson) maxLesson = l.completedBy;
    }
    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stat.name,
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: HaffarColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${fmtInt(stat.completions)} إكمال',
                style: const TextStyle(
                  fontFamily: kAdminFont,
                  fontSize: 12,
                  color: HaffarColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip('وحدات: ${fmtInt(stat.units)}'),
              _chip('دروس: ${fmtInt(stat.lessons)}'),
              _chip('أسئلة: ${fmtInt(stat.questions)}'),
              for (final e in stat.difficulties.entries)
                _chip('${e.key}: ${fmtInt(e.value)}'),
            ],
          ),
          if (types.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 26,
                        sections: [
                          for (var i = 0; i < types.length; i++)
                            PieChartSectionData(
                              value: types[i].value.toDouble(),
                              color: _pieColors[i % _pieColors.length],
                              radius: 34,
                              title: '',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < types.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: ChartLegendDot(
                                color: _pieColors[i % _pieColors.length],
                                label:
                                    '${types[i].key} (${fmtInt(types[i].value)})',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (stat.lessonsDetail.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'إكمال الدروس',
              style: TextStyle(
                fontFamily: kAdminFont,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: HaffarColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            for (var li = 0; li < stat.lessonsDetail.length; li++)
              _lessonCompletionRow(stat.lessonsDetail[li], li + 1, maxLesson),
          ],
        ],
      ),
    );
  }

  Widget _lessonCompletionRow(AdminLessonStat l, int number, int maxLesson) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$number. ${l.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 12,
                    color: HaffarColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                fmtInt(l.completedBy),
                style: const TextStyle(
                  fontFamily: kAdminFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: HaffarColors.textPrimary,
                ),
              ),
              if (l.attempts > 0) ...[
                const SizedBox(width: 6),
                Text(
                  fmtPct(l.accuracy ?? 0),
                  style: TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: (l.accuracy ?? 0) < 50 ? kChartRed : kChartGreen,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: l.completedBy / maxLesson,
              minHeight: 6,
              backgroundColor: HaffarColors.surfaceHigh,
              valueColor: AlwaysStoppedAnimation(_accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: HaffarColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: kAdminFont,
          fontSize: 11,
          color: HaffarColors.textPrimary,
        ),
      ),
    );
  }
}
