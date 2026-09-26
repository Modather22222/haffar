import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/utils/lesson_content_blocks.dart';
import 'package:haffar/utils/rich_content.dart';

void main() {
  group('kLessonContentBlocks', () {
    test('ids are unique and every block is labeled', () {
      final ids = kLessonContentBlocks.map((b) => b.id).toSet();
      expect(ids.length, kLessonContentBlocks.length);
      expect(ids.length, greaterThanOrEqualTo(9));
      for (final block in kLessonContentBlocks) {
        expect(block.title.trim(), isNotEmpty, reason: block.id);
        expect(block.description.trim(), isNotEmpty, reason: block.id);
      }
    });

    test('static blocks carry markdown; the image block uploads instead', () {
      for (final block in kLessonContentBlocks) {
        if (block.requiresImage) {
          expect(block.markdown, isNull, reason: block.id);
        } else {
          expect(block.markdown, isNotNull, reason: block.id);
          expect(block.markdown!.trim(), isNotEmpty, reason: block.id);
        }
      }
      expect(kLessonContentBlocks.where((b) => b.requiresImage).length, 1);
    });

    test('every static block parses to a non-empty stable delta', () {
      for (final block in kLessonContentBlocks) {
        final markdown = block.markdown;
        if (markdown == null) continue;
        final delta = markdownToDelta(markdown);
        expect(delta.isEmpty, isFalse, reason: block.id);
        final once = deltaToMarkdown(delta);
        expect(once.trim(), isNotEmpty, reason: block.id);
        final twice = deltaToMarkdown(markdownToDelta(once));
        expect(twice, once, reason: 'unstable round trip for ${block.id}');
      }
    });
  });
}
