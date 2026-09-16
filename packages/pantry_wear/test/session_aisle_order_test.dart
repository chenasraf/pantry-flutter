import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';

import 'wear_fixtures.dart';

/// The wrist walks trips too, and a shop arranged into the order its aisles
/// are walked has to read that way here as well — the watch has no arranging
/// UI, but it is where the arrangement is used.
void main() {
  final categories = [
    testCategory(id: 1, name: 'Dairy', sortOrder: 1),
    testCategory(id: 2, name: 'Produce', sortOrder: 0),
    testCategory(id: 3, name: 'Bakery', sortOrder: 2),
  ];

  ChecklistsController seeded({
    int? activeStoreId,
    List<int> storeCategoryOrder = const [],
  }) => ChecklistsController.seeded(
    houseId: 1,
    categories: categories,
    stores: [testStore(id: 1, name: 'Corner shop')],
    session: activeStoreId == null
        ? null
        : testSession(activeStoreId: activeStoreId),
    storeCategoryOrder: storeCategoryOrder,
  );

  List<String> names(ChecklistsController c) => [
    for (final category in c.sortedCategories) category.name,
  ];

  test('a trip follows the shop it is standing in', () {
    final controller = seeded(activeStoreId: 1, storeCategoryOrder: [1, 3]);
    addTearDown(controller.dispose);

    // Dairy then Bakery are arranged; Produce trails in the house order.
    expect(names(controller), ['Dairy', 'Bakery', 'Produce']);
  });

  test('an unarranged shop keeps the house order', () {
    final controller = seeded(activeStoreId: 1);
    addTearDown(controller.dispose);

    expect(names(controller), ['Produce', 'Dairy', 'Bakery']);
  });

  test('browsing keeps the house order whatever a shop arranges', () {
    final controller = seeded(storeCategoryOrder: [1, 3]);
    addTearDown(controller.dispose);

    expect(names(controller), ['Produce', 'Dairy', 'Bakery']);
  });

  test('advancing to another shop drops the last one\'s aisles', () {
    final controller = seeded(activeStoreId: 1, storeCategoryOrder: [1, 3]);
    addTearDown(controller.dispose);

    controller.seedSession(testSession(activeStoreId: 2));

    expect(names(controller), ['Produce', 'Dairy', 'Bakery']);
  });
}
