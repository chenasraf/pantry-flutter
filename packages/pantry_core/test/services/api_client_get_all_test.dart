import 'dart:convert';

import 'package:flutter/services.dart';
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
  final store = <String, String>{
    'nextcloud_credentials': jsonEncode({
      'serverUrl': 'https://cloud.example.com',
      'loginName': 'chen',
      'appPassword': 'secret',
    }),
  };

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          final args = (call.arguments as Map?) ?? const {};
          return switch (call.method) {
            'readAll' => Map<String, String>.from(store),
            'read' => store[args['key'] as String],
            'containsKey' => store.containsKey(args['key'] as String),
            _ => null,
          };
        });
    await AuthService.instance.loadCredentials();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  /// Serves [total] rows the way the server does: `limit` rows from `offset`,
  /// or [ignoreOffset] to answer every request with the first page.
  Future<(List<int>, List<Uri>)> fetch(
    int total, {
    int pageSize = 3,
    bool ignoreOffset = false,
  }) async {
    final rows = [for (var i = 1; i <= total; i++) i];
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      final q = request.url.queryParameters;
      final limit = int.parse(q['limit']!);
      final offset = ignoreOffset ? 0 : int.parse(q['offset']!);
      final page = rows.skip(offset).take(limit);
      return http.Response(
        jsonEncode({
          'ocs': {
            'data': [
              for (final id in page) {'id': id},
            ],
          },
        }),
        200,
      );
    });
    final ids = await http.runWithClient(
      () => ApiClient.instance.getAll<int>(
        '/houses/1/categories',
        query: {'sortBy': 'custom'},
        fromJson: (json) => json['id'] as int,
        idOf: (id) => id,
        pageSize: pageSize,
      ),
      () => client,
    );
    return (ids, requests);
  }

  test('reads past the first page', () async {
    final (ids, requests) = await fetch(7);
    expect(ids, [1, 2, 3, 4, 5, 6, 7]);
    expect(requests.map((u) => u.queryParameters['offset']), ['0', '3', '6']);
    expect(
      requests.every((u) => u.queryParameters['sortBy'] == 'custom'),
      isTrue,
    );
  });

  test('a full last page is followed by one empty read', () async {
    final (ids, requests) = await fetch(6);
    expect(ids, [1, 2, 3, 4, 5, 6]);
    expect(requests, hasLength(3));
  });

  test('stops when the server ignores offset', () async {
    final (ids, requests) = await fetch(10, ignoreOffset: true);
    expect(ids, [1, 2, 3]);
    expect(requests, hasLength(2));
  });
}
