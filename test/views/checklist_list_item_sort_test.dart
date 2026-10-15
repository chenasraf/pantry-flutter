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
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';

/// On `pref-list-item-sort` servers the item sort is stored per list (and per
/// person); otherwise it's one house-wide `checklistItemSort`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;
  final cache = ChecklistService.instance.cache;

  const groceries = 10;
  const hardware = 20;
  const created = 30;

  Map<String, dynamic> list(int id, String name) => {
    'id': id,
    'houseId': 1,
    'name': name,
    'icon': 'list',
    'sortOrder': id,
    'createdAt': 0,
    'updatedAt': 0,
  };

  final listPrefsPath = RegExp(r'/lists/(\d+)/prefs$');

  late List<http.Request> requests;
  late Map<int, String> listSorts;
  late String houseSort;
  Completer<void>? listPrefsGate;

  /// Writes fail as if the link dropped, so they stay queued.
  var writesDown = false;
  String? createdName;

  http.Client server() => MockClient((request) async {
    requests.add(request);
    if (writesDown && request.method != 'GET') {
      throw http.ClientException('offline', request.url);
    }
    final path = request.url.path;
    Object data = const <Object>[];
    final listPrefs = listPrefsPath.firstMatch(path);
    if (listPrefs != null) {
      final id = int.parse(listPrefs.group(1)!);
      if (request.method == 'PUT') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        listSorts[id] = body['itemSort'] as String;
        data = {'itemSort': listSorts[id]};
      } else {
        final answer = listSorts[id] ?? houseSort;
        await listPrefsGate?.future;
        data = {'itemSort': answer};
      }
    } else if (path.endsWith('/prefs')) {
      if (request.method == 'PUT') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        houseSort = body['checklistItemSort'] as String? ?? houseSort;
      }
      data = {'checklistItemSort': houseSort};
    } else if (request.method == 'POST' && path.endsWith('/lists')) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      data = list(created, body['name'] as String);
      createdName = body['name'] as String;
    } else if (request.method != 'GET') {
      throw http.ClientException('offline', request.url);
    } else if (path.endsWith('/lists')) {
      data = [
        list(groceries, 'Groceries'),
        list(hardware, 'Hardware'),
        if (createdName != null) list(created, createdName!),
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

  Future<void> quiesce(WidgetTester tester) async {
    unawaited(manager.reset());
    await tester.pump(const Duration(seconds: 1));
  }

  /// Sends whatever the queue holds.
  Future<void> drain() async {
    writesDown = false;
    manager.setOnline(true);
    manager.reportInterfaceAvailable();
    for (var i = 0; i < 20 && !manager.queueForTest.isEmpty; i++) {
      await manager.flushNow();
    }
  }

  void seedFeatures({required bool perList}) =>
      ServerVersionService.instance.debugSeed(
        features: {if (perList) kListItemSortFeature: true},
        featuresAuthoritative: true,
      );

  /// The `sortBy` the last items fetch for [path] asked for.
  String? lastItemsSort(String path) => requests
      .lastWhere((r) => r.method == 'GET' && r.url.path.endsWith(path))
      .url
      .queryParameters['sortBy'];

  Iterable<http.Request> puts(Pattern path) =>
      requests.where((r) => r.method == 'PUT' && r.url.path.contains(path));

  setUp(() async {
    requests = [];
    listSorts = {groceries: 'name_asc', hardware: 'category'};
    houseSort = 'oldest';
    listPrefsGate = null;
    writesDown = false;
    createdName = null;
    for (final key in [
      'sortBy:1',
      'itemSort:1:$groceries',
      'itemSort:1:$hardware',
      'itemSort:1:$created',
      'itemSort:1:0',
    ]) {
      cache.removeKey(key);
    }
    ChecklistService.instance.selectedListId = null;
    ChecklistService.instance.cacheLists(1, const []);
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
    manager.setOnline(true);
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

  group('per-list sort', () {
    setUp(() => seedFeatures(perList: true));

    testWidgets('each list opens in its own stored sort', (tester) async {
      await withServer(() async {
        final controller = await loaded(tester);

        expect(controller.currentList?.id, groceries);
        expect(controller.sortBy, 'name_asc');
        expect(lastItemsSort('/lists/$groceries/items'), 'name_asc');

        await controller.selectList(controller.lists.last);
        expect(controller.sortBy, 'category');
        expect(lastItemsSort('/lists/$hardware/items'), 'category');

        await quiesce(tester);
      });
    });

    testWidgets('a sort change is written to the list, not the house', (
      tester,
    ) async {
      await withServer(() async {
        final controller = await loaded(tester);
        await controller.selectList(controller.lists.last);
        requests.clear();

        await controller.setSortBy('newest');
        await drain();

        final written = puts('/lists/$hardware/prefs').toList();
        expect(written, hasLength(1));
        expect(jsonDecode(written.single.body), {'itemSort': 'newest'});
        expect(puts(RegExp(r'/houses/1/prefs$')), isEmpty);
        expect(lastItemsSort('/lists/$hardware/items'), 'newest');

        await controller.selectList(controller.lists.first);
        expect(controller.sortBy, 'name_asc');

        await quiesce(tester);
      });
    });

    testWidgets('All lists reads custom as newest', (tester) async {
      listSorts[0] = 'custom';
      await withServer(() async {
        final controller = await loaded(tester);

        await controller.selectList(allListsSentinel(1));
        expect(controller.sortBy, 'custom');
        expect(controller.effectiveSortBy, 'newest');
        expect(lastItemsSort('/houses/1/items'), 'newest');

        await quiesce(tester);
      });
    });

    testWidgets('a read overlapping a sort change does not revert it', (
      tester,
    ) async {
      await withServer(() async {
        final controller = await loaded(tester);
        final gate = listPrefsGate = Completer<void>();

        final reselect = controller.selectList(controller.lists.first);
        await tester.pump();
        final change = controller.setSortBy('name_desc');
        gate.complete();
        await Future.wait([reselect, change]);
        await drain();

        expect(controller.sortBy, 'name_desc');
        expect(listSorts[groceries], 'name_desc');

        await quiesce(tester);
      });
    });

    testWidgets('a sort queued while offline is not reverted by a read', (
      tester,
    ) async {
      await withServer(() async {
        final controller = await loaded(tester);
        writesDown = true;

        await controller.setSortBy('store');
        await controller.selectList(controller.lists.first);

        expect(controller.sortBy, 'store');
        expect(listSorts[groceries], 'name_asc');

        await drain();
        expect(listSorts[groceries], 'store');

        await quiesce(tester);
      });
    });

    testWidgets('a sort picked on a list created offline reaches the server', (
      tester,
    ) async {
      await withServer(() async {
        final controller = await loaded(tester);
        writesDown = true;

        final pending = await controller.createList(name: 'Camping');
        await controller.selectList(pending);
        await controller.setSortBy('name_desc');

        final queuedSort = manager.queueForTest.all().last;
        expect(queuedSort.op, SyncOpKind.setItemSort);
        expect(queuedSort.tempEntityId, pending.id);

        await drain();

        final written = puts('/lists/$created/prefs').toList();
        expect(written, hasLength(1));
        expect(jsonDecode(written.single.body), {'itemSort': 'name_desc'});
        expect(
          ChecklistService.instance.cachedItemSort(1, created),
          'name_desc',
        );

        await quiesce(tester);
      });
    });
  });

  group('house-wide sort', () {
    setUp(() => seedFeatures(perList: false));

    testWidgets('reads and writes the house pref only', (tester) async {
      await withServer(() async {
        final controller = await loaded(tester);

        expect(controller.sortBy, 'oldest');
        expect(lastItemsSort('/lists/$groceries/items'), 'oldest');

        await controller.setSortBy('name_desc');
        await tester.pump();

        final written = puts(RegExp(r'/houses/1/prefs$')).toList();
        expect(written, hasLength(1));
        expect(jsonDecode(written.single.body), {
          'checklistItemSort': 'name_desc',
        });
        expect(
          requests.where((r) => listPrefsPath.hasMatch(r.url.path)),
          isEmpty,
        );

        await controller.selectList(controller.lists.last);
        expect(controller.sortBy, 'name_desc');

        await quiesce(tester);
      });
    });
  });
}
