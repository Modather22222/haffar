import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/utils/rich_content.dart';

/// md → delta → md must converge (second serialization equals first), and a
/// second parse must produce the identical delta (no information loss).
void expectRoundTrip(String source) {
  final md1 = deltaToMarkdown(markdownToDelta(source));
  final d1 = markdownToDelta(source);
  final d2 = markdownToDelta(md1);
  final md2 = deltaToMarkdown(d2);
  expect(md2, md1, reason: 'serialization must be stable for: $source');
  expect(
    d2.toString(),
    d1.toString(),
    reason: 'delta must round trip for: $source',
  );
}

void main() {
  group('markdownToDelta / deltaToMarkdown', () {
    test('empty inputs yield empty output', () {
      expect(markdownToDelta('').isEmpty, isTrue);
      expect(markdownToDelta('   \n  ').isEmpty, isTrue);
      expect(deltaToMarkdown(Delta()), '');
    });

    test('plain Arabic paragraph round trips without escaping litter', () {
      const source = 'هذه فقرة تجريبية بالعربية.';
      final out = deltaToMarkdown(markdownToDelta(source));
      expect(out, source);
      expectRoundTrip(source);
    });

    test('bold and italic round trip', () {
      const source = 'نص **مهم** ونص *مائل* هنا.';
      final out = deltaToMarkdown(markdownToDelta(source));
      expect(out, contains('**مهم**'));
      expect(out, anyOf(contains('*مائل*'), contains('_مائل_')));
      expectRoundTrip(source);
    });

    test('image embed round trips to markdown image syntax', () {
      const source = '![](https://example.com/pic.png)';
      final delta = markdownToDelta(source);
      final hasImageEmbed = delta.toList().any(
        (op) => op.data is Map && (op.data as Map).containsKey('image'),
      );
      expect(hasImageEmbed, isTrue);
      expect(deltaToMarkdown(delta), source);
      expectRoundTrip(source);
    });

    test('image embed survives between paragraphs', () {
      const source =
          'قبل الصورة\n\n![](https://example.com/chart.png)\n\nبعد الصورة';
      final out = deltaToMarkdown(markdownToDelta(source));
      expect(out, contains('![](https://example.com/chart.png)'));
      expect(out, contains('قبل الصورة'));
      expect(out, contains('بعد الصورة'));
      expectRoundTrip(source);
    });

    test('headers round trip with header attributes', () {
      const source = '# عنوان أول\n\nنص تحت العنوان.';
      final out = deltaToMarkdown(markdownToDelta(source));
      expect(out, contains('# عنوان أول'));
      expect(out, contains('نص تحت العنوان.'));
      expectRoundTrip(source);
    });

    test('h2 maps to header attribute level 2', () {
      final delta = markdownToDelta('## فاصل');
      final levels = delta
          .toList()
          .map((op) => op.attributes?['header'])
          .whereType<int>();
      expect(levels.isEmpty ? null : levels.first, 2);
    });

    test('unordered list round trips', () {
      const source = '- أول\n- ثاني';
      final out = deltaToMarkdown(markdownToDelta(source));
      expect(out, contains('- أول'));
      expect(out, contains('- ثاني'));
      expectRoundTrip(source);
    });

    test('soft line break keeps both lines', () {
      const source = 'سطر أول\nسطر ثانٍ';
      final out = deltaToMarkdown(markdownToDelta(source));
      expect(out, contains('سطر أول'));
      expect(out, contains('سطر ثانٍ'));
      expectRoundTrip(source);
    });

    test('blockquote round trips', () {
      const source = '> اقتباس مهم';
      final out = deltaToMarkdown(markdownToDelta(source));
      expect(out, contains('>'));
      expect(out, contains('اقتباس مهم'));
      expectRoundTrip(source);
    });

    test('conversion is stable from realistic mixed content', () {
      const source =
          '# تمهيد\n\nمقدمة **مهمة** مع *مائل*.\n\n1. نقطة\n2. نقطة\n\n> اقتباس\n\n- عنصر';
      final once = deltaToMarkdown(markdownToDelta(source));
      final twice = deltaToMarkdown(markdownToDelta(once));
      expect(twice, once);
      expect(twice, contains('مقدمة'));
      expect(twice, contains('اقتباس'));
      expect(twice, contains('عنصر'));
    });

    test('mid-line numbered text is not turned into a list', () {
      const source = 'الخطوة 1. يتم التحقق أولاً.';
      final once = deltaToMarkdown(markdownToDelta(source));
      final twice = deltaToMarkdown(markdownToDelta(once));
      expect(twice, once);
      expect(twice, isNot(contains('\n1.')));
      expect(twice, contains('1.'));
    });
  });

  group('document helpers', () {
    test('documentFromMarkdown / markdownFromDocument round trip', () {
      const source = 'عنوان **عريض** للمحرر.';
      final doc = documentFromMarkdown(source);
      expect(markdownFromDocument(doc), source);
      expect(doc.toDelta().isEmpty, isFalse);
    });

    test('documentFromMarkdown on empty input builds an empty document', () {
      final doc = documentFromMarkdown('');
      expect(markdownFromDocument(doc), '');
    });
  });
}
