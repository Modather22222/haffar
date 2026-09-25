/// Arabic labels for question types. The canonical type names are the
/// `QuestionType` enum names in `models/question.dart` (matching the
/// `questions.type` CHECK constraint); the editor passes `type.name`.
library;

const Map<String, String> questionTypeLabels = {
  'multipleChoice': 'اختيار من متعدد',
  'trueFalse': 'صواب / خطأ',
  'fillBlank': 'أكمل الفراغ',
  'matching': 'مزاوجة',
  'definition': 'تعريف',
  'ordering': 'ترتيب',
  'reading': 'قراءة',
  'calculation': 'حساب',
  'classification': 'تصنيف',
  'diagram': 'رسم / بيان',
  'explanation': 'شرح',
  'composition': 'كتابة',
};

String questionTypeLabel(String type) => questionTypeLabels[type] ?? type;
