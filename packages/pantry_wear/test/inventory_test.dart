import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/list_kind.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/models/stock.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/utils/date_format.dart';
import 'package:pantry_core/utils/quantity.dart';
import 'package:pantry_core/utils/stock_rules.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/checklists/list_switcher_page.dart';
import 'package:pantry_wear/src/shell/wear_shell.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/undo_window.dart';

import 'wear_fixtures.dart';

/// An inventory on the wrist: a tap opens a row's controls, steps show at once
/// and write nothing, and closing the row queues one write with the net change
/// — behind the undo window, or straight away when the app is going away.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final storage = <String, String>{};

  setUp(() async {
    WearShape.markFrom(['round']);
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async {
          final args = (call.arguments as Map?) ?? const {};
          switch (call.method) {
            case 'readAll':
              return Map<String, String>.from(storage);
            case 'write':
              storage[args['key'] as String] = args['value'] as String;
              return null;
            case 'delete':
              storage.remove(args['key'] as String);
              return null;
          }
          return null;
        });
    // Offline, so every write stays in the queue to be counted.
    SyncManager.instance.setOnline(false);
    await PrefsService.instance.setWearUndoSeconds(2);
  });

  tearDown(() async {
    await PrefsService.instance.setWearUndoSeconds(2);
    unawaited(SyncManager.instance.reset());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
  });

  final pantry = ChecklistList(
    id: 9,
    houseId: 1,
    name: 'Pantry',
    icon: 'package',
    kind: ListKind.inventory,
    needsRestock: 1,
    sortOrder: 1,
    createdAt: 0,
    updatedAt: 0,
  );

  ListItem stockItem({
    required int id,
    required String name,
    String? quantity,
    String? target,
    String? reorderPoint,
    StockMode mode = StockMode.count,
    StockLevel? level,
    int? expiresAt,
    int? shelfLifeDays,
  }) => ListItem(
    id: id,
    listId: pantry.id,
    name: name,
    categoryId: 1,
    quantity: quantity,
    target: target,
    reorderPoint: reorderPoint,
    stockMode: mode,
    stockLevel: level,
    expiresAt: expiresAt,
    shelfLifeDays: shelfLifeDays,
    done: false,
    repeatFromCompletion: false,
    deleteOnDone: false,
    sortOrder: id,
    createdAt: 0,
    updatedAt: 0,
  ).withLocalStock(leadDays: defaultExpiryLeadDays);

  ChecklistsController seeded({List<ListItem> extra = const []}) {
    final controller = ChecklistsController.seeded(
      houseId: 1,
      list: pantry,
      lists: [testList()],
      inventories: [pantry],
      categories: [testCategory(id: 1, name: 'Fridge')],
      items: [
        stockItem(
          id: 1,
          name: 'Eggs',
          quantity: '4 eggs',
          target: '12 eggs',
          reorderPoint: '4',
        ),
        stockItem(
          id: 2,
          name: 'Flour',
          quantity: '1 bag',
          mode: StockMode.level,
          level: StockLevel.full,
        ),
        ...extra,
      ],
    );
    addTearDown(controller.dispose);
    return controller;
  }

  Future<void> pump(WidgetTester tester, ChecklistsController c) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: WearShell(controller: c)));
    await tester.pumpAndSettle();
  }

  List<SyncOp> stockWrites() => [
    for (final op in SyncManager.instance.queuedOps)
      if (op.entity == SyncEntity.checklistItem && op.op == SyncOpKind.update)
        op,
  ];

  ListItem itemOf(ChecklistsController c, int id) =>
      c.items.firstWhere((i) => i.id == id);

  Future<void> open(WidgetTester tester, String name) async {
    final row = await revealRow(tester, name);
    await tester.tap(row);
    await tester.pumpAndSettle();
  }

  Future<void> tapIcon(WidgetTester tester, IconData icon) async {
    await tester.tap(find.byIcon(icon));
    await tester.pump();
  }

  testWidgets('steps then ✓ queue one write with the net change', (
    tester,
  ) async {
    final controller = seeded();
    await pump(tester, controller);
    await open(tester, 'Eggs');

    await tapIcon(tester, Icons.add);
    await tapIcon(tester, Icons.add);
    await tapIcon(tester, Icons.add);
    await tapIcon(tester, Icons.remove);
    final expected = stepQuantity(
      stepQuantity(stepQuantity('4 eggs', 1), 1),
      1,
    );
    final net = stepQuantity(expected, -1);

    // Shown at once, written never while the row is open.
    expect(itemOf(controller, 1).quantity, net);
    expect(itemOf(controller, 1).stockStatus, StockStatus.ok);
    expect(controller.inventories.single.needsRestock, 0);
    expect(stockWrites(), isEmpty);

    await tapIcon(tester, Icons.check);
    await tester.pump(const Duration(milliseconds: 100));
    // The window drains first, named for what it would write.
    expect(stockWrites(), isEmpty);
    expect(find.text(m.wear.stockRaised(withNumber('4 eggs', 2))), findsOne);

    await tester.pump(undoWindow);
    await tester.pumpAndSettle();
    final writes = stockWrites();
    expect(writes, hasLength(1));
    expect(writes.single.entityId, 1);
    expect(writes.single.body, {'quantity': net});
  });

  testWidgets('steps that come back to the start write nothing', (
    tester,
  ) async {
    final controller = seeded();
    await pump(tester, controller);
    await open(tester, 'Eggs');

    await tapIcon(tester, Icons.add);
    await tapIcon(tester, Icons.remove);
    await tapIcon(tester, Icons.check);
    await tester.pump(const Duration(milliseconds: 100));

    // Nothing to undo, so no window and no label.
    expect(find.textContaining('+'), findsNothing);
    await tester.pump(undoWindow);
    await tester.pumpAndSettle();
    expect(stockWrites(), isEmpty);
    expect(itemOf(controller, 1).quantity, '4 eggs');
  });

  testWidgets('a tap inside the window takes the change back', (tester) async {
    final controller = seeded();
    await pump(tester, controller);
    await open(tester, 'Eggs');

    await tapIcon(tester, Icons.add);
    await tapIcon(tester, Icons.check);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Eggs'));
    await tester.pump(undoWindow);
    await tester.pumpAndSettle();

    expect(stockWrites(), isEmpty);
    expect(itemOf(controller, 1).quantity, '4 eggs');
    expect(controller.inventories.single.needsRestock, 1);
  });

  testWidgets('scrolling the row away closes it like ✓', (tester) async {
    final controller = seeded();
    await pump(tester, controller);
    await open(tester, 'Eggs');
    await tapIcon(tester, Icons.add);

    await revealRow(tester, 'Flour');
    expect(find.byIcon(Icons.check), findsNothing);
    await tester.pump(undoWindow);
    await tester.pumpAndSettle();

    expect(stockWrites(), hasLength(1));
  });

  testWidgets('leaving the app queues an open row at once', (tester) async {
    final controller = seeded();
    await pump(tester, controller);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await open(tester, 'Eggs');
    await tapIcon(tester, Icons.add);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(stockWrites(), hasLength(1));
    expect(stockWrites().single.body, {'quantity': stepQuantity('4 eggs', 1)});
    // Lets the cache's debounced save land before the test ends.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a level item set Low then back to Full writes nothing', (
    tester,
  ) async {
    final controller = seeded();
    await pump(tester, controller);
    await open(tester, 'Flour');

    await tester.tap(find.text(m.stock.low));
    await tester.pump();
    expect(itemOf(controller, 2).stockStatus, StockStatus.low);
    await tester.tap(find.text(m.stock.full));
    await tester.pump();
    await tapIcon(tester, Icons.check);
    await tester.pump(undoWindow);
    await tester.pumpAndSettle();

    expect(stockWrites(), isEmpty);
  });

  testWidgets('a level item writes its new level', (tester) async {
    final controller = seeded();
    await pump(tester, controller);
    await open(tester, 'Flour');

    await tester.tap(find.text(m.stock.out));
    await tester.pump();
    await tapIcon(tester, Icons.check);
    await tester.pump(const Duration(milliseconds: 100));
    // The undo label is the level the row went to, beside its amount chip.
    expect(find.text(m.stock.out), findsNWidgets(2));
    await tester.pump(undoWindow);
    await tester.pumpAndSettle();

    expect(stockWrites().single.body, {'stockLevel': 'out'});
  });

  group('renewing the expiry on a raise', () {
    final today = todayEpoch();
    final renewed = renewedExpiry(2, today)!;
    // The drawer stays drawn while it lowers, so "offered" is whether it can
    // be reached.
    final drawer = find
        .text(m.stock.renewChip(formatShortDate(renewed)))
        .hitTestable();

    ChecklistsController withMilk() => seeded(
      extra: [
        stockItem(
          id: 3,
          name: 'Milk',
          quantity: '1 carton',
          target: '1 carton',
          expiresAt: addDays(today, -3),
          shelfLifeDays: 2,
        ),
      ],
    );

    testWidgets('a taken offer goes out with the one write', (tester) async {
      final controller = withMilk();
      await pump(tester, controller);
      await open(tester, 'Milk');

      expect(drawer, findsNothing);
      await tapIcon(tester, Icons.add);
      await tester.pumpAndSettle();
      expect(drawer, findsOne);
      expect(itemOf(controller, 3).expiryStatus, ExpiryStatus.expired);

      // A tap approves and closes the row, as ✓ would.
      await tester.tap(drawer);
      await tester.pump(const Duration(milliseconds: 100));
      expect(drawer, findsNothing);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(itemOf(controller, 3).expiresAt, renewed);
      expect(itemOf(controller, 3).expiryStatus, isNot(ExpiryStatus.expired));
      expect(stockWrites(), isEmpty);

      await tester.pump(undoWindow);
      await tester.pumpAndSettle();
      expect(stockWrites().single.body, {
        'quantity': '2 carton',
        'expiresAt': renewed,
      });
    });

    testWidgets('an offer left alone keeps the old date', (tester) async {
      final controller = withMilk();
      await pump(tester, controller);
      await open(tester, 'Milk');

      await tapIcon(tester, Icons.add);
      await tester.pumpAndSettle();
      expect(drawer, findsOne);
      // The row stays live while the drawer is up.
      await tapIcon(tester, Icons.check);
      await tester.pumpAndSettle();
      expect(drawer, findsNothing);
      await tester.pump(undoWindow);
      await tester.pumpAndSettle();
      expect(stockWrites().single.body, {'quantity': '2 carton'});
      expect(itemOf(controller, 3).expiresAt, addDays(today, -3));
    });

    testWidgets('undo takes the renewal back with the amount', (tester) async {
      final controller = withMilk();
      await pump(tester, controller);
      await open(tester, 'Milk');

      await tapIcon(tester, Icons.add);
      await tester.pumpAndSettle();
      await tester.tap(drawer);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Milk'));
      await tester.pump(undoWindow);
      await tester.pumpAndSettle();

      expect(stockWrites(), isEmpty);
      expect(itemOf(controller, 3).quantity, '1 carton');
      expect(itemOf(controller, 3).expiresAt, addDays(today, -3));
    });
  });

  testWidgets('the Needs restock chip filters without regrouping', (
    tester,
  ) async {
    final controller = seeded();
    await pump(tester, controller);

    await tester.tap(find.text(m.stock.filterNeedsRestock));
    await tester.pumpAndSettle();

    expect(find.text('Eggs'), findsOne);
    expect(find.text('Flour'), findsNothing);
    expect(find.text('Fridge'), findsWidgets);
  });

  testWidgets('on a square screen a tap opens any whole row where it lies', (
    tester,
  ) async {
    WearShape.markFrom(['square']);
    final controller = seeded();
    await pump(tester, controller);

    await tester.tap(find.text('Flour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(m.stock.low));
    await tester.pump();
    await tapIcon(tester, Icons.check);
    await tester.pump(undoWindow);
    await tester.pumpAndSettle();

    expect(stockWrites().single.body, {'stockLevel': 'low'});
  });

  testWidgets('the switcher counts what needs restock, and reads it out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ListSwitcherPage(
          lists: [testList()],
          inventories: [
            pantry.copyWith(needsRestock: 3),
            pantry.copyWith(id: 10, name: 'Garage', needsRestock: 0),
          ],
          selectedId: pantry.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final semantics = tester.ensureSemantics();
    expect(find.text('3'), findsOne);
    expect(
      find.bySemanticsLabel(RegExp(m.stock.needsRestockCount(3))),
      findsOne,
    );
    await revealRow(tester, 'Garage');
    expect(find.text('0'), findsNothing);
    semantics.dispose();
  });

  testWidgets('the switcher heads each kind of list', (tester) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Future<void> show(List<ChecklistList> inventories) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ListSwitcherPage(
            lists: [testList()],
            inventories: inventories,
            selectedId: null,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show([pantry]);
    expect(find.text(m.listKinds.checklist.title), findsOne);
    await revealRow(tester, 'Pantry');
    expect(find.text(m.listKinds.inventory.title), findsOne);

    // One kind needs no heading.
    await show([]);
    expect(find.text(m.listKinds.checklist.title), findsNothing);
  });

  group('older servers', () {
    setUp(() async {
      await PrefsService.instance.setLastHouseId(1);
      HouseService.instance.cache.setList('houses', [
        const House(
          id: 1,
          name: 'Home',
          ownerUid: 'casraf',
          role: 'owner',
          createdAt: 0,
          updatedAt: 0,
        ),
      ], (h) => h.toJson());
      ChecklistService.instance
        ..cacheLists(1, [testList()])
        ..cacheListsOfKind(1, ListKind.inventory, [pantry])
        ..selectedListId = testList().id;
    });

    tearDown(ServerVersionService.instance.debugSeed);

    Future<List<ChecklistList>> inventoriesOn(String version) async {
      ServerVersionService.instance.debugSeed(
        pantryVersion: Version.parse(version),
      );
      final controller = ChecklistsController();
      addTearDown(controller.dispose);
      await controller.start();
      return controller.inventories;
    }

    test('show no inventories', () async {
      expect(await inventoriesOn('0.37.0'), isEmpty);
    });

    test('from 0.38.0 the cached inventories are offered', () async {
      expect((await inventoriesOn('0.38.0')).map((l) => l.id), [pantry.id]);
    });
  });
}
