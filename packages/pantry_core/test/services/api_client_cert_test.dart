import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/cert_trust_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';

/// What a pinned client throws when the server offers a certificate it has not
/// accepted. Not a `SocketException` and not an `HttpException`, which is the
/// whole difficulty: `package:http` wraps those two and passes this through.
final _refused = const HandshakeException(
  'Handshake error in client',
  OSError('CERTIFICATE_VERIFY_FAILED: self signed certificate'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final store = <String, String>{};
  final auth = AuthService.instance;
  final trust = CertTrustService.instance;

  Future<Object?> request({Object? throwing}) async {
    final client = MockClient((_) async {
      if (throwing != null) throw throwing;
      return http.Response('{"ocs":{"data":{}}}', 200);
    });
    return http.runWithClient(() async {
      try {
        await ApiClient.instance.get<Map<String, dynamic>, int>(
          '/anything',
          fromJson: (_) => 0,
        );
        return null;
      } catch (e) {
        return e;
      }
    }, () => client);
  }

  setUp(() async {
    store
      ..clear()
      ..['nextcloud_credentials'] = jsonEncode({
        'serverUrl': 'https://cloud.example.com',
        'loginName': 'chen',
        'appPassword': 'secret',
      });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          final args = (call.arguments as Map?) ?? const {};
          switch (call.method) {
            case 'readAll':
              return Map<String, String>.from(store);
            case 'read':
              return store[args['key'] as String];
            case 'write':
              store[args['key'] as String] = args['value'] as String;
              return null;
            case 'delete':
              store.remove(args['key'] as String);
              return null;
            case 'deleteAll':
              store.clear();
              return null;
            case 'containsKey':
              return store.containsKey(args['key'] as String);
          }
          return null;
        });
    await auth.loadCredentials();
    trust.untrustedHost.value = null;
    SyncManager.instance.setOnline(true);
  });

  tearDown(() {
    trust.untrustedHost.value = null;
    SyncManager.instance.setOnline(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  testWidgets('a refused certificate is reported as one, naming the host', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());

    final error = await request(throwing: _refused);

    expect(error, isA<CertUntrustedException>());
    expect((error as CertUntrustedException).hostKey, 'cloud.example.com');
  });

  testWidgets('it is an offline failure, so the queue holds rather than '
      'spending its retry budget', (tester) async {
    // The whole of the fix: dropping into the queue's generic failure path
    // dead-letters the op after eight attempts, and no number of attempts
    // changes a handshake. `statusCode` 0 is what the queue reads to hold.
    await tester.pumpWidget(const SizedBox());

    final error = await request(throwing: _refused);

    expect(error, isA<OfflineException>());
    expect((error as ApiException).statusCode, 0);
  });

  testWidgets('and the app stops believing it is online', (tester) async {
    await tester.pumpWidget(const SizedBox());

    await request(throwing: _refused);

    expect(SyncManager.instance.isOnline, isFalse);
  });

  testWidgets('the refusal is recorded, so a surface can offer the decision', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());

    await request(throwing: _refused);

    expect(trust.untrustedHost.value, 'cloud.example.com');
  });

  testWidgets('a request that reaches the server clears it', (tester) async {
    await tester.pumpWidget(const SizedBox());
    await request(throwing: _refused);
    expect(trust.untrustedHost.value, isNotNull);

    await request();

    expect(trust.untrustedHost.value, isNull);
    expect(SyncManager.instance.isOnline, isTrue);
  });

  testWidgets('it still answers to the check the fingerprint prompts use', (
    tester,
  ) async {
    // Both sign-in surfaces recognise the failure by its message, and one of
    // them sits behind a layer that wraps what it catches.
    await tester.pumpWidget(const SizedBox());

    final error = await request(throwing: _refused);

    expect(CertTrustService.isHandshakeFailure(error!), isTrue);
  });

  testWidgets('a dead socket is still an ordinary offline failure', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());

    final error = await request(
      throwing: const SocketException('Connection refused'),
    );

    expect(error, isA<OfflineException>());
    expect(error, isNot(isA<CertUntrustedException>()));
    expect(trust.untrustedHost.value, isNull);
  });
}
