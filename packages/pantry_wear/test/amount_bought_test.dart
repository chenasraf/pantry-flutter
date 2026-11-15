import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/checklists/item_detail_page.dart';
import 'package:pantry_wear/src/wear_shape.dart';

import 'wear_fixtures.dart';

/// The phone's amount-bought stepper, on the watch: a row there keeps its one
/// tap for checking off, so the stepper lives on the item's detail page, with
/// the phone's rules for when it shows and how far it steps.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final manager = SyncManager.instance;

  setUp(() {
    WearShape.markFrom(['round']);
    manager.setOnline(false);
  });

  tearDown(() {
    unawaited(manager.reset());
    ServerVersionService.instance.debugSeed();
  });

  ChecklistsController seeded(
    ListItem item, {
    bool trip = true,
    ChecklistList? list,
    bool canEditLists = true,
  }) {
    final controller = ChecklistsController.seeded(
      houseId: 1,
      lists: [list ?? testList()],
      items: item.done ? const [] : [item],
      done: item.done ? [item] : const [],
      session: trip ? testSession() : null,
      canEditLists: canEditLists,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  Future<void> pump(
    WidgetTester tester,
    ChecklistsController controller,
    ListItem item,
  ) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ItemDetailPage(item: item, controller: controller),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder step(String label) => find.bySemanticsLabel(label);

  group('when it shows', () {
    test('a counted to-buy item on a trip', () {
      final item = testItem(id: 1, name: 'Milk', quantity: '2 L');
      expect(seeded(item).canStepAmount(item), isTrue);
    });

    test('not off a trip, where nothing is being bought', () {
      final item = testItem(id: 1, name: 'Milk', quantity: '2 L');
      expect(seeded(item, trip: false).canStepAmount(item), isFalse);
    });

    for (final quantity in [null, 'some']) {
      test('not for a quantity of $quantity', () {
        final item = testItem(id: 1, name: 'Milk', quantity: quantity);
        expect(seeded(item).canStepAmount(item), isFalse);
      });
    }

    test('not for an item already in the cart', () {
      final item = testItem(id: 1, name: 'Milk', quantity: '2 L', done: true);
      expect(seeded(item).canStepAmount(item), isFalse);
    });

    test('not on a list shared for viewing only', () {
      ServerVersionService.instance.debugSeed(
        pantryVersion: Version.parse('0.39.0'),
      );
      final item = testItem(id: 1, name: 'Milk', quantity: '2 L');
      const readOnly = ChecklistList(
        id: 4,
        houseId: 1,
        name: 'Groceries',
        icon: 'shopping-cart',
        sortOrder: 0,
        createdAt: 0,
        updatedAt: 0,
        sharedOnly: true,
        canEdit: false,
      );
      expect(seeded(item, list: readOnly).canStepAmount(item), isFalse);
    });

    test('not for a member who may only check items off', () {
      final item = testItem(id: 1, name: 'Milk', quantity: '2 L');
      expect(seeded(item, canEditLists: false).canStepAmount(item), isFalse);
    });
  });

  testWidgets('a step keeps the unit and queues the new amount', (
    tester,
  ) async {
    final item = testItem(id: 1, name: 'Milk', quantity: '2 L');
    final controller = seeded(item);
    await pump(tester, controller, item);

    await tester.tap(step(m.shopping.buyMore));
    await tester.pump();

    expect(find.text('3 L'), findsOneWidget);
    expect(controller.items.single.quantity, '3 L');
    expect(manager.queuedOps.single.body, {'quantity': '3 L'});
  });

  testWidgets('− is off at 1', (tester) async {
    final item = testItem(id: 1, name: 'Bread', quantity: '1 loaf');
    final controller = seeded(item);
    await pump(tester, controller, item);

    await tester.tap(step(m.shopping.buyLess));
    await tester.pump();

    expect(find.text('1 loaf'), findsOneWidget);
    expect(manager.queuedOps, isEmpty);
  });

  test('a refused step puts the amount back and says so', () async {
    final item = testItem(id: 1, name: 'Milk', quantity: '2 L');
    final controller = seeded(item)..listenToSyncForTest();

    controller.stepAmount(item, 1);
    expect(controller.items.single.quantity, '3 L');
    manager.deadLetterForTest(manager.queuedOps.single);
    await Future<void>.delayed(Duration.zero);

    expect(controller.items.single.quantity, '2 L');
    expect(controller.droppedMessage, m.shopping.quantityFailed);
  });
}
