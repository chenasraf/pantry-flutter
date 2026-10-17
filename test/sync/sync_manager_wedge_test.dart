import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';

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

  const listBody =
      '{"id":50,"houseId":1,"name":"Groceries","icon":"list",'
      '"sortOrder":0,"createdAt":0,"updatedAt":0}';
  const itemBody =
      '{"id":60,"listId":50,"name":"Milk","done":false,'
      '"repeatFromCompletion":false,"sortOrder":1,'
      '"createdAt":0,"updatedAt":0}';

  final requests = <String>[];

  setUp(requests.clear);

  /// Answers like the real server: a temp (negative) id in the path names
  /// nothing it knows.
  http.Client server() => MockClient((req) async {
    requests.add('${req.method} ${req.url.path}');
    if (RegExp(r'/-\d+').hasMatch(req.url.path)) {
      return http.Response('{"message":"Not found"}', 404);
    }
    if (req.method == 'POST' && req.url.path.endsWith('/lists')) {
      return http.Response(listBody, 200);
    }
    return http.Response(itemBody, 200);
  });

  SyncOp listCreate() => const SyncOp(
    uuid: 'list',
    entity: SyncEntity.checklistList,
    op: SyncOpKind.create,
    houseId: 1,
    tempEntityId: -1,
    body: {'name': 'Groceries'},
    createdAt: 0,
  );

  SyncOp itemCreate() => const SyncOp(
    uuid: 'item',
    entity: SyncEntity.checklistItem,
    op: SyncOpKind.create,
    houseId: 1,
    parentId: -1,
    tempEntityId: -2,
    body: {'name': 'Milk'},
    createdAt: 0,
  );

  SyncOp itemToggle(String uuid) => SyncOp(
    uuid: uuid,
    entity: SyncEntity.checklistItem,
    op: SyncOpKind.toggle,
    houseId: 1,
    parentId: -1,
    tempEntityId: -2,
    createdAt: 0,
  );

  SyncOp toggleReal(String uuid) => SyncOp(
    uuid: uuid,
    entity: SyncEntity.checklistItem,
    op: SyncOpKind.toggle,
    houseId: 1,
    parentId: 50,
    entityId: 60,
    createdAt: 0,
  );

  test('a queue stuck behind a create that is gone drains', () async {
    final skipped = <SyncOpSkipped>[];
    final sub = manager.onSkipped.listen(skipped.add);
    addTearDown(sub.cancel);

    // Persisted from an earlier session: a toggle on an item whose create
    // never landed, and work queued behind it.
    manager.queueForTest
      ..enqueue(itemToggle('orphan'))
      ..enqueue(toggleReal('behind'));

    await http.runWithClient(manager.flushNow, server);
    await Future<void>.delayed(Duration.zero);

    expect(manager.queueForTest.all(), isEmpty);
    expect(requests, hasLength(1));
    expect(requests.single, endsWith('/lists/50/items/60/toggle'));
    expect(skipped.map((s) => (s.op.uuid, s.reason)), [('orphan', 'orphaned')]);
    expect(manager.status.value, SyncStatus.idle);
  });

  test(
    'a create rejected by the server takes its follow-ups with it',
    () async {
      manager.queueForTest
        ..enqueue(
          const SyncOp(
            uuid: 'item',
            entity: SyncEntity.checklistItem,
            op: SyncOpKind.create,
            houseId: 1,
            parentId: 50,
            tempEntityId: -2,
            body: {'name': 'Milk'},
            createdAt: 0,
          ),
        )
        ..enqueue(itemToggle('toggle'))
        ..enqueue(toggleReal('behind'));

      final client = MockClient((req) async {
        requests.add('${req.method} ${req.url.path}');
        if (req.method == 'POST' && req.url.path.endsWith('/items')) {
          return http.Response('{}', 403);
        }
        return http.Response(itemBody, 200);
      });
      await http.runWithClient(manager.flushNow, () => client);

      expect(manager.queueForTest.all(), isEmpty);
      expect(requests, hasLength(2));
      expect(requests.last, endsWith('/lists/50/items/60/toggle'));
    },
  );

  test(
    'an item keeps syncing without a store that was never created',
    () async {
      manager.queueForTest.enqueue(
        const SyncOp(
          uuid: 'item',
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.update,
          houseId: 1,
          parentId: 50,
          entityId: 60,
          body: {
            'name': 'Milk',
            'storeIds': [3, -4],
          },
          createdAt: 0,
        ),
      );

      final bodies = <String>[];
      final client = MockClient((req) async {
        requests.add('${req.method} ${req.url.path}');
        bodies.add(req.body);
        return http.Response(itemBody, 200);
      });
      await http.runWithClient(manager.flushNow, () => client);

      expect(manager.queueForTest.all(), isEmpty);
      expect(bodies.single, contains('"storeIds":[3]'));
    },
  );

  group('a stopped flush', () {
    late Duration grace;
    setUp(() {
      grace = SyncManager.stallGrace;
      SyncManager.stallGrace = const Duration(milliseconds: 200);
    });
    tearDown(() => SyncManager.stallGrace = grace);

    test('shows the changes it left once they have waited', () async {
      // A 401 holds the queue without marking a backlog or an error.
      final client = MockClient((req) async => http.Response('', 401));
      await http.runWithClient(() async {
        manager.queueForTest.enqueue(toggleReal('held'));
        await manager.flushNow();
      }, () => client);

      expect(manager.queueForTest.all(), hasLength(1));
      expect(manager.hasBacklog.value, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(manager.hasBacklog.value, isTrue);
    });

    test('stays quiet when the next attempt clears it', () async {
      var status = 401;
      final client = MockClient(
        (req) async => http.Response(status == 200 ? itemBody : '', status),
      );
      await http.runWithClient(() async {
        manager.queueForTest.enqueue(toggleReal('held'));
        await manager.flushNow();
        status = 200;
        await manager.flushNow();
      }, () => client);

      expect(manager.queueForTest.all(), isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(manager.hasBacklog.value, isFalse);
    });
  });

  test('an item added to a list created offline lands in that list', () async {
    manager.queueForTest
      ..enqueue(listCreate())
      ..enqueue(itemCreate())
      ..enqueue(itemToggle('toggle'));

    await http.runWithClient(manager.flushNow, server);

    expect(manager.queueForTest.all(), isEmpty);
    expect(requests.where((r) => r.contains('/-')), isEmpty);
    expect(requests, contains(matches(r'^POST .*/lists/50/items$')));
  });
}
