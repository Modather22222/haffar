import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../design_system/colors.dart';
import '../../../models/lesson.dart';
import '../../../models/unit.dart';
import '../../../providers/content_provider.dart';
import '../../../services/content_admin_repository.dart';
import '../../../services/content_repository.dart';
import '../../../utils/routes.dart';
import '../admin_widgets.dart';
import 'editor_dialogs.dart';

/// Units + lessons management for one subject: rename/create/delete units
/// (structure rules live in SECURITY DEFINER RPCs), edit lesson titles and
/// swap lesson positions inside a unit. Route: /admin/content/editor/units
///
/// The student app hard-assumes unit i owns lessons 3i..3i+2, so only the
/// LAST unit is deletable and swaps stay inside a unit.
class ContentUnitsScreen extends StatefulWidget {
  final String subjectId;

  const ContentUnitsScreen({super.key, required this.subjectId});

  @override
  State<ContentUnitsScreen> createState() => _ContentUnitsScreenState();
}

class _ContentUnitsScreenState extends State<ContentUnitsScreen> {
  late final ContentRepository _repo;
  late final ContentAdminRepository _admin;
  String _subjectName = '';
  List<Unit> _units = const [];
  Map<int, Lesson> _lessonsByIndex = {};
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _repo = ContentRepository(client);
    _admin = ContentAdminRepository(client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final subjects = await _repo.fetchSubjects();
      final lessons = await _repo.fetchLessons();
      final subject = subjects.where((s) => s.id == widget.subjectId).toList();
      if (subject.isEmpty) throw StateError('المادة غير موجودة');
      final resolved = subject.first;
      final units = List<Unit>.of(resolved.units);
      final lessonMap = <int, Lesson>{
        for (final l in lessons.where((l) => l.subjectId == widget.subjectId))
          l.index: l,
      };
      if (!mounted) return;
      setState(() {
        _subjectName = resolved.name;
        _units = units;
        _lessonsByIndex = lessonMap;
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

  Future<void> _addUnit() async {
    final title = await showTextPromptDialog(
      context,
      title: 'إضافة وحدة',
      label: 'عنوان الوحدة',
      max: 120,
    );
    if (title == null || !mounted) return;
    try {
      await _admin.createUnit(widget.subjectId, title);
      await _load();
      await _refreshStudentContent();
      if (!mounted) return;
      editorSnack(context, success: 'تمت إضافة الوحدة مع 3 دروس فارغة');
    } catch (e) {
      if (!mounted) return;
      editorSnack(context, error: e);
    }
  }

  Future<void> _renameUnit(Unit unit) async {
    final title = await showTextPromptDialog(
      context,
      title: 'تعديل عنوان الوحدة',
      label: 'العنوان',
      initial: unit.title,
      max: 120,
    );
    if (title == null || title == unit.title || !mounted) return;
    try {
      await _admin.renameUnit(unit.id, title);
      await _load();
      await _refreshStudentContent();
      if (!mounted) return;
      editorSnack(context, success: 'تم حفظ العنوان');
    } catch (e) {
      if (!mounted) return;
      editorSnack(context, error: e);
    }
  }

  Future<void> _deleteUnit(Unit unit) async {
    final isLast = _units.isNotEmpty && unit.index == _units.last.index;
    if (!isLast) {
      editorSnack(
        context,
        error: 'يمكن حذف آخر وحدة فقط — حذف وحدة في الوسط يكسر ترقيم الدروس',
      );
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: 'حذف الوحدة',
      message:
          'سيتم حذف الوحدة "${unit.title}" ودروسها الثلاثة وجميع أسئلتها '
          'نهائياً. هذا لا يمكن التراجع عنه.',
    );
    if (!ok || !mounted) return;
    try {
      await _admin.deleteUnit(widget.subjectId, unit.index);
      await _load();
      await _refreshStudentContent();
      if (!mounted) return;
      editorSnack(context, success: 'تم حذف الوحدة');
    } catch (e) {
      if (!mounted) return;
      editorSnack(context, error: e);
    }
  }

  Future<void> _renameLesson(Lesson lesson) async {
    final title = await showTextPromptDialog(
      context,
      title: 'تعديل عنوان الدرس',
      label: 'العنوان',
      initial: lesson.title,
      max: 120,
    );
    if (title == null || title == lesson.title || !mounted) return;
    try {
      await _admin.updateLesson(
        lessonId: lesson.id,
        title: title,
        summary: lesson.summary,
        keyPoints: lesson.keyPoints,
      );
      await _load();
      await _refreshStudentContent();
      if (!mounted) return;
      editorSnack(context, success: 'تم حفظ العنوان');
    } catch (e) {
      if (!mounted) return;
      editorSnack(context, error: e);
    }
  }

  Future<void> _swapLessons(int from, int to) async {
    try {
      await _admin.swapLessons(widget.subjectId, from, to);
      await _load();
      await _refreshStudentContent();
      if (!mounted) return;
      editorSnack(context, success: 'تم تبديل الدرسرين');
    } catch (e) {
      if (!mounted) return;
      editorSnack(context, error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _error == null && _units.isEmpty) {
      return Scaffold(appBar: _appBar(), body: const AdminLoadingView());
    }
    if (_error != null && _units.isEmpty) {
      return Scaffold(
        appBar: _appBar(),
        body: AdminErrorView(message: adminMessage(_error), onRetry: _load),
      );
    }
    return Scaffold(
      appBar: _appBar(),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _units.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: _addUnit,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'إضافة وحدة',
                    style: TextStyle(
                      fontFamily: kAdminFont,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }
            final unit = _units[i - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _UnitEditorCard(
                unit: unit,
                unitNumber: i,
                lessons: List.generate(3, (k) {
                  final globalIndex = unit.index * 3 + k;
                  return _lessonsByIndex[globalIndex];
                }),
                canDelete: unit.index == _units.last.index,
                onRenameUnit: () => _renameUnit(unit),
                onDeleteUnit: () => _deleteUnit(unit),
                onRenameLesson: _renameLesson,
                onSwapLessons: _swapLessons,
                onOpenLesson: (lesson) => context.push(
                  '${Routes.adminContentLesson}'
                  '?id=${lesson.id}&subject=${widget.subjectId}',
                ),
                onOpenQuestions: (lesson) => context.push(
                  '${Routes.adminContentQuestions}'
                  '?subject=${widget.subjectId}'
                  '&index=${lesson.index}'
                  '&number=${lesson.index + 1}',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    title: Text(
      _subjectName.isEmpty ? 'الوحدات' : 'وحدات $_subjectName',
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

class _UnitEditorCard extends StatelessWidget {
  final Unit unit;
  final int unitNumber;
  final List<Lesson?> lessons;
  final bool canDelete;
  final Future<void> Function() onRenameUnit;
  final Future<void> Function() onDeleteUnit;
  final Future<void> Function(Lesson) onRenameLesson;
  final Future<void> Function(int from, int to) onSwapLessons;
  final void Function(Lesson) onOpenLesson;
  final void Function(Lesson) onOpenQuestions;

  const _UnitEditorCard({
    required this.unit,
    required this.unitNumber,
    required this.lessons,
    required this.canDelete,
    required this.onRenameUnit,
    required this.onDeleteUnit,
    required this.onRenameLesson,
    required this.onSwapLessons,
    required this.onOpenLesson,
    required this.onOpenQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: 'الوحدة $unitNumber — ${unit.title}',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onRenameUnit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text(
                  'تعديل العنوان',
                  style: TextStyle(fontFamily: kAdminFont, fontSize: 12),
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: canDelete ? onDeleteUnit : null,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text(
                  'حذف الوحدة',
                  style: TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 12,
                    color: canDelete ? HaffarColors.error : HaffarColors.grey3,
                  ),
                ),
              ),
            ],
          ),
          if (!canDelete)
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'الحذف متاح لآخر وحدة فقط',
                style: TextStyle(
                  fontFamily: kAdminFont,
                  fontSize: 10,
                  color: HaffarColors.grey3,
                ),
              ),
            ),
          const SizedBox(height: 4),
          for (var k = 0; k < 3; k++) ...[
            _lessonRow(context, k),
            if (k < 2) const Divider(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _lessonRow(BuildContext context, int localIndex) {
    final globalIndex = unit.index * 3 + localIndex;
    final lesson = lessons[localIndex];
    if (lesson == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'درس مفقود',
          style: TextStyle(
            fontFamily: kAdminFont,
            fontSize: 12,
            color: HaffarColors.grey3,
          ),
        ),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onOpenLesson(lesson),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HaffarColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${globalIndex + 1}',
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
              child: Text(
                lesson.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: kAdminFont,
                  fontSize: 13,
                  color: HaffarColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              tooltip: 'سؤال داخل الدرس',
              visualDensity: VisualDensity.compact,
              onPressed: () => onOpenQuestions(lesson),
              icon: const Icon(
                Icons.quiz_outlined,
                size: 18,
                color: HaffarColors.textSecondary,
              ),
            ),
            IconButton(
              tooltip: 'تعديل العنوان',
              visualDensity: VisualDensity.compact,
              onPressed: () => onRenameLesson(lesson),
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: HaffarColors.textSecondary,
              ),
            ),
            IconButton(
              tooltip: 'تحريك لأعلى',
              visualDensity: VisualDensity.compact,
              onPressed: localIndex > 0
                  ? () => onSwapLessons(globalIndex, globalIndex - 1)
                  : null,
              icon: const Icon(Icons.arrow_upward, size: 18),
            ),
            IconButton(
              tooltip: 'تحريك لأسفل',
              visualDensity: VisualDensity.compact,
              onPressed: localIndex < 2
                  ? () => onSwapLessons(globalIndex, globalIndex + 1)
                  : null,
              icon: const Icon(Icons.arrow_downward, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
