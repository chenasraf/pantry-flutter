import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';

/// A refused certificate is a trust problem, not a data problem.
///
/// It arrives as neither a socket failure nor an HTTP one, which puts it one
/// mis-classification away from the queue's generic failure path: eight
/// attempts inside two minutes of backoff, and then the write is dead-lettered.
/// Nothing about a handshake changes between attempts, so that path would drop
/// every change a wearer makes against a server the app has simply never been
/// told to trust.
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

  Future<void> drainAgainstRefusedCert() => http.runWithClient(
    () => manager.flushNow(),
    () => MockClient(
      (_) async => throw const HandshakeException(
        'Handshake error in client',
        OSError('CERTIFICATE_VERIFY_FAILED: self signed certificate'),
      ),
    ),
  );

  test(
    'a refused certificate holds the queue instead of dropping it',
    () async {
      manager.queueForTest.enqueue(toggle('a', 42));
      manager.queueForTest.enqueue(toggle('b', 43));

      await drainAgainstRefusedCert();

      expect(manager.queueForTest.all().map((o) => o.uuid), ['a', 'b']);
    },
  );

  test('it spends no retry budget', () async {
    manager.queueForTest.enqueue(toggle('a', 42));

    await drainAgainstRefusedCert();

    expect(manager.queueForTest.peek()!.attemptCount, 0);
  });

  test('so no number of flushes wears the write away', () async {
    // The ceiling is eight. A wearer ticking items off in an aisle reaches it
    // in about two minutes, and reached it silently.
    manager.queueForTest.enqueue(toggle('a', 42));

    for (var attempt = 0; attempt < 12; attempt++) {
      await drainAgainstRefusedCert();
    }

    expect(manager.queueForTest.all().map((o) => o.uuid), ['a']);
  });

  test('and the app stops claiming to be online while it stands', () async {
    manager.queueForTest.enqueue(toggle('a', 42));

    await drainAgainstRefusedCert();

    expect(manager.isOnline, isFalse);
  });
}
