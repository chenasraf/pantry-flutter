import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/services/background_notification_task.dart';
import 'package:pantry/services/local_notifications_service.dart';
import 'package:pantry/services/locale_service.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/services/theming_service.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late String? _selectedLocale;
  late String? _selectedTheme;

  static const _pollOptions = [15, 30, 60, 120, 360];
  static const _categorySpacingOptions = ['disabled', 'space', 'divider'];

  @override
  void initState() {
    super.initState();
    _selectedLocale = PrefsService.instance.locale;
    _selectedTheme = PrefsService.instance.themeMode;
  }

  Future<void> _setTapRowToComplete(bool value) async {
    await context.read<PrefsService>().setChecklistTapRowToToggle(value);
  }

  Future<void> _setCategorySpacing(String? value) async {
    if (value == null) return;
    final prefs = context.read<PrefsService>();
    if (value == prefs.checklistCategorySpacing) return;
    await prefs.setChecklistCategorySpacing(value);
  }

  String _categorySpacingLabel(String value) => switch (value) {
    'space' => m.settings.categorySpacingNames.space,
    'divider' => m.settings.categorySpacingNames.divider,
    _ => m.settings.categorySpacingNames.disabled,
  };

  // -- Language --

  Future<void> _setLocale(String? value) async {
    await LocaleService.instance.setLocale(value);
    if (!mounted) return;
    setState(() => _selectedLocale = value);
  }

  String _localeLabel(String? code) => switch (code) {
    'en' => m.settings.languageNames.english,
    'de' => m.settings.languageNames.german,
    'es' => m.settings.languageNames.spanish,
    'fr' => m.settings.languageNames.french,
    'he' => m.settings.languageNames.hebrew,
    _ => m.settings.languageNames.system,
  };

  // -- Theme --

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

  // -- Notifications --

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await LocalNotificationsService.instance
          .requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(m.settings.permissionDenied)));
        }
        return;
      }
    }

    if (!mounted) return;
    await context.read<PrefsService>().setNotificationsEnabled(value);

    if (value) {
      await registerBackgroundNotificationPoll();
    } else {
      await cancelBackgroundNotificationPoll();
      await LocalNotificationsService.instance.cancelAll();
    }
  }

  Future<void> _setPollInterval(int? minutes) async {
    if (minutes == null) return;
    final prefs = context.read<PrefsService>();
    if (minutes == prefs.pollIntervalMinutes) return;
    await prefs.setPollIntervalMinutes(minutes);
    if (prefs.notificationsEnabled) {
      await rescheduleBackgroundNotificationPoll();
    }
  }

  String _pollIntervalLabel(int minutes) => switch (minutes) {
    15 => m.settings.pollInterval15m,
    30 => m.settings.pollInterval30m,
    60 => m.settings.pollInterval1h,
    120 => m.settings.pollInterval2h,
    360 => m.settings.pollInterval6h,
    _ => '$minutes min',
  };

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PrefsService>();
    final notificationsEnabled = prefs.notificationsEnabled;
    final pollIntervalMinutes = prefs.pollIntervalMinutes;
    final tapRowToComplete = prefs.checklistTapRowToToggle;
    final categorySpacing = prefs.checklistCategorySpacing;

    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(m.settings.title),
      ),
      body: ListView(
        children: [
          // -- General --
          _SectionHeader(m.settings.generalSection),
          ListTile(
            title: Text(m.settings.language),
            subtitle: Text(_localeLabel(_selectedLocale)),
            trailing: DropdownButton<String?>(
              value: _selectedLocale,
              onChanged: (v) => _setLocale(v),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(m.settings.languageNames.system),
                ),
                DropdownMenuItem<String?>(
                  value: 'en',
                  child: Text(m.settings.languageNames.english),
                ),
                DropdownMenuItem<String?>(
                  value: 'de',
                  child: Text(m.settings.languageNames.german),
                ),
                DropdownMenuItem<String?>(
                  value: 'es',
                  child: Text(m.settings.languageNames.spanish),
                ),
                DropdownMenuItem<String?>(
                  value: 'fr',
                  child: Text(m.settings.languageNames.french),
                ),
                DropdownMenuItem<String?>(
                  value: 'he',
                  child: Text(m.settings.languageNames.hebrew),
                ),
              ],
            ),
          ),

          ListTile(
            title: Text(m.settings.theme),
            subtitle: Text(_themeLabel(_selectedTheme)),
            trailing: DropdownButton<String?>(
              value: _selectedTheme,
              onChanged: (v) => _setTheme(v),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(m.settings.themeNames.system),
                ),
                DropdownMenuItem<String?>(
                  value: 'light',
                  child: Text(m.settings.themeNames.light),
                ),
                DropdownMenuItem<String?>(
                  value: 'dark',
                  child: Text(m.settings.themeNames.dark),
                ),
              ],
            ),
          ),

          // -- Interface --
          _SectionHeader(m.settings.interfaceSection),
          SwitchListTile(
            title: Text(m.settings.tapRowToComplete),
            subtitle: Text(m.settings.tapRowToCompleteBody),
            value: tapRowToComplete,
            onChanged: _setTapRowToComplete,
          ),
          ListTile(
            title: Text(m.settings.categorySpacing),
            subtitle: Text(m.settings.categorySpacingBody),
            trailing: DropdownButton<String>(
              value: categorySpacing,
              onChanged: _setCategorySpacing,
              items: [
                for (final option in _categorySpacingOptions)
                  DropdownMenuItem(
                    value: option,
                    child: Text(_categorySpacingLabel(option)),
                  ),
              ],
            ),
          ),

          // -- Notifications --
          _SectionHeader(m.settings.notificationsSection),
          SwitchListTile(
            title: Text(m.settings.enableNotifications),
            subtitle: Text(m.settings.enableNotificationsBody),
            value: notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          ListTile(
            enabled: notificationsEnabled,
            title: Text(m.settings.pollInterval),
            subtitle: Text(_pollIntervalLabel(pollIntervalMinutes)),
            trailing: DropdownButton<int>(
              value: pollIntervalMinutes,
              onChanged: notificationsEnabled ? _setPollInterval : null,
              items: [
                for (final minutes in _pollOptions)
                  DropdownMenuItem(
                    value: minutes,
                    child: Text(_pollIntervalLabel(minutes)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
