import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';

import '../helpers/test_models.dart';

// The server orders checklist items purely by their sort key (created_at,
// name, category rank) and never groups done items at the end — done rows sit
// wherever their key places them. `checklistInsertIndex` must mirror that so a
// freshly added item lands where a refresh would put it. See issue #81.

/// No categories configured — everything is uncategorized.
int _noRank(int? _) => 1 << 30;

/// The index the item ends up at within the *active* partition, which is what
/// the view actually renders (it splits active/done for display).
int _activePositionAfterInsert(List<ListItem> items, String sort, ListItem n) {
  final at = checklistInsertIndex(items, sort, n, _noRank);
  final merged = [...items]..insert(at, n);
  return merged.where((i) => !i.done).toList().indexWhere((i) => i.id == n.id);
}

void main() {
  group('checklistInsertIndex — oldest sort', () {
    test('new item lands at the bottom when a done item sorts first', () {
      // Reproduces #81: an old *completed* item is the earliest by created_at,
      // so it appears first in the server order. The buggy boundary logic
      // collapsed to that done item's index and inserted the new item at the
      // top.
      final items = [
        makeListItem(id: 1, name: 'old done', done: true, createdAt: 100),
        makeListItem(id: 2, name: 'a', createdAt: 200),
        makeListItem(id: 3, name: 'b', createdAt: 300),
      ];
      final n = makeListItem(id: 99, name: 'new', createdAt: 400);

      // Last among the active items, not the top.
      expect(_activePositionAfterInsert(items, 'oldest', n), 2);
    });

    test('new item lands at the bottom with no done items', () {
      final items = [
        makeListItem(id: 1, name: 'a', createdAt: 100),
        makeListItem(id: 2, name: 'b', createdAt: 200),
      ];
      final n = makeListItem(id: 99, name: 'new', createdAt: 300);
      expect(checklistInsertIndex(items, 'oldest', n, _noRank), 2);
    });
  });

  group('checklistInsertIndex — newest sort', () {
    test('new item lands at the top even with an interleaved done item', () {
      final items = [
        makeListItem(id: 1, name: 'b', createdAt: 300),
        makeListItem(id: 2, name: 'old done', done: true, createdAt: 200),
        makeListItem(id: 3, name: 'a', createdAt: 100),
      ];
      final n = makeListItem(id: 99, name: 'new', createdAt: 400);
      expect(_activePositionAfterInsert(items, 'newest', n), 0);
    });
  });

  group('checklistInsertIndex — name sorts', () {
    test('name_asc slots alphabetically, skipping the done partition', () {
      final items = [
        makeListItem(id: 1, name: 'apple', createdAt: 100),
        makeListItem(id: 2, name: 'banana', done: true, createdAt: 150),
        makeListItem(id: 3, name: 'cherry', createdAt: 200),
      ];
      final n = makeListItem(id: 99, name: 'blueberry', createdAt: 400);
      // Active order should read apple, blueberry, cherry.
      expect(_activePositionAfterInsert(items, 'name_asc', n), 1);
    });

    test('name_desc slots reverse-alphabetically', () {
      final items = [
        makeListItem(id: 1, name: 'cherry', createdAt: 100),
        makeListItem(id: 2, name: 'apple', createdAt: 200),
      ];
      final n = makeListItem(id: 99, name: 'banana', createdAt: 400);
      expect(checklistInsertIndex(items, 'name_desc', n, _noRank), 1);
    });
  });

  group('checklistInsertIndex — category sort', () {
    test('groups by category rank across interleaved done items', () {
      int rankOf(int? id) => switch (id) {
        10 => 0,
        20 => 1,
        _ => 1 << 30,
      };
      final items = [
        makeListItem(id: 1, name: 'a', categoryId: 10, createdAt: 100),
        makeListItem(
          id: 2,
          name: 'b',
          categoryId: 20,
          done: true,
          createdAt: 150,
        ),
        makeListItem(id: 3, name: 'c', categoryId: 20, createdAt: 200),
      ];
      final n = makeListItem(
        id: 99,
        name: 'new',
        categoryId: 10,
        createdAt: 400,
      );
      // Rank-0 item: slots after the existing rank-0 item, before rank-1.
      expect(checklistInsertIndex(items, 'category', n, rankOf), 1);
    });
  });

  group('checklistInsertIndex — custom sort', () {
    test('new item goes to the top', () {
      final items = [makeListItem(id: 1, name: 'a', createdAt: 100)];
      final n = makeListItem(id: 99, name: 'new', createdAt: 400);
      expect(checklistInsertIndex(items, 'custom', n, _noRank), 0);
    });
  });
}
