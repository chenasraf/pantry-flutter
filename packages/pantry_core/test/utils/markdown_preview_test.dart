import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/utils/markdown_preview.dart';

void main() {
  group('markdownPreview', () {
    test('passes plain text through', () {
      expect(markdownPreview('1.5%'), '1.5%');
    });

    test('marks each line break', () {
      expect(markdownPreview('1.5%\nfresh'), '1.5% · fresh');
      expect(markdownPreview('a\n\n\nb'), 'a · b');
    });

    test('drops emphasis, strong and strikethrough', () {
      expect(markdownPreview('**1.5%** fresh'), '1.5% fresh');
      expect(markdownPreview('_fresh_ milk'), 'fresh milk');
      expect(markdownPreview('~~gone~~ now'), 'gone now');
    });

    test('leaves word-internal underscores and lone asterisks alone', () {
      expect(
        markdownPreview('snake_case_name and 3 * 4 = 12'),
        'snake_case_name and 3 * 4 = 12',
      );
    });

    test('drops headings, bullets, numbering and task checkboxes', () {
      expect(markdownPreview('# Heading\n\nbody'), 'Heading · body');
      expect(markdownPreview('- [ ] Milk\n- [x] Eggs'), 'Milk · Eggs');
      expect(markdownPreview('1. first\n2) second'), 'first · second');
      expect(markdownPreview('> quoted'), 'quoted');
    });

    test('keeps the text of a link and the alt text of an image', () {
      expect(
        markdownPreview('See [the site](https://example.com) now'),
        'See the site now',
      );
      expect(markdownPreview('![a photo](x.png) here'), 'a photo here');
      expect(markdownPreview('![only an image](x.png)'), 'only an image');
      expect(markdownPreview('[text][ref] here'), 'text here');
      expect(markdownPreview('<https://example.com>'), 'https://example.com');
    });

    test('drops code fences, backticks, html and comments', () {
      expect(markdownPreview('use `pub get` first'), 'use pub get first');
      expect(markdownPreview('```\ncode\n```'), 'code');
      expect(markdownPreview('<b>bold</b> text'), 'bold text');
      expect(markdownPreview('<!-- hidden -->visible'), 'visible');
    });

    test('drops thematic breaks and table rules', () {
      expect(markdownPreview('---\nafter'), 'after');
      expect(
        markdownPreview('| a | b |\n|---|---|\n| 1 | 2 |'),
        '| a | b | · | 1 | 2 |',
      );
    });

    test('unescapes backslash-escaped punctuation', () {
      expect(markdownPreview(r'literal \*stars\*'), 'literal *stars*');
    });

    test('collapses runs of whitespace', () {
      expect(markdownPreview('a   \t  b'), 'a b');
    });

    test('is empty for a description carrying no text', () {
      expect(markdownPreview(''), '');
      expect(markdownPreview('   '), '');
      expect(markdownPreview('![](x.png)'), '');
      expect(markdownPreview('---'), '');
    });

    test('caps how much of a long description it reads', () {
      final preview = markdownPreview('${'x' * 600} tail');
      expect(preview.length, lessThan(600));
      expect(preview, isNot(contains('tail')));
    });

    test('never cuts an emoji in half', () {
      final preview = markdownPreview('${'x' * 499}🎉tail');
      expect(preview.codeUnits, isNot(contains(0xD83C)));
    });
  });
}
