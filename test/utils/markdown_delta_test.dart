import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/utils/markdown_delta.dart';

void main() {
  /// The markdown the editor reports right after Enter is pressed at the end of
  /// [source] — the moment a list or quote opens an item with nothing in it yet.
  String afterEnterAtEnd(String source) {
    final document = markdownToDocument(source);
    document.insert(document.length - 1, '\n');
    return documentToMarkdown(document);
  }

  group('an empty trailing block is left out', () {
    test('bullet, ordered and quote items', () {
      expect(afterEnterAtEnd('- milk'), '- milk');
      expect(afterEnterAtEnd('- milk\n- eggs'), '- milk\n- eggs');
      expect(afterEnterAtEnd('1. first'), '1. first');
      expect(afterEnterAtEnd('> quoted'), '> quoted');
    });

    test('a list holding nothing at all', () {
      final document = markdownToDocument('- milk');
      document.delete(0, 4);
      expect(documentToMarkdown(document), '');
    });
  });

  group('content is left alone', () {
    test('markers with text after them', () {
      for (final source in [
        '- milk',
        '- milk\n- eggs',
        '1. first\n2. second',
        '> quoted',
        '- [ ] eggs',
        'plain prose',
      ]) {
        expect(normalizeMarkdown(source), source);
      }
    });

    test('a trailing horizontal rule survives, and stays put', () {
      final once = normalizeMarkdown('text\n\n---');
      expect(once, 'text\n\n- - -');
      expect(normalizeMarkdown(once), once);
    });
  });

  group('tables', () {
    const table =
        '| Item | Qty |\n'
        '| :--- | ---: |\n'
        '| Milk | 2 |\n'
        '| Eggs | 12 |';

    test('a lone table survives verbatim', () {
      expect(normalizeMarkdown(table), table);
    });

    test('a table between paragraphs keeps its rows and neighbours', () {
      const source = 'Before\n\n$table\n\nAfter';
      final once = normalizeMarkdown(source);
      expect(once, contains(table));
      expect(once, startsWith('Before'));
      expect(once, endsWith('After'));
      expect(normalizeMarkdown(once), once);
    });

    test('editing text elsewhere leaves the table intact', () {
      final document = markdownToDocument('Groceries\n\n$table');
      document.insert(0, 'My ');
      final markdown = documentToMarkdown(document);
      expect(markdown, startsWith('My Groceries'));
      expect(markdown, contains(table));
    });
  });
}
