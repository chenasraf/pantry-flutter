import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/shopping_reminder.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_wear/src/shopping/start_trip_controller.dart';
import 'package:pantry_wear/src/shopping/start_trip_page.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/focus_list.dart';
import 'package:pantry_wear/src/widgets/wear_choice_page.dart';

import 'wear_fixtures.dart';

/// The page a wearer starts a trip from. Its four rows are choices and its one
/// button is the act, so what these guard is that the choices arrive already
/// made and the act refuses to happen when it cannot succeed.
void main() {
  setUp(() {
    WearShape.markFrom(['round']);
    SyncManager.instance.setOnline(true);
  });

  tearDown(() => SyncManager.instance.setOnline(true));

  ShoppingReminder reminder({
    required int id,
    required String text,
    ShoppingReminderMoment showOn = ShoppingReminderMoment.onStart,
    bool enabled = true,
  }) => ShoppingReminder(
    id: id,
    houseId: 1,
    text: text,
    showOn: showOn,
    position: id,
    enabled: enabled,
    createdAt: 0,
    updatedAt: 0,
  );

  StartTripController seeded({int? scopeListId}) => StartTripController.seeded(
    houseId: 1,
    lists: [
      testList(id: 4),
      testList(id: 5, name: 'Hardware'),
    ],
    itemsByList: {
      4: [
        testItem(id: 1, name: 'Milk', storeIds: const [7]),
      ],
      5: [
        testItem(id: 2, name: 'Bulbs', listId: 5, storeIds: const [8]),
      ],
    },
    stores: [
      testStore(id: 7, name: 'Corner shop'),
      testStore(id: 8, name: 'Hardware store', sortOrder: 1),
    ],
    reminders: [
      reminder(id: 1, text: 'Bring the tote bags'),
      reminder(
        id: 2,
        text: 'Check the receipt',
        showOn: ShoppingReminderMoment.onClose,
      ),
      reminder(id: 3, text: 'Turned off', enabled: false),
    ],
    scopeListId: scopeListId,
  );

  Future<StartTripController> pump(
    WidgetTester tester, {
    int? scopeListId,
  }) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = seeded(scopeListId: scopeListId);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: StartTripPage(houseId: 1, controller: controller)),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  test('the scoped list is the one selected, and its stores with it', () {
    final controller = seeded(scopeListId: 5);
    addTearDown(controller.dispose);

    // The page opens ready to start, so the wearer confirms rather than
    // configures — and the stores follow the list they came in on.
    expect(controller.selectedListIds, {5});
    expect(controller.enabledStoreIds, {8});
  });

  test('the all-lists scope selects every list', () {
    final controller = seeded(scopeListId: kAllListsId);
    addTearDown(controller.dispose);

    expect(controller.selectedListIds, {4, 5});
    expect(controller.enabledStoreIds, {7, 8});
  });

  test('a store stops being offered when its list is dropped', () {
    final controller = seeded(scopeListId: kAllListsId);
    addTearDown(controller.dispose);

    controller.selectLists({4});

    // Only the stores the selected lists' un-done items reference: a leg
    // nothing is being bought at is not a leg.
    expect(controller.availableStores.map((s) => s.id), [7]);
    expect(controller.enabledStoreIds, {7});
  });

  test('the legs run in the house order, not the order the items did', () {
    final controller = StartTripController.seeded(
      houseId: 1,
      lists: [testList(id: 4)],
      itemsByList: {
        4: [
          testItem(id: 1, name: 'Milk', storeIds: const [8]),
          testItem(id: 2, name: 'Bulbs', storeIds: const [7]),
        ],
      },
      stores: [
        testStore(id: 7, name: 'Aaa', sortOrder: 0),
        testStore(id: 8, name: 'Bbb', sortOrder: 1),
      ],
      scopeListId: 4,
    );
    addTearDown(controller.dispose);

    // Leg order is the house's `storeSort`, which is what the phone seeds a
    // trip from — there is nothing to drag here, so there is nothing to differ.
    expect(controller.availableStores.map((s) => s.name), ['Aaa', 'Bbb']);
  });

  test('only the enabled start reminders are offered', () {
    final controller = seeded(scopeListId: 4);
    addTearDown(controller.dispose);

    expect(controller.reminders.map((r) => r.text), ['Bring the tote bags']);
  });

  testWidgets('the button says why it cannot be pressed', (tester) async {
    final controller = await pump(tester, scopeListId: 4);
    expect(find.text(m.wear.needsConnection), findsNothing);

    // Start is online-only: `getItems` is narrowed by the active store
    // server-side, so a queued create has nothing to show for itself.
    SyncManager.instance.setOnline(false);
    await tester.pumpAndSettle();

    expect(find.text(m.wear.needsConnection), findsOneWidget);
    expect(controller.blockedReason, m.wear.needsConnection);
  });

  testWidgets('a trip with no lists is blocked, and says so', (tester) async {
    final controller = await pump(tester, scopeListId: 4);

    controller.selectLists({});
    await tester.pumpAndSettle();

    expect(find.text(m.wear.pickAList), findsOneWidget);
  });

  testWidgets('privacy answers in place', (tester) async {
    final controller = await pump(tester, scopeListId: 4);
    expect(controller.isPrivate, isFalse);

    // Onto the centre line first. Privacy is the last row, and the call to
    // action stands over where it starts — which is the mis-aim rule doing its
    // job rather than a row out of reach: the trailing clearance is what lets
    // it scroll clear of the button.
    await tester.drag(find.byType(SnapFocusList), const Offset(0, -162));
    await tester.pumpAndSettle();

    await tester.tap(find.text(m.wear.privateTrip));
    await tester.pumpAndSettle();
    expect(controller.isPrivate, isTrue);

    // The one row that does not open a page: a switch shows its value and the
    // outcome of a tap at once, which is what the open-a-page rule guards.
    expect(find.byType(WearMultiChoicePage<int>), findsNothing);
  });

  testWidgets('a leg turned off in the picker is a leg the trip drops', (
    tester,
  ) async {
    final controller = await pump(tester, scopeListId: kAllListsId);
    expect(controller.enabledStoreIds, {7, 8});

    // Onto the centre line, which is where a row is acted on — and the only
    // place on this page that the call to action is not standing over.
    await tester.drag(find.byType(SnapFocusList), const Offset(0, -108));
    await tester.pumpAndSettle();

    await tester.tap(find.text(m.shopping.storesTitle));
    await tester.pumpAndSettle();
    expect(find.byType(WearMultiChoicePage<int>), findsOneWidget);

    await tester.tap(find.text('Hardware store'));
    await tester.pumpAndSettle();

    // The picker reports as it goes rather than on the way out: the back
    // gesture is what closes it, and a gesture cannot carry a result.
    expect(controller.enabledStoreIds, {7});
  });

  testWidgets('the rows carry what they would be opening away from', (
    tester,
  ) async {
    await pump(tester, scopeListId: 4);

    expect(find.text(m.shopping.remindersTitle), findsOneWidget);
    expect(find.text(m.shopping.listsToShop), findsOneWidget);
    expect(find.text(m.shopping.storesTitle), findsOneWidget);
    expect(find.text(m.wear.nSelected(1)), findsWidgets);
  });
}
