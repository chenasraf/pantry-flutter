import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/services/nn_localizations.dart';
import 'package:pantry/i18n/messages.i18n.dart';
import 'package:pantry/i18n/messages_de.i18n.dart' as de;
import 'package:pantry/i18n/messages_es.i18n.dart' as es;
import 'package:pantry/i18n/messages_fr.i18n.dart' as fr;
import 'package:pantry/i18n/messages_he.i18n.dart' as he;
import 'package:pantry/i18n/messages_nn.i18n.dart' as nn;
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/prefs_service.dart';

/// Supported app locales.
const supportedLocales = [
  Locale('en'),
  Locale('de'),
  Locale('es'),
  Locale('fr'),
  Locale('he'),
  Locale('nn'),
];

/// Native display name (endonym) for each supported language, shown in the
/// language picker. These read the same regardless of the active locale, so
/// they live here as static data instead of being duplicated across every
/// translation file.
const languageNativeNames = <String, String>{
  'en': 'English',
  'de': 'Deutsch',
  'es': 'Español',
  'fr': 'Français',
  'he': 'עברית',
  'nn': 'Norsk (nynorsk)',
};

/// Framework (Material/Cupertino) localizations delegates for the app.
///
/// `flutter_localizations` ships Norwegian only as Bokmål (`nb`); there is no
/// `nn` (Nynorsk) delegate. Since `nn` is one of our supported app locales, the
/// framework strings (date pickers, dialog buttons, etc.) would otherwise fall
/// back to English and Flutter would log a "locale not supported by all of its
/// localization delegates" warning. [nnLocalizationsDelegates] supplies proper
/// Nynorsk bundles and is listed first so those win for `nn` only.
const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
  ...nnLocalizationsDelegates,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  // The WYSIWYG markdown editor (flutter_quill) needs its own localizations.
  FlutterQuillLocalizations.delegate,
];

class LocaleService extends ChangeNotifier {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  /// Bumped only when the user explicitly changes the language. The root keys
  /// [MaterialApp] on this so a deliberate switch forces a full rebuild (every
  /// cached string re-reads [m]). Automatic re-resolution (e.g. the background
  /// user-profile fetch landing a server language) must NOT bump it — keying on
  /// the locale value there would tear down the whole navigator and drop any
  /// open route, like a half-written note in the editor.
  int _revision = 0;
  int get revision => _revision;

  /// Resolve the effective locale from the user preference, or auto-detect
  /// from the Nextcloud server language, then the system locale.
  Locale get effectiveLocale {
    final pref = PrefsService.instance.locale;
    if (pref != null) return Locale(pref);

    final serverLang = AuthService.instance.serverLanguage;
    if (serverLang != null) {
      for (final supported in supportedLocales) {
        if (serverLang == supported.languageCode) return supported;
      }
    }

    final systemLocale = ui.PlatformDispatcher.instance.locale;
    for (final supported in supportedLocales) {
      if (systemLocale.languageCode == supported.languageCode) {
        return supported;
      }
    }
    return const Locale('en');
  }

  /// Whether the current locale is RTL.
  bool get isRtl => effectiveLocale.languageCode == 'he';

  /// Text direction for the current locale.
  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// Apply the current locale's messages to the global [m] accessor
  /// and notify listeners so the app rebuilds.
  void apply() {
    m = _messagesFor(effectiveLocale);
    notifyListeners();
  }

  /// Change locale, persist, and rebuild. This is the only path that bumps
  /// [revision] — a user-initiated switch is allowed to hard-reset the tree.
  Future<void> setLocale(String? localeCode) async {
    await PrefsService.instance.setLocale(localeCode);
    _revision++;
    apply();
  }

  static Messages _messagesFor(Locale locale) {
    switch (locale.languageCode) {
      case 'de':
        return de.MessagesDe();
      case 'es':
        return es.MessagesEs();
      case 'fr':
        return fr.MessagesFr();
      case 'he':
        return he.MessagesHe();
      case 'nn':
        return nn.MessagesNn();
      default:
        return Messages();
    }
  }
}
