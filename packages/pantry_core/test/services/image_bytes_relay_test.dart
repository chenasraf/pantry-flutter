import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/image_bytes_cache.dart';

/// The one thing the app fetches that does not go through [ApiClient].
///
/// An image store holds its own client so `flutter_cache_manager` can stream
/// bytes to disk, which puts every photo outside the relay unless this seam
/// honours it too. A watch that read all its lists and notes through the phone
/// and still drew an empty photo board would look, to the wearer, exactly like
/// the bug they reported.
void main() {
  /// Requests the relay was asked to make.
  final asked = <ApiRequest>[];

  setUp(() => asked.clear());
  tearDown(() => ApiClient.relay = null);

  /// The store's client, carrying the policies under test.
  http.Client client() => ImageBytesCache.deferredClient();

  test('an image the device cannot reach is fetched by the relay', () async {
    ApiClient.relay = (request) async {
      asked.add(request);
      return http.Response.bytes(utf8.encode('PNGBYTES'), 200);
    };

    final response = await http.runWithClient(
      () => client().get(Uri.parse('https://pantry.local/core/preview?id=7')),
      () => _unroutable(),
    );

    expect(asked.single.method, 'GET');
    expect(asked.single.uri.path, '/core/preview');
    expect(response.body, 'PNGBYTES');
  });

  test('with no relay the transport failure is what comes out', () async {
    await expectLater(
      http.runWithClient(
        () => client().get(Uri.parse('https://pantry.local/core/preview?id=7')),
        () => _unroutable(),
      ),
      throwsA(isA<SocketException>()),
    );

    expect(asked, isEmpty);
  });

  test('a relay that cannot help leaves the original failure', () async {
    ApiClient.relay = (request) async {
      asked.add(request);
      return null;
    };

    // The cache manager has a path for the exception it already knows — it
    // draws whatever is on disk. An unfamiliar one it logs, and draws nothing.
    await expectLater(
      http.runWithClient(
        () => client().get(Uri.parse('https://pantry.local/core/preview?id=7')),
        () => _unroutable(),
      ),
      throwsA(isA<SocketException>()),
    );

    expect(asked, hasLength(1));
  });

  test('a server that answers is never offered to the relay', () async {
    ApiClient.relay = (request) async {
      asked.add(request);
      return http.Response.bytes(utf8.encode('RELAYED'), 200);
    };

    final response = await http.runWithClient(
      () => client().get(Uri.parse('https://pantry.local/core/preview?id=7')),
      () => _answers(),
    );

    expect(response.body, 'DIRECT');
    expect(asked, isEmpty);
  });
}

/// A client with no route to the server, the way the failure actually arrives.
http.Client _unroutable() => _FakeClient(
  (_) async => throw const SocketException('Network is unreachable'),
);

http.Client _answers() => _FakeClient(
  (request) async => http.StreamedResponse(
    Stream.value(utf8.encode('DIRECT')),
    200,
    request: request,
  ),
);

class _FakeClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest) _send;

  _FakeClient(this._send);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _send(request);
}
