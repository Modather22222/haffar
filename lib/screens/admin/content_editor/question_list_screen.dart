import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../design_system/colors.dart';
import '../../../models/question.dart';
import '../../../providers/content_provider.dart';
import '../../../services/content_admin_repository.dart';
import '../../../utils/question_types.dart';
import '../../../utils/routes.dart';
import '../admin_widgets.dart';
import 'editor_dialogs.dart';

/// Questions inside one lesson: list, up/down reorder (admin_reorder_questions
/// RPC), add and edit. Route: /admin/content/editor/questions
class ContentQuestionListScreen extends StatefulWidget {
  final String subjectId;
  final int lessonIndex;
  final int lessonNumber;

  const ContentQuestionListScreen({
    super.key,
    required this.subjectId,
    required this.lessonIndex,
    required this.lessonNumber,
  });

  @override
  State<ContentQuestionListScreen> createState() =>
      _ContentQuestionListScreenState();
}

class _ContentQuestionListScreenState extends State<ContentQuestionListScreen> {
  late final ContentAdminRepository _admin;
  List<Question>? _questions;
  Object? _error;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _admin = ContentAdminRepository(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final questions = await _admin.fetchLessonQuestions(
        widget.subjectId,
        widget.lessonIndex,
      );
      if (!mounted) return;
      setState(() {
        _questions = questions;
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

  Future<void> _refreshStudentContent() async {
    if (!mounted) return;
    try {
      await context.read<ContentProvider>().loadContent();
    } catch (_) {
      // Best-effort student cache refresh.
    }
  }

  Future<void> _move(int index, int delta) async {
    final questions = _questions;
    if (questions == null || _busy) return;
    final j = index + delta;
    if (j < 0 || j >= questions.length) return;
    setState(() => _busy = true);
    final reordered = List<Question>.of(questions);
    final tmp = reordered[index];
    reordered[index] = reordered[j];
    reordered[j] = tmp;
    setState(() => _questions = reordered);
    try {
      await _admin.reorderQuestions(
        widget.subjectId,
        widget.lessonIndex,
        reordered.map((q) => q.id).toList(),
      );
      await _refreshStudentContent();
    } catch (e) {
      await _load();
      if (mounted) editorSnack(context, error: e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Question question) async {
    final ok = await showConfirmDialog(
      context,
      title: 'حذف السؤال',
      message: 'حذف "${question.text}" نهائياً؟',
    );
    if (!ok || !mounted) return;
    try {
      await _admin.deleteQuestion(question.id);
      await _load();
      await _refreshStudentContent();
      if (!mounted) return;
      editorSnack(context, success: 'تم حذف السؤال');
    } catch (e) {
      if (!mounted) return;
      editorSnack(context, error: e);
    }
  }

  Future<void> _openEditor({Question? question}) async {
    final saved = await context.push<bool>(
      '${Routes.adminContentQuestion}'
      '?subject=${widget.subjectId}'
      '&index=${widget.lessonIndex}'
      '&number=${widget.lessonNumber}'
      '${question == null ? '' : '&id=${question.id}'}',
    );
    if (saved == true) {
      await _load();
      await _refreshStudentContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _questions == null) {
      return Scaffold(appBar: _appBar(), body: const AdminLoadingView());
    }
    if (_error != null && _questions == null) {
      return Scaffold(
        appBar: _appBar(),
        body: AdminErrorView(message: adminMessage(_error), onRetry: _load),
      );
    }
    final questions = _questions!;
    return Scaffold(
      appBar: _appBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text(
          'سؤال جديد',
          style: TextStyle(fontFamily: kAdminFont, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: questions.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: AdminEmptyText('لا توجد أسئلة في هذا الدرس')),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: questions.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _QuestionRow(
                    question: questions[i],
                    position: i + 1,
                    busy: _busy,
                    canUp: i > 0 && !_busy,
                    canDown: i < questions.length - 1 && !_busy,
                    onUp: () => _move(i, -1),
                    onDown: () => _move(i, 1),
                    onEdit: () => _openEditor(question: questions[i]),
                    onDelete: () => _delete(questions[i]),
                  ),
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    title: Text(
      'أسئلة الدرس ${widget.lessonNumber}',
      style: const TextStyle(
        fontFamily: kAdminFont,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: HaffarColors.textPrimary,
      ),
    ),
    backgroundColor: HaffarColors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
  );
}

class _QuestionRow extends StatelessWidget {
  final Question question;
  final int position;
  final bool busy;
  final bool canUp;
  final bool canDown;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionRow({
    required this.question,
    required this.position,
    required this.busy,
    required this.canUp,
    required this.canDown,
    required this.onUp,
    required this.onDown,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HaffarColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$position',
              style: const TextStyle(
                fontFamily: kAdminFont,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: HaffarColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HaffarColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    _tag(questionTypeLabel(question.type.name)),
                    _tag(_difficultyLabel(question.difficulty)),
                    _tag('XP ${question.xpReward}'),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'تحريك لأعلى',
                visualDensity: VisualDensity.compact,
                onPressed: canUp ? onUp : null,
                icon: const Icon(Icons.arrow_upward, size: 17),
              ),
              IconButton(
                tooltip: 'تحريك لأسفل',
                visualDensity: VisualDensity.compact,
                onPressed: canDown ? onDown : null,
                icon: const Icon(Icons.arrow_downward, size: 17),
              ),
            ],
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'تعديل',
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: HaffarColors.textSecondary,
                ),
              ),
              IconButton(
                tooltip: 'حذف',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: HaffarColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _difficultyLabel(String d) => switch (d) {
    'easy' => 'سهل',
    'hard' => 'صعب',
    _ => 'متوسط',
  };

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: HaffarColors.surface,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: kAdminFont,
        fontSize: 10,
        color: HaffarColors.textSecondary,
      ),
    ),
  );
}
