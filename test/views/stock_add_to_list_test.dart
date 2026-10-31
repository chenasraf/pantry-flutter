import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';
import 'package:pantry/views/checklists/form_components.dart';

/// An inventory item with nothing to link to on a shopping list can be added to
/// one from its card, and the notice about items that only get flagged counts
/// just those — and can be closed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  const shelf = 30;
  const groceries = 40;
  const eggs = 300;
  const newRow = 950;
  const dairy = 7;

  Map<String, dynamic> list(int id, String name, String kind, {int? restock}) =>
      {
        'id': id,
        'houseId': 1,
        'name': name,
        'kind': kind,
        'icon': 'list',
        'sortOrder': 0,
        'createdAt': 0,
        'updatedAt': 0,
        if (kind == 'inventory') 'restockChecklistId': restock,
      };

  Map<String, dynamic> eggsItem({Map<String, dynamic>? link}) => {
    'id': eggs,
    'listId': shelf,
    'name': 'Eggs',
    'categoryId': dairy,
    'sortOrder': 0,
    'createdAt': 0,
    'updatedAt': 0,
    'stockMode': 'count',
    'quantity': '1 egg',
    'target': '12 eggs',
    'stockStatus': 'low',
    'expiryStatus': 'none',
    'autoLink': true,
    'stockLink': link,
  };

  late List<http.Request> requests;
  late int? restockChecklist;
  late Map<String, dynamic>? eggsLink;

  http.Client server() => MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    final method = request.method;
    Object data = const <Object>[];
    if (method == 'POST' && path.endsWith('/lists/$groceries/items')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      data = {
        'id': newRow,
        'listId': groceries,
        'name': body['name'],
        'categoryId': body['categoryId'],
        'done': false,
        'sortOrder': 0,
        'createdAt': 0,
        'updatedAt': 0,
      };
    } else if (method != 'GET') {
      throw http.ClientException('offline', request.url);
    } else if (path.endsWith('/prefs')) {
      data = <String, dynamic>{};
    } else if (path.endsWith('/houses/1/lists')) {
      data = [list(groceries, 'Groceries', 'checklist')];
    } else if (path.endsWith('/houses/1/inventories')) {
      data = [list(shelf, 'Kitchen', 'inventory', restock: restockChecklist)];
    } else if (path.endsWith('/inventories/$shelf/items')) {
      data = [eggsItem(link: eggsLink)];
    }
    return http.Response(
      jsonEncode({
        'ocs': {
          'meta': {'status': 'ok', 'statuscode': 200, 'message': ''},
          'data': data,
        },
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  });

  Future<void> withServer(Future<void> Function() body) =>
      http.runWithClient(body, server);

  setUp(() async {
    requests = [];
    restockChecklist = null;
    eggsLink = null;
    ServerVersionService.instance.debugSeed(
      pantryVersion: Version.parse('0.38.0'),
    );
    ChecklistService.instance.cacheListsOfEveryKind(1, const []);
    ChecklistService.instance.selectedListId = null;
    ChecklistService.instance.cache.set('restockNoticeHidden:1', null);
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

  /// Takes the queue's retry timer off the clock; see
  /// shopping_billed_offline_test.dart for why this isn't awaited.
  Future<void> quiesce(WidgetTester tester) async {
    unawaited(manager.reset());
    await tester.pump(const Duration(seconds: 1));
  }

  ListItem eggsOf(ChecklistsController c) =>
      c.items.singleWhere((i) => i.id == eggs);

  testWidgets('adds the item to a shopping list and links it there', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await opened(tester);
      final lists = controller.stockRowListsFor(eggsOf(controller));
      expect(lists.map((l) => l.id), [groceries]);

      await controller.addStockRowAndLink(eggsOf(controller), lists.single);

      final create = requests.singleWhere(
        (r) => r.method == 'POST' && r.url.path.endsWith('/items'),
      );
      expect(jsonDecode(create.body), containsPair('name', 'Eggs'));
      expect(jsonDecode(create.body), containsPair('categoryId', dairy));
      final link = eggsOf(controller).stockLink!;
      expect(link.itemId, newRow);
      expect(link.listName, 'Groceries');

      await quiesce(tester);
    });
  });

  group('the only-flagged notice', () {
    testWidgets('counts an unlinked item with no restock checklist', (
      tester,
    ) async {
      await withServer(() async {
        final controller = await opened(tester);
        expect(controller.onlyFlaggedCount, 1);
        await quiesce(tester);
      });
    });

    testWidgets('leaves out a linked item', (tester) async {
      eggsLink = {
        'itemId': 900,
        'name': 'Eggs',
        'listId': groceries,
        'listName': 'Groceries',
        'state': 'open',
      };
      await withServer(() async {
        final controller = await opened(tester);
        expect(controller.onlyFlaggedCount, 0);
        await quiesce(tester);
      });
    });

    testWidgets('leaves out an inventory with a restock checklist', (
      tester,
    ) async {
      restockChecklist = groceries;
      await withServer(() async {
        final controller = await opened(tester);
        expect(controller.onlyFlaggedCount, 0);
        await quiesce(tester);
      });
    });

    testWidgets('stays closed once closed', (tester) async {
      await withServer(() async {
        final controller = await opened(tester);
        expect(controller.isRestockNoticeHidden(shelf), isFalse);

        controller.hideRestockNotice(shelf);

        expect(controller.isRestockNoticeHidden(shelf), isTrue);
        await quiesce(tester);
      });
    });
  });

  testWidgets('a control too wide for its caption row drops under it', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: LabeledFieldCard(
              label: 'Péremption',
              trailing: SizedBox(key: Key('control'), width: 280, height: 30),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final caption = tester.getRect(find.text('PÉREMPTION'));
    final control = tester.getRect(find.byKey(const Key('control')));
    expect(control.top, greaterThanOrEqualTo(caption.bottom));
  });
}
