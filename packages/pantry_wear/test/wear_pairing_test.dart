import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry_core/services/wear_pairing.dart';
import 'package:pantry_wear/src/pairing/wear_pairing_client.dart';
import 'package:pantry_wear/src/services/wear_mirror_client.dart';

/// The watch's half of the credential handoff.
///
/// The two-device transfer itself needs real hardware — nothing here proves a
/// message crossed Bluetooth. What it does hold is the part that decides what
/// the wearer sees: which state each signal produces, that a request keeps
/// going out until something answers, and that a malformed answer leaves the
/// watch signed out rather than half signed in.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel('dev.casraf.pantry/data_layer');
  const events = EventChannel('dev.casraf.pantry/data_layer/events');
  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final link = WearLinkService.instance;
  final client = WearPairingClient.instance;

  final sent = <MethodCall>[];
  final storage = <String, String>{};
  late _StreamHandler handler;

  var available = true;
  var nodes = <Map<String, Object?>>[
    {'id': 'phone-1', 'name': 'Pixel', 'nearby': true},
  ];

  const credentials = NextcloudCredentials(
    serverUrl: 'https://cloud.example',
    loginName: 'ada',
    appPassword: 'secret',
  );

  void emit(String path, Map<String, dynamic> payload) => handler.emit({
    'delivery': 'message',
    'path': path,
    'payload': jsonEncode(payload),
    'nodeId': 'phone-1',
  });

  List<String> sentPaths() => [
    for (final call in sent)
      if (call.method == 'send') call.arguments['path'] as String,
  ];

  /// Accepting a grant writes storage, loads ten cache stores and reports a
  /// scope before it settles, so one turn of the event queue is not enough to
  /// see the end of it.
  Future<void> settle() => pumpEventQueue(times: 50);

  setUp(() async {
    sent.clear();
    storage.clear();
    available = true;
    nodes = [
      {'id': 'phone-1', 'name': 'Pixel', 'nearby': true},
    ];
    handler = _StreamHandler();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(methods, (call) async {
        sent.add(call);
        if (call.method == 'isAvailable') return available;
        if (call.method == 'nodes') return nodes;
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
    await AuthService.instance.logout(revoke: false);
  });

  tearDown(() async {
    await client.debugReset();
    await WearMirrorClient.instance.debugReset();
    await AuthService.instance.logout(revoke: false);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(methods, null)
      ..setMockStreamHandler(events, null)
      ..setMockMethodCallHandler(secureStorage, null);
    WearLinkService.debugHostSupported = null;
    link.debugReset();
  });

  group('the states the wearer sees', () {
    test('no Data Layer is a dead end, not a wait', () async {
      available = false;

      await client.start();

      expect(client.state, WearSetupState.unavailable);
      expect(sentPaths(), isEmpty);
    });

    test('nothing connected asks for a phone rather than the app', () async {
      nodes = [];

      await client.start();

      expect(client.state, WearSetupState.noPhone);
      expect(sentPaths(), isEmpty);
    });

    test('a connected phone gets a request', () async {
      await client.start();

      expect(client.state, WearSetupState.waiting);
      expect(sentPaths(), contains(WearPairing.requestPath));
    });

    test('a phone that signs in later is found without a tap', () async {
      nodes = [];
      await client.start();
      expect(client.state, WearSetupState.noPhone);

      nodes = [
        {'id': 'phone-1', 'name': 'Pixel', 'nearby': true},
      ];
      await client.debugTick();

      expect(client.state, WearSetupState.waiting);
      expect(sentPaths(), contains(WearPairing.requestPath));
    });

    test('a signed-out phone stops the loop instead of retrying', () async {
      await client.start();
      sent.clear();

      emit(WearPairing.refusalPath, WearPairingRefusal.signedOut.toJson());
      await pumpEventQueue();

      expect(client.state, WearSetupState.phoneSignedOut);

      // A retry here would ask a phone that cannot answer differently.
      await client.debugTick();
      expect(sentPaths(), isEmpty);
    });

    test('a signed-in watch listens without asking to be signed in', () async {
      await AuthService.instance.adoptCredentials(credentials);

      await client.start();

      expect(client.state, WearSetupState.ready);
      expect(sentPaths(), isEmpty);
    });
  });

  group('the grant', () {
    test('lands the credential, the pins and the seeded scope', () async {
      await client.start();

      emit(
        WearPairing.grantPath,
        const WearPairingGrant(
          credentials: credentials,
          certPins: {
            'cloud.example': ['AA:BB'],
          },
          houseId: 4,
          listId: 9,
          hiddenItemChips: {'price'},
        ).toJson(),
      );
      await pumpEventQueue();

      expect(AuthService.instance.isLoggedIn, isTrue);
      expect(AuthService.instance.credentials?.loginName, 'ada');
      expect(PrefsService.instance.lastHouseId, 4);
      expect(ChecklistService.instance.selectedListId, 9);
      expect(PrefsService.instance.hiddenItemChips, {'price'});
    });

    test('holds the shell back until the house data is on its way', () async {
      await client.start();

      emit(
        WearPairing.grantPath,
        const WearPairingGrant(
          credentials: credentials,
          certPins: {},
          houseId: 4,
        ).toJson(),
      );
      await pumpEventQueue();

      await settle();

      expect(client.state, WearSetupState.syncing);
      // Reporting the scope is what asks for the seed.
      expect(sentPaths(), contains('/watch/scope'));
    });

    test('a malformed grant leaves the watch signed out', () async {
      await client.start();

      emit(WearPairing.grantPath, const {'houseId': 4});
      await pumpEventQueue();

      expect(AuthService.instance.isLoggedIn, isFalse);
      expect(client.state, WearSetupState.waiting);
    });
  });

  group('unpair', () {
    test('drops the session and the stored credential with it', () async {
      await AuthService.instance.adoptCredentials(credentials);
      await client.start();
      expect(storage, isNotEmpty);

      emit(WearPairing.unpairPath, const {});
      await settle();

      expect(AuthService.instance.isLoggedIn, isFalse);
      expect(storage.keys, isNot(contains('nextcloud_credentials')));
    });

    test('asks to be set up again rather than sitting signed out', () async {
      await AuthService.instance.adoptCredentials(credentials);
      await client.start();

      emit(WearPairing.unpairPath, const {});
      await settle();

      expect(client.state, WearSetupState.waiting);
    });
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
