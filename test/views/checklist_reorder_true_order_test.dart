import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';

import '../helpers/test_models.dart';

// `reorderToTrueOrder` reconstructs the full stored order after a drag: only the
// dragged item moves, every other item keeps its sort_order slot. It backs the
// stable custom order across check/uncheck (#665) and the within-group drags in
// category (#666) and store sort.

/// The order of ids after applying [order] over [items] (sorted by resulting
/// sortOrder). Mirrors what the client persists and the server stores.
List<int> _idsAfter(
  List<ListItem> items,
  List<({int id, int sortOrder})> order,
) {
  final map = {for (final o in order) o.id: o.sortOrder};
  final sorted = [...items]
    ..sort(
      (a, b) => (map[a.id] ?? a.sortOrder).compareTo(map[b.id] ?? b.sortOrder),
    );
  return sorted.map((i) => i.id).toList();
}

void main() {
  group('reorderToTrueOrder — custom (whole active partition)', () {
    test('moving an item down re-slots only it', () {
      final items = [
        makeListItem(id: 1, name: 'a', sortOrder: 0),
        makeListItem(id: 2, name: 'b', sortOrder: 1),
        makeListItem(id: 3, name: 'c', sortOrder: 2),
        makeListItem(id: 4, name: 'd', sortOrder: 3),
      ];
      // Drag id 1 to index 2 (after c) within the scope-without-dragged.
      final order = reorderToTrueOrder(items, items, 1, 2);
      expect(_idsAfter(items, order), [2, 3, 1, 4]);
    });

    test('moving an item up re-slots only it', () {
      final items = [
        makeListItem(id: 1, name: 'a', sortOrder: 0),
        makeListItem(id: 2, name: 'b', sortOrder: 1),
        makeListItem(id: 3, name: 'c', sortOrder: 2),
      ];
      // Drag id 3 to the top.
      final order = reorderToTrueOrder(items, items, 3, 0);
      expect(_idsAfter(items, order), [3, 1, 2]);
    });

    test('checked items keep their slots when an active item is dragged', () {
      // sort_order is the true order independent of done: a done item sits
      // between actives and must not shift when an active item is reordered.
      final all = [
        makeListItem(id: 1, name: 'a', sortOrder: 0),
        makeListItem(id: 2, name: 'b', done: true, sortOrder: 1),
        makeListItem(id: 3, name: 'c', sortOrder: 2),
        makeListItem(id: 4, name: 'd', sortOrder: 3),
      ];
      // Scope is the active partition only (a, c, d) — the reorderable list.
      final scope = all.where((i) => !i.done).toList();
      // Drag id 4 (d) to the top of the active partition.
      final order = reorderToTrueOrder(all, scope, 4, 0);
      // Global true order: d lands just before a; done b keeps its slot after a.
      expect(_idsAfter(all, order), [4, 1, 2, 3]);
    });

    test('no-op when the dragged id is not in scope', () {
      final items = [makeListItem(id: 1, sortOrder: 0)];
      expect(reorderToTrueOrder(items, items, 99, 0), isEmpty);
    });

    test('renumbers every item contiguously from 0', () {
      final items = [
        makeListItem(id: 1, sortOrder: 5),
        makeListItem(id: 2, sortOrder: 9),
        makeListItem(id: 3, sortOrder: 20),
      ];
      final order = reorderToTrueOrder(items, items, 2, 0);
      expect(order.map((o) => o.sortOrder).toList(), [0, 1, 2]);
    });
  });

  group('reorderToTrueOrder — within a group scope', () {
    test('dragging within a category leaves other categories untouched', () {
      // Global true order interleaves two categories by sort_order.
      final all = [
        makeListItem(id: 1, name: 'a', categoryId: 1, sortOrder: 0),
        makeListItem(id: 2, name: 'b', categoryId: 2, sortOrder: 1),
        makeListItem(id: 3, name: 'c', categoryId: 1, sortOrder: 2),
        makeListItem(id: 4, name: 'd', categoryId: 1, sortOrder: 3),
      ];
      // Category-1 column (in sort_order): a(1), c(3), d(4). Drag d to the top.
      final scope = all.where((i) => i.categoryId == 1).toList();
      final order = reorderToTrueOrder(all, scope, 4, 0);
      // d slots before a; category-2 item b keeps its absolute slot.
      expect(_idsAfter(all, order), [4, 1, 2, 3]);
    });

    test('moving within a store column keeps the multi-store coupling', () {
      // Cookies (id 3) is in both columns via one shared sort_order.
      final all = [
        makeListItem(id: 1, name: 'a', storeIds: [1], sortOrder: 0),
        makeListItem(id: 2, name: 'b', storeIds: [2], sortOrder: 1),
        makeListItem(id: 3, name: 'cookies', storeIds: [1, 2], sortOrder: 2),
      ];
      // Store-1 column (sort_order): a(1), cookies(3). Drag cookies to the top.
      final scope = all.where((i) => i.storeIds.contains(1)).toList();
      final order = reorderToTrueOrder(all, scope, 3, 0);
      // cookies now leads globally — so it also leads store-2's column.
      expect(_idsAfter(all, order), [3, 1, 2]);
    });
  });

  group('reseedOrder', () {
    List<int> seededIds(
      List<ListItem> items,
      String basis, [
      List<int>? categoryOrder,
    ]) {
      final order = reseedOrder(items, basis, categoryOrder);
      final map = {for (final o in order) o.id: o.sortOrder};
      final sorted = [...items]
        ..sort((a, b) => map[a.id]!.compareTo(map[b.id]!));
      return sorted.map((i) => i.id).toList();
    }

    test('dateAdded orders oldest first', () {
      final items = [
        makeListItem(id: 1, name: 'z', createdAt: 300),
        makeListItem(id: 2, name: 'a', createdAt: 100),
        makeListItem(id: 3, name: 'm', createdAt: 200),
      ];
      expect(seededIds(items, 'dateAdded'), [2, 3, 1]);
    });

    test('name_asc and name_desc sort by name', () {
      final items = [
        makeListItem(id: 1, name: 'Banana'),
        makeListItem(id: 2, name: 'apple'),
        makeListItem(id: 3, name: 'Cherry'),
      ];
      expect(seededIds(items, 'name_asc'), [2, 1, 3]);
      expect(seededIds(items, 'name_desc'), [3, 1, 2]);
    });

    test('category order groups by header rank, uncategorized last', () {
      final items = [
        makeListItem(id: 1, name: 'b', categoryId: 2),
        makeListItem(id: 2, name: 'a', categoryId: 1),
        makeListItem(id: 3, name: 'c', categoryId: null),
        makeListItem(id: 4, name: 'a', categoryId: 2),
      ];
      // Header order: category 1 then 2; within a category, name_asc.
      final ids = seededIds(items, 'name_asc', [1, 2]);
      expect(ids, [2, 4, 1, 3]);
    });

    test('renumbers contiguously from 0', () {
      final items = [
        makeListItem(id: 1, name: 'a'),
        makeListItem(id: 2, name: 'b'),
      ];
      final order = reseedOrder(items, 'name_asc', null);
      expect(order.map((o) => o.sortOrder).toList(), [0, 1]);
    });
  });
}
