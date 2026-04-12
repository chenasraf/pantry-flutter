import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/services/background_notification_task.dart';
import 'package:pantry/services/local_notifications_service.dart';
import 'package:pantry/services/locale_service.dart';
import 'package:pantry/services/prefs_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late bool _notificationsEnabled;
  late int _pollIntervalMinutes;
  late String? _selectedLocale;

  static const _pollOptions = [15, 30, 60, 120, 360];

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = PrefsService.instance.notificationsEnabled;
    _pollIntervalMinutes = PrefsService.instance.pollIntervalMinutes;
    _selectedLocale = PrefsService.instance.locale;
  }

  // -- Language --

  Future<void> _setLocale(String? value) async {
    await LocaleService.instance.setLocale(value);
    if (!mounted) return;
    setState(() => _selectedLocale = value);
  }

  String _localeLabel(String? code) => switch (code) {
    'en' => m.settings.languageNames.english,
    'he' => m.settings.languageNames.hebrew,
    _ => m.settings.languageNames.system,
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

    await PrefsService.instance.setNotificationsEnabled(value);
    setState(() => _notificationsEnabled = value);

    if (value) {
      await registerBackgroundNotificationPoll();
    } else {
      await cancelBackgroundNotificationPoll();
      await LocalNotificationsService.instance.cancelAll();
    }
  }

  Future<void> _setPollInterval(int? minutes) async {
    if (minutes == null || minutes == _pollIntervalMinutes) return;
    await PrefsService.instance.setPollIntervalMinutes(minutes);
    setState(() => _pollIntervalMinutes = minutes);
    if (_notificationsEnabled) {
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
    return Scaffold(
      appBar: AppBar(title: Text(m.settings.title)),
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
                  value: 'he',
                  child: Text(m.settings.languageNames.hebrew),
                ),
              ],
            ),
          ),

          // -- Notifications --
          _SectionHeader(m.settings.notificationsSection),
          SwitchListTile(
            title: Text(m.settings.enableNotifications),
            subtitle: Text(m.settings.enableNotificationsBody),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          ListTile(
            enabled: _notificationsEnabled,
            title: Text(m.settings.pollInterval),
            subtitle: Text(_pollIntervalLabel(_pollIntervalMinutes)),
            trailing: DropdownButton<int>(
              value: _pollIntervalMinutes,
              onChanged: _notificationsEnabled ? _setPollInterval : null,
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
