import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry/services/background_notification_task.dart';
import 'package:pantry/services/local_notifications_service.dart';
import 'package:pantry/utils/app_toast.dart';
import 'package:pantry/views/settings/settings_tiles.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  static const _pollOptions = [15, 30, 60, 120, 360];

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await LocalNotificationsService.instance
          .requestPermission();
      if (!granted) {
        if (mounted) {
          showAppToast(
            message: m.settings.permissionDenied,
            kind: ToastKind.error,
          );
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

    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(m.settings.notificationsSection),
      ),
      body: SettingsList(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(m.settings.enableNotifications),
            subtitle: Text(m.settings.enableNotificationsBody),
            value: notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          DropdownSettingTile<int>(
            icon: Icons.timer_outlined,
            title: m.settings.pollInterval,
            subtitle: _pollIntervalLabel(prefs.pollIntervalMinutes),
            value: prefs.pollIntervalMinutes,
            options: _pollOptions,
            labelOf: _pollIntervalLabel,
            onChanged: _setPollInterval,
            enabled: notificationsEnabled,
          ),
        ],
      ),
    );
  }
}
