import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/shopping_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final requests = <http.Request>[];

  Future<void> delete({int status = 200}) {
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode({
          'ocs': {
            'data': {'success': status == 200},
          },
        }),
        status,
        headers: {'content-type': 'application/json'},
      );
    });
    return http.runWithClient(
      () => ShoppingService.instance.deleteSession(3, 42),
      () => client,
    );
  }

  setUp(() async {
    requests.clear();
    const credentials = {
      'nextcloud_credentials':
          '{"serverUrl":"https://cloud.example.com",'
          '"loginName":"chen","appPassword":"secret"}',
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          final args = (call.arguments as Map?) ?? const {};
          if (call.method == 'read') return credentials[args['key']];
          if (call.method == 'readAll') return credentials;
          return null;
        });
    await AuthService.instance.loadCredentials();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  test('deleting a trip sends DELETE to the session', () async {
    await delete();

    final request = requests.single;
    expect(request.method, 'DELETE');
    expect(
      request.url.path,
      '/ocs/v2.php/apps/pantry/api/houses/3/shopping/sessions/42',
    );
  });

  test('a refused delete surfaces the status', () async {
    await expectLater(
      delete(status: 404),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)),
    );
  });
}
