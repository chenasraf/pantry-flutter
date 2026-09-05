import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final store = <String, String>{};
  final auth = AuthService.instance;

  /// Long enough to outlast the grace window, whatever it is set to.
  const pastGrace = Duration(seconds: 10);

  Future<void> request(int statusCode) async {
    final client = MockClient(
      (_) async => http.Response(
        statusCode >= 400 ? 'nope' : '{"ocs":{"data":{}}}',
        statusCode,
      ),
    );
    await http.runWithClient(() async {
      try {
        await ApiClient.instance.get<Map<String, dynamic>, int>(
          '/anything',
          fromJson: (_) => 0,
        );
      } on ApiException {
        // The status code is the subject; the throw is incidental.
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
    auth.reportAuthorized();
  });

  tearDown(() {
    auth.reportAuthorized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  testWidgets('a single 401 does not trip the state immediately', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    await request(401);
    expect(auth.isUnauthorized.value, isFalse);
    // The grace timer is deliberately still pending here, which the binding
    // reports as a leak unless it is cancelled before the test ends.
    auth.reportAuthorized();
  });

  testWidgets('a 401 that stands through the grace window trips the state', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    await request(401);
    await tester.pump(pastGrace);
    expect(auth.isUnauthorized.value, isTrue);
  });

  testWidgets('a success inside the grace window cancels the 401', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    await request(401);
    await request(200);
    await tester.pump(pastGrace);
    expect(auth.isUnauthorized.value, isFalse);
  });

  testWidgets('a success after it trips clears the state', (tester) async {
    await tester.pumpWidget(const SizedBox());
    await request(401);
    await tester.pump(pastGrace);
    expect(auth.isUnauthorized.value, isTrue);

    await request(200);
    expect(auth.isUnauthorized.value, isFalse);
  });

  testWidgets('a burst of 401s trips it once, on the first one', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    var notifications = 0;
    void count() => notifications++;
    auth.isUnauthorized.addListener(count);
    addTearDown(() => auth.isUnauthorized.removeListener(count));

    await Future.wait([request(401), request(401), request(401)]);
    await tester.pump(pastGrace);

    expect(auth.isUnauthorized.value, isTrue);
    expect(notifications, 1);
  });

  testWidgets('a 403 does not trip it', (tester) async {
    await tester.pumpWidget(const SizedBox());
    await request(403);
    await tester.pump(pastGrace);
    expect(auth.isUnauthorized.value, isFalse);
  });

  testWidgets('a 500 does not clear a state a 401 already set', (tester) async {
    await tester.pumpWidget(const SizedBox());
    await request(401);
    await tester.pump(pastGrace);

    await request(500);
    expect(auth.isUnauthorized.value, isTrue);
  });
}
