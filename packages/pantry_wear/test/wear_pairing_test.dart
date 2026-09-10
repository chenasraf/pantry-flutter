import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/cache_store.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry_core/services/wear_mirror_service.dart';
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
  const localNode = {'id': 'watch-1', 'name': 'Galaxy Watch', 'nearby': true};
  final published = <Map<String, Object?>>[];

  const credentials = NextcloudCredentials(
    serverUrl: 'https://cloud.example',
    loginName: 'ada',
    appPassword: 'secret',
  );

  void emit(
    String path,
    Map<String, dynamic> payload, {
    String delivery = 'message',
  }) => handler.emit({
    'delivery': delivery,
    'path': path,
    'payload': jsonEncode(payload),
    'nodeId': 'phone-1',
  });

  /// What the phone has published about this watch, as the link would report
  /// it on a cold start.
  void publishPairing(Map<String, dynamic>? state) => published
    ..clear()
    ..addAll([
      if (state != null)
        {
          'delivery': 'dataItem',
          'path': WearPairing.statePath,
          'payload': jsonEncode(state),
          'nodeId': 'phone-1',
        },
    ]);

  List<String> sentPaths() => [
    for (final call in sent)
      if (call.method == 'send') call.arguments['path'] as String,
  ];

  /// Accepting a grant writes storage, loads ten cache stores and reports a
  /// scope before it settles, so one turn of the event queue is not enough to
  /// see the end of it.
  Future<void> settle() => pumpEventQueue(times: 50);

  /// Turn the event queue until [reached] holds, or give up and let the
  /// assertion that follows say what was missing.
  ///
  /// A count of turns is a guess about how deep an async chain runs, and an
  /// unpair is the deepest one here: a logout, ten cache stores, the prefs and
  /// the appearance, then a fresh `start`. Waiting on the outcome instead is
  /// what stops the same code passing and failing on different runs.
  Future<void> settleUntil(bool Function() reached) async {
    for (var turn = 0; turn < 200 && !reached(); turn++) {
      await pumpEventQueue(times: 1);
    }
  }

  setUp(() async {
    sent.clear();
    storage.clear();
    published.clear();
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
        if (call.method == 'localNode') return localNode;
        if (call.method == 'dataItems') return published;
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
    // An unpair is fired and never awaited, so its tail — the prefs, the
    // appearance, the fresh `start` — can still be in flight when the test
    // that set it off ends. Draining it while the mocks are still answering is
    // what stops it calling a channel that has already been taken away, and
    // that exception landing on whichever test happens to be running by then.
    await settle();
    await client.debugReset();
    await WearMirrorClient.instance.debugReset();
    // A cache write is debounced half a second, and the stores are singletons
    // that outlive the test that wrote them — so one left armed here fires
    // partway through a later test and writes into the very map that test is
    // asserting about. Draining is what keeps each test's storage its own.
    await CacheStore.flushAll();
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

    test(
      'a renewal replaces the credential and leaves the chips alone',
      () async {
        await client.start();

        emit(
          WearPairing.grantPath,
          const WearPairingGrant(
            credentials: credentials,
            certPins: {},
            houseId: 4,
            hiddenItemChips: {'price'},
          ).toJson(),
        );
        await settle();

        // The wearer has since chosen for themselves, on the watch, for the
        // watch — and the phone has moved on too.
        await PrefsService.instance.setItemChipVisible('price', true);
        await PrefsService.instance.setItemChipVisible('note', false);

        await client.renew();
        emit(
          WearPairing.grantPath,
          const WearPairingGrant(
            credentials: NextcloudCredentials(
              serverUrl: 'https://cloud.example',
              loginName: 'ada',
              appPassword: 'fresher',
            ),
            certPins: {},
            houseId: 4,
            hiddenItemChips: {'store', 'quantity'},
          ).toJson(),
        );
        await settle();

        expect(AuthService.instance.credentials?.appPassword, 'fresher');
        expect(PrefsService.instance.hiddenItemChips, {'note'});
      },
    );

    test('a malformed grant leaves the watch signed out', () async {
      await client.start();

      emit(WearPairing.grantPath, const {'houseId': 4});
      await pumpEventQueue();

      expect(AuthService.instance.isLoggedIn, isFalse);
      expect(client.state, WearSetupState.waiting);
    });
  });

  /// Setting the watch up is the one moment the wearer is already attending to
  /// it with both hands, and it is before any trip exists — where every other
  /// moment to ask for the notification grant is mid-shop.
  group('the notification grant', () {
    const host = MethodChannel('dev.casraf.pantry/wear_host');
    final asked = <String>[];

    setUp(() {
      asked.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(host, (call) async {
            asked.add(call.method);
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(host, null);
    });

    test('is asked for once the watch is signed in from the phone', () async {
      await client.start();

      emit(
        WearPairing.grantPath,
        const WearPairingGrant(
          credentials: credentials,
          certPins: {},
          houseId: 4,
        ).toJson(),
      );
      await settle();
      // The seed is what the syncing state is waiting on, and it is the last
      // thing between a wearer and their lists.
      emit(
        WearMirrorService.instance.pathFor(MirrorEntity.lists, 4),
        WearMirrorService.instance.snapshot(
          const [],
          capturedAt: DateTime.fromMillisecondsSinceEpoch(1),
        ),
        delivery: 'channel',
      );
      await settle();

      expect(client.state, WearSetupState.ready);
      expect(asked, contains('requestNotifications'));
    });

    test('is asked for on the QR path too', () async {
      await client.adoptLocalSignIn();

      expect(asked, contains('requestNotifications'));
    });

    test('is not re-asked when a credential is merely renewed', () async {
      await client.start();
      emit(
        WearPairing.grantPath,
        const WearPairingGrant(
          credentials: credentials,
          certPins: {},
          houseId: 4,
        ).toJson(),
      );
      await settle();
      asked.clear();

      await client.renew();
      emit(
        WearPairing.grantPath,
        const WearPairingGrant(
          credentials: NextcloudCredentials(
            serverUrl: 'https://cloud.example',
            loginName: 'ada',
            appPassword: 'fresher',
          ),
          certPins: {},
          houseId: 4,
        ).toJson(),
      );
      await settle();

      // A prompt is a single moment, answered once. The settings row is where
      // a wearer changes their mind afterwards.
      expect(asked, isNot(contains('requestNotifications')));
    });
  });

  group('the pairing the phone published', () {
    test('drops the session and the stored credential with it', () async {
      await AuthService.instance.adoptCredentials(credentials);
      await client.start();
      expect(storage, isNotEmpty);

      emit(WearPairing.statePath, const {}, delivery: 'dataItem');
      await settleUntil(() => client.state == WearSetupState.waiting);

      expect(AuthService.instance.isLoggedIn, isFalse);
      expect(storage.keys, isNot(contains('nextcloud_credentials')));
    });

    test('asks to be set up again rather than sitting signed out', () async {
      await AuthService.instance.adoptCredentials(credentials);
      await client.start();

      emit(WearPairing.statePath, const {}, delivery: 'dataItem');
      await settleUntil(() => client.state == WearSetupState.waiting);

      expect(client.state, WearSetupState.waiting);
    });

    test('naming another watch is an unpair too', () async {
      // The phone paired something else. Nothing was ever aimed at this watch,
      // and the state alone has to be enough.
      await AuthService.instance.adoptCredentials(credentials);
      await client.start();

      emit(WearPairing.statePath, const {
        'nodeId': 'watch-2',
      }, delivery: 'dataItem');
      await settleUntil(() => client.state == WearSetupState.waiting);

      expect(AuthService.instance.isLoggedIn, isFalse);
    });

    test('naming this watch leaves it alone', () async {
      await AuthService.instance.adoptCredentials(credentials);
      await client.start();

      emit(WearPairing.statePath, const {
        'nodeId': 'watch-1',
      }, delivery: 'dataItem');
      await settle();

      expect(AuthService.instance.isLoggedIn, isTrue);
      expect(client.state, WearSetupState.ready);
    });

    test('is read on a cold start, not waited for', () async {
      // The unpair landed while the watch was asleep, so no change is ever
      // reported — the item is simply there on the next run.
      await AuthService.instance.adoptCredentials(credentials);
      publishPairing(const {'nodeId': 'watch-2'});

      await client.readPairing();
      await settle();

      expect(AuthService.instance.isLoggedIn, isFalse);
    });

    test('nothing published says nothing about this watch', () async {
      // A watch signed in by the QR path, or by a phone too old to publish.
      await AuthService.instance.adoptCredentials(credentials);
      publishPairing(null);

      await client.readPairing();
      await settle();

      expect(AuthService.instance.isLoggedIn, isTrue);
    });

    test('a signed-out watch has nothing to forget', () async {
      publishPairing(const {});

      await client.readPairing();
      await settle();

      expect(client.state, WearSetupState.checking);
      expect(sentPaths(), isEmpty);
    });
  });

  group('what signing out leaves behind', () {
    test('nothing: the settings go with the account', () async {
      await AuthService.instance.adoptCredentials(credentials);
      final prefs = PrefsService.instance;
      // A wearer who has been using this watch: a language, an accent, and the
      // three answers the settings page holds.
      await prefs.setLocale('he');
      await prefs.setThemeColorHex('#A02334');
      await prefs.setWearCrownTurnsPages(true);
      await prefs.setWearUndoSeconds(5);
      await prefs.setHiddenItemChips({'price'});

      await client.forget();
      await settle();

      // Every one of these describes how the watch draws for a household it no
      // longer belongs to. A watch handed on starts where a new one does.
      expect(prefs.locale, isNull);
      expect(prefs.themeColorHex, isNull);
      expect(prefs.wearCrownTurnsPages, isFalse);
      expect(prefs.wearUndoSeconds, 2);
      expect(prefs.hiddenItemChips, isEmpty);
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
