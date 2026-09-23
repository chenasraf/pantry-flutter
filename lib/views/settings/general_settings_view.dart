import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/locale_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/theming_service.dart';
import 'package:pantry/views/settings/settings_tiles.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';

class GeneralSettingsView extends StatefulWidget {
  /// Drawn beside the settings sidebar rather than as a screen of its own, so
  /// the row naming it is already on show and a bar repeating that name is
  /// chrome for nothing.
  final bool embedded;

  const GeneralSettingsView({super.key, this.embedded = false});

  @override
  State<GeneralSettingsView> createState() => _GeneralSettingsViewState();
}

class _GeneralSettingsViewState extends State<GeneralSettingsView> {
  late String? _selectedLocale;
  late String? _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedLocale = PrefsService.instance.locale;
    _selectedTheme = PrefsService.instance.themeMode;
  }

  Future<void> _setLocale(String? value) async {
    await LocaleService.instance.setLocale(value);
    if (!mounted) return;
    setState(() => _selectedLocale = value);
  }

  String _localeLabel(String? code) =>
      languageNativeNames[code] ?? m.settings.systemLanguage;

  Future<void> _setTheme(String? value) async {
    await ThemingService.instance.setThemeMode(value);
    if (!mounted) return;
    setState(() => _selectedTheme = value);
  }

  String _themeLabel(String? code) => switch (code) {
    'light' => m.settings.themeNames.light,
    'dark' => m.settings.themeNames.dark,
    _ => m.settings.themeNames.system,
  };

  Future<void> _toggleUseServerThemeColor(bool value) async {
    await ThemingService.instance.setUseServerThemeColor(value);
  }

  Future<void> _toggleSyncLastHouse(bool value) async {
    await PrefsService.instance.setSyncLastHouse(value);
    // Switching it on makes the house on screen the account's, rather than
    // leaving the device to adopt a staler one on its next launch.
    final houseId = PrefsService.instance.lastHouseId;
    if (value && houseId != null) {
      await AuthService.instance.publishLastHouseId(houseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PrefsService>();

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              leading: appBarBackLeading(context),
              title: Text(m.settings.generalSection),
            ),
      body: SettingsList(
        children: [
          DropdownSettingTile<String?>(
            icon: Icons.language,
            title: m.settings.language,
            subtitle: _localeLabel(_selectedLocale),
            value: _selectedLocale,
            options: [
              null,
              for (final locale in supportedLocales) locale.languageCode,
            ],
            labelOf: _localeLabel,
            onChanged: _setLocale,
          ),
          DropdownSettingTile<String?>(
            icon: Icons.palette_outlined,
            title: m.settings.theme,
            subtitle: _themeLabel(_selectedTheme),
            value: _selectedTheme,
            options: const [null, 'light', 'dark'],
            labelOf: _themeLabel,
            onChanged: _setTheme,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.color_lens_outlined),
            title: Text(m.settings.useServerThemeColor),
            subtitle: Text(m.settings.useServerThemeColorBody),
            value: prefs.useServerThemeColor,
            onChanged: _toggleUseServerThemeColor,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.sync_outlined),
            title: Text(m.settings.syncLastHouse),
            subtitle: Text(m.settings.syncLastHouseBody),
            value: prefs.syncLastHouse,
            onChanged: _toggleSyncLastHouse,
          ),
        ],
      ),
    );
  }
}
