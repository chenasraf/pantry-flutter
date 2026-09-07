import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/locale_service.dart';
import 'package:pantry_core/services/prefs_service.dart';

import '../widgets/wear_choice_page.dart';

/// How the language setting is said, wherever it is said. Endonyms rather than
/// translated names: a wearer looking for their own language reads it in that
/// language, whatever the watch is currently drawing in.
String languageLabel(String? code) =>
    languageNativeNames[code] ?? m.wear.followPhone;

/// What language the watch draws in.
///
/// Following the phone is the first option and the one a watch starts on,
/// because the phone is where this wearer already answered the question. It
/// stays an option rather than becoming a one-way door: a choice made here
/// outranks the phone permanently, and coming back to *Follow phone* is how
/// that is undone.
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) => WearChoicePage<String?>(
    selected: PrefsService.instance.locale,
    empty: '',
    onSelected: LocaleService.instance.setLocale,
    choices: [
      WearChoice(
        value: null,
        label: m.wear.followPhone,
        icon: Icons.phone_iphone,
      ),
      for (final locale in supportedLocales)
        WearChoice(
          value: locale.languageCode,
          label: languageLabel(locale.languageCode),
          icon: Icons.language,
        ),
    ],
  );
}
