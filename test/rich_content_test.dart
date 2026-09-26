import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
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

  group('insertMarkdownAt', () {
    QuillController makeController(String source) => QuillController(
      document: documentFromMarkdown(source),
      selection: const TextSelection.collapsed(offset: 0),
    );

    List<String> lines(QuillController c) => markdownFromDocument(
      c.document,
    ).split('\n').where((l) => l.trim().isNotEmpty).toList();

    test('inserts a paragraph into an empty document and moves the caret', () {
      final c = makeController('');
      insertMarkdownAt(c, 'نص جديد');
      expect(markdownFromDocument(c.document), 'نص جديد');
      expect(c.selection.isValid, isTrue);
      expect(c.selection.end, c.document.length - 1);
    });

    test('splits the line when inserting mid-text', () {
      final c = makeController('abc');
      insertMarkdownAt(c, 'نص', at: 1);
      final mdLines = lines(c);
      expect(mdLines.first, 'a');
      expect(mdLines, contains('نص'));
      expect(mdLines.last, 'bc');
    });

    test('inserting at the end of the content starts a new line', () {
      final c = makeController('abc');
      insertMarkdownAt(c, 'نص', at: 3);
      final md = markdownFromDocument(c.document);
      expect(md, startsWith('abc'));
      expect(md, contains('نص'));
      expect(md, isNot(contains('abcنص')));
    });

    test('inserting at a line start keeps surrounding lines intact', () {
      final c = makeController('abc\ndef');
      insertMarkdownAt(c, 'نص', at: 4);
      expect(lines(c), ['abc', 'نص', 'def']);
    });

    test('uses the current selection when at is omitted', () {
      final c = makeController('abc');
      c.updateSelection(
        const TextSelection.collapsed(offset: 1),
        ChangeSource.local,
      );
      insertMarkdownAt(c, 'نص');
      final mdLines = lines(c);
      expect(mdLines.first, 'a');
      expect(mdLines.last, 'bc');
    });

    test('stale out-of-range offsets are clamped into the document', () {
      final c = makeController('abc');
      insertMarkdownAt(c, 'نص', at: 999);
      expect(markdownFromDocument(c.document), contains('نص'));
      expect(c.selection.end, c.document.length - 1);
    });

    test('multi-block markdown keeps headers and paragraphs', () {
      final c = makeController('');
      insertMarkdownAt(c, '## عنوان\n\nفقرة تجريبية');
      final md = markdownFromDocument(c.document);
      expect(md, contains('## عنوان'));
      expect(md, contains('فقرة تجريبية'));
      expect(lines(c).length, 2);
    });

    test('image embeds do not glue the next block onto their line', () {
      final c = makeController('');
      insertMarkdownAt(c, '![](https://example.com/a.png)');
      insertMarkdownAt(c, 'نص بعد الصورة');
      final md = markdownFromDocument(c.document);
      expect(md, contains('![](https://example.com/a.png)'));
      expect(md, contains('نص بعد الصورة'));
      expect(md, isNot(contains('.pngنص')));
      expect(lines(c).length, 2);
    });

    test('empty markdown is a no-op', () {
      final c = makeController('abc');
      final before = markdownFromDocument(c.document);
      final selectionBefore = c.selection;
      insertMarkdownAt(c, '   ');
      expect(markdownFromDocument(c.document), before);
      expect(c.selection, selectionBefore);
    });
  });
}
