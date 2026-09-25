/// Pure validation for the admin content editor. Every function returns an
/// Arabic user-facing message, or `null` when the value is valid. Kept free of
/// Flutter/Supabase imports so it can be unit-tested directly.
library;

final _idPattern = RegExp(r'^[a-z][a-z0-9_]{1,39}$');
final _colorPattern = RegExp(r'^#[0-9a-fA-F]{6}$');
final _urlPattern = RegExp(r'^https?://');

/// Subject id: lowercase slug used as the questions/lessons foreign key and
/// as the key for subject artwork — immutable after creation.
String? validateSubjectId(String id) {
  final value = id.trim();
  if (value.isEmpty) return 'المعرّف مطلوب';
  if (!_idPattern.hasMatch(value)) {
    return 'المعرّف يبدأ بحرف إنجليزي صغير ويحتوي حروفاً إنجليزية وأرقاماً فقط';
  }
  return null;
}

String? validateRequiredText(String value, String label, {int max = 300}) {
  final v = value.trim();
  if (v.isEmpty) return '$label مطلوب';
  if (v.length > max) return '$label طويل جداً (الحد $max حرف)';
  return null;
}

String? validateColorHex(String value) {
  final v = value.trim();
  if (v.isEmpty) return 'اللون مطلوب';
  if (!_colorPattern.hasMatch(v)) return 'اللون بصيغة ‎#RRGGBB‎';
  return null;
}

String? validateSortOrder(int value) {
  if (value < 0 || value > 9999) return 'ترتيب العرض من 0 إلى 9999';
  return null;
}

String? validateXpReward(int value) {
  if (value < 1 || value > 1000) return 'نقاط الخبرة من 1 إلى 1000';
  return null;
}

/// Optional remote image URL (uploaded images are https Supabase URLs).
String? validateImageUrl(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  if (!_urlPattern.hasMatch(value.trim())) return 'رابط الصورة غير صالح';
  return null;
}

/// Per-type question validation. Guards the invariants the student widgets
/// rely on (correct answer indexing, even matching pairs, answer keys).
String? validateQuestion({
  required String type,
  required String text,
  required List<String> options,
  required int correctIndex,
  List<String>? correctWords,
  List<String>? itemCategories,
  String? passage,
  String? imageUrl,
}) {
  final textError = validateRequiredText(text, 'نص السؤال', max: 2000);
  if (textError != null) return textError;
  final urlError = validateImageUrl(imageUrl);
  if (urlError != null) return urlError;

  switch (type) {
    case 'trueFalse':
      if (correctIndex != 0 && correctIndex != 1) {
        return 'الإجابة الصحيحة: صواب (0) أو خطأ (1)';
      }
      return null;
    case 'multipleChoice':
    case 'definition':
    case 'reading':
      if (options.length < 2) return 'أضف خيارين على الأقل';
      if (correctIndex < 0 || correctIndex >= options.length) {
        return 'حدّد الإجابة الصحيحة من الخيارات';
      }
      return null;
    case 'diagram':
      if (imageUrl == null || imageUrl.trim().isEmpty) {
        return 'ارفع صورة الرسم أو البيانات';
      }
      if (options.length < 2) return 'أضف خيارين على الأقل';
      if (correctIndex < 0 || correctIndex >= options.length) {
        return 'حدّد الإجابة الصحيحة من الخيارات';
      }
      return null;
    case 'matching':
      if (options.length < 2 || options.length.isOdd) {
        return 'المزاوجة تحتاج عدداً زوجياً من العناصر (2 على الأقل)';
      }
      if (correctIndex >= options.length) return 'رقم الإجابة غير صالح';
      return null;
    case 'ordering':
      if (options.length < 2) return 'أضف عنصرين على الأقل للترتيب';
      if (correctWords != null &&
          correctWords.isNotEmpty &&
          correctWords.length != options.length) {
        return 'ترتيب الإجابة يجب أن يطابق عدد العناصر';
      }
      return null;
    case 'classification':
      if (options.length < 2) return 'أضف عنصرين على الأقل للتصنيف';
      if (itemCategories == null || itemCategories.isEmpty) {
        return 'صنّف كل عنصر إلى فئة';
      }
      if (itemCategories.length != options.length) {
        return 'عدد التصنيفات يجب أن يطابق عدد العناصر';
      }
      if (itemCategories.any((c) => c != '0' && c != '1')) {
        return 'الفئتان المسموحتان: 0 و 1';
      }
      return null;
    case 'fillBlank':
      if (correctWords == null || correctWords.isEmpty) {
        return 'أضف الإجابة أو الإجابات الصحيحة';
      }
      if (correctWords.any((w) => w.trim().isEmpty)) {
        return 'لا تترك إجابة فارغة';
      }
      return null;
    case 'calculation':
      final hasOptions = options.length >= 2;
      final hasWords = correctWords != null && correctWords.isNotEmpty;
      if (!hasOptions && !hasWords) {
        return 'أضف خيارات أو إجابة رقمية صحيحة';
      }
      if (hasOptions && (correctIndex < 0 || correctIndex >= options.length)) {
        return 'حدّد الإجابة الصحيحة من الخيارات';
      }
      return null;
    case 'composition':
    case 'explanation':
      return null;
    default:
      return 'نوع سؤال غير مدعوم';
  }
}

/// True when [type] renders a selectable option list in the student app.
bool typeUsesOptions(String type) => const {
  'multipleChoice',
  'definition',
  'reading',
  'diagram',
  'matching',
  'ordering',
  'classification',
  'calculation',
}.contains(type);

/// True when the type grades against [correctWords] instead of an index.
bool typeUsesCorrectWords(String type) =>
    const {'fillBlank', 'ordering', 'calculation'}.contains(type);

/// True when the type shows a hint card.
bool typeUsesHint(String type) =>
    const {'multipleChoice', 'fillBlank', 'calculation'}.contains(type);

/// True when the type shows a passage/context block.
bool typeUsesPassage(String type) => const {
  'reading',
  'explanation',
  'composition',
  'calculation',
}.contains(type);

/// Storage path for an uploaded content image (public `content` bucket).
/// [timestampMicros], [randomHex] and [folder] are injected for deterministic
/// tests.
String contentImagePath({
  required String mimeType,
  required int timestampMicros,
  required String randomHex,
  String folder = 'editor',
}) {
  final ext = switch (mimeType) {
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'image/webp' => 'webp',
    'image/gif' => 'gif',
    _ => 'bin',
  };
  final safeFolder = folder.trim().isEmpty ? 'editor' : folder.trim();
  return '$safeFolder/$timestampMicros-$randomHex.$ext';
}

const maxUploadBytes = 5 * 1024 * 1024;

/// Validates picked image bytes before upload.
String? validateImageBytes(int byteLength) {
  if (byteLength <= 0) return 'تعذّر قراءة الصورة';
  if (byteLength > maxUploadBytes) return 'الصورة أكبر من 5 ميجابايت';
  return null;
}
