import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../design_system/colors.dart';
import '../../../services/content_admin_repository.dart';
import '../../../utils/lesson_templates.dart';
import '../admin_widgets.dart';
import 'editor_dialogs.dart';

/// Opens the lesson-template picker shown before a new lesson is created.
/// Returns null when dismissed — no lesson is created in that case.
Future<LessonTemplate?> showLessonTemplateSheet(BuildContext context) {
  return showModalBottomSheet<LessonTemplate>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: HaffarColors.white,
    builder: (_) => const LessonTemplateSheet(),
  );
}

class LessonTemplateSheet extends StatefulWidget {
  const LessonTemplateSheet({super.key});

  @override
  State<LessonTemplateSheet> createState() => _LessonTemplateSheetState();
}

class _LessonTemplateSheetState extends State<LessonTemplateSheet> {
  late final ContentAdminRepository _admin;
  List<Map<String, dynamic>> _saved = [];
  bool _loaded = false;
  bool _useSaved = false;

  @override
  void initState() {
    super.initState();
    _admin = ContentAdminRepository(Supabase.instance.client);
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final rows = await _admin.fetchContentTemplates();
      if (!mounted) return;
      setState(() {
        _saved = rows;
        _loaded = true;
        if (_saved.isEmpty && _useSaved) _useSaved = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saved = [];
        _loaded = true;
        _useSaved = false;
      });
    }
  }

  Future<void> _deleteSaved(Map<String, dynamic> row) async {
    final title = (row['title'] as String?)?.trim() ?? '';
    final ok = await showConfirmDialog(
      context,
      title: 'حذف القالب',
      message:
          'سيتم حذف القالب "${title.isEmpty ? 'بدون اسم' : title}" '
          'نهائياً.',
    );
    if (!ok || !mounted) return;
    try {
      await _admin.deleteContentTemplate(row['id'] as String);
      if (!mounted) return;
      await _loadSaved();
      if (!mounted) return;
      editorSnack(context, success: 'تم حذف القالب');
    } catch (e) {
      if (!mounted) return;
      editorSnack(context, error: e);
    }
  }

  LessonTemplate _wrapSaved(Map<String, dynamic> row) {
    final title = (row['title'] as String?)?.trim() ?? '';
    final description = (row['description'] as String?)?.trim() ?? '';
    return LessonTemplate(
      id: 'saved-${row['id']}',
      title: title.isEmpty ? 'قالب محفوظ' : title,
      description: description.isEmpty
          ? 'قالب محفوظ من محرر الدرس'
          : description,
      icon: Icons.bookmark_outline,
      markdown: (row['markdown'] as String?) ?? '',
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: kAdminFont,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: HaffarColors.textPrimary,
      ),
    );
  }

  Widget _builtinTile(LessonTemplate template) {
    return ListTile(
      onTap: () => Navigator.of(context).pop(template),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: HaffarColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(template.icon, size: 20, color: HaffarColors.primary),
      ),
      title: Text(
        template.title,
        style: const TextStyle(
          fontFamily: kAdminFont,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: HaffarColors.textPrimary,
        ),
      ),
      subtitle: Text(
        template.description,
        style: const TextStyle(
          fontFamily: kAdminFont,
          fontSize: 11.5,
          color: HaffarColors.grey2,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_back_ios_new,
        size: 13,
        color: HaffarColors.grey3,
      ),
    );
  }

  Widget _savedTile(Map<String, dynamic> row) {
    final template = _wrapSaved(row);
    return ListTile(
      onTap: () => Navigator.of(context).pop(template),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: HaffarColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(template.icon, size: 20, color: HaffarColors.primary),
      ),
      title: Text(
        template.title,
        style: const TextStyle(
          fontFamily: kAdminFont,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: HaffarColors.textPrimary,
        ),
      ),
      subtitle: Text(
        template.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: kAdminFont,
          fontSize: 11.5,
          color: HaffarColors.grey2,
        ),
      ),
      trailing: IconButton(
        tooltip: 'حذف القالب',
        visualDensity: VisualDensity.compact,
        onPressed: () => _deleteSaved(row),
        icon: const Icon(
          Icons.delete_outline,
          size: 19,
          color: HaffarColors.error,
        ),
      ),
    );
  }

  Widget _savedBody() {
    if (!_loaded) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_saved.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Text(
          'لا توجد قوالب محفوظة — احفظ قالباً من محرر الدرس.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kAdminFont,
            fontSize: 13,
            color: HaffarColors.grey2,
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: _saved.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) => _savedTile(_saved[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('اختر قالباً للدرس'),
          const SizedBox(height: 4),
          const Text(
            'يُنشأ الدرس كمسودة — عدّل المحتوى ثم احفظه لإظهاره للطلاب.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kAdminFont,
              fontSize: 11.5,
              color: HaffarColors.grey2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: Text(
                  'جاهزة',
                  style: TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: !_useSaved ? HaffarColors.white : HaffarColors.grey1,
                  ),
                ),
                selected: !_useSaved,
                onSelected: (_) => setState(() => _useSaved = false),
                selectedColor: HaffarColors.primary,
                backgroundColor: HaffarColors.white,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                side: BorderSide(
                  color: HaffarColors.outline.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(
                  'محفوظة (${_saved.length})',
                  style: TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _useSaved ? HaffarColors.white : HaffarColors.grey1,
                  ),
                ),
                selected: _useSaved,
                onSelected: (_) => setState(() => _useSaved = true),
                selectedColor: HaffarColors.primary,
                backgroundColor: HaffarColors.white,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                side: BorderSide(
                  color: HaffarColors.outline.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Flexible(
            child: _useSaved
                ? _savedBody()
                : ListView.separated(
                    itemCount: kLessonTemplates.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) =>
                        _builtinTile(kLessonTemplates[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
