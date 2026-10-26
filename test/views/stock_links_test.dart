import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/notification.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/deep_link_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/services/cache_store.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/sync/sync_queue.dart';
import 'package:pantry_core/utils/stock_rules.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/utils/app_toast.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';
import 'package:pantry/views/checklists/restock_feedback.dart';
import 'package:pantry/views/checklists/restock_markers.dart';
import 'package:pantry/views/checklists/stock_link_parts.dart';

import '../helpers/test_app.dart';

/// Inventory items reach shopping lists through stock links (Pantry 0.38.0):
/// linked by name or by hand, synced by the server, and reported back to the
/// member whose write caused it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  const shelf = 30;
  const groceries = 40;
  const eggs = 300;
  const eggsRow = 900;

  final today = todayEpoch();

  Map<String, dynamic> inventory({int? restockChecklistId}) => {
    'id': shelf,
    'houseId': 1,
    'name': 'Kitchen',
    'kind': 'inventory',
    'icon': 'list',
    'sortOrder': 0,
    'createdAt': 0,
    'updatedAt': 0,
    'needsRestock': 0,
    'expiryLeadDays': 2,
    'restockChecklistId': restockChecklistId,
    'stockSummary': true,
  };

  const eggsLink = {
    'itemId': eggsRow,
    'name': 'Eggs',
    'quantity': '8 eggs',
    'listId': groceries,
    'listName': 'Groceries',
    'listColor': '#00aa55',
    'state': 'open',
  };

  Map<String, dynamic> eggsItem({
    String quantity = '4 eggs',
    Map<String, dynamic>? link,
    List<Map<String, dynamic>> candidates = const [],
    bool autoLink = true,
    int? expiresAt,
    int? shelfLifeDays,
  }) => {
    'id': eggs,
    'listId': shelf,
    'name': 'Eggs',
    'sortOrder': 0,
    'createdAt': 0,
    'updatedAt': 0,
    'stockMode': 'count',
    'stockLevel': 'full',
    'quantity': quantity,
    'target': '12 eggs',
    'reorderPoint': null,
    'stockStatus': 'ok',
    'shortfall': null,
    'expiresAt': expiresAt,
    'shelfLifeDays': shelfLifeDays,
    'expiryStatus': 'none',
    'autoLink': autoLink,
    'stockLink': link,
    'linkCandidates': candidates,
  };

  late List<http.Request> requests;
  late Map<String, dynamic> eggsOnServer;

  http.Client server() => MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    final method = request.method;
    Object data = const <Object>[];
    final body = request.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(request.body) as Map<String, dynamic>;
    if (path.endsWith('/items/$eggs/link') && method == 'POST') {
      eggsOnServer = {
        ...eggsOnServer,
        'stockLink': eggsLink,
        'linkCandidates': const [],
        'restockSync': [
          {
            'event': 'changed',
            'itemId': eggs,
            'rowId': eggsRow,
            'rowName': 'Eggs',
            'quantity': '8 eggs',
            'listId': groceries,
            'listName': 'Groceries',
          },
        ],
      };
      data = eggsOnServer;
    } else if (path.endsWith('/items/$eggs/link') && method == 'DELETE') {
      eggsOnServer = {...eggsOnServer, 'stockLink': null, 'autoLink': false};
      data = eggsOnServer;
    } else if (path.endsWith('/items/$eggs') && method == 'PATCH') {
      eggsOnServer = {...eggsOnServer, ...body};
      data = eggsOnServer;
    } else if (path.endsWith('/inventories/$shelf') && method == 'PATCH') {
      data = {...inventory(), ...body};
    } else if (method != 'GET') {
      throw http.ClientException('offline', request.url);
    } else if (path.endsWith('/link-targets')) {
      data = [eggsLink];
    } else if (path.endsWith('/prefs')) {
      data = <String, dynamic>{};
    } else if (path.endsWith('/houses/1/inventories')) {
      data = [inventory(restockChecklistId: groceries)];
    } else if (path.endsWith('/houses/1/checklists')) {
      data = [
        {
          'id': groceries,
          'houseId': 1,
          'name': 'Groceries',
          'kind': 'checklist',
          'icon': 'list',
          'sortOrder': 0,
          'createdAt': 0,
          'updatedAt': 0,
        },
      ];
    } else if (path.endsWith('/inventories/$shelf/items')) {
      data = [eggsOnServer];
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

  Iterable<http.Request> hits(String method, String suffix) =>
      requests.where((r) => r.method == method && r.url.path.endsWith(suffix));

  setUp(() async {
    requests = [];
    eggsOnServer = eggsItem();
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

  Future<void> quiesce(WidgetTester tester) async {
    unawaited(manager.reset());
    await tester.pump(const Duration(seconds: 1));
  }

  ListItem byId(ChecklistsController c, int id) =>
      c.items.singleWhere((i) => i.id == id);

  group('models', () {
    test('inventory items read their link, and lists their restock '
        'checklist', () {
      final item = ListItem.fromJson(eggsItem(link: eggsLink, autoLink: false));
      expect(item.autoLink, isFalse);
      expect(item.stockLink!.name, 'Eggs');
      expect(item.stockLink!.state, StockLinkState.open);
      expect(item.stockLink!.listColor, '#00aa55');

      final list = ChecklistList.fromJson(
        inventory(restockChecklistId: groceries),
      );
      expect(list.restockChecklistId, groceries);
      expect(list.stockSummary, isTrue);
      expect(
        list.copyWith(clearRestockChecklistId: true).restockChecklistId,
        isNull,
      );
    });

    test('checklist items read what they restock and what a tick did', () {
      final row = ListItem.fromJson({
        'id': eggsRow,
        'listId': groceries,
        'name': 'Eggs',
        'done': true,
        'sortOrder': 0,
        'createdAt': 0,
        'updatedAt': 0,
        'quantityPinned': true,
        'restocks': [
          {'itemId': eggs, 'name': 'Eggs', 'listId': shelf, 'listName': 'K'},
        ],
        'restock': [
          {
            'itemId': eggs,
            'listId': shelf,
            'itemName': 'Eggs',
            'listName': 'Kitchen',
            'added': '8',
            'previousLevel': null,
            'replaced': false,
          },
        ],
        'restocked': [
          {
            'itemId': eggs,
            'listId': shelf,
            'itemName': 'Eggs',
            'listName': 'Kitchen',
            'added': '8',
          },
        ],
      });
      expect(row.quantityPinned, isTrue);
      expect(row.restocks.single.itemId, eggs);
      expect(row.restock!.single.added, '8');
      expect(row.restocked, hasLength(1));

      // What a write did is news once, never something to cache.
      final cached = ListItem.fromJson(row.toJson());
      expect(cached.restocked, isEmpty);
      expect(cached.restock!.single.added, '8');
      expect(cached.restocks, hasLength(1));
      expect(cached.quantityPinned, isTrue);
    });

    test('Shopping Mode check answers carry what they restocked', () {
      final result = ShoppingCheckResult.fromJson({
        'success': true,
        'restock': null,
        'restocked': const [],
        'restockUndone': [
          {
            'itemId': eggs,
            'listId': shelf,
            'itemName': 'Eggs',
            'listName': 'Kitchen',
            'added': '8',
          },
        ],
        'restockSync': [
          {
            'event': 'revived',
            'itemId': eggs,
            'rowId': eggsRow,
            'rowName': 'Eggs',
            'quantity': null,
            'listId': groceries,
            'listName': 'Groceries',
          },
          {'event': 'unheard-of', 'itemId': 1, 'rowId': 1, 'listId': 1},
        ],
      });
      expect(result.restock, isNull);
      expect(result.restockUndone.single.itemName, 'Eggs');
      expect(result.restockSync.single.kind, RestockSyncKind.revived);
    });

    test('a stock summary opens its inventory on Needs restock', () {
      final n = NcNotification.fromJson({
        'notification_id': 1,
        'app': 'pantry',
        'user': 'chen',
        'datetime': '2026-10-26T08:00:00+00:00',
        'object_type': 'inventory',
        'object_id': '$shelf',
        'subject': 'Kitchen: 2 low',
        'message': '',
        'link':
            'https://cloud.example.com/apps/pantry/houses/1/inventories/'
            '$shelf?stock=restock',
      });
      expect(n.target, NotificationTarget.checklists);
      final target = n.inventoryLinkTarget!;
      expect(target.listId, shelf);
      expect(target.needsRestock, isTrue);

      const link = DeepLink(
        tabIndex: 0,
        houseId: 1,
        listId: shelf,
        needsRestock: true,
      );
      final decoded = DeepLink.decode(link.encode())!;
      expect(decoded.listId, shelf);
      expect(decoded.needsRestock, isTrue);
      expect(DeepLink.decode('0:1:$shelf:')!.needsRestock, isFalse);
    });
  });

  group('renew offer', () {
    StockFields count(String onHand, {int? expiresAt, int? shelf = 10}) =>
        StockFields(
          stockMode: null,
          stockLevel: null,
          quantity: onHand,
          target: '12',
          reorderPoint: null,
          expiresAt: expiresAt,
          shelfLifeDays: shelf,
        );

    test('a raise while some is on hand offers today + shelf life', () {
      expect(
        renewOffer(count('4', expiresAt: addDays(today, 2)), count('5'), today),
        addDays(today, 10),
      );
    });

    test('nothing is offered from empty, on a drop, without a shelf life, '
        'or when it would not move the date later', () {
      expect(renewOffer(count('0'), count('5'), today), isNull);
      expect(renewOffer(count('4'), count('3'), today), isNull);
      expect(renewOffer(count('4', shelf: null), count('5'), today), isNull);
      expect(
        renewOffer(
          count('4', expiresAt: addDays(today, 20)),
          count('5'),
          today,
        ),
        isNull,
      );
    });
  });

  group('feedback', () {
    const entry = RestockEntry(
      itemId: eggs,
      listId: shelf,
      itemName: 'Eggs',
      listName: 'Kitchen',
      added: '8',
    );
    const milk = RestockEntry(
      itemId: 2,
      listId: shelf,
      itemName: 'Milk',
      listName: 'Kitchen',
      added: '2',
      replaced: true,
    );
    const flour = RestockEntry(
      itemId: 3,
      listId: shelf,
      itemName: 'Flour',
      listName: 'Kitchen',
      previousLevel: 'low',
    );
    const dateOnly = RestockEntry(
      itemId: 4,
      listId: shelf,
      itemName: 'Salt',
      listName: 'Kitchen',
    );

    test('restock texts follow the web wording', () {
      expect(
        restockText(const [entry, milk]),
        'Restocked Eggs (Kitchen) +8, replaced Milk (Kitchen) ×2',
      );
      expect(restockText(const [flour]), 'Restocked Flour (Kitchen) to Full');
      expect(restockText(const [dateOnly]), isNull);
      expect(
        restockUndoneText(const [entry]),
        'Undid: restocked Eggs (Kitchen) +8',
      );
    });

    test('sync events read as the member would say them', () {
      RestockMessage of(RestockSyncKind kind, {String? quantity}) =>
          syncEventMessage(
            RestockSyncEvent(
              kind: kind,
              itemId: eggs,
              rowId: eggsRow,
              rowName: 'Eggs',
              quantity: quantity,
              listId: groceries,
              listName: 'Groceries',
            ),
          );
      expect(
        of(RestockSyncKind.added, quantity: '8 eggs').text,
        'Added 8 eggs to Groceries',
      );
      expect(of(RestockSyncKind.added).text, 'Added Eggs to Groceries');
      expect(of(RestockSyncKind.added).kind, ToastKind.success);
      expect(
        of(RestockSyncKind.changed, quantity: '6').text,
        'Groceries: Eggs now × 6',
      );
      expect(of(RestockSyncKind.changed, quantity: '6').kind, ToastKind.info);
      expect(
        of(RestockSyncKind.pinned).text,
        'Eggs on Groceries was set by hand, left as it is',
      );
      expect(
        of(RestockSyncKind.recovered).text,
        'No longer needed: Eggs on Groceries',
      );
    });

    test('a write that leaves several matches asks for a pick', () {
      final before = ListItem.fromJson(eggsItem());
      final after = ListItem.fromJson(
        eggsItem(candidates: [eggsLink, eggsLink]),
      );
      final op = SyncOp(
        uuid: 'u',
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.update,
        houseId: 1,
        parentId: shelf,
        entityId: eggs,
        body: const {'quantity': '3'},
        createdAt: 0,
      );
      final messages = itemWriteMessages(op, before, after);
      expect(messages.single.kind, ToastKind.warning);
      expect(
        messages.single.text,
        'Eggs matches 2 items on Groceries. Pick one to link.',
      );
    });

    test('only answers that come back in time are claimed', () async {
      final tracker = RestockFeedbackTracker<int>(
        window: const Duration(milliseconds: 20),
      );
      tracker.track('fast', 1);
      tracker.track('slow', 2);
      expect(tracker.claim('fast'), 1);
      expect(tracker.claim('fast'), isNull);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(tracker.claim('slow'), isNull);
    });
  });

  group('linking', () {
    testWidgets('picking a row links it and reports what the sync did', (
      tester,
    ) async {
      await withServer(() async {
        final controller = await opened(tester);
        final row = StockLinkRow.fromJson(eggsLink);
        controller.linkStock(byId(controller, eggs), row);
        expect(byId(controller, eggs).stockLink!.itemId, eggsRow);

        await manager.flushNow();
        await tester.pump();
        final sent =
            jsonDecode(hits('POST', '/items/$eggs/link').single.body) as Map;
        expect(sent, {'targetItemId': eggsRow});
        expect(hits('PATCH', '/items/$eggs'), isEmpty);
        expect(byId(controller, eggs).stockLink!.listName, 'Groceries');

        await quiesce(tester);
      });
    });

    testWidgets('unlinking turns auto-link off and unlinks', (tester) async {
      eggsOnServer = eggsItem(link: eggsLink);
      await withServer(() async {
        final controller = await opened(tester);
        controller.unlinkStock(byId(controller, eggs));
        final local = byId(controller, eggs);
        expect(local.stockLink, isNull);
        expect(local.autoLink, isFalse);

        await manager.flushNow();
        await tester.pump();
        expect(hits('DELETE', '/items/$eggs/link'), hasLength(1));
        expect(jsonDecode(hits('PATCH', '/items/$eggs').single.body), {
          'autoLink': false,
        });

        await quiesce(tester);
      });
    });

    test('a link and an unlink queued together send only the last', () {
      final queue = SyncQueue(CacheStore('test_stock_link_queue.json'));
      SyncOp write(String uuid, Map<String, dynamic> body) => SyncOp(
        uuid: uuid,
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.update,
        houseId: 1,
        parentId: shelf,
        entityId: eggs,
        body: body,
        createdAt: 0,
      );
      queue.enqueue(write('link', {stockLinkTargetKey: eggsRow}));
      queue.enqueue(
        write('unlink', {stockLinkTargetKey: 0, 'autoLink': false}),
      );
      queue.merge();
      final merged = queue.all().single;
      expect(merged.body, {stockLinkTargetKey: 0, 'autoLink': false});
    });

    testWidgets('a new restock checklist is saved, and none clears it', (
      tester,
    ) async {
      await withServer(() async {
        final controller = await opened(tester);
        final list = controller.currentList!;
        controller.saveInventorySettings(
          list,
          name: list.name,
          expiryLeadDays: 2,
          restockChecklistId: null,
          stockSummary: false,
        );
        expect(controller.currentList!.restockChecklistId, isNull);

        await manager.flushNow();
        await tester.pump();
        expect(jsonDecode(hits('PATCH', '/inventories/$shelf').single.body), {
          'restockChecklistId': 0,
          'stockSummary': false,
        });

        await quiesce(tester);
      });
    });
  });

  group('renewing', () {
    testWidgets('a raise offers a renewal that a tap sends as a date', (
      tester,
    ) async {
      eggsOnServer = eggsItem(expiresAt: addDays(today, 1), shelfLifeDays: 10);
      await withServer(() async {
        final controller = await opened(tester);
        await controller.setOnHand(byId(controller, eggs), '5 eggs');
        expect(
          controller.renewOfferFor(byId(controller, eggs)),
          addDays(today, 10),
        );

        await controller.renewExpiry(byId(controller, eggs));
        expect(controller.renewOfferFor(byId(controller, eggs)), isNull);
        expect(byId(controller, eggs).expiresAt, addDays(today, 10));

        await manager.flushNow();
        await tester.pump();
        final bodies = hits(
          'PATCH',
          '/items/$eggs',
        ).map((r) => jsonDecode(r.body) as Map).toList();
        expect(bodies.last, containsPair('expiresAt', addDays(today, 10)));

        await quiesce(tester);
      });
    });

    testWidgets('any other edit drops the offer', (tester) async {
      eggsOnServer = eggsItem(expiresAt: addDays(today, 1), shelfLifeDays: 10);
      await withServer(() async {
        final controller = await opened(tester);
        await controller.setOnHand(byId(controller, eggs), '5 eggs');
        await controller.updateItem(byId(controller, eggs), name: 'Big eggs');
        expect(controller.renewOfferFor(byId(controller, eggs)), isNull);

        await quiesce(tester);
      });
    });
  });

  group('widgets', () {
    Future<void> pumpCard(
      WidgetTester tester,
      ListItem item, {
      StockLinkActions? actions,
      String? checklist = 'Groceries',
    }) => tester.pumpWidget(
      wrapForTest(
        SingleChildScrollView(
          child: StockLinkCard(
            item: item,
            restockChecklistName: checklist,
            actions: actions,
          ),
        ),
      ),
    );

    testWidgets('the card shows the link and unlinks', (tester) async {
      var unlinked = false;
      await pumpCard(
        tester,
        ListItem.fromJson(eggsItem(link: eggsLink)),
        actions: StockLinkActions(
          onUnlink: () => unlinked = true,
          onPick: (_) {},
          onSetAutoLink: (_) {},
          onLinkByHand: () {},
        ),
      );
      expect(find.text('Linked to Eggs on Groceries · × 8 eggs'), findsOne);
      await tester.tap(find.text('Unlink'));
      expect(unlinked, isTrue);
    });

    testWidgets('several matches ask which one, and link the pick', (
      tester,
    ) async {
      StockLinkRow? picked;
      final other = {...eggsLink, 'itemId': 901, 'name': 'Eggs (free range)'};
      await pumpCard(
        tester,
        ListItem.fromJson(eggsItem(candidates: [eggsLink, other])),
        actions: StockLinkActions(
          onUnlink: () {},
          onPick: (row) => picked = row,
          onSetAutoLink: (_) {},
          onLinkByHand: () {},
        ),
      );
      expect(
        find.text('2 items match on the restock checklist. Which one is this?'),
        findsOne,
      );
      await tester.tap(find.text('Eggs (free range), Groceries, × 8 eggs'));
      await tester.pump();
      await tester.tap(find.text('Link'));
      expect(picked!.itemId, 901);
    });

    testWidgets('an unlinked item says where it will be added', (tester) async {
      await pumpCard(tester, ListItem.fromJson(eggsItem()));
      expect(
        find.text('Finds or adds "Eggs" on Groceries when it is needed.'),
        findsOne,
      );
      await pumpCard(tester, ListItem.fromJson(eggsItem()), checklist: null);
      expect(
        find.text(
          'Pick a restock checklist in the inventory settings to find or '
          'add this item there.',
        ),
        findsOne,
      );
      await pumpCard(tester, ListItem.fromJson(eggsItem(autoLink: false)));
      expect(
        find.text('This item is only marked here when it runs low.'),
        findsOne,
      );
    });

    testWidgets('narrow rows chip the link state that needs saying', (
      tester,
    ) async {
      expect(StockLinkChip.showsFor(ListItem.fromJson(eggsItem())), isFalse);
      final pick = ListItem.fromJson(eggsItem(candidates: [eggsLink]));
      expect(StockLinkChip.showsFor(pick), isTrue);
      await tester.pumpWidget(wrapForTest(StockLinkChip(item: pick)));
      expect(find.text('Not linked · 1 match, pick one'), findsOne);
    });

    test('checklist rows mark a restock and a system done', () {
      final ticked = ListItem.fromJson({
        'id': eggsRow,
        'listId': groceries,
        'name': 'Eggs',
        'done': true,
        'doneBy': 'chen',
        'sortOrder': 0,
        'createdAt': 0,
        'updatedAt': 0,
        'restock': [
          {
            'itemId': eggs,
            'listId': shelf,
            'itemName': 'Eggs',
            'listName': 'Kitchen',
            'added': '8',
          },
        ],
      });
      expect(
        ticked.restockLine,
        'Restocked Eggs (Kitchen) +8 · uncheck to undo',
      );
      expect(ticked.noLongerNeeded, isFalse);

      final recovered = ListItem.fromJson({
        ...ticked.toJson(),
        'doneBy': null,
        'restock': null,
        'restocks': [
          {'itemId': eggs, 'name': 'Eggs', 'listId': shelf, 'listName': 'K'},
        ],
      });
      expect(recovered.restockLine, isNull);
      expect(recovered.noLongerNeeded, isTrue);
    });
  });
}
