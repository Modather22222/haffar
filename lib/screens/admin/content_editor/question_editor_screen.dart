import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../design_system/colors.dart';
import '../../../models/question.dart';
import '../../../services/content_admin_repository.dart';
import '../../../utils/content_validators.dart';
import '../../../utils/question_types.dart';
import '../../../widgets/question_widgets/question_widget_factory.dart';
import '../admin_widgets.dart';
import 'editor_dialogs.dart';

/// Question create/edit form for one lesson: per-type fields (options,
/// answer key, passage, hint, image upload), validation via
/// `content_validators`, and a live student preview rendered through the
/// real `QuestionWidgetFactory`.
class QuestionEditorScreen extends StatefulWidget {
  final String subjectId;
  final int lessonIndex;
  final int lessonNumber;
  final String? questionId;

  const QuestionEditorScreen({
    super.key,
    required this.subjectId,
    required this.lessonIndex,
    required this.lessonNumber,
    this.questionId,
  });

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  late final ContentAdminRepository _admin;
  Question? _existing;
  bool _loading = true;
  Object? _error;
  bool _saving = false;
  bool _uploading = false;

  QuestionType _type = QuestionType.multipleChoice;
  final _textController = TextEditingController();
  final _passageController = TextEditingController();
  final _hintController = TextEditingController();
  final _addWordController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  List<String> _correctWords = [];
  List<String> _categories = [];
  int _correctIndex = 0;
  int _xp = 5;
  String _difficulty = 'medium';
  String? _imageUrl;
  int _sortOrder = 0;

