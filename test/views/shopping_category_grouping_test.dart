import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry/views/shopping/shopping_session_controller.dart';

import '../helpers/test_models.dart';

// `groupShoppingItemsByCategory` backs the category headers on the dense
// shopping screen: one block per category, in the house's category order.

void main() {
  group('groupShoppingItemsByCategory', () {
    final dairy = makeCategory(id: 1, name: 'Dairy', sortOrder: 0);
    final fruits = makeCategory(id: 2, name: 'Fruits', sortOrder: 0);
    final categories = {dairy.id: dairy, fruits.id: fruits};

    test('keeps a category whole when the server interleaves two of them', () {
      // Categories tied on sortOrder fall through to the item order, so the
      // server hands back dairy/fruits/dairy/fruits.
      final items = [
        makeListItem(id: 1, name: 'Milk', categoryId: dairy.id),
        makeListItem(id: 2, name: 'Apples', categoryId: fruits.id),
        makeListItem(id: 3, name: 'Butter', categoryId: dairy.id),
        makeListItem(id: 4, name: 'Strawberries', categoryId: fruits.id),
        makeListItem(id: 5, name: 'Buttermilk', categoryId: dairy.id),
      ];

      final groups = groupShoppingItemsByCategory(items, categories);

      expect(groups.map((g) => g.category?.id).toList(), [dairy.id, fruits.id]);
      expect(groups[0].items.map((i) => i.id).toList(), [1, 3, 5]);
      expect(groups[1].items.map((i) => i.id).toList(), [2, 4]);
    });

    test('orders groups by sortOrder, not by first appearance', () {
      final produce = makeCategory(id: 3, name: 'Produce', sortOrder: 1);
      final bakery = makeCategory(id: 4, name: 'Bakery', sortOrder: 0);
      final items = [
        makeListItem(id: 1, categoryId: produce.id),
        makeListItem(id: 2, categoryId: bakery.id),
      ];

      final groups = groupShoppingItemsByCategory(items, {
        produce.id: produce,
        bakery.id: bakery,
      });

      expect(groups.map((g) => g.category?.id).toList(), [
        bakery.id,
        produce.id,
      ]);
    });

    test('breaks a sortOrder tie on name, so ties order predictably', () {
      final items = [
        makeListItem(id: 1, categoryId: fruits.id),
        makeListItem(id: 2, categoryId: dairy.id),
      ];

      final groups = groupShoppingItemsByCategory(items, categories);

      expect(groups.map((g) => g.category?.name).toList(), ['Dairy', 'Fruits']);
    });

    test('uncategorized items land in one trailing group', () {
      final items = [
        makeListItem(id: 1, categoryId: null),
        makeListItem(id: 2, categoryId: dairy.id),
        makeListItem(id: 3, categoryId: null),
      ];

      final groups = groupShoppingItemsByCategory(items, categories);

      expect(groups.map((g) => g.category?.id).toList(), [dairy.id, null]);
      expect(groups.last.items.map((i) => i.id).toList(), [1, 3]);
    });

    test('categories missing from reference data trail in server order', () {
      final items = [
        makeListItem(id: 1, categoryId: 98),
        makeListItem(id: 2, categoryId: dairy.id),
        makeListItem(id: 3, categoryId: 97),
        makeListItem(id: 4, categoryId: null),
        makeListItem(id: 5, categoryId: 98),
      ];

      final groups = groupShoppingItemsByCategory(items, categories);

      expect(groups.map((g) => g.category).toList(), [
        dairy,
        isNull,
        isNull,
        isNull,
      ]);
      expect(groups[1].items.map((i) => i.id).toList(), [1, 5]);
      expect(groups[2].items.map((i) => i.id).toList(), [3]);
      expect(groups[3].items.map((i) => i.id).toList(), [4]);
    });

    test('empty input yields no groups', () {
      expect(
        groupShoppingItemsByCategory(const <ListItem>[], categories),
        isEmpty,
      );
    });
  });
}
