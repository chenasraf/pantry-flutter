import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/http_pool.dart';

class _CountingOverrides extends HttpOverrides {
  int built = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    built++;
    return super.createHttpClient(context);
  }
}

void main() {
  late HttpServer server;
  late Uri url;
  late Set<int> clientPorts;
  late HttpPool pool;

  setUp(() async {
    // The test binding answers every request with an empty 400 through
    // overrides of its own; these tests count real sockets.
    HttpOverrides.global = null;
    clientPorts = {};
    pool = HttpPool(maxConnectionsPerHost: 2);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    url = Uri.parse('http://${server.address.address}:${server.port}/');
    server.listen((request) async {
      clientPorts.add(request.connectionInfo!.remotePort);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      request.response.write('ok');
      await request.response.close();
    });
  });

  tearDown(() async {
    pool.close();
    HttpOverrides.global = null;
    await server.close(force: true);
  });

  test('sequential requests share one connection', () async {
    for (var i = 0; i < 5; i++) {
      final response = await pool.client.get(url);
      expect(response.body, 'ok');
    }
    expect(clientPorts, hasLength(1));
  });

  test('concurrent requests open no more than the per-host limit', () async {
    final responses = await Future.wait([
      for (var i = 0; i < 10; i++) pool.client.get(url),
    ]);
    expect(responses.map((r) => r.body), everyElement('ok'));
    expect(clientPorts.length, lessThanOrEqualTo(2));
  });

  test('a runWithClient zone supplies the client', () async {
    final mock = MockClient((_) async => http.Response('mocked', 200));
    final response = await http.runWithClient(
      () => pool.client.get(url),
      () => mock,
    );
    expect(response.body, 'mocked');
    expect(clientPorts, isEmpty);
  });

  test(
    'requests go out under the overrides current when they are made',
    () async {
      await pool.client.get(url);

      final overrides = _CountingOverrides();
      HttpOverrides.global = overrides;
      await pool.client.get(url);
      await pool.client.get(url);

      expect(overrides.built, 1);
    },
  );
}