  @override
  void initState() {
    super.initState();
    _admin = ContentAdminRepository(Supabase.instance.client);
    _optionControllers.addAll([
      TextEditingController(),
      TextEditingController(),
    ]);
    _categories = ['0', '0'];
    for (final c in [
      _textController,
      _passageController,
      _hintController,
      ..._optionControllers,
    ]) {
      c.addListener(_onFormChanged);
    }
    if (widget.questionId != null) {
      _load();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _textController,
      _passageController,
      _hintController,
      _addWordController,
      ..._optionControllers,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final q = await _admin.fetchQuestion(widget.questionId!);
      _textController.text = q.text;
      _passageController.text = q.passage ?? '';
      _hintController.text = q.hint ?? '';
      _optionControllers
        ..clear()
        ..addAll(q.options.map((o) => TextEditingController(text: o)));
      for (final c in _optionControllers) {
        c.addListener(_onFormChanged);
      }
      if (_optionControllers.length < 2) {
        _optionControllers
          ..add(TextEditingController())
          ..add(TextEditingController());
      }
      _correctWords = List.of(q.correctWords ?? const []);
      _categories = List.of(q.itemCategories ?? const []);
      if (_categories.length != _optionControllers.length) {
        _categories = List.filled(_optionControllers.length, '0');
      }
      _correctIndex = q.correctIndex;
      _xp = q.xpReward;
      _difficulty = q.difficulty;
      _imageUrl = q.imageUrl;
      _sortOrder = q.sortOrder;
      if (!mounted) return;
      setState(() {
        _type = q.type;
        _existing = q;
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

  Future<void> _pickAndUploadImage() async {
    if (_uploading) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last.toLowerCase();
      final mime = switch (ext) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
      final url = await _admin.uploadImage(bytes: bytes, mimeType: mime);
      setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) editorSnack(context, error: e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _addOption() {
    setState(() {
      final c = TextEditingController();
      c.addListener(_onFormChanged);
      _optionControllers.add(c);
      _categories.add('0');
    });
  }

  void _removeOption(int i) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers[i].dispose();
      _optionControllers.removeAt(i);
      _categories.removeAt(i);
      if (_correctIndex >= _optionControllers.length) _correctIndex = 0;
    });
  }

  void _addWord() {
    final word = _addWordController.text.trim();
    if (word.isEmpty) return;
    setState(() {
      _correctWords = [..._correctWords, word];
      _addWordController.clear();
    });
  }

  void _removeWord(int i) {
    setState(
      () => _correctWords = [
        for (var k = 0; k < _correctWords.length; k++)
          if (k != i) _correctWords[k],
      ],
    );
  }

  List<String> get _options => [for (final c in _optionControllers) c.text];

  Question _previewQuestion() => Question(
    id: _existing?.id ?? 'preview',
    subjectId: widget.subjectId,
    lessonIndex: widget.lessonIndex,
    type: _type,
    text: _textController.text,
    passage: typeUsesPassage(_type.name) && _passageController.text.isNotEmpty
        ? _passageController.text
        : null,
    hint: typeUsesHint(_type.name) && _hintController.text.isNotEmpty
        ? _hintController.text
        : null,
    options: typeUsesOptions(_type.name) ? _options : const [],
    correctIndex: _correctIndex,
    correctWords: _correctWords.isEmpty ? null : _correctWords,
    itemCategories: _type == QuestionType.classification ? _categories : null,
    xpReward: _xp,
    imageUrl: _imageUrl,
    difficulty: _difficulty,
    sortOrder: _sortOrder,
  );

  Future<void> _save() async {
    if (_saving) return;
    final options = _options;
    final message = validateQuestion(
      type: _type.name,
      text: _textController.text,
      options: options,
      correctIndex: _correctIndex,
      correctWords: _correctWords,
      itemCategories: _categories,
      passage: _passageController.text,
      imageUrl: _imageUrl,
    );
    if (message != null) {
      editorSnack(context, error: ArgumentError(message));
      return;
    }
    final xpMessage = validateXpReward(_xp);
    if (xpMessage != null) {
      editorSnack(context, error: ArgumentError(xpMessage));
      return;
    }
    setState(() => _saving = true);
    final keepOptions = typeUsesOptions(_type.name);
    final row = <String, dynamic>{
      'subject_id': widget.subjectId,
      'lesson_index': widget.lessonIndex,
      'type': _type.name,
      'text': _textController.text.trim(),
      'passage':
          typeUsesPassage(_type.name) &&
              _passageController.text.trim().isNotEmpty
          ? _passageController.text.trim()
          : null,
      'hint': typeUsesHint(_type.name) && _hintController.text.trim().isNotEmpty
          ? _hintController.text.trim()
          : null,
      'options': keepOptions ? options : const <String>[],
      'correct_index': _correctIndex,
      'correct_words': typeUsesCorrectWords(_type.name)
          ? _correctWords
          : const <String>[],
      'item_categories': _type == QuestionType.classification
          ? _categories
          : const <String>[],
      'xp_reward': _xp,
      'image_url': (_imageUrl?.isNotEmpty ?? false) ? _imageUrl : null,
      'difficulty': _difficulty,
      'sort_order': _sortOrder,
    };
    try {
      if (_existing == null) {
        final existing = await _admin.fetchLessonQuestions(
          widget.subjectId,
          widget.lessonIndex,
        );
        row['id'] = ContentAdminRepository.nextQuestionId(
          subjectId: widget.subjectId,
          lessonIndex: widget.lessonIndex,
          existingIds: existing.map((q) => q.id).toSet(),
        );
        row['sort_order'] = existing.isEmpty
            ? 0
            : existing.map((q) => q.sortOrder).reduce((a, b) => a > b ? a : b) +
                  1;
        await _admin.insertQuestion(row);
      } else {
        await _admin.updateQuestion(_existing!.id, row);
      }
      if (!mounted) return;
      editorSnack(
        context,
        success: _existing == null ? 'تمت إضافة السؤال' : 'تم حفظ السؤال',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      editorSnack(context, error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: _appBar(),
        body: _error != null
            ? AdminErrorView(message: adminMessage(_error), onRetry: _load)
            : const AdminLoadingView(),
      );
    }
    return Scaffold(
      appBar: _appBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section(
              'نوع السؤال',
              DropdownButtonFormField<QuestionType>(
                initialValue: _type,
                style: const TextStyle(
                  fontFamily: kAdminFont,
                  fontSize: 14,
                  color: HaffarColors.textPrimary,
                ),
                items: [
                  for (final t in QuestionType.values)
                    DropdownMenuItem(
                      value: t,
                      child: Text(questionTypeLabel(t.name)),
                    ),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
            ),
            _section(
              _type == QuestionType.definition ? 'المصطلح' : 'نص السؤال',
              _multiline(_textController, 'النص...'),
            ),
            if (typeUsesPassage(_type.name))
              _section(
                _type == QuestionType.calculation
                    ? 'المعادلة (اختياري)'
                    : 'النص المرفق',
                _multiline(
                  _passageController,
                  _type == QuestionType.calculation
                      ? 'مثال: ص = ج × ع'
                      : 'فقرة السؤال...',
                ),
              ),
            if (typeUsesHint(_type.name))
              _section(
                'التلميح (اختياري)',
                _multiline(_hintController, 'تلميح...'),
              ),
            if (typeUsesOptions(_type.name)) _optionsSection(),
            if (typeUsesCorrectWords(_type.name)) _correctWordsSection(),
            _section(
              'الصورة',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _uploading ? null : _pickAndUploadImage,
                        icon: _uploading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.image_outlined, size: 18),
                        label: Text(
                          _type == QuestionType.diagram
                              ? 'رفع صورة الرسم'
                              : 'رفع صورة توضيحية',
                          style: const TextStyle(
                            fontFamily: kAdminFont,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (_imageUrl != null && _imageUrl!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => setState(() => _imageUrl = null),
                          child: const Text(
                            'إزالة',
                            style: TextStyle(
                              fontFamily: kAdminFont,
                              fontSize: 12,
                              color: HaffarColors.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_imageUrl != null && _imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _imageUrl!,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Text(
                            'تعذّر تحميل الصورة',
                            style: TextStyle(
                              fontFamily: kAdminFont,
                              fontSize: 12,
                              color: HaffarColors.grey3,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _section(
              'المكافأة والصعوبة',
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '$_xp',
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 14,
                      ),
                      decoration: _inputDecoration('نقاط الخبرة'),
                      onChanged: (v) =>
                          setState(() => _xp = int.tryParse(v) ?? 0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _difficulty,
                      style: const TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 14,
                        color: HaffarColors.textPrimary,
                      ),
                      decoration: _inputDecoration('الصعوبة'),
                      items: const [
                        DropdownMenuItem(value: 'easy', child: Text('سهل')),
                        DropdownMenuItem(value: 'medium', child: Text('متوسط')),
                        DropdownMenuItem(value: 'hard', child: Text('صعب')),
                      ],
                      onChanged: (v) =>
                          setState(() => _difficulty = v ?? _difficulty),
                    ),
                  ),
                ],
              ),
            ),
            _section(
              'معاينة كما يراها الطالب',
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HaffarColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: HaffarColors.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: QuestionWidgetFactory.create(
                  question: _previewQuestion(),
                  subjectName: '',
                  lessonNumber: widget.lessonNumber,
                  customTitle: 'معاينة — درس ${widget.lessonNumber}',
                  onBack: () {},
                  onSkip: () {},
                  onNext: () {},
                  onSubmitAnswer: (_, _) {},
                ),
              ),
            ),
            const SizedBox(height: 8),
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
                    : Text(
                        _existing == null ? 'إضافة السؤال' : 'حفظ السؤال',
                        style: const TextStyle(
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

  Widget _section(String label, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: kAdminFont,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: HaffarColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    ),
  );

  Widget _multiline(TextEditingController controller, String hint) => TextField(
    controller: controller,
    maxLines: null,
    minLines: 2,
    style: const TextStyle(fontFamily: kAdminFont, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: kAdminFont,
        fontSize: 12,
        color: HaffarColors.grey3,
      ),
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontFamily: kAdminFont, fontSize: 12),
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  );

  Widget _optionsSection() {
    final showCorrectRadio = switch (_type) {
      QuestionType.multipleChoice ||
      QuestionType.definition ||
      QuestionType.reading ||
      QuestionType.diagram ||
      QuestionType.calculation => true,
      _ => false,
    };
    final showCategories = _type == QuestionType.classification;
    final hint = switch (_type) {
      QuestionType.matching =>
        'العمود الأول: أول نصف — العمود الثاني: ثاني نصف',
      QuestionType.ordering =>
        'الترتيب الافتراضي كما تكتبه (أو حدّد ترتيباً خاصاً)',
      _ => 'اختر الإجابة الصحيحة',
    };
    return _section(
      'الخيارات',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hint,
            style: const TextStyle(
              fontFamily: kAdminFont,
              fontSize: 11,
              color: HaffarColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          RadioGroup<int>(
            groupValue: _correctIndex,
            onChanged: (v) =>
                setState(() => _correctIndex = v ?? _correctIndex),
            child: Column(
              children: [
                for (var i = 0; i < _optionControllers.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        if (showCorrectRadio)
                          Radio<int>(
                            value: i,
                            activeColor: HaffarColors.primary,
                          ),
                        if (showCategories)
                          DropdownButton<String>(
                            value: _categories[i],
                            isDense: true,
                            style: const TextStyle(
                              fontFamily: kAdminFont,
                              fontSize: 13,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: '0',
                                child: Text('فئة 1'),
                              ),
                              DropdownMenuItem(
                                value: '1',
                                child: Text('فئة 2'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _categories[i] = v ?? '0'),
                          ),
                        if (showCategories) const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _optionControllers[i],
                            style: const TextStyle(
                              fontFamily: kAdminFont,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'خيار ${i + 1}',
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
                          tooltip: 'حذف الخيار',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _removeOption(i),
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: HaffarColors.grey3,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'إضافة خيار',
                style: TextStyle(fontFamily: kAdminFont, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _correctWordsSection() {
    final label = switch (_type) {
      QuestionType.fillBlank => 'الإجابات الصحيحة (بدائل مقبولة)',
      QuestionType.ordering =>
        'ترتيب الإجابة الصحيح (اختياري — الافتراضي كما تكتبه)',
      _ => 'الإجابات الرقمية المقبولة',
    };
    return _section(
      label,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < _correctWords.length; i++)
                Chip(
                  label: Text(
                    _correctWords[i],
                    style: const TextStyle(
                      fontFamily: kAdminFont,
                      fontSize: 12,
                    ),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeWord(i),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addWordController,
                  style: const TextStyle(fontFamily: kAdminFont, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'اكتب إجابة ثم أضفها...',
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
                  onSubmitted: (_) => _addWord(),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _addWord,
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'إضافة',
                  style: TextStyle(fontFamily: kAdminFont, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    title: Text(
      widget.questionId == null ? 'سؤال جديد' : 'تعديل السؤال',
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
