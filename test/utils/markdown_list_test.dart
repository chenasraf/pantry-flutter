import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/models/category.dart';
import 'package:pantry/utils/markdown_list.dart';

import '../helpers/test_models.dart';

void main() {
  final produce = makeCategory(id: 10, name: 'Produce', icon: 'food-apple');
  Category? categoryFor(int? id) => id == produce.id ? produce : null;

  // 2026-06-26 (Dart months are 1-based).
  final now = DateTime(2026, 6, 26);

  group('buildListMarkdown', () {
    test('renders title and export date', () {
      final md = buildListMarkdown('Groceries', [], categoryFor, now: now);
      expect(md, contains('# Groceries'));
      expect(md, contains('_Exported 2026-06-26_'));
    });

    test('groups items under category headings, uncategorized last', () {
      final md = buildListMarkdown(
        'Groceries',
        [
          makeListItem(id: 1, name: 'Milk', categoryId: null),
          makeListItem(id: 2, name: 'Apples', categoryId: produce.id),
        ],
        categoryFor,
        now: now,
      );
      final produceIdx = md.indexOf('## Produce');
      final uncatIdx = md.indexOf('## Uncategorized');
      expect(produceIdx, greaterThan(-1));
      expect(uncatIdx, greaterThan(produceIdx));
    });

    test('renders checkbox state and inline quantity/description', () {
      final md = buildListMarkdown(
        'Groceries',
        [
          makeListItem(name: 'Apples', quantity: '1 kg', done: false),
          makeListItem(name: 'Bananas', done: true),
          makeListItem(name: 'Milk', quantity: '2 L', description: 'organic'),
        ],
        categoryFor,
        now: now,
      );
      expect(md, contains('- [ ] Apples — 1 kg'));
      expect(md, contains('- [x] Bananas'));
      expect(md, contains('- [ ] Milk — 2 L — organic'));
    });

    test('flattens newlines in descriptions', () {
      final md = buildListMarkdown(
        'L',
        [makeListItem(name: 'X', description: 'a\nb')],
        categoryFor,
        now: now,
      );
      expect(md, contains('- [ ] X — a b'));
    });
  });

  group('parseMarkdownItems', () {
    test('parses checkbox items with state', () {
      expect(parseMarkdownItems('- [ ] Milk\n- [x] Bread'), const [
        ParsedMarkdownItem(name: 'Milk', done: false),
        ParsedMarkdownItem(name: 'Bread', done: true),
      ]);
    });

    test('parses plain bullets and ordered lists', () {
      expect(
        parseMarkdownItems('- Apples\n* Bananas\n+ Pears\n1. Grapes\n2) Plums'),
        const [
          ParsedMarkdownItem(name: 'Apples', done: false),
          ParsedMarkdownItem(name: 'Bananas', done: false),
          ParsedMarkdownItem(name: 'Pears', done: false),
          ParsedMarkdownItem(name: 'Grapes', done: false),
          ParsedMarkdownItem(name: 'Plums', done: false),
        ],
      );
    });

    test('ignores headings, prose and blank lines', () {
      const text =
          '# Groceries\n\n_Exported 2026-06-26_\n\n## Produce\n- Apples\n\nsome note\n';
      expect(parseMarkdownItems(text), const [
        ParsedMarkdownItem(name: 'Apples', done: false),
      ]);
    });

    test('strips the quantity/description suffix to recover the name', () {
      expect(parseMarkdownItems('- [ ] Milk — 2 L — organic'), const [
        ParsedMarkdownItem(name: 'Milk', done: false),
      ]);
    });

    test('round-trips names from buildListMarkdown', () {
      final md = buildListMarkdown(
        'Groceries',
        [
          makeListItem(
            name: 'Apples',
            quantity: '1 kg',
            categoryId: produce.id,
          ),
        ],
        categoryFor,
        now: now,
      );
      expect(parseMarkdownItems(md), const [
        ParsedMarkdownItem(name: 'Apples', done: false),
      ]);
    });

    test('skips empty checkbox lines', () {
      expect(parseMarkdownItems('- [ ] \n-   '), isEmpty);
    });
  });
}
