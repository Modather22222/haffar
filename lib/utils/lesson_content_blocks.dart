import 'package:flutter/material.dart';

/// Grouping for the "insert block" sheet filters.
enum LessonBlockCategory { text, lists, media, structure, saved }

extension LessonBlockCategoryLabel on LessonBlockCategory {
  String get label => switch (this) {
    LessonBlockCategory.text => 'نصوص',
    LessonBlockCategory.lists => 'قوائم',
    LessonBlockCategory.media => 'صور وجداول',
    LessonBlockCategory.structure => 'أمثلة وتنبيهات',
    LessonBlockCategory.saved => 'المحفوظة',
  };
}

/// A predefined content block the admin can insert into the lesson editor at
/// the cursor. Blocks are plain GitHub-Flavored Markdown snippets (stored in
/// `lessons.summary` unchanged) so the student-side markdown renderer needs
/// no new embed support. [requiresImage] blocks upload an image first, then
/// insert its markdown plus a caption line.
class LessonContentBlock {
  const LessonContentBlock({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    this.markdown,
    this.requiresImage = false,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final LessonBlockCategory category;
  final String? markdown;
  final bool requiresImage;
}

/// The built-in block catalog shown in the lesson editor's insert sheet.
const List<LessonContentBlock> kLessonContentBlocks = [
  LessonContentBlock(
    id: 'section',
    title: 'عنوان وفقرة',
    description: 'افتتاح قسم جديد بعنوان ونص تمهيدي',
    icon: Icons.title,
    category: LessonBlockCategory.text,
    markdown:
        '## عنوان القسم\n\nاكتب تمهيد القسم هنا، ثم وضّح الفكرة '
        'الأساسية للطلاب.',
  ),
  LessonContentBlock(
    id: 'objectives',
    title: 'أهداف الدرس',
    description: 'قائمة أهداف تعليمية يتحقق منها في النهاية',
    icon: Icons.flag_outlined,
    category: LessonBlockCategory.text,
    markdown: '### أهداف الدرس\n\n- الهدف الأول\n- الهدف الثاني',
  ),
  LessonContentBlock(
    id: 'summary',
    title: 'خلاصة القسم',
    description: 'تلخيص أهم النقاط قبل الانتقال',
    icon: Icons.summarize_outlined,
    category: LessonBlockCategory.text,
    markdown: '### خلاصة الدرس\n\n- الخلاصة الأولى\n- الخلاصة الثانية',
  ),
  LessonContentBlock(
    id: 'bullets',
    title: 'قائمة نقطية',
    description: 'نقاط مرتّبة بدون تسلسل',
    icon: Icons.format_list_bulleted,
    category: LessonBlockCategory.lists,
    markdown: '- البند الأول\n- البند الثاني\n- البند الثالث',
  ),
  LessonContentBlock(
    id: 'numbered',
    title: 'قائمة مرقمة',
    description: 'خطوات أو ترتيب متسلسل',
    icon: Icons.format_list_numbered,
    category: LessonBlockCategory.lists,
    markdown: '1. الخطوة الأولى\n2. الخطوة الثانية\n3. الخطوة الثالثة',
  ),
  LessonContentBlock(
    id: 'image',
    title: 'صورة مع شرح',
    description: 'ارفع صورة ثم يُدرج أسفلها سطر شرح جاهز للتعديل',
    icon: Icons.image_outlined,
    category: LessonBlockCategory.media,
    requiresImage: true,
  ),
  LessonContentBlock(
    id: 'table',
    title: 'جدول مقارنة',
    description: 'جدول بين خيارين أو أكثر',
    icon: Icons.table_chart_outlined,
    category: LessonBlockCategory.media,
    markdown:
        '| الجانب | الخيار الأول | الخيار الثاني |\n'
        '| --- | --- | --- |\n'
        '| الصف الأول | قيمة | قيمة |\n'
        '| الصف الثاني | قيمة | قيمة |',
  ),
  LessonContentBlock(
    id: 'definition',
    title: 'تعريف مهم',
    description: 'صندوق اقتباس للتعريفات المفتاحية',
    icon: Icons.menu_book_outlined,
    category: LessonBlockCategory.structure,
    markdown: '> **تعريف:** اكتب التعريف الدقيق للمصطلح هنا.',
  ),
  LessonContentBlock(
    id: 'example',
    title: 'مثال محلول',
    description: 'مسألة مع خطوات الحل خطوة بخطوة',
    icon: Icons.calculate_outlined,
    category: LessonBlockCategory.structure,
    markdown:
        '### مثال محلول\n\n**المسألة:** اكتب نص المسألة هنا.\n\n'
        '**الحل:**\n\n1. الخطوة الأولى\n2. الخطوة الثانية\n\n'
        '**الإجابة:** اكتب النتيجة النهائية.',
  ),
  LessonContentBlock(
    id: 'warning',
    title: 'تنبيه وخطأ شائع',
    description: 'تنبيه لخطأ يتكرر عند الطلاب مع تصحيحه',
    icon: Icons.warning_amber_outlined,
    category: LessonBlockCategory.structure,
    markdown:
        '> **تنبيه:** الخطأ الشائع: اكتب الخطأ هنا — '
        'التصحيح: اكتب الإجابة الصحيحة.',
  ),
  LessonContentBlock(
    id: 'practice',
    title: 'تدريب سريع',
    description: 'سؤال قصير مع تلميح للمراجعة',
    icon: Icons.edit_note_outlined,
    category: LessonBlockCategory.structure,
    markdown:
        '### تدريب سريع\n\n**السؤال:** اكتب سؤال التدريب هنا.\n\n'
        '> راجع إجابتك في أسئلة الدرس بعد المحاولة.',
  ),
];
