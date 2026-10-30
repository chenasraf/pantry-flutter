import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';

/// A category created and then dragged before the queue drains has only a
/// temp id in the reorder. The server skips ids it doesn't know, so unless the
/// queue swaps in the real one the new category's position is silently lost.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final manager = SyncManager.instance;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async => null);
  });

  setUp(() async {
    await manager.reset();
    manager.setOnline(true);
    await AuthService.instance.adoptCredentials(
      const NextcloudCredentials(
        serverUrl: 'https://cloud.example',
        loginName: 'ada',
        appPassword: 'secret',
      ),
    );
  });

  tearDown(() async {
    await manager.reset();
    manager.setOnline(true);
  });

  SyncOp create() => const SyncOp(
    uuid: 'create',
    entity: SyncEntity.category,
    op: SyncOpKind.create,
    houseId: 1,
    tempEntityId: -3,
    body: {'name': 'Bakery', 'icon': 'tag', 'color': ''},
    createdAt: 0,
  );

  SyncOp reorder(String uuid, List<int> ids) => SyncOp(
    uuid: uuid,
    entity: SyncEntity.category,
    op: SyncOpKind.reorder,
    houseId: 1,
    body: {
      'order': [
        for (var i = 0; i < ids.length; i++) {'id': ids[i], 'sortOrder': i},
      ],
    },
    createdAt: 0,
  );

  test('a reorder naming a just-created category sends its real id', () async {
    final sent = <List<int>>[];
    await http.runWithClient(
      () async {
        manager.setOnline(false);
        manager.enqueue(create());
        manager.enqueue(reorder('r', [-3, 1, 2]));
        // Coming back online starts the flush; wait for it to drain.
        manager.setOnline(true);
        for (var i = 0; i < 100 && manager.queuedOps.isNotEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      },
      () => MockClient((req) async {
        if (req.url.path.endsWith('/categories/reorder')) {
          final items = (jsonDecode(req.body)['items'] as List).cast<Map>();
          sent.add([for (final e in items) e['id'] as int]);
          return http.Response('{"success":true}', 200);
        }
        return http.Response(
          '{"id":30,"houseId":1,"name":"Bakery","icon":"tag","color":"",'
          '"sortOrder":2,"createdAt":0,"updatedAt":0}',
          200,
        );
      }),
    );

    expect(sent, [
      [30, 1, 2],
    ]);
    expect(manager.queuedOps, isEmpty);
  });

  test('pendingSortOrders reads the latest queued reorder', () async {
    manager.setOnline(false);
    manager.enqueue(reorder('a', [1, 2, 3]));
    manager.enqueue(reorder('b', [3, 1, 2]));

    expect(manager.pendingSortOrders(SyncEntity.category, 1), {
      3: 0,
      1: 1,
      2: 2,
    });
    expect(manager.pendingSortOrders(SyncEntity.category, 2), isEmpty);
    expect(manager.pendingSortOrders(SyncEntity.store, 1), isEmpty);
  });
}
