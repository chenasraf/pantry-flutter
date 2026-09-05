import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/shell/wear_shell.dart';
import 'package:pantry_wear/src/wear_shape.dart';

import 'wear_fixtures.dart';

/// Grouping follows the house's own `checklistItemSort`, the same pref the
/// phone and the web app read — so a household that shops by store sees its
/// stores on the wrist too. It is house data, not a device setting, which is
/// what keeps it clear of the watch's no-pref-sync rule.
void main() {
  setUp(() => WearShape.markFrom(['round']));

  Future<void> pump(WidgetTester tester, ChecklistsController c) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(c.dispose);
    await tester.pumpWidget(MaterialApp(home: WearShell(controller: c)));
    await tester.pumpAndSettle();
  }

  testWidgets('store sort buckets by store, and repeats a shared item', (
    tester,
  ) async {
    await pump(
      tester,
      ChecklistsController.seeded(
        houseId: 1,
        list: testList(),
        lists: [testList()],
        itemSort: 'store',
        categories: [testCategory(id: 1, name: 'Dairy')],
        stores: [
          testStore(id: 1, name: 'Corner shop', sortOrder: 0),
          testStore(id: 2, name: 'Market', sortOrder: 1),
        ],
        items: [
          testItem(id: 1, name: 'Milk', categoryId: 1, storeIds: [1, 2]),
          testItem(id: 2, name: 'Apples', categoryId: 1, storeIds: [2]),
          testItem(id: 3, name: 'Batteries', categoryId: 1),
        ],
      ),
    );

    expect(find.text('Corner shop'), findsWidgets);
    expect(find.text('Market'), findsOneWidget);
    // Sold in both, so it is on both shopping trips.
    expect(find.text('Milk'), findsNWidgets(2));
    expect(find.text('Apples'), findsOneWidget);
    // Assigned to no store at all, so it lands in the trailing bucket.
    expect(find.text(m.checklists.noStore), findsOneWidget);
  });

  testWidgets('the chip naming the grouping is the one that never draws', (
    tester,
  ) async {
    await pump(
      tester,
      ChecklistsController.seeded(
        houseId: 1,
        list: testList(),
        lists: [testList()],
        itemSort: 'store',
        categories: [testCategory(id: 1, name: 'Dairy')],
        stores: [testStore(id: 1, name: 'Corner shop', sortOrder: 0)],
        items: [
          testItem(id: 1, name: 'Milk', categoryId: 1, storeIds: [1]),
        ],
      ),
    );

    // The store is said twice — its own header, and the rail naming the
    // focused row's group — and never a third time as a chip on the row.
    expect(find.text('Corner shop'), findsNWidgets(2));
    // The category is free to take the chip the store gave up.
    expect(find.text('Dairy'), findsOneWidget);
  });

  testWidgets('a session never groups by store', (tester) async {
    await pump(
      tester,
      ChecklistsController.seeded(
        houseId: 1,
        itemSort: 'store',
        session: testSession(activeStoreId: 1),
        categories: [testCategory(id: 1, name: 'Dairy')],
        stores: [testStore(id: 1, name: 'Corner shop', sortOrder: 0)],
        items: [
          testItem(id: 1, name: 'Milk', categoryId: 1, storeIds: [1]),
        ],
      ),
    );

    // Category headers, even though the house sorts by store: the header and
    // the rail both say the category.
    expect(find.text('Dairy'), findsNWidgets(2));
    // The store is on the rail as the place you are standing in, and on the
    // row as a chip, but it is not what the list is cut into.
    expect(find.text('Corner shop'), findsNWidgets(2));
  });
}
