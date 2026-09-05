import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';

/// What "offline" means to every read and write in the app.
///
/// It is the outcome of the last real request, not a reading of the platform's
/// network interfaces — a Bluetooth-paired watch proxies its traffic through
/// the phone and reports no interface of its own the whole time it is reaching
/// the server perfectly well.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async => null);
  });

  setUp(() async {
    await AuthService.instance.adoptCredentials(
      const NextcloudCredentials(
        serverUrl: 'https://cloud.example',
        loginName: 'ada',
        appPassword: 'secret',
      ),
    );
    SyncManager.instance.setOnline(true);
  });

  tearDown(() => SyncManager.instance.setOnline(true));

  Future<T> withClient<T>(
    Future<T> Function() body,
    Future<http.Response> Function(http.Request) handler,
  ) => http.runWithClient(body, () => MockClient(handler));

  Future<Object?> failWith(Object error) async {
    try {
      await withClient(
        () => ApiClient.instance.get<List, List>(
          '/houses/1/lists',
          fromJson: (data) => data,
        ),
        (_) => Future.error(error),
      );
      return null;
    } catch (e) {
      return e;
    }
  }

  group('OfflineException', () {
    test('carries statusCode 0 so the queue spends no retry budget', () {
      const e = OfflineException();
      expect(e.statusCode, 0);
      expect(e, isA<ApiException>());
    });

    test('is what a dead socket becomes', () async {
      expect(
        await failWith(const SocketException('Network is unreachable')),
        isA<OfflineException>(),
      );
      expect(SyncManager.instance.isOnline, isFalse);
    });

    test('is what a dropped connection becomes', () async {
      expect(
        await failWith(http.ClientException('Connection closed')),
        isA<OfflineException>(),
      );
      expect(SyncManager.instance.isOnline, isFalse);
    });

    test('is what a server that never answers becomes', () async {
      expect(
        await failWith(TimeoutException('no answer')),
        isA<OfflineException>(),
      );
      expect(SyncManager.instance.isOnline, isFalse);
    });
  });

  group('reachability', () {
    test('an interface reading never blocks a request', () async {
      SyncManager.instance.setOnline(false);
      final lists = await withClient(
        () => ApiClient.instance.get<List, List>(
          '/houses/1/lists',
          fromJson: (data) => data,
        ),
        (_) async => http.Response('{"ocs":{"data":[]}}', 200),
      );
      expect(lists, isEmpty);
    });

    test('a server that answers is what puts the app back online', () async {
      SyncManager.instance.setOnline(false);
      await withClient(
        () => ApiClient.instance.get<List, List>(
          '/houses/1/lists',
          fromJson: (data) => data,
        ),
        (_) async => http.Response('{"ocs":{"data":[]}}', 200),
      );
      expect(SyncManager.instance.isOnline, isTrue);
    });

    test('a refusal still counts as reached', () async {
      SyncManager.instance.setOnline(false);
      await expectLater(
        withClient(
          () => ApiClient.instance.get<List, List>(
            '/houses/1/lists',
            fromJson: (data) => data,
          ),
          (_) async => http.Response('nope', 403),
        ),
        throwsA(isA<ApiException>()),
      );
      expect(SyncManager.instance.isOnline, isTrue);
    });
  });
}
