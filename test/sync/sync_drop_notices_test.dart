import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/sync/sync_drop_notices.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';

/// A write the server refuses is popped and gone. Before these notices the
/// only trace was a log line, so a proxy blocking PUT/PATCH/DELETE looked like
/// changes quietly reverting.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final manager = SyncManager.instance;
  late SyncDropNotices notices;
  late List<SyncDropReport> reports;

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
    notices = SyncDropNotices(manager, quiet: const Duration(hours: 1))
      ..start();
    reports = [];
    notices.reports.listen(reports.add);
  });

  tearDown(() async {
    await notices.dispose();
    await manager.reset();
    manager.setOnline(true);
  });

  SyncOp update(String uuid, int itemId, [String? name]) => SyncOp(
    uuid: uuid,
    entity: SyncEntity.checklistItem,
    op: SyncOpKind.update,
    houseId: 1,
    parentId: 7,
    entityId: itemId,
    body: {'name': ?name},
    createdAt: 0,
  );

  Future<void> drainAgainst(int statusCode, [String body = '{}']) =>
      http.runWithClient(
        () => manager.flushNow(),
        () => MockClient((_) async => http.Response(body, statusCode)),
      );

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    notices.flushForTest();
    await Future<void>.delayed(Duration.zero);
  }

  test('a blocked queue reads as one notice', () async {
    for (var i = 0; i < 5; i++) {
      manager.queueForTest.enqueue(update('op$i', 40 + i));
    }

    await drainAgainst(405);
    await settle();

    expect(reports, hasLength(1));
    expect(reports.single.statusCode, 405);
    expect(reports.single.ops, hasLength(5));
    expect(reports.single.message, contains('5'));
  });

  test('one refused change is named in the user’s own words', () async {
    manager.queueForTest.enqueue(update('a', 42, 'Milk'));

    await drainAgainst(403);
    await settle();

    expect(reports.single.name, 'Milk');
    expect(reports.single.message, contains('Milk'));
    expect(reports.single.message, contains('403'));
  });

  test('a conflict and a vanished record stay quiet', () async {
    manager.queueForTest.enqueue(update('a', 42));
    await drainAgainst(409);
    manager.queueForTest.enqueue(update('b', 43));
    await drainAgainst(404);
    await settle();

    expect(reports, isEmpty);
  });

  test('different refusals are reported apart', () async {
    manager.queueForTest.enqueue(update('a', 42));
    await drainAgainst(403);
    manager.queueForTest.enqueue(update('b', 43));
    await drainAgainst(422);
    await settle();

    expect(reports.map((r) => r.statusCode), [403, 422]);
  });

  test('the skip carries what the server said', () async {
    manager.queueForTest.enqueue(update('a', 42));
    final skipped = manager.onSkipped.first;

    await drainAgainst(
      412,
      '{"ocs":{"meta":{"message":"CSRF check failed"},"data":[]}}',
    );

    final event = await skipped;
    expect(event.statusCode, 412);
    expect(event.serverMessage, 'CSRF check failed');
  });

  test('retry puts the dropped changes back with a fresh budget', () async {
    manager.queueForTest.enqueue(
      update('a', 42).copyWith(attemptCount: 3, lastError: 'earlier'),
    );
    await drainAgainst(403);
    await settle();
    manager.setOnline(false);

    notices.retry(reports.single);

    expect(manager.queueForTest.all().map((o) => o.uuid), ['a']);
    expect(manager.queueForTest.peek()!.attemptCount, 0);
  });
}
