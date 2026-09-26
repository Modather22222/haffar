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

/// Units + lessons management for one subject: create/delete units, add,
/// remove, and reorder lessons inside a unit, and edit lesson titles.
/// Route: /admin/content/editor/units
///
/// Lessons are dynamic: a unit holds any number of them, `lesson_index` is a
/// stable identity (progress keys), and `position` is the only thing that
/// changes when lessons move. Structure rules live in SECURITY DEFINER RPCs.
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

  /// Lessons of this subject grouped by unit_index, ordered by position.
  Map<int, List<Lesson>> _lessonsByUnit = {};
  bool _loading = true;
  bool _saving = false;
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
      final byUnit = <int, List<Lesson>>{};
      for (final lesson in lessons) {
        if (lesson.subjectId != widget.subjectId) continue;
        byUnit.putIfAbsent(lesson.unitIndex, () => []).add(lesson);
      }
      for (final list in byUnit.values) {
        list.sort((a, b) => a.position.compareTo(b.position));
      }
      if (!mounted) return;
      setState(() {
        _subjectName = resolved.name;
        _units = units;
        _lessonsByUnit = byUnit;
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

  List<Lesson> _lessonsOf(Unit unit) => _lessonsByUnit[unit.index] ?? const [];

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
      if (!mounted) return;
      editorSnack(
        context,
        success:
            'تمت إضافة الوحدة مع 3 دروس كمسودات — أكمل محتواها ثم اضغط حفظ',
      );
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
    final lessonCount = _lessonsOf(unit).length;
    final ok = await showConfirmDialog(
      context,
      title: 'حذف الوحدة',
      message:
          'سيتم حذف الوحدة "${unit.title}" و${Unit.lessonsCountLabel(lessonCount)} '
          'وجميع أسئلتها وتمريناتها وتقدم الطلاب فيها نهائياً. '
          'هذا لا يمكن التراجع عنه.',
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

  Future<void> _addLesson(Unit unit) async {
    try {
      await _admin.createLesson(widget.subjectId, unit.index);
      await _load();
      if (!mounted) return;
      editorSnack(
        context,
        success: 'تمت إضافة الدرس كمسودة — لن يظهر للطلاب قبل الحفظ',
      );
    } catch (e) {
      if (!mounted) return;
      editorSnack(context, error: e);
    }
  }

  /// Publishes all draft lessons of this subject after validating required
  /// content client-side; the server re-validates and rejects atomically
  /// (`lessons incomplete: ...`) if anything is still missing.
  Future<void> _publish() async {
    final incomplete = <String>[
      for (final list in _lessonsByUnit.values)
        for (final lesson in list)
          if (!lesson.published &&
              (lesson.title.trim().isEmpty || lesson.summary.trim().isEmpty))
            (lesson.title.trim().isEmpty ? '(بلا عنوان)' : lesson.title.trim()),
    ];
    if (incomplete.isNotEmpty) {
      editorSnack(
        context,
        errorMessage: 'أكمل محتوى هذه الدروس أولاً: ${incomplete.join(' | ')}',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final count = await _admin.publishLessons(widget.subjectId);
      await _load();
      await _refreshStudentContent();
      if (!mounted) return;
      editorSnack(
        context,
        success: count > 0
            ? 'تم حفظ الدروس وظهرت للطلاب ($count)'
            : 'لا توجد دروس جديدة للنشر',
      );
    } catch (e) {
      if (!mounted) return;
      editorSnack(context, error: e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteLesson(Lesson lesson) async {
    final ok = await showConfirmDialog(
      context,
      title: 'حذف الدرس',
      message:
          'سيتم حذف الدرس "${lesson.title}" مع جميع أسئلته وتقدم الطلاب فيه '
          'نهائياً. هذا لا يمكن التراجع عنه.',
    );
    if (!ok || !mounted) return;
    try {
      await _admin.deleteLesson(widget.subjectId, lesson.index);
      await _load();
      await _refreshStudentContent();
      if (!mounted) return;
      editorSnack(context, success: 'تم حذف الدرس');
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

  Future<void> _moveLesson(Lesson lesson, int delta) async {
    try {
      await _admin.moveLesson(widget.subjectId, lesson.index, delta);
      await _load();
      await _refreshStudentContent();
      if (!mounted) return;
      editorSnack(context, success: 'تم تحريك الدرس');
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
                lessons: _lessonsOf(unit),
                onRenameUnit: () => _renameUnit(unit),
                onDeleteUnit: () => _deleteUnit(unit),
                onAddLesson: () => _addLesson(unit),
                onDeleteLesson: _deleteLesson,
                onRenameLesson: _renameLesson,
                onMoveLesson: _moveLesson,
                onOpenLesson: (lesson) => context.push(
                  '${Routes.adminContentLesson}'
                  '?id=${lesson.id}&subject=${widget.subjectId}',
                ),
                onOpenQuestions: (lesson, number) => context.push(
                  '${Routes.adminContentQuestions}'
                  '?subject=${widget.subjectId}'
                  '&index=${lesson.index}'
                  '&number=$number',
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
    actions: [
      Padding(
        padding: const EdgeInsetsDirectional.only(end: 12),
        child: TextButton(
          onPressed: _saving ? null : _publish,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'حفظ',
                  style: TextStyle(
                    fontFamily: kAdminFont,
                    fontWeight: FontWeight.w800,
                    color: HaffarColors.primaryDark,
                  ),
                ),
        ),
      ),
    ],
    backgroundColor: HaffarColors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
  );
}

class _UnitEditorCard extends StatelessWidget {
  final Unit unit;
  final int unitNumber;
  final List<Lesson> lessons;
  final Future<void> Function() onRenameUnit;
  final Future<void> Function() onDeleteUnit;
  final Future<void> Function() onAddLesson;
  final Future<void> Function(Lesson) onDeleteLesson;
  final Future<void> Function(Lesson) onRenameLesson;
  final Future<void> Function(Lesson, int) onMoveLesson;
  final void Function(Lesson) onOpenLesson;
  final void Function(Lesson, int) onOpenQuestions;

  const _UnitEditorCard({
    required this.unit,
    required this.unitNumber,
    required this.lessons,
    required this.onRenameUnit,
    required this.onDeleteUnit,
    required this.onAddLesson,
    required this.onDeleteLesson,
    required this.onRenameLesson,
    required this.onMoveLesson,
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
                onPressed: onDeleteUnit,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text(
                  'حذف الوحدة',
                  style: TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 12,
                    color: HaffarColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (var k = 0; k < lessons.length; k++) ...[
            _lessonRow(context, k),
            if (k < lessons.length - 1) const Divider(height: 10),
          ],
          if (lessons.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'لا توجد دروس في هذه الوحدة',
                style: TextStyle(
                  fontFamily: kAdminFont,
                  fontSize: 12,
                  color: HaffarColors.grey3,
                ),
              ),
            ),
          const Divider(height: 10),
          TextButton.icon(
            onPressed: onAddLesson,
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'إضافة درس',
              style: TextStyle(fontFamily: kAdminFont, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lessonRow(BuildContext context, int localIndex) {
    final lesson = lessons[localIndex];
    final canDelete = lessons.length > 1;
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
                '${localIndex + 1}',
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
            if (!lesson.published) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: kChartOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'مسودة',
                  style: TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: kChartOrange,
                  ),
                ),
              ),
            ],
            IconButton(
              tooltip: 'سؤال داخل الدرس',
              visualDensity: VisualDensity.compact,
              onPressed: () => onOpenQuestions(lesson, localIndex + 1),
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
              tooltip: canDelete ? 'حذف الدرس' : 'آخر درس في الوحدة',
              visualDensity: VisualDensity.compact,
              onPressed: canDelete ? () => onDeleteLesson(lesson) : null,
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: canDelete ? HaffarColors.error : HaffarColors.grey3,
              ),
            ),
            IconButton(
              tooltip: 'تحريك لأعلى',
              visualDensity: VisualDensity.compact,
              onPressed: localIndex > 0 ? () => onMoveLesson(lesson, -1) : null,
              icon: const Icon(Icons.arrow_upward, size: 18),
            ),
            IconButton(
              tooltip: 'تحريك لأسفل',
              visualDensity: VisualDensity.compact,
              onPressed: localIndex < lessons.length - 1
                  ? () => onMoveLesson(lesson, 1)
                  : null,
              icon: const Icon(Icons.arrow_downward, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
