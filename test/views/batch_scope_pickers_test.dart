import 'dart:async';
import 'dart:convert';

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
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';
import 'package:pantry/views/checklists/checklists_selection_bar.dart';

import '../helpers/test_app.dart';

/// Batch category and label pickers offer only what is valid for every
/// selected item — the batch endpoints don't check scope themselves.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  const groceries = 10;
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

  Map<String, dynamic> scoped(int id, String name, int? listId) => {
    'id': id,
    'houseId': 1,
    'listId': listId,
    'name': name,
    'icon': 'tag',
    'color': '#ef4444',
    'sortOrder': id,
    'createdAt': 0,
    'updatedAt': 0,
  };

  var withGlobals = false;

  http.Client server() => MockClient((request) async {
    final path = request.url.path;
    Object data = const <Object>[];
    if (request.method != 'GET') {
      throw http.ClientException('offline', request.url);
    } else if (path.endsWith('/prefs')) {
      data = <String, dynamic>{};
    } else if (path.endsWith('/houses/1/lists')) {
      data = [list(groceries, 'Groceries', 'checklist')];
    } else if (path.endsWith('/houses/1/inventories')) {
      data = [
        list(fridge, 'Fridge', 'inventory'),
        list(freezer, 'Freezer', 'inventory'),
      ];
    } else if (path.endsWith('/houses/1/inventories/items')) {
      data = [
        item(300, fridge, 'Milk'),
        item(301, fridge, 'Butter'),
        item(310, freezer, 'Peas'),
      ];
    } else if (path.endsWith('/houses/1/categories')) {
      data = [
        scoped(1, 'Dairy', fridge),
        scoped(2, 'Frozen', freezer),
        if (withGlobals) scoped(3, 'Everyday', null),
      ];
    } else if (path.endsWith('/houses/1/labels')) {
      data = [
        scoped(11, 'Cold', fridge),
        scoped(12, 'Icy', freezer),
        if (withGlobals) scoped(13, 'Organic', null),
      ];
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

  setUp(() async {
    withGlobals = false;
    ServerVersionService.instance.debugSeed(
      pantryVersion: Version.parse('0.39.0'),
    );
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

  Future<ChecklistsController> allInventories(WidgetTester tester) async {
    final controller = ChecklistsController(
      houseId: 1,
      section: ListKind.inventory,
    );
    addTearDown(controller.dispose);
    await controller.load();
    await controller.selectList(allListsSentinel(1, kind: ListKind.inventory));
    await tester.pump();
    return controller;
  }

  ListItem named(ChecklistsController c, String name) =>
      c.items.firstWhere((i) => i.name == name);

  group('helpers', () {
    testWidgets('items on one list get that list\'s entries', (tester) async {
      await withServer(() async {
        withGlobals = true;
        final c = await allInventories(tester);
        final items = [named(c, 'Milk'), named(c, 'Butter')];

        expect(c.categoriesForItems(items).map((x) => x.name), [
          'Dairy',
          'Everyday',
        ]);
        expect(c.labelsForItems(items).map((x) => x.name), ['Cold', 'Organic']);

        await quiesce(tester);
      });
    });

    testWidgets('items across lists get only the globals', (tester) async {
      await withServer(() async {
        withGlobals = true;
        final c = await allInventories(tester);
        final items = [named(c, 'Milk'), named(c, 'Peas')];

        expect(c.categoriesForItems(items).map((x) => x.name), ['Everyday']);
        expect(c.labelsForItems(items).map((x) => x.name), ['Organic']);

        await quiesce(tester);
      });
    });
  });

  group('in "All inventories"', () {
    Future<ChecklistsController> pumpSelected(
      WidgetTester tester,
      List<String> names,
    ) async {
      final c = await allInventories(tester);
      for (final name in names) {
        c.toggleSelected(named(c, name).id);
      }
      await tester.pumpWidget(wrapForTest(SelectionActionBar(controller: c)));
      await tester.pump();
      return c;
    }

    testWidgets('the category picker offers the items\' list categories', (
      tester,
    ) async {
      await withServer(() async {
        await pumpSelected(tester, ['Milk', 'Butter']);

        await tester.tap(find.text(m.checklists.batch.category));
        await tester.pumpAndSettle();

        expect(find.text('Dairy'), findsOneWidget);
        expect(find.text('Frozen'), findsNothing);
        expect(find.text(m.checklists.batch.noSharedCategories), findsNothing);

        await tester.tap(find.text('Dairy'));
        await tester.pumpAndSettle();

        await quiesce(tester);
      });
    });

    testWidgets('items across lists with no globals explain the empty picker', (
      tester,
    ) async {
      await withServer(() async {
        await pumpSelected(tester, ['Milk', 'Peas']);

        await tester.tap(find.text(m.checklists.batch.category));
        await tester.pumpAndSettle();

        expect(find.text(m.checklists.batch.clearCategory), findsOneWidget);
        expect(
          find.text(m.checklists.batch.noSharedCategories),
          findsOneWidget,
        );
        expect(find.text('Dairy'), findsNothing);
        expect(find.text('Frozen'), findsNothing);

        await quiesce(tester);
      });
    });

    testWidgets('the label picker leaves out other lists\' labels', (
      tester,
    ) async {
      await withServer(() async {
        await pumpSelected(tester, ['Peas']);

        await tester.tap(find.text(m.checklists.batch.labels));
        await tester.pumpAndSettle();

        expect(find.text('Icy'), findsOneWidget);
        expect(find.text('Cold'), findsNothing);

        await quiesce(tester);
      });
    });

    testWidgets('the label picker explains items across lists', (tester) async {
      await withServer(() async {
        await pumpSelected(tester, ['Butter', 'Peas']);

        await tester.tap(find.text(m.checklists.batch.labels));
        await tester.pumpAndSettle();

        expect(find.text(m.checklists.batch.noSharedLabels), findsOneWidget);

        await quiesce(tester);
      });
    });
  });
}
