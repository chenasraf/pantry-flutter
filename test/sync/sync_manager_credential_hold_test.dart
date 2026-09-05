import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';

/// A 401 is a credential problem, not a data problem.
///
/// Phone and watch share one app password, and a logout on either revokes it
/// server-side — so the drop-on-any-4xx branch turned one device signing out
/// into the silent deletion of the other device's unsynced check-offs. The op
/// is well-formed and the record is still there; it lands the moment a valid
/// credential returns.
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

  SyncOp toggle(String uuid, int itemId) => SyncOp(
    uuid: uuid,
    entity: SyncEntity.checklistItem,
    op: SyncOpKind.toggle,
    houseId: 1,
    parentId: 7,
    entityId: itemId,
    createdAt: 0,
  );

  Future<void> drainAgainst(int statusCode) => http.runWithClient(
    () => manager.flushNow(),
    () => MockClient((_) async => http.Response('{}', statusCode)),
  );

  test('a 401 holds the queue instead of dropping it', () async {
    manager.queueForTest.enqueue(toggle('a', 42));
    manager.queueForTest.enqueue(toggle('b', 43));

    await drainAgainst(401);

    expect(
      manager.queueForTest.all().map((o) => o.uuid),
      ['a', 'b'],
      reason:
          'a revoked password is the one case nothing can be fixed by '
          'dropping the write',
    );
  });

  test('a 401 spends no retry budget', () async {
    manager.queueForTest.enqueue(toggle('a', 42));

    await drainAgainst(401);

    expect(manager.queueForTest.peek()!.attemptCount, 0);
  });

  test('an ordinary 4xx still drops the op', () async {
    manager.queueForTest.enqueue(toggle('a', 42));

    final skipped = manager.onSkipped.first;
    await drainAgainst(400);

    expect(manager.queueForTest.all(), isEmpty);
    expect((await skipped).reason, 'http_400');
  });
}
