import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/utils/list_kind_strings.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';
import 'package:pantry/views/checklists/switcher_duplicate_stage.dart';
import 'package:pantry/views/checklists/switcher_list_stage.dart';

import '../helpers/test_app.dart';

/// Templates and inventories are served by their own resources next to the
/// checklists' `/lists`, and only from Pantry 0.38.0 on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  const checklistA = 10;
  const checklistB = 11;
  const template = 20;
  const inventory = 30;
  const templateItem = 200;

  Map<String, dynamic> list(
    int id,
    String name,
    String kind, {
    int sortOrder = 0,
  }) => {
    'id': id,
    'houseId': 1,
    'name': name,
    'kind': kind,
    'icon': 'list',
    'sortOrder': sortOrder,
    'createdAt': 0,
    'updatedAt': 0,
  };

  // A template item carries no done state.
  Map<String, dynamic> item(int id, int listId) => {
    'id': id,
    'listId': listId,
    'name': 'Eggs',
    'sortOrder': 0,
    'createdAt': 0,
    'updatedAt': 0,
  };

  late List<http.Request> requests;
  late bool withInventory;

  http.Client server() => MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    Object data = const <Object>[];
    if (request.method == 'POST' && path.contains('/from/')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      data = list(40, body['name'] as String, 'template');
    } else if (request.method == 'POST' && path.endsWith('/batch/move')) {
      data = {
        'success': true,
        'items': [item(templateItem, checklistA)],
        'skipped': <int>[],
      };
    } else if (request.method != 'GET') {
      throw http.ClientException('offline', request.url);
    } else if (path.endsWith('/prefs')) {
      data = <String, dynamic>{};
    } else if (path.endsWith('/houses/1/lists')) {
      data = [
        list(checklistA, 'Groceries', 'checklist', sortOrder: 0),
        list(checklistB, 'Hardware', 'checklist', sortOrder: 2),
      ];
    } else if (path.endsWith('/houses/1/templates')) {
      data = [list(template, 'Weekly staples', 'template', sortOrder: 1)];
    } else if (path.endsWith('/houses/1/inventories')) {
      data = withInventory
          ? [list(inventory, 'Pantry shelf', 'inventory', sortOrder: 3)]
          : const <Object>[];
    } else if (path.endsWith('/templates/$template/items')) {
      data = [item(templateItem, template)];
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

  void seedVersion(String version) => ServerVersionService.instance.debugSeed(
    pantryVersion: Version.parse(version),
  );

  setUp(() async {
    requests = [];
    withInventory = true;
    seedVersion('0.38.0');
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

  Future<ChecklistsController> loaded(WidgetTester tester) async {
    final controller = ChecklistsController(houseId: 1);
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pump();
    return controller;
  }

  ChecklistList byId(ChecklistsController c, int id) =>
      c.lists.singleWhere((l) => l.id == id);

  testWidgets('every kind loads from its own resource', (tester) async {
    await withServer(() async {
      final controller = await loaded(tester);

      expect(
        {for (final l in controller.lists) l.id: l.kind},
        {
          checklistA: ListKind.checklist,
          checklistB: ListKind.checklist,
          template: ListKind.template,
          inventory: ListKind.inventory,
        },
      );
      expect(
        ChecklistService.instance.getCachedLists(1)!.map((l) => l.id),
        [checklistA, checklistB],
        reason: 'widgets, shopping and the watch read only checklists',
      );
      expect(
        ChecklistService.instance
            .getCachedListsOfEveryKind(1)!
            .map((l) => l.id)
            .toSet(),
        {checklistA, checklistB, template, inventory},
      );

      await quiesce(tester);
    });
  });

  testWidgets('older servers only see checklists', (tester) async {
    seedVersion('0.37.0');
    await withServer(() async {
      final controller = await loaded(tester);

      expect(controller.lists.map((l) => l.kind).toSet(), {ListKind.checklist});
      expect(
        requests.where(
          (r) =>
              r.url.path.contains('/templates') ||
              r.url.path.contains('/inventories'),
        ),
        isEmpty,
      );

      await quiesce(tester);
    });
  });

  testWidgets('a template reads its items from /templates', (tester) async {
    await withServer(() async {
      final controller = await loaded(tester);
      requests.clear();

      await controller.selectList(byId(controller, template));

      expect(
        requests.map((r) => r.url.path),
        contains(endsWith('/houses/1/templates/$template/items')),
      );
      expect(controller.kind, ListKind.template);
      expect(controller.isChecklistKind, isFalse);
      expect(controller.items.single.done, isFalse);
      expect(controller.canUncheckAll, isFalse);
      expect(controller.canRemoveAllDone, isFalse);

      await quiesce(tester);
    });
  });

  testWidgets('a section without lists stays open on its empty state', (
    tester,
  ) async {
    withInventory = false;
    await withServer(() async {
      final controller = await loaded(tester);

      await controller.selectKind(ListKind.inventory);
      expect(controller.kind, ListKind.inventory);
      expect(controller.currentList, isNull);

      await controller.selectKind(ListKind.template);
      expect(controller.currentList?.id, template);

      await quiesce(tester);
    });
  });

  testWidgets('removing a section\'s last list keeps the section open', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);
      await controller.selectList(byId(controller, template));

      await controller.deleteList(byId(controller, template));

      expect(controller.currentList, isNull);
      expect(controller.kind, ListKind.template);

      await quiesce(tester);
    });
  });

  testWidgets('duplicating as another kind posts to that kind\'s from/', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);
      requests.clear();

      await controller.duplicateList(
        byId(controller, checklistA),
        name: 'Staples',
        resetDone: true,
        as: ListKind.template,
      );

      final call = requests.singleWhere((r) => r.method == 'POST');
      expect(call.url.path, endsWith('/houses/1/templates/from/$checklistA'));
      expect(jsonDecode(call.body), {'name': 'Staples'});
      expect(controller.currentList?.id, 40);
      expect(controller.kind, ListKind.template);
      expect(ChecklistService.instance.kindOf(40), ListKind.template);

      await quiesce(tester);
    });
  });

  testWidgets('moving an item to another kind goes through batch/move', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);
      await controller.selectList(byId(controller, template));
      requests.clear();

      final skipped = await controller.moveItem(
        controller.items.single,
        checklistA,
      );

      final call = requests.singleWhere((r) => r.method == 'POST');
      expect(call.url.path, endsWith('/houses/1/items/batch/move'));
      expect(jsonDecode(call.body), {
        'itemIds': [templateItem],
        'targetListId': checklistA,
      });
      expect(skipped, 0);
      expect(controller.items, isEmpty);

      await quiesce(tester);
    });
  });

  testWidgets('reordering a section keeps the other kinds in their slots', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);

      // Shared order: checklistA 0, template 1, checklistB 2, inventory 3.
      await controller.reorderLists(0, 1, kind: ListKind.checklist);

      expect(controller.sortedLists.map((l) => l.id), [
        checklistB,
        template,
        checklistA,
        inventory,
      ]);
      final op = manager.queueForTest.all().single;
      expect(op.op, SyncOpKind.reorder);
      expect((op.body['order'] as List).map((e) => (e as Map)['id']), [
        checklistB,
        template,
        checklistA,
        inventory,
      ]);

      await quiesce(tester);
    });
  });

  testWidgets('a list created offline keeps its kind for its queued items', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);

      final created = await controller.createList(
        kind: ListKind.inventory,
        name: 'Freezer',
      );

      expect(created.kind, ListKind.inventory);
      expect(ChecklistService.instance.kindOf(created.id), ListKind.inventory);
      final op = manager.queueForTest.all().single;
      expect(op.op, SyncOpKind.create);
      expect(op.body['kind'], 'inventory');

      await quiesce(tester);
    });
  });

  testWidgets('emptying one kind\'s trash leaves another kind\'s restore', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);
      final trashed = byId(controller, checklistB);

      await controller.restoreList(trashed);
      await controller.emptyListsTrash(kind: ListKind.template);
      manager.queueForTest.merge();

      final ops = manager.queueForTest.all();
      expect(ops.map((o) => o.op), [SyncOpKind.restore, SyncOpKind.emptyTrash]);
      expect(ops.last.body['kind'], 'template');

      await quiesce(tester);
    });
  });

  testWidgets('the switcher shows a section\'s empty state', (tester) async {
    withInventory = false;
    await withServer(() async {
      final controller = await loaded(tester);
      ListKind? picked;

      await tester.pumpWidget(
        wrapForTest(
          ListStage(
            controller: controller,
            kind: ListKind.inventory,
            onKindChanged: (k) => picked = k,
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

      expect(find.text(ListKind.inventory.strings.emptyTitle), findsOneWidget);
      expect(find.text(ListKind.inventory.strings.newList), findsOneWidget);
      expect(find.text('Groceries'), findsNothing);

      await tester.tap(find.text(ListKind.template.strings.title));
      expect(picked, ListKind.template);

      await quiesce(tester);
    });
  });

  testWidgets('duplicating offers every kind and resets done only for '
      'checklist to checklist', (tester) async {
    await withServer(() async {
      final controller = await loaded(tester);
      await tester.pumpWidget(
        wrapForTest(
          DuplicateListStage(
            controller: controller,
            source: byId(controller, checklistA),
            onBack: () {},
            onDuplicated: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text(m.listKinds.duplicateAs), findsOneWidget);
      for (final kind in ListKind.values) {
        expect(find.text(kind.strings.name), findsOneWidget);
      }
      expect(find.byType(CheckboxListTile), findsOneWidget);

      await tester.tap(find.text(ListKind.template.strings.name));
      await tester.pump();
      expect(find.byType(CheckboxListTile), findsNothing);

      await quiesce(tester);
    });
  });
}
