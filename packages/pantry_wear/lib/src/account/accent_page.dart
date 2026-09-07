import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/theming_service.dart';

import '../widgets/wear_choice_page.dart';

/// How the accent setting is said, wherever it is said.
String accentLabel(bool? useServerColor) => switch (useServerColor) {
  null => m.wear.followPhone,
  true => m.wear.accentServer,
  false => m.wear.accentApp,
};

/// Which accent the watch paints with.
///
/// The watch has no path to a Nextcloud theme of its own — nothing here fetches
/// one — so the colour and the opt-out over it both arrive from the phone. This
/// is parity rather than necessity: a watch on the default blue is perfectly
/// usable where a watch in the wrong language is not. It exists so that every
/// carried field answers to the same precedence rule instead of two.
class AccentPage extends StatelessWidget {
  const AccentPage({super.key});

  @override
  Widget build(BuildContext context) => WearChoicePage<bool?>(
    selected: ThemingService.instance.useServerThemeColorPref,
    empty: '',
    onSelected: ThemingService.instance.setUseServerThemeColor,
    choices: [
      WearChoice(
        value: null,
        label: accentLabel(null),
        icon: Icons.phone_iphone,
      ),
      WearChoice(
        value: true,
        label: accentLabel(true),
        icon: Icons.cloud_outlined,
      ),
      WearChoice(
        value: false,
        label: accentLabel(false),
        icon: Icons.palette_outlined,
      ),
    ],
  );
}
