import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/utils/lesson_templates.dart';
import 'package:haffar/utils/rich_content.dart';

void main() {
  group('kLessonTemplates', () {
    test('ids are unique and the blank template comes first', () {
      final ids = kLessonTemplates.map((t) => t.id).toSet();
      expect(ids.length, kLessonTemplates.length);
      expect(ids.length, greaterThanOrEqualTo(4));
      expect(kLessonTemplates.first.id, 'blank');
      expect(kLessonTemplates.first.isBlank, isTrue);
    });

    test('only the blank template has empty markdown', () {
      for (final template in kLessonTemplates) {
        if (template.id == 'blank') {
          expect(template.isBlank, isTrue);
        } else {
          expect(template.isBlank, isFalse, reason: template.id);
          expect(template.markdown.trim(), isNotEmpty, reason: template.id);
        }
      }
    });

    test('every template seeds a non-empty publishable summary', () {
      for (final template in kLessonTemplates) {
        if (template.isBlank) continue;
        final delta = markdownToDelta(template.markdown);
        expect(delta.isEmpty, isFalse, reason: template.id);
        final once = deltaToMarkdown(delta);
        expect(once.trim(), isNotEmpty, reason: template.id);
        final twice = deltaToMarkdown(markdownToDelta(once));
        expect(twice, once, reason: 'unstable round trip for ${template.id}');
      }
    });

    test('structured templates carry section headings', () {
      for (final template in kLessonTemplates) {
        if (template.isBlank) continue;
        expect(
          template.markdown,
          contains('## '),
          reason: '${template.id} must have sections',
        );
      }
    });
  });
}
