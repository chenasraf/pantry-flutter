import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry/services/wear_mirror_host.dart';
import 'package:pantry/services/wear_pairing_host.dart';
import 'package:pantry/services/wear_relay_host.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry_core/services/wear_relay.dart';

/// The phone's half of the relay: making a request the watch had no route for.
///
/// The phone is not a better-connected watch, it is a differently connected
/// one — a household server on the wearer's LAN is reachable from here and from
/// nowhere else in the house. What these cover is who may ask, what comes back,
/// and what a phone that cannot help says instead.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel('dev.casraf.pantry/data_layer');
  const events = EventChannel('dev.casraf.pantry/data_layer/events');
  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final link = WearLinkService.instance;
  final pairing = WearPairingHost.instance;
  final host = WearRelayHost.instance;

  final calls = <MethodCall>[];
  final storage = <String, String>{};
  late _StreamHandler handler;

  const watch = WearPairingRequest(nodeId: 'watch-1', nodeName: 'Galaxy Watch');

  /// Requests the phone actually put on the wire.
  final served = <http.Request>[];

  /// What the phone streamed back, or null if it answered nothing.
  WearRelayResponse? answer() {
    final call = calls.cast<MethodCall?>().lastWhere(
      (c) =>
          c!.method == 'stream' &&
          c.arguments['path'] == WearRelay.responsePath,
      orElse: () => null,
    );
    if (call == null) return null;
    return WearRelayResponse.fromJson(
      jsonDecode(call.arguments['payload'] as String) as Map<String, dynamic>,
    );
  }

  setUp(() async {
    calls.clear();
    storage.clear();
    served.clear();
    handler = _StreamHandler();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(methods, (call) async {
        calls.add(call);
        if (call.method == 'isAvailable') return true;
        if (call.method == 'nodes') {
          return [
            {'id': 'watch-1', 'name': 'Galaxy Watch', 'nearby': true},
          ];
        }
        return true;
      })
      ..setMockStreamHandler(events, handler)
      ..setMockMethodCallHandler(secureStorage, (call) async {
        final args = (call.arguments as Map?) ?? const {};
        switch (call.method) {
          case 'readAll':
            return Map<String, String>.from(storage);
          case 'read':
            return storage[args['key'] as String];
          case 'write':
            storage[args['key'] as String] = args['value'] as String;
            return null;
          case 'delete':
            storage.remove(args['key'] as String);
            return null;
        }
        return null;
      });

    link.debugReset();
    WearLinkService.debugHostSupported = true;
    await AuthService.instance.adoptCredentials(
      const NextcloudCredentials(
        serverUrl: 'https://pantry.local',
        loginName: 'ada',
        appPassword: 'secret',
      ),
    );
  });

  tearDown(() async {
    await host.dispose();
    await pairing.unpair();
    await pairing.dispose();
    await WearMirrorHost.instance.dispose();
    await AuthService.instance.logout(revoke: false);
    WearMirrorHost.instance.pairedNode = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(methods, null)
      ..setMockStreamHandler(events, null)
      ..setMockMethodCallHandler(secureStorage, null);
    WearLinkService.debugHostSupported = null;
    link.debugReset();
  });

  /// A server on the wearer's own network — reachable from this phone, which is
  /// the whole premise — with [respond] deciding what it says.
  http.Client lan({
    int status = 200,
    String body = '{"ok":true}',
    bool dead = false,
  }) => MockClient((request) async {
    served.add(request);
    if (dead) throw http.ClientException('No route', request.url);
    return http.Response(body, status);
  });

  /// The listener's zone is fixed when `listen` is called, so the host has to
  /// be started *inside* the client's zone or its requests miss the mock.
  Future<void> withLan(http.Client client, Future<void> Function() body) =>
      http.runWithClient(() async {
        await host.init();
        await body();
      }, () => client);

  /// A relayed request arriving from [nodeId].
  Future<void> ask(
    String nodeId, {
    String id = 'req-1',
    String method = 'GET',
    String url = 'https://pantry.local/ocs/v2.php/apps/pantry/api/houses',
    Map<String, dynamic>? payload,
  }) async {
    handler.emit({
      'delivery': 'message',
      'path': WearRelay.requestPath,
      'payload': jsonEncode(
        payload ??
            WearRelayRequest(
              id: id,
              method: method,
              url: url,
              headers: const {'Authorization': 'Basic abc'},
            ).toJson(),
      ),
      'nodeId': nodeId,
    });
    // The serve is started unawaited from the listener, so the request, the
    // response and the stream back each need a turn.
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('it makes the request and streams back what the server said', () async {
    await pairing.grant(watch);

    await withLan(lan(body: '{"houses":[]}'), () => ask('watch-1'));

    expect(served.single.method, 'GET');
    expect(served.single.url.host, 'pantry.local');
    expect(served.single.headers['Authorization'], 'Basic abc');
    expect(answer()?.id, 'req-1');
    expect(answer()?.status, 200);
    expect(utf8.decode(answer()!.bodyBytes), '{"houses":[]}');
  });

  test('an error status is an answer, not a failure', () async {
    await pairing.grant(watch);

    // The server was reached and it said no. Collapsing that into
    // "unreachable" would send the watch to its cache holding a 404 the queue
    // needed in order to drop a row that is gone.
    await withLan(lan(status: 404, body: 'gone'), () => ask('watch-1'));

    expect(answer()?.status, 404);
    expect(answer()?.reached, isTrue);
  });

  test('a phone with no route says only that', () async {
    await pairing.grant(watch);

    await withLan(lan(dead: true), () => ask('watch-1'));

    // One spelling for every way it failed: the watch is already holding the
    // same news from its own attempt and has a cache path for it.
    expect(answer()?.status, 0);
    expect(answer()?.reached, isFalse);
  });

  test('only the watch this phone signed in is served', () async {
    await pairing.grant(watch);

    await withLan(lan(), () => ask('watch-2'));

    // The relay carries the household's credential to a household server, so
    // who may ask is what pairing already answered — and a watch that missed
    // its unpair must not go on being served.
    expect(served, isEmpty);
    expect(answer(), isNull);
  });

  test('a phone that paired nobody serves nobody', () async {
    await withLan(lan(), () => ask('watch-1'));

    expect(served, isEmpty);
    expect(answer(), isNull);
  });

  test('it will not fetch anything but our own server', () async {
    await pairing.grant(watch);

    await withLan(
      lan(),
      () => ask('watch-1', url: 'http://192.168.1.1/admin/config'),
    );

    // A phone willing to fetch any address for the watch would be a way onto
    // the whole home network. The watch has never had a reason to ask for
    // anything but the server it is signed in to.
    expect(served, isEmpty);
    expect(answer()?.status, 0);
  });

  test('a different port on the same host is a different server', () async {
    await pairing.grant(watch);

    await withLan(
      lan(),
      () => ask('watch-1', url: 'https://pantry.local:8443/api/houses'),
    );

    expect(served, isEmpty);
    expect(answer()?.status, 0);
  });

  test('an image from another path on our server is served', () async {
    await pairing.grant(watch);

    // The API lives under the instance's path and an image does not, so the
    // origin is what has to match — not the whole URL.
    await withLan(
      lan(body: 'PNGBYTES'),
      () => ask('watch-1', url: 'https://pantry.local/core/preview?fileId=7'),
    );

    expect(served.single.url.path, '/core/preview');
    expect(answer()?.status, 200);
  });

  test(
    'an unreadable payload goes unanswered rather than half-served',
    () async {
      await pairing.grant(watch);

      await withLan(
        lan(),
        () => ask('watch-1', payload: const {'id': 'req-1', 'method': 'GET'}),
      );

      expect(served, isEmpty);
      expect(answer(), isNull);
    },
  );

  test('a payload delivered twice is performed once', () async {
    await pairing.grant(watch);
    // Held open, because that is the whole window the guard covers: once the
    // request has finished there is nothing in flight to join, and a watch that
    // gave up waiting asks again under a new id by design.
    final gate = Completer<void>();
    final server = MockClient((request) async {
      served.add(request);
      await gate.future;
      return http.Response('{}', 200);
    });

    await withLan(server, () async {
      await ask('watch-1', id: 'req-1', method: 'POST');
      await ask('watch-1', id: 'req-1', method: 'POST');
      gate.complete();
      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    });

    // The wearer's check-off must not land twice because the link repeated
    // itself.
    expect(served, hasLength(1));
    expect(answer()?.status, 200);
  });
}

class _StreamHandler extends MockStreamHandler {
  MockStreamHandlerEventSink? _sink;

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) =>
      _sink = events;

  @override
  void onCancel(Object? arguments) => _sink = null;

  void emit(Object? event) => _sink?.success(event);
}
