import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/services/wear_mirror_host.dart';
import 'package:pantry/services/wear_pairing_host.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry_core/services/wear_pairing.dart';

/// The phone's half of the pairing, and the one thing it says out loud.
///
/// A watch app runs for seconds a day, so the phone cannot tell it anything by
/// sending: what it knows about the pairing has to be readable whenever the
/// watch next wakes. These cover what gets published and when — not the
/// transfer itself, which needs two devices.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel('dev.casraf.pantry/data_layer');
  const events = EventChannel('dev.casraf.pantry/data_layer/events');
  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final link = WearLinkService.instance;
  final host = WearPairingHost.instance;

  final calls = <MethodCall>[];
  final storage = <String, String>{};
  late _StreamHandler handler;

  const credentials = NextcloudCredentials(
    serverUrl: 'https://cloud.example',
    loginName: 'ada',
    appPassword: 'secret',
  );

  const watch = WearPairingRequest(nodeId: 'watch-1', nodeName: 'Galaxy Watch');

  /// The pairing as it went out on the wire, or null if none did.
  WearPairingState? publishedState() {
    final call = calls.cast<MethodCall?>().lastWhere(
      (c) =>
          c!.method == 'publish' &&
          c.arguments['path'] == WearPairing.statePath,
      orElse: () => null,
    );
    if (call == null) return null;
    return WearPairingState.fromJson(
      jsonDecode(call.arguments['payload'] as String) as Map<String, dynamic>,
    );
  }

  setUp(() async {
    calls.clear();
    storage.clear();
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
    await AuthService.instance.adoptCredentials(credentials);
    await host.init();
  });

  tearDown(() async {
    await host.unpair();
    await host.dispose();
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

  test('a grant names the watch where a sleeping one can read it', () async {
    expect(await host.grant(watch), isTrue);

    expect(publishedState()?.nodeId, 'watch-1');
    expect(host.paired.value?.nodeId, 'watch-1');
  });

  test('the mirror is told which watch is ours', () async {
    await host.grant(watch);

    expect(WearMirrorHost.instance.pairedNode, 'watch-1');
  });

  test('unpairing says nobody rather than saying nothing', () async {
    await host.grant(watch);
    calls.clear();

    await host.unpair();

    // Deleting the item would be indistinguishable from a phone that never
    // published one, and a watch reads that as "no information".
    expect(calls.map((c) => c.method), isNot(contains('clear')));
    expect(publishedState(), isNotNull);
    expect(publishedState()?.nodeId, isNull);
    expect(WearMirrorHost.instance.pairedNode, isNull);
  });

  test('a phone that paired nobody makes no statement', () async {
    calls.clear();

    await host.unpair();

    // "Nobody" from here would forget a watch this phone never signed in —
    // one that came in by the QR path, say.
    expect(publishedState(), isNull);
  });

  /// A watch asking to be signed in, as it arrives over the link.
  Future<void> request(String nodeId) async {
    handler.emit({
      'delivery': 'message',
      'path': WearPairing.requestPath,
      'payload': '{}',
      'nodeId': nodeId,
    });
    await Future<void>.delayed(Duration.zero);
  }

  test('unpairing lets a watch that was once refused ask again', () async {
    // A refusal suppresses that watch's prompt, or it would reappear seconds
    // after being dismissed — the watch re-sends every five seconds and has no
    // state to enter on being ignored.
    await host.grant(watch);
    await request(watch.nodeId);
    host.deny();
    await request(watch.nodeId);
    expect(host.pending.value, isNull, reason: 'still refused');

    // Unpairing is a deliberate act about this watch, exactly as opening the
    // pairing screen is. Setting the same watch up again has to raise a prompt
    // rather than wait for that screen to be reopened by chance.
    await host.unpair();
    await request(watch.nodeId);

    expect(host.pending.value?.nodeId, watch.nodeId);
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
