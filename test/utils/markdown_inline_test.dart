import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/utils/markdown_inline.dart';

void main() {
  /// `marker:text` for markers, `[styles]text` for content.
  List<String> describe(String source) => [
    for (final s in parseInlineMarkdown(source))
      s.marker
          ? 'marker:${s.text}'
          : '${(s.styles.map((e) => e.name).toList()..sort())}${s.text}',
  ];

  group('parseInlineMarkdown', () {
    test('segments always add back up to the source', () {
      for (final source in [
        'plain',
        '**bold** and _italic_',
        '***both***',
        '`a ** b` then **c**',
        '[the docs](https://example.com) ~~gone~~',
        'snake_case_name stays plain',
        '2 * 3 * 4',
      ]) {
        final joined = parseInlineMarkdown(source).map((s) => s.text).join();
        expect(joined, source, reason: source);
      }
    });

    test('styles content and separates markers', () {
      expect(describe('a **b** c'), [
        '[]a ',
        'marker:**',
        '[bold]b',
        'marker:**',
        '[] c',
      ]);
    });

    test('nests styles', () {
      expect(describe('**a _b_**'), [
        'marker:**',
        '[bold]a ',
        'marker:_',
        '[bold, italic]b',
        'marker:_',
        'marker:**',
      ]);
    });

    test('code spans are literal', () {
      expect(describe('`**x**`'), ['marker:`', '[code]**x**', 'marker:`']);
    });

    test('links keep the address in the closing marker', () {
      expect(describe('[docs](https://x.y)'), [
        'marker:[',
        '[link]docs',
        'marker:](https://x.y)',
      ]);
    });

    test('underscores inside words and spaced asterisks stay plain', () {
      expect(describe('snake_case_name'), ['[]snake_case_name']);
      expect(describe('2 * 3 * 4'), ['[]2 * 3 * 4']);
    });
  });

  group('toggleInlineStyle', () {
    TextEditingValue value(String text, int start, [int? end]) =>
        TextEditingValue(
          text: text,
          selection: TextSelection(
            baseOffset: start,
            extentOffset: end ?? start,
          ),
        );

    test('wraps the selection and keeps it selected', () {
      final next = toggleInlineStyle(value('a milk b', 2, 6), InlineStyle.bold);
      expect(next.text, 'a **milk** b');
      expect(
        next.selection,
        const TextSelection(baseOffset: 4, extentOffset: 8),
      );
      expect(isInlineStyleActive(next, InlineStyle.bold), isTrue);
    });

    test('unwraps markers just outside the selection', () {
      final next = toggleInlineStyle(
        value('a **milk** b', 4, 8),
        InlineStyle.bold,
      );
      expect(next.text, 'a milk b');
      expect(
        next.selection,
        const TextSelection(baseOffset: 2, extentOffset: 6),
      );
    });

    test('unwraps markers selected along with the text', () {
      final next = toggleInlineStyle(
        value('a **milk** b', 2, 10),
        InlineStyle.bold,
      );
      expect(next.text, 'a milk b');
      expect(
        next.selection,
        const TextSelection(baseOffset: 2, extentOffset: 6),
      );
    });

    test('a collapsed caret gets an empty pair to type into', () {
      final next = toggleInlineStyle(value('ab', 1), InlineStyle.code);
      expect(next.text, 'a``b');
      expect(next.selection, const TextSelection.collapsed(offset: 2));
    });

    test('italic is not mistaken for half of an underscore bold', () {
      expect(
        isInlineStyleActive(value('__milk__', 2, 6), InlineStyle.italic),
        isFalse,
      );
      expect(
        isInlineStyleActive(value('__milk__', 2, 6), InlineStyle.bold),
        isFalse,
      );
    });

    test('link wraps the text and leaves the caret for the address', () {
      final next = toggleInlineStyle(value('see docs', 4, 8), InlineStyle.link);
      expect(next.text, 'see [docs]()');
      expect(next.selection, const TextSelection.collapsed(offset: 11));
    });
  });
}
