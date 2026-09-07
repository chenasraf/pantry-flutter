import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/locale_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/theming_service.dart';
import 'package:pantry_core/services/wear_appearance.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry_wear/src/account/accent_page.dart';
import 'package:pantry_wear/src/account/language_page.dart';
import 'package:pantry_wear/src/services/wear_appearance_client.dart';
import 'package:pantry_wear/src/services/wear_tile_service.dart';
import 'package:pantry_wear/src/wear_app.dart';
import 'package:pantry_wear/src/widgets/wear_mechanics.dart';

/// What the phone says about how it draws, arriving on the wrist.
///
/// The transfer itself needs two devices; what is provable here is the part
/// that decides what the wearer sees — that a publication is taken on as a
/// default, that a choice made on the wrist outranks it and keeps outranking
/// it, and that a watch nobody publishes to is left exactly where it was.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel('dev.casraf.pantry/data_layer');
  const events = EventChannel('dev.casraf.pantry/data_layer/events');
  const tile = MethodChannel('dev.casraf.pantry/tile');
  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final link = WearLinkService.instance;
  final client = WearAppearanceClient.instance;

  final storage = <String, String>{};
  final published = <Map<String, Object?>>[];
  final tileCalls = <MethodCall>[];
  late _StreamHandler handler;

  var available = true;

  /// What the phone has published about how it draws, as the link would report
  /// it on a cold start.
  void publishAppearance(Map<String, dynamic>? state) => published
    ..clear()
    ..addAll([
      if (state != null)
        {
          'delivery': 'dataItem',
          'path': WearAppearance.path,
          'payload': jsonEncode(state),
          'nodeId': 'phone-1',
        },
    ]);

  void emit(Map<String, dynamic> payload) => handler.emit({
    'delivery': 'dataItem',
    'path': WearAppearance.path,
    'payload': jsonEncode(payload),
    'nodeId': 'phone-1',
  });

  Future<void> settle() => pumpEventQueue(times: 20);

  setUp(() async {
    storage.clear();
    published.clear();
    tileCalls.clear();
    available = true;
    handler = _StreamHandler();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(methods, (call) async {
        if (call.method == 'isAvailable') return available;
        if (call.method == 'dataItems') return published;
        return true;
      })
      ..setMockStreamHandler(events, handler)
      ..setMockMethodCallHandler(tile, (call) async => tileCalls.add(call))
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
    // A watch reading a publication is a signed-in watch: the phone states how
    // it draws to the watch it signed in, and a signed-out one ignores it.
    await AuthService.instance.adoptCredentials(
      const NextcloudCredentials(
        serverUrl: 'https://cloud.example',
        loginName: 'ada',
        appPassword: 'secret',
      ),
    );
    ThemingService.instance.clear();
    LocaleService.instance.apply();
  });

  tearDown(() async {
    await AuthService.instance.logout(revoke: false);
    await client.debugReset();
    await WearTileService.instance.clear();
    await PrefsService.instance.clear();
    ThemingService.instance.clear();
    LocaleService.instance.apply();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(methods, null)
      ..setMockStreamHandler(events, null)
      ..setMockMethodCallHandler(tile, null)
      ..setMockMethodCallHandler(secureStorage, null);
    WearLinkService.debugHostSupported = null;
    link.debugReset();
  });

  group('what a watch reads at launch', () {
    test('a phone that published is what the watch draws', () async {
      publishAppearance(const {
        'locale': 'de',
        'themeColorHex': '#A02334',
        'useServerThemeColor': true,
      });

      await client.start();
      await settle();

      expect(LocaleService.instance.effectiveLocale.languageCode, 'de');
      expect(ThemingService.instance.effectiveColor.toARGB32(), 0xFFA02334);
    });

    test('a statement landing later applies the same way', () async {
      await client.start();
      expect(LocaleService.instance.effectiveLocale.languageCode, 'en');

      emit(const {'locale': 'fr', 'useServerThemeColor': true});
      await settle();

      expect(LocaleService.instance.effectiveLocale.languageCode, 'fr');
    });

    test('and never as a reset — the revision is untouched', () async {
      final before = LocaleService.instance.revision;

      publishAppearance(const {'locale': 'de', 'useServerThemeColor': true});
      await client.start();
      await settle();

      // A watch's only way back out of a route is a deliberate edge-strip
      // drag, so a landed value rebuilds rather than tearing the tree down.
      expect(LocaleService.instance.revision, before);
    });

    test('a signed-out watch reads it and takes nothing', () async {
      // The publication is a `DataItem` and outlives the session it was made
      // for, so it is still sitting there on the launch after a sign-out.
      // Landing it would hand back the accent and language the wearer had just
      // dropped — a local sign-out undone by restarting the app.
      await AuthService.instance.logout(revoke: false);
      publishAppearance(const {
        'locale': 'de',
        'themeColorHex': '#A02334',
        'useServerThemeColor': true,
      });

      await client.start();
      await settle();

      expect(LocaleService.instance.effectiveLocale.languageCode, 'en');
      expect(PrefsService.instance.themeColorHex, isNull);
    });

    test(
      'a statement that beat the credentials is read again on sign-in',
      () async {
        // The pairing hands the session over by message and states the
        // appearance by DataItem, and nothing orders the two. Arriving first, the
        // statement is refused — and the item is still sitting there, so signing
        // in is the moment to look again rather than the next cold start.
        await AuthService.instance.logout(revoke: false);
        publishAppearance(const {
          'locale': 'de',
          'themeColorHex': '#A02334',
          'useServerThemeColor': true,
        });

        await client.start();
        await settle();
        expect(LocaleService.instance.effectiveLocale.languageCode, 'en');

        await AuthService.instance.adoptCredentials(
          const NextcloudCredentials(
            serverUrl: 'https://cloud.example',
            loginName: 'ada',
            appPassword: 'secret',
          ),
        );
        await client.refresh();
        await settle();

        expect(LocaleService.instance.effectiveLocale.languageCode, 'de');
        expect(ThemingService.instance.effectiveColor.toARGB32(), 0xFFA02334);
      },
    );

    test('a watch with no Data Layer keeps its own answers', () async {
      // The F-Droid pairing: the link is not there to read, and absence
      // carries no information.
      available = false;
      publishAppearance(const {'locale': 'de', 'useServerThemeColor': false});

      await client.start();
      await settle();

      expect(PrefsService.instance.phoneLocale, isNull);
      expect(LocaleService.instance.effectiveLocale.languageCode, 'en');
      expect(PrefsService.instance.useServerThemeColor, isTrue);
    });

    test('a watch nobody published to reads nothing', () async {
      // The QR sign-in: a live link with no statement on it.
      publishAppearance(null);

      await client.start();
      await settle();

      expect(PrefsService.instance.phoneLocale, isNull);
      expect(LocaleService.instance.effectiveLocale.languageCode, 'en');
    });

    test('a wrist choice survives the phone changing its mind', () async {
      await LocaleService.instance.setLocale('he');
      await client.start();

      emit(const {'locale': 'de', 'useServerThemeColor': true});
      await settle();

      expect(LocaleService.instance.effectiveLocale.languageCode, 'he');
      // Still landed, so returning to *Follow phone* has something to follow.
      expect(PrefsService.instance.phoneLocale, 'de');
    });
  });

  group('forgetting the phone', () {
    test('drops its defaults and leaves the wearer their own', () async {
      publishAppearance(const {
        'locale': 'de',
        'themeColorHex': '#A02334',
        'useServerThemeColor': true,
      });
      await client.start();
      await settle();
      await PrefsService.instance.setUseServerThemeColor(false);

      await client.forget();
      await settle();

      expect(PrefsService.instance.phoneLocale, isNull);
      expect(PrefsService.instance.themeColorHex, isNull);
      expect(LocaleService.instance.effectiveLocale.languageCode, 'en');
      // The opt-out was theirs before the pairing and outlives it.
      expect(PrefsService.instance.useServerThemeColorPref, isFalse);
    });
  });

  group('the Tile', () {
    test('is told when the accent moves under it', () async {
      await client.start();
      await WearTileService.instance.publish(
        houseId: 1,
        houseName: 'Home',
        lists: [
          ChecklistList(
            id: 4,
            houseId: 1,
            name: 'Groceries',
            icon: 'cart',
            sortOrder: 0,
            createdAt: 0,
            updatedAt: 0,
          ),
        ],
      );
      tileCalls.clear();

      emit(const {'themeColorHex': '#A02334', 'useServerThemeColor': true});
      await settle();

      // A Tile is drawn by the system with no engine running, so it holds its
      // own copy and would go on drawing the old accent until a list happened
      // to be renamed.
      final payload =
          jsonDecode((tileCalls.single.arguments as Map)['payload'] as String)
              as Map<String, dynamic>;
      expect(payload['accent'], '#A02334');
      expect((payload['lists'] as List), hasLength(1));
    });

    test('is left alone when nothing has been drawn on it', () async {
      await client.start();
      tileCalls.clear();

      emit(const {'themeColorHex': '#A02334', 'useServerThemeColor': true});
      await settle();

      expect(tileCalls, isEmpty);
    });
  });

  group('the settings rows', () {
    test('say who is being followed rather than a value', () async {
      expect(languageLabel(null), m.wear.followPhone);
      expect(accentLabel(null), m.wear.followPhone);
      // An endonym, so a wearer hunting for their own language reads it in
      // that language whatever the watch is drawing in.
      expect(languageLabel('he'), 'עברית');
    });
  });

  testWidgets('the root repaints in the language that landed', (tester) async {
    // The link is unavailable, so the app settles on the setup page's dead
    // end — a real page, drawn from the same global message bundle as every
    // other, which is what makes it worth asserting against.
    available = false;
    // Signed out, which is what settles the app on the setup page. These two
    // assert the rebuild reaching a tree, not the rule about what may land, so
    // they write the published value straight into prefs.
    await AuthService.instance.logout(revoke: false);
    await tester.pumpWidget(const PantryWearApp());
    await tester.pumpAndSettle();
    expect(find.text('No phone link'), findsOneWidget);

    await PrefsService.instance.setPhoneAppearance(
      locale: 'de',
      useServerThemeColor: true,
    );
    LocaleService.instance.apply();
    // Twice: the first frame is right against a widget that never rebuilt, so
    // a single pump would pass on a frozen tree.
    await tester.pump();
    await tester.pump();

    expect(find.text('Keine Telefonverbindung'), findsOneWidget);
    expect(find.text('No phone link'), findsNothing);
  });

  testWidgets('and reaches a route standing over it', (tester) async {
    // Every page above the pager is a pushed route, so a language that lands
    // while the wearer is three drags deep has to reach all of them — a route
    // rebuilds only because the navigator's own widget was replaced, which is
    // a longer chain than the frame the root repainted.
    available = false;
    // Signed out, which is what settles the app on the setup page. These two
    // assert the rebuild reaching a tree, not the rule about what may land, so
    // they write the published value straight into prefs.
    await AuthService.instance.logout(revoke: false);
    await tester.pumpWidget(const PantryWearApp());
    await tester.pumpAndSettle();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
    // Through the shared helper, because a plain `MaterialPageRoute` fails
    // this: its builder hands back the instance it closed over, identical on
    // every call, so the page below stays in the language it was pushed in.
    unawaited(navigator.push(wearRoute<void>(const _Probe())));
    await tester.pumpAndSettle();
    expect(find.text('No phone link'), findsOneWidget);

    await PrefsService.instance.setPhoneAppearance(
      locale: 'de',
      useServerThemeColor: true,
    );
    LocaleService.instance.apply();
    await tester.pump();
    await tester.pump();

    expect(find.text('Keine Telefonverbindung'), findsOneWidget);
  });
}

/// A pushed page drawn from the same global message bundle every real one
/// reads, standing in for the account and settings pages without their
/// channels.
class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(m.wear.setupNoLink)));
}

class _StreamHandler extends MockStreamHandler {
  MockStreamHandlerEventSink? _sink;

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {
    _sink = events;
  }

  @override
  void onCancel(Object? arguments) => _sink = null;

  void emit(Object? event) => _sink?.success(event);
}
