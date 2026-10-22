import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';

/// `package:http` follows a redirect for a read and hands a write back as the
/// bare 3xx. Counted as success, that popped every change made against a
/// server address that redirects — typically `http://` on a server that moved
/// to `https://` — while reads kept working and the app looked synced.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final manager = SyncManager.instance;
  final auth = AuthService.instance;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async => null);
  });

  setUp(() async {
    await manager.reset();
    manager.setOnline(true);
    await auth.adoptCredentials(
      const NextcloudCredentials(
        serverUrl: 'http://cloud.example',
        loginName: 'ada',
        appPassword: 'secret',
      ),
    );
  });

  tearDown(() async {
    await manager.reset();
    manager.setOnline(true);
  });

  const itemBody =
      '{"id":42,"listId":7,"name":"Milk","done":true,'
      '"repeatFromCompletion":false,"sortOrder":1,'
      '"createdAt":0,"updatedAt":0}';

  SyncOp toggle(String uuid, int itemId) => SyncOp(
    uuid: uuid,
    entity: SyncEntity.checklistItem,
    op: SyncOpKind.toggle,
    houseId: 1,
    parentId: 7,
    entityId: itemId,
    createdAt: 0,
  );

  /// Answers every request with [statusCode], pointing a redirect at the same
  /// path on `https`.
  MockClient redirecting(int statusCode) => MockClient(
    (request) async => http.Response(
      '{"ocs":{"data":{}}}',
      statusCode,
      headers: {'location': request.url.replace(scheme: 'https').toString()},
    ),
  );

  for (final status in [301, 302, 307, 308]) {
    test('a write answered $status stays queued', () async {
      manager.queueForTest.enqueue(toggle('a', 42));
      manager.queueForTest.enqueue(toggle('b', 43));
      final applied = <SyncOpApplied>[];
      final sub = manager.onApplied.listen(applied.add);

      await http.runWithClient(manager.flushNow, () => redirecting(status));
      await sub.cancel();

      expect(manager.queueForTest.all().map((o) => o.uuid), ['a', 'b']);
      expect(manager.queueForTest.peek()!.attemptCount, 0);
      expect(applied, isEmpty);
      expect(manager.status.value, SyncStatus.error);
    });
  }

  test('a redirected write offers the address it was sent to', () async {
    manager.queueForTest.enqueue(toggle('a', 42));

    await http.runWithClient(manager.flushNow, () => redirecting(308));

    expect(auth.serverRedirect.value?.serverUrl, 'https://cloud.example');
  });

  test(
    'adopting the address keeps the credential and drains the queue',
    () async {
      manager.queueForTest.enqueue(toggle('a', 42));
      await http.runWithClient(manager.flushNow, () => redirecting(301));

      final sent = <Uri>[];
      await http.runWithClient(
        () async {
          expect(await auth.adoptRedirectedServerUrl(), isTrue);
          await manager.flushNow();
        },
        () => MockClient((request) async {
          sent.add(request.url);
          return http.Response(itemBody, 200);
        }),
      );

      expect(auth.credentials!.serverUrl, 'https://cloud.example');
      expect(auth.credentials!.appPassword, 'secret');
      expect(auth.serverRedirect.value, isNull);
      expect(manager.queueForTest.all(), isEmpty);
      expect(sent.single.scheme, 'https');
    },
  );

  test('a read answered with a redirect is left to package:http', () async {
    await http.runWithClient(() async {
      final value = await ApiClient.instance.get<Map<String, dynamic>, int>(
        '/houses',
        fromJson: (_) => 1,
      );
      expect(value, 1);
    }, () => redirecting(301));

    expect(auth.serverRedirect.value, isNull);
  });

  test('sign-in follows the server address to where it redirects', () async {
    final resolved = await http.runWithClient(
      () => auth.resolveServerUrl('http://cloud.example'),
      () => MockClient((request) async {
        if (request.url.scheme == 'http') {
          return http.Response(
            '',
            301,
            headers: {'location': 'https://cloud.example/status.php'},
          );
        }
        return http.Response('{"installed":true}', 200);
      }),
    );

    expect(resolved, 'https://cloud.example');
  });

  test('sign-in keeps an address that does not redirect', () async {
    final resolved = await http.runWithClient(
      () => auth.resolveServerUrl('https://cloud.example/nextcloud'),
      () => MockClient((_) async => http.Response('{}', 200)),
    );

    expect(resolved, 'https://cloud.example/nextcloud');
  });
}
