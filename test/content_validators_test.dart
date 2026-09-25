import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/utils/content_validators.dart';

void main() {
  group('validateSubjectId', () {
    test('accepts typical slugs', () {
      expect(validateSubjectId('math'), isNull);
      expect(validateSubjectId('ict'), isNull);
      expect(validateSubjectId('social_studies'), isNull);
      expect(validateSubjectId(' bio1 '), isNull);
    });

    test('rejects invalid slugs', () {
      expect(validateSubjectId(''), isNotNull);
      expect(validateSubjectId('1abc'), isNotNull);
      expect(validateSubjectId('Math'), isNotNull);
      expect(validateSubjectId('with space'), isNotNull);
      expect(validateSubjectId('ماده'), isNotNull);
      expect(validateSubjectId('a'), isNotNull); // too short
      expect(validateSubjectId('x' * 41), isNotNull);
    });
  });

  group('validateRequiredText', () {
    test('empty and whitespace are rejected', () {
      expect(validateRequiredText('', 'العنوان'), isNotNull);
      expect(validateRequiredText('   ', 'العنوان'), isNotNull);
    });

    test('trims and enforces max length', () {
      expect(validateRequiredText(' عنوان ', 'العنوان'), isNull);
      expect(validateRequiredText('x' * 301, 'العنوان', max: 300), isNotNull);
    });
  });

  group('validateColorHex', () {
    test('accepts #RRGGBB', () {
      expect(validateColorHex('#FD7202'), isNull);
      expect(validateColorHex('#abcdef'), isNull);
    });

    test('rejects other formats', () {
      expect(validateColorHex('FD7202'), isNotNull);
      expect(validateColorHex('#FFF'), isNotNull);
      expect(validateColorHex('#GGGGGG'), isNotNull);
      expect(validateColorHex(''), isNotNull);
    });
  });

  group('validateXpReward / validateSortOrder', () {
    test('bounds', () {
      expect(validateXpReward(0), isNotNull);
      expect(validateXpReward(1), isNull);
      expect(validateXpReward(1000), isNull);
      expect(validateXpReward(1001), isNotNull);
      expect(validateSortOrder(-1), isNotNull);
      expect(validateSortOrder(0), isNull);
      expect(validateSortOrder(10000), isNotNull);
    });
  });

  group('validateImageUrl', () {
    test('null and empty pass (image optional)', () {
      expect(validateImageUrl(null), isNull);
      expect(validateImageUrl('  '), isNull);
    });

    test('http(s) URLs pass, junk fails', () {
      expect(validateImageUrl('https://x.co/a.png'), isNull);
      expect(validateImageUrl('http://x.co/a.png'), isNull);
      expect(validateImageUrl('ftp://x.co/a.png'), isNotNull);
      expect(validateImageUrl('not a url'), isNotNull);
    });
  });

  group('validateQuestion', () {
    Map<String, Object?> base = {
      'type': 'multipleChoice',
      'text': 'سؤال؟',
      'options': <String>['أ', 'ب', 'ج', 'د'],
      'correctIndex': 2,
    };

    String? run({
      String? type,
      String? text,
      List<String>? options,
      int? correctIndex,
      List<String>? correctWords,
      List<String>? itemCategories,
      String? imageUrl,
    }) => validateQuestion(
      type: type ?? base['type']! as String,
      text: text ?? base['text']! as String,
      options: options ?? base['options']! as List<String>,
      correctIndex: correctIndex ?? base['correctIndex']! as int,
      correctWords: correctWords,
      itemCategories: itemCategories,
      imageUrl: imageUrl,
    );

    test('valid multiple choice passes', () {
      expect(run(), isNull);
    });

    test('empty text is rejected', () {
      expect(run(text: '  '), isNotNull);
    });

    test('correctIndex must address an existing option', () {
      expect(run(correctIndex: 4), isNotNull);
      expect(run(correctIndex: -1), isNotNull);
      expect(run(correctIndex: 3), isNull);
    });

    test('multiple choice needs at least two options', () {
      expect(run(options: ['أ'], correctIndex: 0), isNotNull);
    });

    test('trueFalse only accepts 0/1', () {
      expect(run(type: 'trueFalse', options: [], correctIndex: 0), isNull);
      expect(run(type: 'trueFalse', options: [], correctIndex: 1), isNull);
      expect(run(type: 'trueFalse', options: [], correctIndex: 2), isNotNull);
    });

    test('matching needs an even number of items', () {
      expect(
        run(type: 'matching', options: ['أ', 'ب', 'ج', 'د'], correctIndex: 0),
        isNull,
      );
      expect(
        run(type: 'matching', options: ['أ', 'ب', 'ج'], correctIndex: 0),
        isNotNull,
      );
    });

    test('ordering accepts options with or without an explicit order', () {
      expect(run(type: 'ordering', options: ['أ', 'ب', 'ج']), isNull);
      expect(
        run(
          type: 'ordering',
          options: ['أ', 'ب', 'ج'],
          correctWords: ['ج', 'أ', 'ب'],
        ),
        isNull,
      );
      expect(
        run(
          type: 'ordering',
          options: ['أ', 'ب', 'ج'],
          correctWords: ['ج', 'أ'],
        ),
        isNotNull,
      );
    });

    test('classification requires a category per item', () {
      expect(
        run(
          type: 'classification',
          options: ['أ', 'ب'],
          itemCategories: ['0', '1'],
          correctIndex: 0,
        ),
        isNull,
      );
      expect(
        run(
          type: 'classification',
          options: ['أ', 'ب'],
          itemCategories: ['0'],
          correctIndex: 0,
        ),
        isNotNull,
      );
      expect(
        run(
          type: 'classification',
          options: ['أ', 'ب'],
          itemCategories: ['0', '2'],
          correctIndex: 0,
        ),
        isNotNull,
      );
      expect(
        run(type: 'classification', options: ['أ', 'ب'], correctIndex: 0),
        isNotNull,
      );
    });

    test('fillBlank requires at least one non-empty answer', () {
      expect(run(type: 'fillBlank', options: [], correctWords: []), isNotNull);
      expect(
        run(type: 'fillBlank', options: [], correctWords: ['جواب']),
        isNull,
      );
      expect(
        run(type: 'fillBlank', options: [], correctWords: ['  ']),
        isNotNull,
      );
    });

    test('calculation accepts options or a written answer', () {
      expect(
        run(type: 'calculation', options: ['1', '2'], correctIndex: 0),
        isNull,
      );
      expect(
        run(
          type: 'calculation',
          options: [],
          correctWords: ['42'],
          correctIndex: 0,
        ),
        isNull,
      );
      expect(
        run(
          type: 'calculation',
          options: [],
          correctWords: [],
          correctIndex: 0,
        ),
        isNotNull,
      );
      expect(
        run(type: 'calculation', options: ['1', '2'], correctIndex: 5),
        isNotNull,
      );
    });

    test('reading needs options; explanation/composition only need text', () {
      expect(run(type: 'reading'), isNull);
      expect(run(type: 'reading', options: []), isNotNull);
      expect(run(type: 'explanation', options: []), isNull);
      expect(run(type: 'composition', options: []), isNull);
    });

    test('invalid image url is rejected', () {
      expect(run(imageUrl: 'not-a-url'), isNotNull);
      expect(run(imageUrl: 'https://x.co/a.png'), isNull);
    });

    test('diagram requires an image and valid options', () {
      expect(
        run(type: 'diagram', options: ['أ', 'ب'], correctIndex: 0),
        isNotNull,
      );
      expect(
        run(
          type: 'diagram',
          options: ['أ', 'ب'],
          correctIndex: 0,
          imageUrl: 'https://x.co/a.png',
        ),
        isNull,
      );
      expect(
        run(
          type: 'diagram',
          options: [],
          correctIndex: 0,
          imageUrl: 'https://x.co/a.png',
        ),
        isNotNull,
      );
    });
  });

  group('type capability helpers', () {
    test('options usage', () {
      expect(typeUsesOptions('multipleChoice'), isTrue);
      expect(typeUsesOptions('classification'), isTrue);
      expect(typeUsesOptions('trueFalse'), isFalse);
      expect(typeUsesOptions('composition'), isFalse);
    });

    test('correct words usage', () {
      expect(typeUsesCorrectWords('fillBlank'), isTrue);
      expect(typeUsesCorrectWords('ordering'), isTrue);
      expect(typeUsesCorrectWords('matching'), isFalse);
    });

    test('hint and passage usage', () {
      expect(typeUsesHint('multipleChoice'), isTrue);
      expect(typeUsesHint('reading'), isFalse);
      expect(typeUsesPassage('reading'), isTrue);
      expect(typeUsesPassage('explanation'), isTrue);
      expect(typeUsesPassage('multipleChoice'), isFalse);
    });
  });

  group('contentImagePath', () {
    test('builds a deterministic path from injected parts', () {
      expect(
        contentImagePath(
          mimeType: 'image/png',
          timestampMicros: 123,
          randomHex: 'abc123',
        ),
        'editor/123-abc123.png',
      );
      expect(
        contentImagePath(
          mimeType: 'image/jpeg',
          timestampMicros: 5,
          randomHex: 'ff',
          folder: 'lessons',
        ),
        'lessons/5-ff.jpg',
      );
    });

    test('unknown mime falls back to bin, blank folder to editor', () {
      expect(
        contentImagePath(
          mimeType: 'image/tiff',
          timestampMicros: 7,
          randomHex: '00',
          folder: '  ',
        ),
        'editor/7-00.bin',
      );
    });
  });

  group('validateImageBytes', () {
    test('size limits', () {
      expect(validateImageBytes(0), isNotNull);
      expect(validateImageBytes(1024), isNull);
      expect(validateImageBytes(maxUploadBytes), isNull);
      expect(validateImageBytes(maxUploadBytes + 1), isNotNull);
    });
  });
}
