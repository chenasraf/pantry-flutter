import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/list_kind_strings.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/checklists/checklist_switcher_sheet.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';
import 'package:pantry/views/checklists/switcher_list_stage.dart';

import '../helpers/test_app.dart';

/// "All inventories" gathers the items of every inventory, the way "All lists"
/// gathers the checklists', on servers that announce it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  const groceries = 10;
  const hardware = 11;
  const fridge = 30;
  const freezer = 31;

  Map<String, dynamic> list(int id, String name, String kind) => {
    'id': id,
    'houseId': 1,
    'name': name,
    'kind': kind,
    'icon': 'list',
    'sortOrder': id,
    'createdAt': 0,
    'updatedAt': 0,
  };

  Map<String, dynamic> item(int id, int listId, String name) => {
    'id': id,
    'listId': listId,
    'name': name,
    'sortOrder': 0,
    'createdAt': 0,
    'updatedAt': 0,
  };

  late List<http.Request> requests;

  http.Client server() => MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    Object data = const <Object>[];
    if (request.method != 'GET') {
      throw http.ClientException('offline', request.url);
    } else if (path.endsWith('/prefs')) {
      data = <String, dynamic>{};
    } else if (path.endsWith('/houses/1/lists')) {
      data = [
        list(groceries, 'Groceries', 'checklist'),
        list(hardware, 'Hardware', 'checklist'),
      ];
    } else if (path.endsWith('/houses/1/inventories')) {
      data = [
        list(fridge, 'Fridge', 'inventory'),
        list(freezer, 'Freezer', 'inventory'),
      ];
    } else if (path.endsWith('/houses/1/inventories/items')) {
      data = [item(300, fridge, 'Milk'), item(310, freezer, 'Peas')];
    } else if (path.endsWith('/houses/1/items')) {
      data = [item(100, groceries, 'Bread')];
    }
    return http.Response(
      jsonEncode({
        'ocs': {
          'meta': {'status': 'ok', 'statuscode': 200, 'message': 'OK'},
          'data': data,
        },
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  });

  Future<void> withServer(Future<void> Function() body) =>
      http.runWithClient(body, server);

  /// Takes the queue's retry timer off the clock; see
  /// shopping_billed_offline_test.dart for why this isn't awaited.
  Future<void> quiesce(WidgetTester tester) async {
    unawaited(manager.reset());
    await tester.pump(const Duration(seconds: 1));
  }

  void seed({bool advertised = true}) =>
      ServerVersionService.instance.debugSeed(
        pantryVersion: Version.parse('0.38.0'),
        advertised: {if (advertised) 'inventory-all-view'},
      );

  setUp(() async {
    requests = [];
    seed();
    ChecklistService.instance.cacheListsOfEveryKind(1, const []);
    ChecklistService.instance.selectedListId = null;
    ChecklistService.instance.invalidateItems();
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

  Future<ChecklistsController> loaded(WidgetTester tester) async {
    final controller = ChecklistsController(houseId: 1);
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pump();
    return controller;
  }

  Future<void> pumpSwitcher(
    WidgetTester tester,
    ChecklistsController controller,
  ) async {
    await tester.pumpWidget(
      wrapForTest(
        ListStage(
          controller: controller,
          kind: ListKind.inventory,
          itemCountForList: (_) async => 0,
          onCreateNew: () {},
          onEdit: (_) {},
          onDuplicate: (_) {},
          onOpenTrash: () {},
          onOpenArchive: () {},
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('gathers the items of every inventory', (tester) async {
    await withServer(() async {
      final controller = await loaded(tester);
      expect(controller.hasAllView(ListKind.inventory), isTrue);

      await controller.selectList(
        allListsSentinel(1, kind: ListKind.inventory),
      );
      await tester.pump();

      expect(controller.isMetaMode, isTrue);
      expect(controller.kind, ListKind.inventory);
      expect(controller.currentList!.name, 'All inventories');
      expect(controller.items.map((i) => i.name), ['Milk', 'Peas']);
      expect(
        requests.map((r) => r.url.path),
        contains(endsWith('/houses/1/inventories/items')),
      );
      expect(
        ChecklistService.instance.selectedListId,
        kAllInventoriesId,
        reason: 'the view is remembered apart from "All lists"',
      );

      await quiesce(tester);
    });
  });

  testWidgets('keeps its own cache slot next to "All lists"', (tester) async {
    await withServer(() async {
      final controller = await loaded(tester);

      await controller.selectList(allListsSentinel(1));
      await controller.selectList(
        allListsSentinel(1, kind: ListKind.inventory),
      );
      await tester.pump();

      final cache = ChecklistService.instance;
      expect(cache.getCachedItems(kAllListsId)!.map((i) => i.name), ['Bread']);
      expect(cache.getCachedItems(kAllInventoriesId)!.map((i) => i.name), [
        'Milk',
        'Peas',
      ]);

      await quiesce(tester);
    });
  });

  testWidgets('reopens on the next load', (tester) async {
    await withServer(() async {
      ChecklistService.instance.selectedListId = kAllInventoriesId;
      final controller = await loaded(tester);

      expect(controller.currentList!.id, kAllInventoriesId);
      expect(controller.kind, ListKind.inventory);

      await quiesce(tester);
    });
  });

  testWidgets('heads the inventories in the switcher', (tester) async {
    await withServer(() async {
      final controller = await loaded(tester);
      await pumpSwitcher(tester, controller);

      expect(find.text(ListKind.inventory.strings.allTitle), findsOneWidget);
      expect(find.text(ListKind.inventory.strings.allSubtitle), findsOneWidget);

      await quiesce(tester);
    });
  });

  testWidgets('is missing from servers that do not announce it', (
    tester,
  ) async {
    seed(advertised: false);
    await withServer(() async {
      ChecklistService.instance.selectedListId = kAllInventoriesId;
      final controller = await loaded(tester);

      expect(controller.hasAllView(ListKind.inventory), isFalse);
      expect(controller.isMetaMode, isFalse);
      await pumpSwitcher(tester, controller);
      expect(find.text(ListKind.inventory.strings.allTitle), findsNothing);

      await quiesce(tester);
    });
  });

  group('the Inventories tab', () {
    Future<ChecklistsController> loadedTab(WidgetTester tester) async {
      final controller = ChecklistsController(
        houseId: 1,
        section: ListKind.inventory,
      );
      addTearDown(controller.dispose);
      await controller.load();
      await tester.pump();
      return controller;
    }

    setUp(() => ChecklistService.instance.selectedInventoryId = null);

    testWidgets('opens on an inventory, whatever the lists tab shows', (
      tester,
    ) async {
      await withServer(() async {
        ChecklistService.instance.selectedListId = groceries;
        final controller = await loadedTab(tester);

        expect(controller.kind, ListKind.inventory);
        expect(controller.currentList!.kind, ListKind.inventory);
        expect(
          ChecklistService.instance.selectedListId,
          groceries,
          reason: 'the widgets and the watch follow the lists tab',
        );
        expect(
          ChecklistService.instance.selectedInventoryId,
          controller.currentList!.id,
        );

        await quiesce(tester);
      });
    });

    testWidgets('reopens on its own last list', (tester) async {
      await withServer(() async {
        ChecklistService.instance.selectedInventoryId = kAllInventoriesId;
        final controller = await loadedTab(tester);

        expect(controller.currentList!.id, kAllInventoriesId);

        await quiesce(tester);
      });
    });

    testWidgets('stays on inventories', (tester) async {
      await withServer(() async {
        final controller = await loadedTab(tester);
        await controller.selectKind(ListKind.checklist);

        expect(controller.kind, ListKind.inventory);

        await tester.pumpWidget(
          wrapForTest(
            SheetHost(controller: controller, itemCountForList: (_) async => 0),
          ),
        );
        await tester.pump();
        expect(find.text('Fridge'), findsOneWidget);
        expect(
          find.text(ListKind.checklist.strings.title),
          findsNothing,
          reason: 'the switcher offers no other kind',
        );

        await quiesce(tester);
      });
    });
  });
}
