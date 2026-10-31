import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/models/list_kind.dart';
import 'package:pantry_core/models/stock.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/list_kind_strings.dart';
import 'package:pantry_core/utils/stock_rules.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/checklists/list_switcher_page.dart';
import 'package:pantry_wear/src/scope/wear_scope.dart';
import 'package:pantry_wear/src/wear_shape.dart';

import 'wear_fixtures.dart';

/// "All inventories" on the wrist: the inventories' own entry in the switcher,
/// gathering every inventory's rows, on servers that announce it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ChecklistList inventory(int id, String name) => ChecklistList(
    id: id,
    houseId: 1,
    name: name,
    icon: 'package',
    kind: ListKind.inventory,
    sortOrder: id,
    createdAt: 0,
    updatedAt: 0,
  );

  final fridge = inventory(30, 'Fridge');
  final freezer = inventory(31, 'Freezer');

  // Out of stock, so each one needs restocking.
  ListItem stocked(int id, ChecklistList list, String name) => ListItem(
    id: id,
    listId: list.id,
    name: name,
    stockMode: StockMode.count,
    target: '2',
    quantity: '0',
    done: false,
    repeatFromCompletion: false,
    deleteOnDone: false,
    sortOrder: id,
    createdAt: 0,
    updatedAt: 0,
  ).withLocalStock(leadDays: defaultExpiryLeadDays);

  void seed({bool advertised = true}) =>
      ServerVersionService.instance.debugSeed(
        pantryVersion: Version.parse('0.38.0'),
        advertised: {if (advertised) 'inventory-all-view'},
      );

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final storage = <String, String>{};

  setUp(() {
    WearShape.markFrom(['round']);
    seed();
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async {
          final args = (call.arguments as Map?) ?? const {};
          switch (call.method) {
            case 'read':
              return storage[args['key'] as String];
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
  });

  tearDown(() {
    ServerVersionService.instance.debugSeed();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
  });

  group('the switcher', () {
    Future<void> show(
      WidgetTester tester,
      List<ChecklistList> inventories,
    ) async {
      tester.view.physicalSize = const Size(450, 450);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
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

    final title = ListKind.inventory.strings.allTitle;

    testWidgets('heads two inventories or more', (tester) async {
      await show(tester, [fridge, freezer]);
      await revealRow(tester, title);
      expect(find.text(title), findsOne);
    });

    testWidgets('skips a lone inventory', (tester) async {
      await show(tester, [fridge]);
      await revealRow(tester, 'Fridge');
      expect(find.text(title), findsNothing);
    });

    testWidgets('is missing from servers that do not announce it', (
      tester,
    ) async {
      seed(advertised: false);
      await show(tester, [fridge, freezer]);
      await revealRow(tester, 'Freezer');
      expect(find.text(title), findsNothing);
    });
  });

  group('the view', () {
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
        ..cacheListsOfKind(1, ListKind.inventory, [fridge, freezer])
        ..cacheItems(fridge.id, [stocked(300, fridge, 'Milk')])
        ..cacheItems(freezer.id, [stocked(310, freezer, 'Peas')])
        ..selectedListId = kAllInventoriesId;
    });

    Future<ChecklistsController> started() async {
      final controller = ChecklistsController();
      addTearDown(controller.dispose);
      await controller.start();
      return controller;
    }

    test('gathers every inventory\'s rows, and counts them', () async {
      final controller = await started();

      expect(controller.list!.id, kAllInventoriesId);
      expect(controller.list!.name, ListKind.inventory.strings.allTitle);
      expect(controller.isInventory, isTrue);
      expect(controller.railNamesList, isFalse);
      expect(controller.items.map((i) => i.name).toSet(), {'Milk', 'Peas'});
      expect(
        {for (final l in controller.inventories) l.id: l.needsRestock},
        {fridge.id: 1, freezer.id: 1},
      );
    });

    test('falls back to a list on servers that do not announce it', () async {
      seed(advertised: false);
      final controller = await started();

      expect(controller.list!.id, isNot(kAllInventoriesId));
    });
  });

  test('a watch that never read the server version reads it first', () async {
    ServerVersionService.instance.debugSeed();
    storage['nextcloud_credentials'] =
        '{"serverUrl":"https://cloud.example.com",'
        '"loginName":"chen","appPassword":"secret"}';
    await AuthService.instance.loadCredentials();
    final paths = <String>[];
    http.Response ocs(Object data) => http.Response(
      jsonEncode({
        'ocs': {
          'meta': {'status': 'ok', 'statuscode': 200, 'message': 'OK'},
          'data': data,
        },
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
    final server = MockClient((request) async {
      paths.add(request.url.path);
      if (request.url.path.endsWith('/cloud/capabilities')) {
        return ocs({
          'version': {'string': '35.0.2'},
          'capabilities': {
            'pantry': {
              'version': {'string': '0.38.0'},
              'features': ['inventory-all-view'],
            },
          },
        });
      }
      return ocs(const <Object>[]);
    });

    await http.runWithClient(() async {
      final controller = ChecklistsController();
      addTearDown(controller.dispose);
      await controller.refresh();
    }, () => server);

    expect(paths.first, endsWith('/cloud/capabilities'));
    expect(ServerFeature.inventoryStock, isTrue);
    expect(ServerFeature.inventoryAllView, isTrue);
  });

  group('the Inventories page scope', () {
    setUp(() {
      ChecklistService.instance.selectedListId = 4;
      ChecklistService.instance.selectedInventoryId = null;
    });

    test('opens on "All inventories" when there are several', () async {
      final id = await WearScope.inventory.resolveList([fridge, freezer]);

      expect(id, kAllInventoriesId);
      expect(ChecklistService.instance.selectedInventoryId, kAllInventoriesId);
      expect(
        ChecklistService.instance.selectedListId,
        4,
        reason: 'the lists page keeps its own list',
      );
    });

    test('opens on the one inventory there is', () async {
      expect(await WearScope.inventory.resolveList([fridge]), fridge.id);
    });

    test('never lands on "All lists"', () async {
      ChecklistService.instance.selectedInventoryId = kAllListsId;
      expect(await WearScope.inventory.resolveList([fridge]), fridge.id);
    });
  });
}
