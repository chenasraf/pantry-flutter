import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/shopping/shopping_session_view.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

import '../helpers/test_app.dart';

/// The trip screen holds the screen awake only when asked to, and leaves the
/// wakelock as it found it once the trip is closed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  late _FakeWakelock wakelock;

  final session = {
    'id': 12,
    'houseId': 1,
    'userId': 'chen',
    'listIds': [4],
    'stores': [],
    'activeStoreId': null,
    'includeUnassigned': true,
    'isPrivate': false,
    'lastSeenAt': 0,
    'memberIds': ['chen'],
    'live': true,
    'closedAt': null,
    'abortedAt': null,
    'createdAt': 1000,
    'updatedAt': 2000,
  };

  http.Response ocs(Object data) => http.Response(
    jsonEncode({
      'ocs': {'data': data},
    }),
    200,
    headers: {'content-type': 'application/json'},
  );

  setUp(() async {
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
    ServerVersionService.instance.debugSeed(
      pantryVersion: Version.parse('0.39.0'),
    );
    wakelock = _FakeWakelock();
    WakelockPlusPlatformInterface.instance = wakelock;
  });

  tearDown(() async {
    await PrefsService.instance.setKeepScreenOnWhileShopping(false);
    ServerVersionService.instance.debugSeed();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  Future<void> openTrip(WidgetTester tester) => http.runWithClient(
    () async {
      await tester.pumpWidget(
        wrapForTest(
          ShoppingSessionView(session: ShoppingSession.fromJson(session)),
        ),
      );
      await tester.pumpAndSettle();
    },
    () => MockClient((request) async {
      if (request.url.path.endsWith('/review')) {
        return ocs({'stores': [], 'grandTotal': [], 'uncheckedCount': 0});
      }
      if (request.url.path.endsWith('/sessions/current')) return ocs(session);
      return ocs(const []);
    }),
  );

  Future<void> closeTrip(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('with the setting off, the screen is left alone', (tester) async {
    await openTrip(tester);

    expect(wakelock.toggles, isEmpty);
    await closeTrip(tester);
    expect(wakelock.toggles, isEmpty);
  });

  testWidgets('with the setting on, the screen stays awake for the trip', (
    tester,
  ) async {
    await PrefsService.instance.setKeepScreenOnWhileShopping(true);

    await openTrip(tester);
    expect(wakelock.held, isTrue);

    await closeTrip(tester);
    expect(wakelock.held, isFalse);
  });

  testWidgets('switching the setting off mid-trip lets the screen sleep', (
    tester,
  ) async {
    await PrefsService.instance.setKeepScreenOnWhileShopping(true);
    await openTrip(tester);

    await PrefsService.instance.setKeepScreenOnWhileShopping(false);
    await tester.pump();
    expect(wakelock.held, isFalse);
    await closeTrip(tester);
  });

  testWidgets('a wakelock held before the trip outlives it', (tester) async {
    wakelock.held = true;
    await PrefsService.instance.setKeepScreenOnWhileShopping(true);

    await openTrip(tester);
    await closeTrip(tester);

    expect(wakelock.held, isTrue);
  });
}

class _FakeWakelock extends WakelockPlusPlatformInterface {
  bool held = false;
  final toggles = <bool>[];

  @override
  Future<void> toggle({required bool enable}) async {
    toggles.add(enable);
    held = enable;
  }

  @override
  Future<bool> get enabled async => held;
}
