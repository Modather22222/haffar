import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../design_system/colors.dart';
import '../../../services/content_admin_repository.dart';
import '../../../utils/lesson_content_blocks.dart';
import '../admin_widgets.dart';
import 'editor_dialogs.dart';

/// Opens the "insert block" bottom sheet and returns the picked block, or
/// null when dismissed. Used by the lesson editor's إدراج قسم action.
Future<LessonContentBlock?> showContentBlockSheet(BuildContext context) {
  return showModalBottomSheet<LessonContentBlock>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: HaffarColors.white,
    builder: (_) => const ContentBlockSheet(),
  );
}

class ContentBlockSheet extends StatefulWidget {
  const ContentBlockSheet({super.key});

  @override
  State<ContentBlockSheet> createState() => _ContentBlockSheetState();
}

class _ContentBlockSheetState extends State<ContentBlockSheet> {
  final _searchController = TextEditingController();
  late final ContentAdminRepository _admin;
  LessonBlockCategory? _category;
  String _query = '';
  List<LessonContentBlock> _saved = [];

  @override
  void initState() {
    super.initState();
    _admin = ContentAdminRepository(Supabase.instance.client);
    _loadSaved();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Saved templates (from `content_templates`) shown alongside the built-in
  /// blocks under the المحفوظة filter; failures degrade to built-ins only.
  Future<void> _loadSaved() async {
    try {
      final rows = await _admin.fetchContentTemplates();
      if (!mounted) return;
      setState(() {
        _saved = [
          for (final row in rows)
            LessonContentBlock(
              id: 'saved-${row['id']}',
              title: (row['title'] as String?)?.trim().isEmpty ?? true
                  ? 'قالب محفوظ'
                  : (row['title'] as String).trim(),
              description:
                  ((row['description'] as String?) ?? '').trim().isEmpty
                  ? 'قالب محفوظ من محرر الدرس'
                  : (row['description'] as String).trim(),
              icon: Icons.bookmark_outline,
              category: LessonBlockCategory.saved,
              markdown: (row['markdown'] as String?) ?? '',
            ),
        ];
        if (_saved.isEmpty && _category == LessonBlockCategory.saved) {
          _category = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saved = [];
        if (_category == LessonBlockCategory.saved) _category = null;
      });
    }
  }

  Future<void> _deleteSaved(LessonContentBlock block) async {
    final ok = await showConfirmDialog(
      context,
      title: 'حذف القالب',
      message: 'سيتم حذف القالب "${block.title}" نهائياً.',
    );
    if (!ok || !mounted) return;
    try {
      await _admin.deleteContentTemplate(block.id.substring('saved-'.length));
      if (!mounted) return;
      await _loadSaved();
      if (!mounted) return;
      editorSnack(context, success: 'تم حذف القالب');
    } catch (e) {
      if (!mounted) return;
      editorSnack(context, error: e);
    }
  }

  List<LessonBlockCategory?> get _categories {
    return [
      null,
      for (final category in LessonBlockCategory.values)
        if (category != LessonBlockCategory.saved || _saved.isNotEmpty)
          category,
    ];
  }

  List<LessonContentBlock> get _filtered {
    final query = _query.trim();
    return [...kLessonContentBlocks, ..._saved].where((block) {
      final byCategory = _category == null || block.category == _category;
      final byQuery =
          query.isEmpty ||
          block.title.contains(query) ||
          block.description.contains(query);
      return byCategory && byQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _filtered;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'إدراج قسم',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kAdminFont,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: HaffarColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            style: const TextStyle(fontFamily: kAdminFont, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'ابحث عن قسم...',
              hintStyle: const TextStyle(
                fontFamily: kAdminFont,
                fontSize: 12.5,
                color: HaffarColors.grey3,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: HaffarColors.grey3,
              ),
              isDense: true,
              filled: true,
              fillColor: HaffarColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: HaffarColors.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: HaffarColors.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final category in _categories)
                ChoiceChip(
                  label: Text(
                    category?.label ?? 'الكل',
                    style: TextStyle(
                      fontFamily: kAdminFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _category == category
                          ? HaffarColors.white
                          : HaffarColors.grey1,
                    ),
                  ),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
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
          const SizedBox(height: 4),
          Flexible(
            child: blocks.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      'لا توجد أقسام مطابقة للبحث',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 13,
                        color: HaffarColors.grey2,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: blocks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final block = blocks[index];
                      final isSaved =
                          block.category == LessonBlockCategory.saved;
                      return ListTile(
                        onTap: () => Navigator.of(context).pop(block),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: HaffarColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            block.icon,
                            size: 19,
                            color: HaffarColors.primary,
                          ),
                        ),
                        title: Text(
                          block.title,
                          style: const TextStyle(
                            fontFamily: kAdminFont,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: HaffarColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          block.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: kAdminFont,
                            fontSize: 11,
                            color: HaffarColors.grey2,
                          ),
                        ),
                        trailing: isSaved
                            ? IconButton(
                                tooltip: 'حذف القالب',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _deleteSaved(block),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 19,
                                  color: HaffarColors.error,
                                ),
                              )
                            : Icon(
                                Icons.add_circle_outline,
                                size: 20,
                                color: HaffarColors.primary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
