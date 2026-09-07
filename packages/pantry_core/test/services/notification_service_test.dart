import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final store = <String, String>{};
  final auth = AuthService.instance;

  /// The requests the fake server saw, so a test can assert what was sent.
  final requests = <http.Request>[];

  String bodyWith(List<Map<String, dynamic>> notifications) => jsonEncode({
    'ocs': {'data': notifications},
  });

  Map<String, dynamic> pantryNotification(int id) => {
    'notification_id': id,
    'app': 'pantry',
    'user': 'chen',
    'datetime': '2026-01-01T00:00:00+00:00',
    'object_type': 'item',
    'object_id': '1',
    'subject': 'Milk added',
    'message': '',
    'link': '',
  };

  Future<NotificationFetch> fetch({
    String? etag,
    required http.Response Function(http.Request request) respond,
  }) {
    final client = MockClient((request) async {
      requests.add(request);
      return respond(request);
    });
    return http.runWithClient(
      () => NotificationService.instance.getNotifications(etag: etag),
      () => client,
    );
  }

  setUp(() async {
    requests.clear();
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
          if (call.method == 'read') return store[args['key'] as String];
          if (call.method == 'readAll') return Map<String, String>.from(store);
          return null;
        });
    await auth.loadCredentials();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  test('a first poll sends no token and keeps the one it gets', () async {
    final result = await fetch(
      respond: (_) => http.Response(
        bodyWith([pantryNotification(1)]),
        200,
        headers: {'etag': '"abc"'},
      ),
    );

    expect(requests.single.headers.containsKey('If-None-Match'), isFalse);
    expect(result.notifications.single.notificationId, 1);
    expect(result.etag, '"abc"');
    expect(result.unchanged, isFalse);
  });

  test('a known token comes back as If-None-Match', () async {
    await fetch(etag: '"abc"', respond: (_) => http.Response('', 304));

    expect(requests.single.headers['If-None-Match'], '"abc"');
  });

  test('304 reports unchanged without a body to parse', () async {
    final result = await fetch(
      etag: '"abc"',
      respond: (_) => http.Response('', 304),
    );

    expect(result.unchanged, isTrue);
    expect(result.notifications, isEmpty);
    // The server sent no ETag of its own, so the one that still describes the
    // caller's copy survives for the next poll.
    expect(result.etag, '"abc"');
  });

  test('204 is an empty list, not a parse failure', () async {
    final result = await fetch(
      etag: '"abc"',
      respond: (_) => http.Response('', 204),
    );

    expect(result.unchanged, isFalse);
    expect(result.notifications, isEmpty);
  });

  test('notifications from other apps are filtered out', () async {
    final result = await fetch(
      respond: (_) => http.Response(
        bodyWith([
          pantryNotification(1),
          {...pantryNotification(2), 'app': 'files'},
        ]),
        200,
      ),
    );

    expect(result.notifications.map((n) => n.notificationId), [1]);
  });

  test(
    'a server without the notifications app yields an empty fetch',
    () async {
      final result = await fetch(
        respond: (_) => http.Response('not found', 404),
      );

      expect(result.notifications, isEmpty);
      expect(result.unchanged, isFalse);
    },
  );
}
