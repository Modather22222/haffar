import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../design_system/colors.dart';
import '../../../models/subject.dart';
import '../../../providers/content_provider.dart';
import '../../../services/content_admin_repository.dart';
import '../../../services/content_repository.dart';
import '../../../utils/content_validators.dart';
import '../../../utils/routes.dart';
import '../admin_widgets.dart';
import 'editor_dialogs.dart';

/// Content editor root — subjects CRUD. From here the admin drills into
/// units/lessons (`ContentUnitsScreen`), lesson rich-text editing and the
/// question editor. Route: /admin/content/editor
class ContentEditorScreen extends StatefulWidget {
  const ContentEditorScreen({super.key});

  @override
  State<ContentEditorScreen> createState() => _ContentEditorScreenState();
}

class _ContentEditorScreenState extends State<ContentEditorScreen> {
  late final ContentRepository _repo;
  late final ContentAdminRepository _admin;
  List<Subject>? _subjects;
  Object? _error;
  bool _loading = true;

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

  Future<void> _refreshStudentContent() async {
    if (!mounted) return;
    try {
      await context.read<ContentProvider>().loadContent();
    } catch (_) {
      // Student cache refresh is best-effort after an admin write.
    }
  }

  Future<void> _editSubject([Subject? subject]) async {
    final data = await _showSubjectDialog(subject);
    if (data == null || !mounted) return;
    try {
      if (subject == null) {
        await _admin.insertSubject(
          id: data.id,
          name: data.name,
          icon: data.icon,
          colorHex: data.colorHex,
          sortOrder: data.sortOrder,
        );
      } else {
        await _admin.updateSubject(
          subject.id,
          name: data.name,
          icon: data.icon,
          colorHex: data.colorHex,
          sortOrder: data.sortOrder,
        );
      }
      await _load();
      await _refreshStudentContent();
      if (!mounted) return;
      editorSnack(context, success: 'تم حفظ المادة');
    } catch (e) {
      if (!mounted) return;
      editorSnack(context, error: e);
    }
  }

  Future<_SubjectFormResult?> _showSubjectDialog(Subject? subject) {
    final idController = TextEditingController(text: subject?.id ?? '');
    final nameController = TextEditingController(text: subject?.name ?? '');
    final iconController = TextEditingController(text: subject?.icon ?? '');
    final colorController = TextEditingController(
      text: subject?.colorHex ?? '#FD7202',
    );
    final sortController = TextEditingController(
      text: (subject?.sortOrder ?? 0).toString(),
    );
    final formKey = GlobalKey<FormState>();

    return showDialog<_SubjectFormResult>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          subject == null ? 'إضافة مادة' : 'تعديل المادة',
          style: const TextStyle(
            fontFamily: kAdminFont,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: idController,
                  enabled: subject == null,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: kAdminFont, fontSize: 14),
                  decoration: _decoration('المعرّف (إنجليزي، لا يتغير)'),
                  validator: (v) => validateSubjectId(v ?? ''),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(fontFamily: kAdminFont, fontSize: 14),
                  decoration: _decoration('اسم المادة'),
                  validator: (v) => validateRequiredText(v ?? '', 'الاسم'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: iconController,
                  style: const TextStyle(fontFamily: kAdminFont, fontSize: 14),
                  decoration: _decoration('الأيقونة (رمز/إيموجي)'),
                  validator: (v) =>
                      validateRequiredText(v ?? '', 'الأيقونة', max: 8),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: colorController,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: kAdminFont, fontSize: 14),
                  decoration: _decoration('اللون ‎#RRGGBB‎'),
                  validator: (v) => validateColorHex(v ?? ''),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: sortController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: kAdminFont, fontSize: 14),
                  decoration: _decoration('ترتيب العرض'),
                  validator: (v) =>
                      validateSortOrder(int.tryParse(v ?? '') ?? -1),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: kAdminFont),
            ),
          ),
          TextButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.of(dialogContext).pop(
                _SubjectFormResult(
                  id: idController.text.trim(),
                  name: nameController.text.trim(),
                  icon: iconController.text.trim(),
                  colorHex: colorController.text.trim().toUpperCase(),
                  sortOrder: int.parse(sortController.text),
                ),
              );
            },
            child: const Text(
              'حفظ',
              style: TextStyle(
                fontFamily: kAdminFont,
                fontWeight: FontWeight.w700,
                color: HaffarColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubject(Subject subject) async {
    if (subject.units.isNotEmpty) {
      editorSnack(
        context,
        error: 'احذف وحدات المادة أولاً — الحذف يمسح كل المحتوى',
      );
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: 'حذف المادة',
      message: 'حذف المادة الفارغة "${subject.name}" نهائياً؟',
    );
    if (!ok || !mounted) return;
    try {
      await _admin.deleteSubject(subject.id);
      await _load();
      await _refreshStudentContent();
      if (!mounted) return;
      editorSnack(context, success: 'تم حذف المادة');
    } catch (e) {
      if (!mounted) return;
      editorSnack(context, error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _subjects == null) {
      return Scaffold(appBar: _appBar(), body: const AdminLoadingView());
    }
    if (_error != null && _subjects == null) {
      return Scaffold(
        appBar: _appBar(),
        body: AdminErrorView(message: adminMessage(_error), onRetry: _load),
      );
    }
    final subjects = _subjects!;
    return Scaffold(
      appBar: _appBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editSubject(),
        icon: const Icon(Icons.add),
        label: const Text(
          'مادة جديدة',
          style: TextStyle(fontFamily: kAdminFont, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: subjects.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: AdminEmptyText('لا توجد مواد — أضف مادة جديدة'),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: subjects.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SubjectEditorCard(
                    subject: subjects[i],
                    onOpen: () => context.push(
                      '${Routes.adminContentUnits}?subject=${subjects[i].id}',
                    ),
                    onEdit: () => _editSubject(subjects[i]),
                    onDelete: () => _deleteSubject(subjects[i]),
                  ),
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    title: const Text(
      'محرر المحتوى',
      style: TextStyle(
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

  static InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontFamily: kAdminFont, fontSize: 13),
    errorStyle: const TextStyle(fontFamily: kAdminFont, fontSize: 11),
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  );
}

class _SubjectFormResult {
  final String id;
  final String name;
  final String icon;
  final String colorHex;
  final int sortOrder;

  const _SubjectFormResult({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.sortOrder,
  });
}

class _SubjectEditorCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectEditorCard({
    required this.subject,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _accent {
    final hex = subject.colorHex;
    if (hex != null && hex.length == 7 && hex.startsWith('#')) {
      final value = int.tryParse(hex.substring(1), radix: 16);
      if (value != null) return Color(0xFF00000000 | value);
    }
    return HaffarColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final unitCount = subject.units.length;
    return AdminSectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(subject.icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: HaffarColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'وحدات: ${fmtInt(unitCount)} — '
                      'معرّف: ${subject.id}',
                      style: const TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 11,
                        color: HaffarColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'تعديل',
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: HaffarColors.textSecondary,
                ),
              ),
              IconButton(
                tooltip: 'حذف',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: HaffarColors.error,
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
