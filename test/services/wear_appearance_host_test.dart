import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/services/wear_appearance_host.dart';
import 'package:pantry/services/wear_pairing_host.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/wear_appearance.dart';
import 'package:pantry_core/services/wear_link_service.dart';

/// When the phone states how it draws itself.
///
/// The statement is deduped, because its triggers are cosmetic and fire freely
/// — but the dedupe is about not repeating ourselves to the same listener, and
/// a pairing is a new one. A watch that has just been signed in has never heard
/// the statement however unchanged it is, and one that heard it while signed
/// out deliberately ignored it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel('dev.casraf.pantry/data_layer');
  const events = EventChannel('dev.casraf.pantry/data_layer/events');
  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final link = WearLinkService.instance;
  final pairing = WearPairingHost.instance;
  final appearance = WearAppearanceHost.instance;

  final calls = <MethodCall>[];
  final storage = <String, String>{};
  late _StreamHandler handler;

  const credentials = NextcloudCredentials(
    serverUrl: 'https://cloud.example',
    loginName: 'ada',
    appPassword: 'secret',
  );

  const watch = WearPairingRequest(nodeId: 'watch-1', nodeName: 'Galaxy Watch');

  /// Every appearance statement that went out on the wire, oldest first.
  List<Map<String, dynamic>> appearancePublishes() => calls
      .where(
        (c) =>
            c.method == 'publish' && c.arguments['path'] == WearAppearance.path,
      )
      .map(
        (c) =>
            jsonDecode(c.arguments['payload'] as String)
                as Map<String, dynamic>,
      )
      .toList();

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
    await PrefsService.instance.load();
    await AuthService.instance.adoptCredentials(credentials);
    await pairing.init();
    await appearance.init();
  });

  tearDown(() async {
    await pairing.unpair();
    await appearance.dispose();
    await pairing.dispose();
    await AuthService.instance.logout(revoke: false);
    await PrefsService.instance.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(methods, null)
      ..setMockStreamHandler(events, null)
      ..setMockMethodCallHandler(secureStorage, null);
    WearLinkService.debugHostSupported = null;
    link.debugReset();
  });

  test('a phone with nobody signed in states nothing', () async {
    expect(appearancePublishes(), isEmpty);
  });

  test('granting a pairing states how this phone draws', () async {
    await pairing.grant(watch);

    expect(appearancePublishes(), hasLength(1));
  });

  test('an unchanged statement is not repeated', () async {
    await pairing.grant(watch);
    calls.clear();

    // The triggers are cosmetic and fire freely — a profile fetch landing the
    // same language it already had, say.
    await appearance.publish();

    expect(appearancePublishes(), isEmpty);
  });

  test('but pairing again always states it, unchanged or not', () async {
    await pairing.grant(watch);
    await pairing.unpair();
    calls.clear();

    await pairing.grant(watch);

    // Nothing about how the phone draws has changed, and the watch still needs
    // telling: it either has never heard this, or ignored it while signed out.
    // Without a statement here it stays on its own defaults until some
    // unrelated cosmetic change happens to fire one.
    expect(appearancePublishes(), hasLength(1));
  });
}

class _StreamHandler extends MockStreamHandler {
  MockStreamHandlerEventSink? _sink;

  // A block body, not an arrow: `void` is a static annotation in Dart, so an
  // arrow returns the sink and the mock handler errors on activation.
  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {
    _sink = events;
  }

  @override
  void onCancel(Object? arguments) {
    _sink = null;
  }

  void emit(Object? event) => _sink?.success(event);
}
