import 'package:flutter/material.dart';

import '../../../design_system/colors.dart';
import '../../../models/question.dart';
import '../../../utils/question_types.dart';
import '../admin_widgets.dart';

/// How an exercise (تمرين الدرس / تمرين الوحدة) picks the student's
/// questions. Shared by the lesson questions screen and the units editor.
enum QuizDeliveryMode {
  /// Admin-set random count (the normal mode).
  fixedCount,

  /// Admin-pinned explicit questions, display order kept — overrides the
  /// count.
  pinned,
}

/// Editing surface for exercise delivery settings: mode chips, the count
/// editor, and the pinned-question picker with a live student preview.
///
/// The widget owns no state: parents (screen state / dialog state) hold the
/// mode, size text, and selection, and persist through their repository.
/// Works inline (lesson questions screen) and inside dialogs (units editor).
class QuizDeliveryCard extends StatelessWidget {
  final List<Question> questions;
  final QuizDeliveryMode mode;
  final TextEditingController sizeController;
  final List<String> selectedIds;
  final bool busy;
  final ValueChanged<QuizDeliveryMode> onModeChanged;
  final ValueChanged<String> onTogglePinned;
  final ValueChanged<int> onSizeDelta;
  final VoidCallback onSave;

  /// Card heading; null hides it (dialogs supply their own AppBar-like
  /// title).
  final String? title;

  /// Render the full-width save button — hidden inside dialogs where the
  /// AlertDialog action row owns saving.
  final bool showSave;

  const QuizDeliveryCard({
    super.key,
    required this.questions,
    required this.mode,
    required this.sizeController,
    required this.selectedIds,
    required this.busy,
    required this.onModeChanged,
    required this.onTogglePinned,
    required this.onSizeDelta,
    required this.onSave,
    this.title = 'إعدادات التمرين',
    this.showSave = true,
  });

  String get _previewText {
    switch (mode) {
      case QuizDeliveryMode.fixedCount:
        final parsed = int.tryParse(sizeController.text.trim());
        if (parsed == null) {
          return 'أدخل عدد الأسئلة لكل محاولة';
        }
        final count = parsed.clamp(1, 200);
        final n = count.clamp(0, questions.length);
        return questions.isEmpty
            ? 'لا توجد أسئلة بعد — أضف أسئلة أولاً'
            : 'سيشاهد الطالب $n ${quizWord(n)} عشوائياً';
      case QuizDeliveryMode.pinned:
        return selectedIds.isEmpty
            ? 'حدد الأسئلة التي سيراها الطالب بالترتيب'
            : 'سيشاهد الطالب ${selectedIds.length} ${quizWord(selectedIds.length)} بالمحدد';
    }
  }

