import 'package:flutter/material.dart';

/// A full-lesson skeleton offered when adding a new lesson. The markdown
/// seeds `lessons.summary`; the lesson is still created as a draft the admin
/// edits before publishing.
class LessonTemplate {
  const LessonTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.markdown = '',
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;

  /// Initial `lessons.summary` content; empty means a blank lesson.
  final String markdown;

  bool get isBlank => markdown.trim().isEmpty;
}

/// Built-in lesson templates shown in the add-lesson picker.
const List<LessonTemplate> kLessonTemplates = [
  LessonTemplate(
    id: 'blank',
    title: 'درس فارغ',
    description: 'ابدأ من الصفر بدون محتوى مسبق',
    icon: Icons.note_add_outlined,
  ),
  LessonTemplate(
    id: 'traditional',
    title: 'شرح تقليدي',
    description: 'تمهيد وأهداف ثم شرح وخلاصة',
    icon: Icons.menu_book_outlined,
    markdown:
        '## التمهيد\n\n'
        'اكتب هنا تمهيداً قصيراً يربط الدرس بما قبله.\n\n'
        '## أهداف الدرس\n\n'
        '- الهدف الأول\n'
        '- الهدف الثاني\n\n'
        '## الشرح\n\n'
        'اكتب شرح الدرس هنا، وقسّمه بعناوين فرعية عند الحاجة.\n\n'
        '## خلاصة الدرس\n\n'
        '- أهم نقطة يتذكرها الطالب',
  ),
  LessonTemplate(
    id: 'examples',
    title: 'شرح مع أمثلة',
    description: 'شرح مختصر يتبعه مثال محلول وتدريب',
    icon: Icons.calculate_outlined,
    markdown:
        '## شرح مختصر\n\n'
        'اكتب الفكرة الأساسية في فقرتين كحد أقصى.\n\n'
        '## مثال محلول\n\n'
        '**المسألة:** اكتب نص المسألة هنا.\n\n'
        '**الحل:**\n\n'
        '1. الخطوة الأولى\n'
        '2. الخطوة الثانية\n\n'
        '**الإجابة:** اكتب النتيجة النهائية.\n\n'
        '## تدريب\n\n'
        '**السؤال:** سؤال قصير للتطبيق.',
  ),
  LessonTemplate(
    id: 'review',
    title: 'مراجعة واختبار',
    description: 'أهم النقاط وأخطاء شائعة وتدريب ختامي',
    icon: Icons.fact_check_outlined,
    markdown:
        '## ملخص سريع\n\n'
        'اكتب ملخص الدرس في نقاط.\n\n'
        '## أهم النقاط\n\n'
        '- نقطة مهمة ١\n'
        '- نقطة مهمة ٢\n\n'
        '## أخطاء شائعة\n\n'
        '> **تنبيه:** الخطأ الشائع: اكتب الخطأ — التصحيح: الإجابة الصحيحة.\n\n'
        '## تدريب ختامي\n\n'
        '1. سؤال أول\n'
        '2. سؤال ثانٍ',
  ),
];
