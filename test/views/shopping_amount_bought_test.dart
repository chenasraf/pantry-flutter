import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/shopping/shopping_item_row.dart';
import 'package:pantry/views/shopping/shopping_session_controller.dart';

import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

/// A shopper often comes back with more or less than the list asked for, and
/// checking an item off restocks by its quantity — so a to-buy row lets the
/// amount be stepped first, wherever the shopper may edit the item.
void main() {
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  ShoppingSession session() => ShoppingSession(
    id: 12,
    houseId: 1,
    userId: 'chen',
    listIds: const [4],
    stores: const [],
    activeStoreId: null,
    includeUnassigned: true,
    isPrivate: false,
    lastSeenAt: 0,
    memberIds: const ['chen'],
    live: true,
    createdAt: 0,
    updatedAt: 0,
  );

  http.Client serverWith(List<ListItem> items) => MockClient((request) async {
    final path = request.url.path;
    final Object data;
    if (path.endsWith('/sessions/12/items')) {
      data = [for (final i in items) i.toJson()];
    } else if (path.endsWith('/review')) {
      data = {'stores': [], 'grandTotal': [], 'uncheckedCount': 0};
    } else {
      data = <dynamic>[];
    }
    return http.Response(
      jsonEncode({
        'ocs': {'data': data},
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  });

  var checks = 0;

  /// One to-buy row, fed from a trip that has loaded [item], so a step lands
  /// on the item the controller holds. [seed] fills the caches the trip reads
  /// permissions from, on the real clock: a cache write's debounce left on the
  /// test's fake one outlives the test.
  Future<ShoppingSessionController> pumpRow(
    WidgetTester tester,
    ListItem item, {
    double width = 800,
    void Function()? seed,
  }) async {
    tester.view.physicalSize = Size(width, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ShoppingSessionController(session: session());
    addTearDown(controller.dispose);
    await tester.runAsync(() async {
      seed?.call();
      await http.runWithClient(controller.load, () => serverWith([item]));
      await ChecklistService.instance.cache.flush();
      await HouseService.instance.cache.flush();
    });
    // A read that reached the server marks the queue online; held offline, a
    // step stays queued for the test to settle by hand.
    manager.setOnline(false);
    await tester.pumpWidget(
      wrapForTest(
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => ListView(
            children: [
              for (final i in controller.items)
                ShoppingItemRow(
                  item: i,
                  controller: controller,
                  onCheck: () => checks++,
                  onSkip: () {},
                  onView: () {},
                ),
            ],
          ),
        ),
      ),
    );
    return controller;
  }

  Finder stepButton(String label) => find.byTooltip(label);

  setUp(() async {
    checks = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          final args = (call.arguments as Map?) ?? const {};
          const credentials = {
            'nextcloud_credentials':
                '{"serverUrl":"https://cloud.example.com",'
                '"loginName":"chen","appPassword":"secret"}',
          };
          if (call.method == 'read') return credentials[args['key']];
          if (call.method == 'readAll') return credentials;
          return null;
        });
    await AuthService.instance.loadCredentials();
  });

  tearDown(() async {
    unawaited(manager.reset());
    manager.setOnline(true);
    ServerVersionService.instance.debugSeed();
    ChecklistService.instance.cacheLists(1, const []);
    HouseService.instance.cache.removeKey('houses');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  /// Takes the queue's retry timer off the clock before the test ends.
  Future<void> quiesce(WidgetTester tester) async {
    unawaited(manager.reset());
    await tester.pump(const Duration(seconds: 1));
  }

  group('which rows get a stepper', () {
    testWidgets('a counted quantity does, showing the amount between its '
        'buttons in place of the chip', (tester) async {
      await pumpRow(
        tester,
        makeListItem(id: 1, listId: 4, name: 'Milk', quantity: '2 L'),
      );

      expect(stepButton(m.shopping.buyLess), findsOneWidget);
      expect(stepButton(m.shopping.buyMore), findsOneWidget);
      expect(find.text('2 L'), findsOneWidget);
    });

    testWidgets('a narrow row keeps the chip and shows the buttons alone', (
      tester,
    ) async {
      await pumpRow(
        tester,
        makeListItem(id: 1, listId: 4, name: 'Milk', quantity: '2 L'),
        width: 400,
      );

      expect(stepButton(m.shopping.buyMore), findsOneWidget);
      expect(find.text('2 L'), findsOneWidget);
    });

    for (final quantity in [null, 'some']) {
      testWidgets('a quantity of $quantity has nothing to step', (
        tester,
      ) async {
        await pumpRow(
          tester,
          makeListItem(id: 1, listId: 4, name: 'Milk', quantity: quantity),
        );

        expect(stepButton(m.shopping.buyMore), findsNothing);
      });
    }

    test('a checked item has nothing left to buy', () {
      final controller = ShoppingSessionController(session: session());
      addTearDown(controller.dispose);

      expect(
        controller.canStepAmount(
          makeListItem(id: 1, listId: 4, quantity: '2 L', done: true),
        ),
        isFalse,
      );
    });

    testWidgets('a list shared for viewing only is not the shopper\'s to '
        'change', (tester) async {
      ServerVersionService.instance.debugSeed(
        pantryVersion: Version.parse('0.39.0'),
      );
      await pumpRow(
        tester,
        makeListItem(id: 1, listId: 4, name: 'Milk', quantity: '2 L'),
        seed: () => ChecklistService.instance.cacheLists(1, [
          ChecklistList(
            id: 4,
            houseId: 1,
            name: 'Groceries',
            icon: 'cart',
            sortOrder: 0,
            createdAt: 0,
            updatedAt: 0,
            sharedOnly: true,
            canEdit: false,
          ),
        ]),
      );

      expect(stepButton(m.shopping.buyMore), findsNothing);
    });

    testWidgets('a member who may only check items off cannot step them', (
      tester,
    ) async {
      ServerVersionService.instance.debugSeed(
        pantryVersion: Version.parse('0.39.0'),
      );
      await pumpRow(
        tester,
        makeListItem(id: 1, listId: 4, name: 'Milk', quantity: '2 L'),
        seed: () => HouseService.instance.cache.setList('houses', [
          const House(
            id: 1,
            name: 'Home',
            ownerUid: 'casraf',
            role: 'member',
            permissions: HousePermissions(canEditLists: false),
            createdAt: 0,
            updatedAt: 0,
          ),
        ], (h) => h.toJson()),
      );

      expect(stepButton(m.shopping.buyMore), findsNothing);
    });
  });

  testWidgets('a step keeps the unit and sends the new amount', (tester) async {
    await pumpRow(
      tester,
      makeListItem(id: 1, listId: 4, name: 'Milk', quantity: '2 L'),
    );

    await tester.tap(stepButton(m.shopping.buyMore));
    await tester.pump();

    expect(find.text('3 L'), findsOneWidget);
    expect(checks, 0);
    final op = manager.queuedOps.single;
    expect(op.entityId, 1);
    expect(op.body, {'quantity': '3 L'});

    await quiesce(tester);
  });

  testWidgets('− is off at 1, and a tap on it does not check the item off', (
    tester,
  ) async {
    await pumpRow(
      tester,
      makeListItem(id: 1, listId: 4, name: 'Bread', quantity: '1 loaf'),
    );

    await tester.tap(stepButton(m.shopping.buyLess));
    await tester.pump();

    expect(find.text('1 loaf'), findsOneWidget);
    expect(checks, 0);
    expect(manager.queuedOps, isEmpty);
  });

  testWidgets('a step the server refuses puts the amount back', (tester) async {
    await pumpRow(
      tester,
      makeListItem(id: 1, listId: 4, name: 'Milk', quantity: '2 L'),
    );

    await tester.tap(stepButton(m.shopping.buyMore));
    await tester.pump();
    manager.deadLetterForTest(manager.queuedOps.single);
    await tester.pump();

    expect(find.text('2 L'), findsOneWidget);
    expect(find.text(m.shopping.quantityFailed), findsOneWidget);

    await quiesce(tester);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('only the latest of several quick steps settles the amount', (
    tester,
  ) async {
    await pumpRow(
      tester,
      makeListItem(id: 1, listId: 4, name: 'Milk', quantity: '2 L'),
    );

    await tester.tap(stepButton(m.shopping.buyMore));
    await tester.pump();
    await tester.tap(stepButton(m.shopping.buyMore));
    await tester.pump();
    // The first step's write failing says nothing about the second.
    manager.deadLetterForTest(manager.queuedOps.first);
    await tester.pump();

    expect(find.text('4 L'), findsOneWidget);
    expect(find.text(m.shopping.quantityFailed), findsNothing);

    await quiesce(tester);
  });
}
