import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/locale_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/theming_service.dart';
import 'package:pantry_core/services/wear_appearance.dart';

/// The resolution the watch's appearance rests on.
///
/// The three watch kinds differ only in whether a phone ever published to
/// them, so what has to hold is one ladder rather than three: a wrist choice
/// outranks a publication, a publication outranks what the device would have
/// worked out for itself, and a watch nobody published to is left where it
/// already was.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final storage = <String, String>{};

  setUp(() async {
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async {
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
    await PrefsService.instance.load();
  });

  tearDown(() async {
    await PrefsService.instance.clear();
    ThemingService.instance.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
  });

  group('the wire contract', () {
    test('a statement survives the round trip', () {
      const sent = WearAppearanceState(
        locale: 'de',
        themeColorHex: '#A02334',
        useServerThemeColor: false,
      );

      final read = WearAppearanceState.fromJson(sent.toJson());

      expect(read.locale, 'de');
      expect(read.themeColorHex, '#A02334');
      expect(read.useServerThemeColor, isFalse);
      expect(read, sent);
    });

    test('a phone with nothing to state says so without lying', () {
      final read = WearAppearanceState.fromJson(
        const WearAppearanceState().toJson(),
      );

      expect(read.locale, isNull);
      expect(read.themeColorHex, isNull);
      // The phone's own default, so a payload that omitted it would have the
      // watch paint plain blue against a phone painting its Nextcloud accent.
      expect(read.useServerThemeColor, isTrue);
    });

    test('an empty string is not a locale', () {
      final read = WearAppearanceState.fromJson(const {
        'locale': '',
        'themeColorHex': '',
      });

      expect(read.locale, isNull);
      expect(read.themeColorHex, isNull);
    });

    test('appearance never shares the pairing path', () {
      expect(WearAppearance.path, isNot('/pairing/state'));
    });
  });

  group('the language ladder', () {
    test('a phone that publishes is what a watch draws in', () async {
      await PrefsService.instance.setPhoneAppearance(
        locale: 'fr',
        useServerThemeColor: true,
      );

      expect(LocaleService.instance.effectiveLocale.languageCode, 'fr');
    });

    test('a wrist choice outranks the phone', () async {
      await PrefsService.instance.setPhoneAppearance(
        locale: 'fr',
        useServerThemeColor: true,
      );
      await PrefsService.instance.setLocale('he');

      expect(LocaleService.instance.effectiveLocale.languageCode, 'he');
    });

    test('and goes on outranking it when the phone changes its mind', () async {
      await PrefsService.instance.setLocale('he');
      await PrefsService.instance.setPhoneAppearance(
        locale: 'de',
        useServerThemeColor: true,
      );

      expect(LocaleService.instance.effectiveLocale.languageCode, 'he');
    });

    test('returning to follow-phone is one write, not a lost option', () async {
      await PrefsService.instance.setPhoneAppearance(
        locale: 'de',
        useServerThemeColor: true,
      );
      await PrefsService.instance.setLocale('he');
      await PrefsService.instance.setLocale(null);

      expect(LocaleService.instance.effectiveLocale.languageCode, 'de');
    });

    test('a language this build cannot draw falls through', () async {
      await PrefsService.instance.setPhoneAppearance(
        locale: 'ja',
        useServerThemeColor: true,
      );

      expect(LocaleService.instance.effectiveLocale.languageCode, isNot('ja'));
    });

    test('a watch nobody publishes to keeps its own answer', () {
      // The QR sign-in and the F-Droid pairing are this case, and it is also
      // every phone: absence carries no information, so the ladder simply
      // carries on to the rungs that were always there.
      expect(PrefsService.instance.phoneLocale, isNull);
      expect(LocaleService.instance.effectiveLocale.languageCode, 'en');
    });

    test('a phone outranks the server language it already resolved', () async {
      await PrefsService.instance.setUserProfileCache(
        displayName: 'Ada',
        serverLanguage: 'es',
      );
      AuthService.instance.hydrateFromCache();
      await PrefsService.instance.setPhoneAppearance(
        locale: 'de',
        useServerThemeColor: true,
      );

      // The publication *is* that resolution, arriving on a device with no
      // profile of its own to read; a phone never has both.
      expect(LocaleService.instance.effectiveLocale.languageCode, 'de');
    });
  });

  group('the accent', () {
    test('follows the phone until the wrist says otherwise', () async {
      await PrefsService.instance.setPhoneAppearance(
        locale: null,
        useServerThemeColor: false,
      );

      expect(PrefsService.instance.useServerThemeColorPref, isNull);
      expect(PrefsService.instance.useServerThemeColor, isFalse);

      await PrefsService.instance.setUseServerThemeColor(true);

      expect(PrefsService.instance.useServerThemeColor, isTrue);
    });

    test('and on is what a device with nobody to follow paints', () {
      expect(PrefsService.instance.useServerThemeColorPref, isNull);
      expect(PrefsService.instance.useServerThemeColor, isTrue);
    });

    test('a published colour runs through the resolver unchanged', () async {
      await ThemingService.instance.adoptPublishedColor('#A02334');

      expect(ThemingService.instance.effectiveColor.toARGB32(), 0xFFA02334);

      await PrefsService.instance.setUseServerThemeColor(false);

      expect(ThemingService.instance.effectiveColor.toARGB32(), 0xFF0082C9);
    });

    test('a phone with no accent clears the one being held', () async {
      // Absolute where a fetch is not: nothing on a watch ever fetches an
      // accent, so a value kept "just in case" outlives the only thing that
      // could contradict it.
      await ThemingService.instance.adoptPublishedColor('#A02334');
      await ThemingService.instance.adoptPublishedColor(null);

      expect(ThemingService.instance.effectiveColor.toARGB32(), 0xFF0082C9);
      expect(PrefsService.instance.themeColorHex, isNull);
    });
  });
}