  static String quizWord(int n) => n == 1 ? 'سؤال' : 'أسئلة';

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      title: title,
      trailing: const Icon(
        Icons.tune,
        size: 18,
        color: HaffarColors.textSecondary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تحكم في عدد أسئلة التمرين وما يظهر للطالب من الأسئلة',
            style: TextStyle(
              fontFamily: kAdminFont,
              fontSize: 12,
              color: HaffarColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _modeChip(
                label: 'عدد محدد',
                selected: mode == QuizDeliveryMode.fixedCount,
                selection: QuizDeliveryMode.fixedCount,
              ),
              _modeChip(
                label: 'أسئلة محددة',
                selected: mode == QuizDeliveryMode.pinned,
                selection: QuizDeliveryMode.pinned,
                enabled: questions.isNotEmpty,
              ),
            ],
          ),
          const SizedBox(height: 14),
          switch (mode) {
            QuizDeliveryMode.fixedCount => _fixedCountEditor(),
            QuizDeliveryMode.pinned => _pinnedPicker(),
          },
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.visibility_outlined,
                size: 16,
                color: HaffarColors.primaryDark,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _previewText,
                  style: const TextStyle(
                    fontFamily: kAdminFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: HaffarColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (showSave) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy ? null : onSave,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: const Text('حفظ الإعدادات'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeChip({
    required String label,
    required bool selected,
    required QuizDeliveryMode selection,
    bool enabled = true,
  }) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: busy || !enabled ? null : (_) => onModeChanged(selection),
    selectedColor: HaffarColors.primary.withValues(alpha: 0.15),
    checkmarkColor: HaffarColors.primaryDark,
    labelStyle: TextStyle(
      fontFamily: kAdminFont,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: selected ? HaffarColors.primaryDark : HaffarColors.textSecondary,
    ),
    side: BorderSide(color: HaffarColors.outline),
    disabledColor: HaffarColors.surface,
  );

  Widget _fixedCountEditor() => Row(
    children: [
      IconButton(
        tooltip: 'إنقاص',
        onPressed: busy ? null : () => onSizeDelta(-1),
        icon: const Icon(Icons.remove_circle_outline),
      ),
      SizedBox(
        width: 96,
        child: TextField(
          controller: sizeController,
          enabled: !busy,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontFamily: kAdminFont,
            fontWeight: FontWeight.w800,
          ),
          decoration: const InputDecoration(
            isDense: true,
            hintText: 'عدد الأسئلة',
          ),
        ),
      ),
      IconButton(
        tooltip: 'زيادة',
        onPressed: busy ? null : () => onSizeDelta(1),
        icon: const Icon(Icons.add_circle_outline),
      ),
      const SizedBox(width: 8),
      const Expanded(
        child: Text(
          'عدد الأسئلة العشوائية في كل محاولة (1–200)',
          style: TextStyle(
            fontFamily: kAdminFont,
            fontSize: 11,
            color: HaffarColors.textSecondary,
          ),
        ),
      ),
    ],
  );

  Widget _pinnedPicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'حدّد الأسئلة التي سيراها الطالب — الترتيب يتبع ترتيب القائمة:',
        style: TextStyle(
          fontFamily: kAdminFont,
          fontSize: 12,
          color: HaffarColors.textSecondary,
        ),
      ),
      const SizedBox(height: 6),
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: questions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, i) {
          final question = questions[i];
          final checked = selectedIds.contains(question.id);
          return InkWell(
            onTap: busy ? null : () => onTogglePinned(question.id),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: checked,
                    onChanged: busy ? null : (_) => onTogglePinned(question.id),
                    activeColor: HaffarColors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: HaffarColors.surface,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: HaffarColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 12,
                        color: HaffarColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: HaffarColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      questionTypeLabel(question.type.name),
                      style: const TextStyle(
                        fontFamily: kAdminFont,
                        fontSize: 10,
                        color: HaffarColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
}

/// Validates and normalizes the current editor state into DB values:
/// count mode → {quizSize}, pinned mode → {quizIds}. `_UnitQuizDialog` and
/// the lesson screen share the semantics; `error` is an Arabic message on
/// invalid input (null = ready).
({String? error, int? quizSize, List<String> quizIds}) resolveQuizDelivery({
  required QuizDeliveryMode mode,
  required TextEditingController sizeController,
  required List<String> selectedIds,
}) => switch (mode) {
  QuizDeliveryMode.fixedCount => switch (int.tryParse(
    sizeController.text.trim(),
  )) {
    null => (
      error: 'أدخل عدد الأسئلة أولاً',
      quizSize: null,
      quizIds: const [],
    ),
    final size =>
      size < 1 || size > 200
          ? (
              error: 'عدد الأسئلة من 1 إلى 200',
              quizSize: null,
              quizIds: const [],
            )
          : (error: null, quizSize: size, quizIds: const []),
  },
  QuizDeliveryMode.pinned =>
    selectedIds.isEmpty
        ? (
            error: 'حدد سؤالاً واحداً على الأقل',
            quizSize: null,
            quizIds: const [],
          )
        : (error: null, quizSize: null, quizIds: List.of(selectedIds)),
};
