import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final auth = AuthService.instance;
  final requests = <http.Request>[];

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async => null);
  });

  setUp(() async {
    requests.clear();
    await auth.adoptCredentials(
      const NextcloudCredentials(
        serverUrl: 'https://cloud.example',
        loginName: 'ada',
        appPassword: 'secret',
      ),
    );
    SyncManager.instance.setOnline(true);
  });

  tearDown(() async {
    SyncManager.instance.setOnline(true);
    await PrefsService.instance.setBarcodeFillNameCache(true);
  });

  Future<void> withServer(
    Future<void> Function() body,
    Future<http.Response> Function(http.Request) handler,
  ) => http.runWithClient(
    body,
    () => MockClient((r) {
      requests.add(r);
      return handler(r);
    }),
  );

  http.Response ocs(Object? data, {int status = 200}) => http.Response(
    jsonEncode({
      'ocs': {'meta': <String, Object?>{}, 'data': data},
    }),
    status,
    headers: {'content-type': 'application/json'},
  );

  test('fetchUserPrefs reads the Pantry prefs and caches them', () async {
    await withServer(
      auth.fetchUserPrefs,
      (_) async => ocs({'firstDayOfWeek': 3, 'barcodeFillName': false}),
    );

    expect(
      requests.single.url.toString(),
      'https://cloud.example/ocs/v2.php/apps/pantry/api/prefs',
    );
    expect(requests.single.method, 'GET');
    expect(auth.firstDayOfWeek, 3);
    await pumpEventQueue();
    expect(PrefsService.instance.barcodeFillName, isFalse);
  });

  test(
    'fetchUserPrefs keeps the first day of week on a server error',
    () async {
      await withServer(
        auth.fetchUserPrefs,
        (_) async => ocs({'firstDayOfWeek': 4}),
      );
      await withServer(
        auth.fetchUserPrefs,
        (_) async => ocs(null, status: 500),
      );

      expect(auth.firstDayOfWeek, 4);
    },
  );

  test('fetchUserPrefs reports an unreachable server as offline', () async {
    await withServer(
      auth.fetchUserPrefs,
      (_) => Future.error(const SocketException('unreachable')),
    );

    expect(SyncManager.instance.isOnline, isFalse);
  });

  test('publishLastHouseId writes the house to the Pantry prefs', () async {
    await withServer(() => auth.publishLastHouseId(9), (_) async => ocs({}));

    final r = requests.single;
    expect(r.method, 'PUT');
    expect(
      r.url.toString(),
      'https://cloud.example/ocs/v2.php/apps/pantry/api/prefs',
    );
    expect(jsonDecode(r.body), {'lastHouseId': 9});
  });

  test('fetchUserProfile reads the Nextcloud user', () async {
    await withServer(
      auth.fetchUserProfile,
      (_) async => ocs({'display-name': 'Ada', 'language': 'en_GB'}),
    );

    expect(
      requests.single.url.toString(),
      'https://cloud.example/ocs/v2.php/cloud/user',
    );
    expect(auth.displayName, 'Ada');
    expect(auth.serverLanguage, 'en');
  });
}
