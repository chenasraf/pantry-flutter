import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/messages.i18n.dart';
import 'package:pantry/messages_he.i18n.dart' as he;
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/prefs_service.dart';

/// Supported app locales.
const supportedLocales = [Locale('en'), Locale('he')];

class LocaleService extends ChangeNotifier {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  /// Resolve the effective locale from the user preference, or auto-detect
  /// from the Nextcloud server language, then the system locale.
  Locale get effectiveLocale {
    final pref = PrefsService.instance.locale;
    if (pref != null) return Locale(pref);

    // Try the Nextcloud server's user language first
    final serverLang = AuthService.instance.serverLanguage;
    if (serverLang != null) {
      for (final supported in supportedLocales) {
        if (serverLang == supported.languageCode) return supported;
      }
    }

    // Fall back to system locale
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

  /// Change locale, persist, and rebuild.
  Future<void> setLocale(String? localeCode) async {
    await PrefsService.instance.setLocale(localeCode);
    apply();
  }

  static Messages _messagesFor(Locale locale) {
    switch (locale.languageCode) {
      case 'he':
        return he.MessagesHe();
      default:
        return Messages();
    }
  }
}
