import '../design_system/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../providers/economy_provider.dart';
import '../providers/progress_provider.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../models/unit.dart';
import '../services/lesson_unlocks.dart';
import '../utils/routes.dart';
import '../widgets/markdown_text.dart';
import '../widgets/mascot.dart';

class LessonDetailScreen extends StatefulWidget {
  final String subjectId;
  final int lessonIndex;

  const LessonDetailScreen({
    super.key,
    required this.subjectId,
    required this.lessonIndex,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late String _subjectName;
  late Lesson? _lesson;
  late int _lessonOrdinal;
  late List<Question> _quizQuestions;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final content = context.read<ContentProvider>();
    _subjectName =
        content.subjectById(widget.subjectId)?.name ?? widget.subjectId;
    _lesson = content.lessonOf(widget.subjectId, widget.lessonIndex);
    // Display ordinal (position in the subject) — lesson_index may have gaps.
    final lessons = content.lessonsOf(widget.subjectId);
    final pos = lessons.indexWhere((l) => l.index == widget.lessonIndex);
    _lessonOrdinal = pos >= 0 ? pos + 1 : widget.lessonIndex + 1;
    _quizQuestions = buildLessonQuiz(
      subjectId: widget.subjectId,
      lessonIndex: widget.lessonIndex,
      pool: content.getQuestions(widget.subjectId, widget.lessonIndex),
    );
  }

  void _back() {
    context.pop();
  }

  String get _lessonTitle =>
      _lesson?.title ?? 'درس ${Unit.toArabicNumeral(_lessonOrdinal)}';

  /// Lesson content body with a graceful placeholder instead of an empty
  /// box: the lesson may be missing (hidden draft / removed) or published
  /// without content yet.
  Widget _summaryBody() {
    final lesson = _lesson;
    const style = TextStyle(
      fontFamily: 'BeVietnamPro',
      fontSize: 14,
      height: 1.6,
      color: HaffarColors.textSecondary,
    );
    if (lesson == null) {
      return const Text(
        'هذا الدرس غير متاح حالياً',
        textAlign: TextAlign.center,
        style: style,
      );
    }
    if (lesson.summary.trim().isEmpty) {
      return const Text(
        'سيظهر محتوى الدرس هنا قريباً',
        textAlign: TextAlign.center,
        style: style,
      );
    }
    return MarkdownText(lesson.summary);
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HaffarColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _lessonTitle,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Mascot(pose: MascotPose.study, size: 56),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'محتوى الدرس',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: HaffarColors.outline.withValues(alpha: 0.2),
              ),
            ),
            child: _summaryBody(),
          ),
          const SizedBox(height: 20),
          const Text(
            'نقاط مهمة',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...(_lesson?.keyPoints ?? const <String>[]).map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 20,
                    color: HaffarColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MarkdownText(
                      point,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 14,
                        color: HaffarColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text(
                'ابدأ التمرين',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: HaffarColors.primaryDark,
                side: const BorderSide(color: HaffarColors.primary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _markLessonUnderstood,
              icon: const Icon(Icons.check_circle_outline, size: 22),
              label: const Text(
                'لقد فهمت الدرس',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _markLessonUnderstood() {
    context.read<ProgressProvider>().completeSubjectLesson(
      widget.subjectId,
      widget.lessonIndex,
    );
    // Manual completion still counts toward the daily streak.
    context.read<EconomyProvider>().updateStreakOnCompletion();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'رائع! تم فتح ما يلي من رحلتك',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: HaffarColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) context.pop();
    });
  }

  Widget _buildQuizTab() {
    if (_quizQuestions.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد أسئلة لهذا الدرس',
          style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 16),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Mascot(pose: MascotPose.determined, size: 88),
          const SizedBox(height: 16),
          const Text(
            'تمرين الدرس',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أجب على ${_quizQuestions.length} أسئلة لاختبار فهمك',
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 14,
              color: HaffarColors.outline,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            width: 200,
            child: ElevatedButton(
              onPressed: () => context.push(
                '${Routes.practiceQuiz}?'
                'subject=${Uri.encodeComponent(widget.subjectId)}'
                '&title=${Uri.encodeComponent('$_subjectName - $_lessonTitle')}'
                '&kind=lesson&ref=${widget.lessonIndex}',
                extra: _quizQuestions,
              ),
              child: const Text(
                'ابدأ التمرين',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_lessonTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: HaffarColors.primary,
          labelColor: HaffarColors.primary,
          unselectedLabelColor: HaffarColors.textSecondary,
          tabs: const [
            Tab(text: 'ملخص الدرس'),
            Tab(text: 'تمرين الدرس'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSummaryTab(), _buildQuizTab()],
      ),
    );
  }
}
