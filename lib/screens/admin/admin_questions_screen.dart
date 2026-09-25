import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../design_system/colors.dart';
import '../../models/admin_stats.dart';
import '../../services/admin_repository.dart';
import 'admin_widgets.dart';

/// "أسئلة تحتاج مراجعة" — per-question accuracy list from
/// admin_question_stats (hardest first). Route: /admin/questions
///
/// Flags content problems: <40% accuracy across real attempts usually means
/// a broken answer key or unclear wording; >95% means too easy/guessable.
class AdminQuestionsScreen extends StatefulWidget {
  const AdminQuestionsScreen({super.key});

  @override
  State<AdminQuestionsScreen> createState() => _AdminQuestionsScreenState();
}

enum _QuestionFilter { all, tooHard, tooEasy }

class _AdminQuestionsScreenState extends State<AdminQuestionsScreen> {
  late final AdminRepository _repo;
  AdminQuestionStatsPayload? _payload;
  Object? _error;
  bool _loading = true;
  _QuestionFilter _filter = _QuestionFilter.all;

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
      final payload = await _repo.fetchQuestionStats();
      if (!mounted) return;
      setState(() {
        _payload = payload;
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

  List<AdminQuestionStat> get _visible {
    final all = _payload?.questions ?? const <AdminQuestionStat>[];
    switch (_filter) {
      case _QuestionFilter.tooHard:
        return all.where((q) => q.isTooHard).toList();
      case _QuestionFilter.tooEasy:
        return all.where((q) => q.isTooEasy).toList();
      case _QuestionFilter.all:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _payload == null) {
      return Scaffold(appBar: _appBar(), body: const AdminLoadingView());
    }
    if (_error != null && _payload == null) {
      return Scaffold(
        appBar: _appBar(),
        body: AdminErrorView(message: adminMessage(_error), onRetry: _load),
      );
    }
    final payload = _payload!;
    final visible = _visible;
    final tooHard = payload.questions.where((q) => q.isTooHard).length;
    final tooEasy = payload.questions.where((q) => q.isTooEasy).length;
    return Scaffold(
      appBar: _appBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AdminSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${fmtInt(payload.questionsAnswered)} من '
                      '${fmtInt(payload.questionsTotal)} سؤال له إجابات '
                      '(${fmtInt(payload.answersTotal)} إجابة — '
                      'الحد الأدنى ${fmtInt(payload.minAttempts)})',
                      style: const TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 13,
                        color: HaffarColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _countChip('تحتاج مراجعة: $tooHard', kChartRed),
                        _countChip('سهلة جداً: $tooEasy', kChartPurple),
                        _countChip(
                          'ضمن الحدود: '
                          '${fmtInt(payload.questions.length - tooHard - tooEasy)}',
                          kChartGreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<_QuestionFilter>(
                segments: const [
                  ButtonSegment(
                    value: _QuestionFilter.all,
                    label: Text(
                      'الكل',
                      style: TextStyle(fontFamily: kAdminFont),
                    ),
                  ),
                  ButtonSegment(
                    value: _QuestionFilter.tooHard,
                    label: Text(
                      'تحتاج مراجعة',
                      style: TextStyle(fontFamily: kAdminFont),
                    ),
                  ),
                  ButtonSegment(
                    value: _QuestionFilter.tooEasy,
                    label: Text(
                      'سهلة جداً',
                      style: TextStyle(fontFamily: kAdminFont),
                    ),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (s) => setState(() => _filter = s.first),
                showSelectedIcon: false,
                style: ButtonStyle(
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontFamily: kAdminFont, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                const AdminEmptyText('لا توجد أسئلة في هذا الفلتر')
              else
                for (final q in visible) _QuestionCard(question: q),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    title: const Text('أسئلة تحتاج مراجعة'),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).maybePop(),
    ),
  );

  Widget _countChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: kAdminFont,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final AdminQuestionStat question;

  const _QuestionCard({required this.question});

  Color get _flagColor => question.isTooHard
      ? kChartRed
      : question.isTooEasy
      ? kChartPurple
      : kChartGreen;

  String get _flagLabel => question.isTooHard
      ? 'تحتاج مراجعة'
      : question.isTooEasy
      ? 'سهلة جداً'
      : 'ضمن الحدود';

  String get _typeLabel {
    switch (question.type) {
      case 'multipleChoice':
        return 'اختيار من متعدد';
      case 'trueFalse':
        return 'صح/خطأ';
      case 'fillBlank':
        return 'ملء فراغ';
      case 'matching':
        return 'ربط';
      case 'ordering':
        return 'ترتيب';
      case 'definition':
        return 'تعريف';
      case 'reading':
        return 'قراءة';
      case 'calculation':
        return 'حساب';
      case 'explanation':
        return 'شرح';
      case 'diagram':
        return 'رسم';
      case 'classification':
        return 'تصنيف';
      case 'composition':
        return 'تأليفي';
      default:
        return question.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HaffarColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HaffarColors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _flagColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  fmtPct(question.accuracy),
                  style: TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _flagColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: HaffarColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${question.subjectName} • درس ${question.lessonIndex + 1} • $_typeLabel',
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _chip(_flagLabel, _flagColor),
              _chip('إجابات: ${fmtInt(question.attempts)}', HaffarColors.grey2),
              _chip('طلاب: ${fmtInt(question.users)}', HaffarColors.grey2),
              if (question.difficulty != null)
                _chip(question.difficulty!, HaffarColors.grey2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontFamily: kAdminFont, fontSize: 10, color: color),
      ),
    );
  }
}
