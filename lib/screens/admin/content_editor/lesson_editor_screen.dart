import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../design_system/colors.dart';
import '../../../models/lesson.dart';
import '../../../providers/content_provider.dart';
import '../../../services/content_admin_repository.dart';
import '../../../utils/content_validators.dart';
import '../../../utils/rich_content.dart';
import '../../../widgets/markdown_text.dart';
import '../admin_widgets.dart';
import 'editor_dialogs.dart';

/// Rich-text lesson editor: title, Quill summary (stored as GitHub-Flavored
/// Markdown in `lessons.summary`), image upload into the public `content`
/// bucket, and reorderable key points. Route: /admin/content/editor/lesson
class LessonEditorScreen extends StatefulWidget {
  final String lessonId;
  final String subjectId;

  const LessonEditorScreen({
    super.key,
    required this.lessonId,
    required this.subjectId,
  });

  @override
  State<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends State<LessonEditorScreen> {
  late final ContentAdminRepository _admin;
  late final QuillController _summaryController;
  final _titleController = TextEditingController();
  final List<TextEditingController> _pointControllers = [];
  Lesson? _lesson;
  Object? _error;
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _admin = ContentAdminRepository(Supabase.instance.client);
    _summaryController = QuillController.basic();
    _load();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _titleController.dispose();
    for (final c in _pointControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lesson = await _admin.fetchLesson(widget.lessonId);
      _titleController.text = lesson.title;
      _summaryController.document = documentFromMarkdown(lesson.summary);
      _summaryController.updateSelection(
        const TextSelection.collapsed(offset: 0),
        ChangeSource.local,
      );
      _pointControllers
        ..clear()
        ..addAll(lesson.keyPoints.map((p) => TextEditingController(text: p)));
      if (_pointControllers.isEmpty) {
        _pointControllers.add(TextEditingController());
      }
      if (!mounted) return;
      setState(() {
        _lesson = lesson;
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

  Future<void> _pickAndUploadImage() async {
    if (_uploading) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await _admin.uploadImage(
        bytes: bytes,
        mimeType: _mimeTypeFor(picked.path),
      );
      final base = _summaryController.selection.isValid
          ? _summaryController.selection.baseOffset
          : _summaryController.document.length - 1;
      final index = base < 0 ? 0 : base;
      _summaryController.replaceText(index, 0, BlockEmbed.image(url), null);
      if (mounted) {
        editorSnack(context, success: 'تم إدراج الصورة');
      }
    } catch (e) {
      if (mounted) editorSnack(context, error: e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  static String _mimeTypeFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }

  /// Action row above the rich editor: image insert, student preview, and the
  /// fullscreen toggle (⤢ / minimize). Shared by the compact card and the
  /// expanded editing mode.
  Widget _editorActions({required bool expanded}) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _uploading ? null : _pickAndUploadImage,
          icon: _uploading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.image_outlined, size: 18),
          label: Text(
            _uploading ? 'جارٍ الرفع...' : 'إدراج صورة',
            style: const TextStyle(fontFamily: kAdminFont, fontSize: 12),
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _showPreview,
          icon: const Icon(Icons.visibility_outlined, size: 16),
          label: const Text(
            'معاينة',
            style: TextStyle(fontFamily: kAdminFont, fontSize: 12),
          ),
        ),
        TextButton.icon(
          onPressed: () => setState(() => _expanded = !expanded),
          icon: Icon(
            expanded ? Icons.close_fullscreen : Icons.open_in_full,
            size: 16,
          ),
          label: Text(
            expanded ? 'تصغير' : 'ملء الشاشة',
            style: const TextStyle(fontFamily: kAdminFont, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _editorToolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: QuillSimpleToolbar(
        controller: _summaryController,
        config: const QuillSimpleToolbarConfig(
          showAlignmentButtons: true,
          showDirection: true,
        ),
      ),
    );
  }

  Widget _quillEditor({required bool expanded}) {
    return QuillEditor.basic(
      controller: _summaryController,
      config: QuillEditorConfig(
        placeholder: 'اكتب ملخص الدرس هنا...',
        padding: const EdgeInsets.all(12),
        minHeight: expanded ? null : 200,
        expands: expanded,
        embedBuilders: [
          QuillEditorImageEmbedBuilder(
            config: const QuillEditorImageEmbedConfig(),
          ),
        ],
      ),
    );
  }

  Widget _editorFrame({required bool expanded, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: HaffarColors.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [_editorToolbar(), const Divider(height: 1), child],
      ),
    );
  }

  void _addPoint() {
    setState(() => _pointControllers.add(TextEditingController()));
  }

  void _removePoint(int i) {
    setState(() {
      _pointControllers[i].dispose();
      _pointControllers.removeAt(i);
      if (_pointControllers.isEmpty) {
        _pointControllers.add(TextEditingController());
      }
    });
  }

  void _movePoint(int i, int delta) {
    final j = i + delta;
    if (j < 0 || j >= _pointControllers.length) return;
    setState(() {
      final tmp = _pointControllers[i];
      _pointControllers[i] = _pointControllers[j];
      _pointControllers[j] = tmp;
    });
  }

  Future<void> _showPreview() async {
    final summary = markdownFromDocument(_summaryController.document);
    final points = _pointControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'معاينة كما يراها الطالب',
          style: TextStyle(
            fontFamily: kAdminFont,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: HaffarColors.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: MarkdownText(summary),
              ),
              if (points.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'نقاط مهمة',
                  style: TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                for (final p in points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: HaffarColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: MarkdownText(p)),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'إغلاق',
              style: TextStyle(fontFamily: kAdminFont),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final lesson = _lesson;
    if (lesson == null || _saving) return;
    final titleError = validateRequiredText(
      _titleController.text,
      'عنوان الدرس',
      max: 120,
    );
    if (titleError != null) {
      editorSnack(context, error: ArgumentError(titleError));
      return;
    }
    setState(() => _saving = true);
    try {
      await _admin.updateLesson(
        lessonId: lesson.id,
        title: _titleController.text.trim(),
        summary: markdownFromDocument(_summaryController.document),
        keyPoints: _pointControllers
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
      );
      await _refreshStudentContent();
      if (!mounted) return;
      editorSnack(context, success: 'تم حفظ الدرس');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      editorSnack(context, error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _lesson == null) {
      return Scaffold(appBar: _appBar(), body: const AdminLoadingView());
    }
    if (_error != null && _lesson == null) {
      return Scaffold(
        appBar: _appBar(),
        body: AdminErrorView(message: adminMessage(_error), onRetry: _load),
      );
    }
    if (_expanded) {
      return Scaffold(
        appBar: _appBar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _editorActions(expanded: true),
                const SizedBox(height: 8),
                Expanded(
                  child: _editorFrame(
                    expanded: true,
                    child: Expanded(child: _quillEditor(expanded: true)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: _appBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminSectionCard(
              title: 'عنوان الدرس',
              child: TextField(
                controller: _titleController,
                style: const TextStyle(fontFamily: kAdminFont, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'عنوان الدرس...',
                  hintStyle: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 13,
                    color: HaffarColors.grey3,
                  ),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AdminSectionCard(
              title: 'محتوى الدرس (تنسيق غني)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _editorActions(expanded: false),
                  const SizedBox(height: 8),
                  _editorFrame(
                    expanded: false,
                    child: _quillEditor(expanded: false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AdminSectionCard(
              title: 'نقاط مهمة',
              child: Column(
                children: [
                  for (var i = 0; i < _pointControllers.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: HaffarColors.primary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _pointControllers[i],
                              style: const TextStyle(
                                fontFamily: kAdminFont,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: 'نقطة (يدعم Markdown)...',
                                hintStyle: const TextStyle(
                                  fontFamily: kAdminFont,
                                  fontSize: 12,
                                  color: HaffarColors.grey3,
                                ),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'تحريك لأعلى',
                            visualDensity: VisualDensity.compact,
                            onPressed: i > 0 ? () => _movePoint(i, -1) : null,
                            icon: const Icon(Icons.arrow_upward, size: 16),
                          ),
                          IconButton(
                            tooltip: 'تحريك لأسفل',
                            visualDensity: VisualDensity.compact,
                            onPressed: i < _pointControllers.length - 1
                                ? () => _movePoint(i, 1)
                                : null,
                            icon: const Icon(Icons.arrow_downward, size: 16),
                          ),
                          IconButton(
                            tooltip: 'حذف',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _removePoint(i),
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: HaffarColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: _addPoint,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'إضافة نقطة',
                        style: TextStyle(fontFamily: kAdminFont, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: HaffarColors.primary,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'حفظ الدرس',
                        style: TextStyle(
                          fontFamily: kAdminFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    title: const Text(
      'تحرير الدرس',
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
    actions: [
      TextButton(
        onPressed: _saving ? null : _save,
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
                  color: HaffarColors.primary,
                ),
              ),
      ),
    ],
  );
}
