import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/store.dart';
import 'package:pantry/views/checklists/checklist_item_list.dart';

import '../helpers/test_models.dart';

// `groupItemsByStore` backs the sticky store headers. Unlike categories, an
// item's store link is many-valued, so an item is emitted once under each store
// it belongs to; items with no (resolvable) store fall under a trailing "No
// store" group. Store groups follow `sortedStores` order; items within a group
// sort by `sortOrder` (tie-break name), honouring a custom within-column order.

Store _store(int id, String name, {int sortOrder = 0}) => Store(
  id: id,
  houseId: 1,
  name: name,
  icon: 'store',
  color: '#ef4444',
  sortOrder: sortOrder,
  createdAt: 0,
  updatedAt: 0,
);

void main() {
  group('groupItemsByStore', () {
    test('emits an item once under each store it belongs to', () {
      final stores = [_store(1, 'Aldi'), _store(2, 'Bakery')];
      final items = [
        makeListItem(id: 10, name: 'Bread', storeIds: [1, 2]),
      ];

      final groups = groupItemsByStore(items, stores);

      expect(groups.map((g) => g.storeId).toList(), [1, 2]);
      expect(groups[0].items.single.id, 10);
      expect(groups[1].items.single.id, 10);
    });

    test(
      'groups follow sortedStores order, items name-sort on equal order',
      () {
        final stores = [_store(2, 'Bakery'), _store(1, 'Aldi')];
        final items = [
          makeListItem(id: 10, name: 'Zucchini', storeIds: [1]),
          makeListItem(id: 11, name: 'Apples', storeIds: [1]),
          makeListItem(id: 12, name: 'Baguette', storeIds: [2]),
        ];

        final groups = groupItemsByStore(items, stores);

        expect(groups.map((g) => g.storeId).toList(), [2, 1]);
        expect(groups[0].items.map((i) => i.id).toList(), [12]);
        // Equal sortOrder → name tie-break: Apples (11) before Zucchini (10).
        expect(groups[1].items.map((i) => i.id).toList(), [11, 10]);
      },
    );

    test('within a group, sortOrder wins over name', () {
      final stores = [_store(1, 'Aldi')];
      final items = [
        // Alphabetically Apples < Zucchini, but sortOrder puts Zucchini first.
        makeListItem(id: 10, name: 'Zucchini', storeIds: [1], sortOrder: 0),
        makeListItem(id: 11, name: 'Apples', storeIds: [1], sortOrder: 1),
      ];

      final groups = groupItemsByStore(items, stores);

      expect(groups.single.items.map((i) => i.id).toList(), [10, 11]);
    });

    test('a multi-store item keeps one sortOrder across its columns', () {
      final stores = [_store(1, 'Aldi'), _store(2, 'Bakery')];
      final items = [
        makeListItem(id: 10, name: 'Cookies', storeIds: [1, 2], sortOrder: 0),
        makeListItem(id: 11, name: 'Bread', storeIds: [1], sortOrder: 1),
        makeListItem(id: 12, name: 'Cake', storeIds: [2], sortOrder: 1),
      ];

      final groups = groupItemsByStore(items, stores);

      // Cookies (sortOrder 0) leads in both its columns despite its later name.
      expect(groups[0].items.map((i) => i.id).toList(), [10, 11]);
      expect(groups[1].items.map((i) => i.id).toList(), [10, 12]);
    });

    test('items with no store fall under a trailing null group', () {
      final stores = [_store(1, 'Aldi')];
      final items = [
        makeListItem(id: 10, name: 'Milk', storeIds: [1]),
        makeListItem(id: 11, name: 'Unassigned'),
      ];

      final groups = groupItemsByStore(items, stores);

      expect(groups.map((g) => g.storeId).toList(), [1, null]);
      expect(groups.last.items.single.id, 11);
    });

    test('ids referencing a deleted store fall under "No store"', () {
      // Store 99 no longer exists among the known stores.
      final stores = [_store(1, 'Aldi')];
      final items = [
        makeListItem(id: 10, name: 'Orphan', storeIds: [99]),
      ];

      final groups = groupItemsByStore(items, stores);

      expect(groups.map((g) => g.storeId).toList(), [null]);
      expect(groups.single.items.single.id, 10);
    });

    test('empty groups are omitted', () {
      final stores = [_store(1, 'Aldi'), _store(2, 'Empty')];
      final items = [
        makeListItem(id: 10, name: 'Milk', storeIds: [1]),
      ];

      final groups = groupItemsByStore(items, stores);

      expect(groups.map((g) => g.storeId).toList(), [1]);
    });

    test('empty input yields no groups', () {
      expect(groupItemsByStore(const <ListItem>[], const <Store>[]), isEmpty);
    });
  });
}
