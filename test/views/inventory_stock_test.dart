import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/stock.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/layout_breakpoints.dart';
import 'package:pantry_core/utils/stock_rules.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';
import 'package:pantry/views/checklists/inventory_row_parts.dart';

import '../helpers/test_app.dart';

/// Inventories count and level their stock from Pantry 0.38.0 on. A stock edit
/// shows as final at once, worked out with the shared rules, and the server's
/// answer replaces it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  const shelf = 30;
  const eggs = 300;
  const flour = 301;
  const milk = 302;

  Map<String, dynamic> inventory({int needsRestock = 0, int lead = 2}) => {
    'id': shelf,
    'houseId': 1,
    'name': 'Pantry shelf',
    'kind': 'inventory',
    'icon': 'list',
    'sortOrder': 0,
    'createdAt': 0,
    'updatedAt': 0,
    'needsRestock': needsRestock,
    'expiryLeadDays': lead,
  };

  Map<String, dynamic> item(
    int id,
    String name, {
    String mode = 'count',
    String level = 'full',
    String? quantity,
    String? target,
    String status = 'ok',
    String? shortfall,
    int? expiresAt,
    int? shelfLifeDays,
    String expiry = 'none',
  }) => {
    'id': id,
    'listId': shelf,
    'name': name,
    'sortOrder': 0,
    'createdAt': 0,
    'updatedAt': 0,
    'stockMode': mode,
    'stockLevel': level,
    'quantity': quantity,
    'target': target,
    'reorderPoint': null,
    'stockStatus': status,
    'shortfall': shortfall,
    'expiresAt': expiresAt,
    'shelfLifeDays': shelfLifeDays,
    'expiryStatus': expiry,
  };

  final today = todayEpoch();
  late List<http.Request> requests;
  late List<Map<String, dynamic>> items;
  late int patchStatus;

  http.Client server() => MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    final method = request.method;
    Object data = const <Object>[];
    var status = 200;
    if (method == 'PATCH' && path.contains('/inventories/$shelf/items/')) {
      status = patchStatus;
      final id = int.parse(path.split('/').last);
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      data = {...items.firstWhere((i) => i['id'] == id), ...body};
    } else if (method == 'PATCH' && path.endsWith('/inventories/$shelf')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      data = {...inventory(), ...body};
    } else if (method != 'GET') {
      throw http.ClientException('offline', request.url);
    } else if (path.endsWith('/prefs')) {
      data = <String, dynamic>{};
    } else if (path.endsWith('/houses/1/inventories')) {
      data = [inventory(needsRestock: 2)];
    } else if (path.endsWith('/inventories/$shelf/items')) {
      data = items;
    }
    return http.Response(
      jsonEncode({
        'ocs': {
          'meta': {
            'status': status == 200 ? 'ok' : 'failure',
            'statuscode': status,
            'message': '',
          },
          'data': data,
        },
      }),
      status,
      headers: {'content-type': 'application/json'},
    );
  });

  Future<void> withServer(Future<void> Function() body) =>
      http.runWithClient(body, server);

  Future<void> quiesce(WidgetTester tester) async {
    unawaited(manager.reset());
    await tester.pump(const Duration(seconds: 1));
  }

  Iterable<http.Request> hits(String method, String suffix) =>
      requests.where((r) => r.method == method && r.url.path.endsWith(suffix));

  setUp(() async {
    requests = [];
    patchStatus = 200;
    items = [
      item(eggs, 'Eggs', quantity: '12 eggs', target: '12 eggs'),
      item(
        flour,
        'Flour',
        mode: 'level',
        level: 'low',
        quantity: '1 kg bag',
        status: 'low',
        shortfall: '1 kg bag',
      ),
      item(
        milk,
        'Milk',
        quantity: '0',
        target: '2 cartons',
        status: 'out',
        shortfall: '2 cartons',
        expiresAt: addDays(today, -3),
        shelfLifeDays: 7,
      ),
    ];
    ServerVersionService.instance.debugSeed(
      pantryVersion: Version.parse('0.38.0'),
    );
    ChecklistService.instance.cacheListsOfEveryKind(1, const []);
    ChecklistService.instance.selectedListId = null;
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
    unawaited(manager.reset());
  });

  tearDown(() {
    unawaited(manager.reset());
    ServerVersionService.instance.debugSeed();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  Future<ChecklistsController> opened(WidgetTester tester) async {
    final controller = ChecklistsController(houseId: 1);
    addTearDown(controller.dispose);
    await controller.load();
    await controller.selectKind(ListKind.inventory);
    await tester.pump();
    return controller;
  }

  ListItem byId(ChecklistsController c, int id) =>
      c.items.singleWhere((i) => i.id == id);

  test('stock is gated on Pantry 0.38.0', () {
    ServerVersionService.instance.debugSeed(
      pantryVersion: Version.parse('0.37.0'),
    );
    expect(ServerFeature.inventoryStock, isFalse);
    ServerVersionService.instance.debugSeed(
      pantryVersion: Version.parse('0.38.0'),
    );
    expect(ServerFeature.inventoryStock, isTrue);
  });

  test('items and inventories read their stock fields', () {
    final parsed = ListItem.fromJson(items[1]);
    expect(parsed.stockMode, StockMode.level);
    expect(parsed.stockLevel, StockLevel.low);
    expect(parsed.stockStatus, StockStatus.low);
    expect(parsed.shortfall, '1 kg bag');
    expect(ListItem.fromJson(parsed.toJson()).stockLevel, StockLevel.low);

    final list = ChecklistList.fromJson(inventory(needsRestock: 3, lead: 4));
    expect(list.needsRestock, 3);
    expect(list.expiryLeadDays, 4);
  });

  testWidgets('a step shows its status at once and sends only on hand', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await opened(tester);
      expect(controller.currentList!.id, shelf);
      expect(controller.currentList!.needsRestock, 2);

      controller.setOnHand(byId(controller, eggs), '4 eggs');
      final local = byId(controller, eggs);
      expect(local.stockStatus, StockStatus.low);
      expect(local.shortfall, '8 eggs');
      expect(controller.currentList!.needsRestock, 3);

      await tester.pump(const Duration(seconds: 1));
      await manager.flushNow();
      await tester.pump();
      final body =
          jsonDecode(hits('PATCH', '/items/$eggs').single.body)
              as Map<String, dynamic>;
      expect(body, {'quantity': '4 eggs'});

      await quiesce(tester);
    });
  });

  testWidgets('a run of steps goes out as one write once they pause', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await opened(tester);

      controller.setOnHand(byId(controller, eggs), '11 eggs');
      await tester.pump(const Duration(milliseconds: 300));
      controller.setOnHand(byId(controller, eggs), '10 eggs');
      await tester.pump(const Duration(milliseconds: 300));
      controller.setOnHand(byId(controller, eggs), '9 eggs');
      expect(byId(controller, eggs).quantity, '9 eggs');
      expect(hits('PATCH', '/items/$eggs'), isEmpty);

      await tester.pump(const Duration(seconds: 1));
      await manager.flushNow();
      await tester.pump();
      final bodies = hits(
        'PATCH',
        '/items/$eggs',
      ).map((r) => jsonDecode(r.body)).toList();
      expect(bodies, [
        {'quantity': '9 eggs'},
      ]);

      await quiesce(tester);
    });
  });

  testWidgets('steps that end where they started send nothing', (tester) async {
    await withServer(() async {
      final controller = await opened(tester);

      controller.setOnHand(byId(controller, eggs), '11 eggs');
      controller.setOnHand(byId(controller, eggs), '12 eggs');
      expect(byId(controller, eggs).quantity, '12 eggs');

      await tester.pump(const Duration(seconds: 1));
      await manager.flushNow();
      await tester.pump();
      expect(hits('PATCH', '/items/$eggs'), isEmpty);

      await quiesce(tester);
    });
  });

  testWidgets('another edit sends a waiting step first', (tester) async {
    await withServer(() async {
      final controller = await opened(tester);

      controller.setOnHand(byId(controller, eggs), '11 eggs');
      await controller.updateItem(byId(controller, eggs), name: 'Big eggs');
      expect(byId(controller, eggs).quantity, '11 eggs');
      expect(byId(controller, eggs).name, 'Big eggs');

      await manager.flushNow();
      await tester.pump();
      final merged = hits('PATCH', '/items/$eggs')
          .map((r) => jsonDecode(r.body) as Map)
          .fold<Map>({}, (a, b) => a..addAll(b));
      expect(merged, {'quantity': '11 eggs', 'name': 'Big eggs'});

      await quiesce(tester);
    });
  });

  testWidgets('raising stock from empty renews the date like the server', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await opened(tester);
      expect(byId(controller, milk).expiryStatus, ExpiryStatus.none);

      controller.setOnHand(byId(controller, milk), '1');
      final local = byId(controller, milk);
      expect(local.expiresAt, addDays(today, 7));
      expect(local.stockStatus, StockStatus.low);
      expect(local.expiryStatus, ExpiryStatus.ok);

      await tester.pump(const Duration(seconds: 1));
      await manager.flushNow();
      await tester.pump();
      final body =
          jsonDecode(hits('PATCH', '/items/$milk').single.body)
              as Map<String, dynamic>;
      expect(body.containsKey('expiresAt'), isFalse);

      await quiesce(tester);
    });
  });

  testWidgets('a refused stock write reloads the inventory', (tester) async {
    await withServer(() async {
      final controller = await opened(tester);
      patchStatus = 409;
      final fetchesBefore = hits('GET', '/inventories/$shelf/items').length;

      controller.setStockLevel(byId(controller, flour), StockLevel.full);
      expect(byId(controller, flour).stockStatus, StockStatus.ok);

      await tester.pump(const Duration(seconds: 1));
      await manager.flushNow();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        hits('GET', '/inventories/$shelf/items').length,
        greaterThan(fetchesBefore),
      );
      expect(byId(controller, flour).stockLevel, StockLevel.low);

      await tester.pump(const Duration(seconds: 5));
      await quiesce(tester);
    });
  });

  testWidgets('the expiry warning re-rates every item at once', (tester) async {
    await withServer(() async {
      items[0] = item(
        eggs,
        'Eggs',
        quantity: '12 eggs',
        target: '12 eggs',
        expiresAt: addDays(today, 4),
        expiry: 'ok',
      );
      final controller = await opened(tester);

      controller.saveInventorySettings(
        controller.currentList!,
        name: 'Pantry shelf',
        expiryLeadDays: 5,
      );
      expect(byId(controller, eggs).expiryStatus, ExpiryStatus.expiring);
      expect(controller.currentList!.expiryLeadDays, 5);

      await manager.flushNow();
      await tester.pump();
      final body =
          jsonDecode(hits('PATCH', '/inventories/$shelf').single.body)
              as Map<String, dynamic>;
      expect(body, {'expiryLeadDays': 5});

      await quiesce(tester);
    });
  });

  group('row controls', () {
    ListItem eggsAt(String onHand) => ListItem.fromJson(
      item(eggs, 'Eggs', quantity: onHand, target: '12 eggs'),
    ).withLocalStock(leadDays: 2);

    Future<String?> pumpStepper(
      WidgetTester tester,
      ListItem stocked, {
      required bool narrow,
      required Future<void> Function() act,
    }) async {
      String? set;
      await tester.pumpWidget(
        wrapForTest(
          Center(
            child: InventoryRowControl(
              item: stocked,
              narrow: narrow,
              actions: InventoryRowActions(onSetOnHand: (v) => set = v),
            ),
          ),
        ),
      );
      await act();
      await tester.pump();
      return set;
    }

    testWidgets('the wide stepper shows on hand; the narrow one does not', (
      tester,
    ) async {
      await pumpStepper(
        tester,
        eggsAt('4 eggs'),
        narrow: false,
        act: () async {},
      );
      expect(find.text('4 eggs'), findsOneWidget);
      await pumpStepper(
        tester,
        eggsAt('4 eggs'),
        narrow: true,
        act: () async {},
      );
      expect(find.text('4 eggs'), findsNothing);
    });

    testWidgets('holding + fills to the target, holding − empties', (
      tester,
    ) async {
      expect(
        await pumpStepper(
          tester,
          eggsAt('4 eggs'),
          narrow: true,
          act: () => tester.longPress(find.byTooltip(m.stock.increase)),
        ),
        '12 eggs',
      );
      expect(
        await pumpStepper(
          tester,
          eggsAt('4 eggs'),
          narrow: true,
          act: () => tester.longPress(find.byTooltip(m.stock.decrease)),
        ),
        '0 eggs',
      );
      expect(
        await pumpStepper(
          tester,
          eggsAt('4 eggs'),
          narrow: true,
          act: () => tester.tap(find.byTooltip(m.stock.increase)),
        ),
        '5 eggs',
      );
    });

    testWidgets('− is off at zero and both are off without a number', (
      tester,
    ) async {
      expect(
        await pumpStepper(
          tester,
          eggsAt('0 eggs'),
          narrow: true,
          act: () => tester.tap(find.byTooltip(m.stock.decrease)),
        ),
        isNull,
      );
      expect(
        await pumpStepper(
          tester,
          eggsAt('some'),
          narrow: true,
          act: () => tester.tap(find.byTooltip(m.stock.increase)),
        ),
        isNull,
      );
    });

    testWidgets('holding the amount types on hand', (tester) async {
      String? set;
      await tester.pumpWidget(
        wrapForTest(
          StockAmountChip(item: eggsAt('4 eggs'), onSetOnHand: (v) => set = v),
        ),
      );
      expect(find.text(m.stock.amount('4', '12 eggs')), findsOneWidget);
      await tester.longPress(find.text(m.stock.amount('4', '12 eggs')));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '9');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(set, '9 eggs');
    });
  });

  test('chips name the shortfall, or leave it to expiry', () {
    final low = ListItem.fromJson(
      item(eggs, 'Eggs', quantity: '4 eggs', target: '12 eggs'),
    ).withLocalStock(leadDays: 2);
    expect(stockStatusChips(low).map((c) => c.label), [
      m.stock.lowBuy('8 eggs'),
    ]);

    final lowAndExpiring = ListItem.fromJson(
      item(
        eggs,
        'Eggs',
        quantity: '4 eggs',
        target: '12 eggs',
        expiresAt: addDays(today, 1),
      ),
    ).withLocalStock(leadDays: 2);
    expect(stockStatusChips(lowAndExpiring).map((c) => c.label), [
      m.stock.low,
      m.stock.expiresTomorrowBuy('12 eggs'),
    ]);
  });

  test('the list pane is narrow up to 600 logical pixels', () {
    expect(isNarrowListPane(600), isTrue);
    expect(isNarrowListPane(601), isFalse);
  });
}
