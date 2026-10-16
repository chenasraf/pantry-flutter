import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry/services/background_notification_task.dart';
import 'package:pantry/services/local_notifications_service.dart';
import 'package:pantry/services/unified_push_service.dart';
import 'package:pantry/utils/app_toast.dart';
import 'package:pantry/views/settings/settings_tiles.dart';

enum _Delivery { polling, unifiedPush }

const _distributorsUrl = 'https://unifiedpush.org/users/distributors/';

/// How long the connecting dialog waits before suggesting what to check.
const _slowConnect = Duration(seconds: 15);

String _distributorName(UnifiedPushService push) =>
    push.distributorLabel ?? push.distributor ?? m.settings.deliveryUnifiedPush;

class NotificationSettingsView extends StatefulWidget {
  /// Drawn beside the settings sidebar rather than as a screen of its own, so
  /// the row naming it is already on show and a bar repeating that name is
  /// chrome for nothing.
  final bool embedded;

  const NotificationSettingsView({super.key, this.embedded = false});

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  static const _pollOptions = [15, 30, 60, 120, 360];

  @override
  void initState() {
    super.initState();
    UnifiedPushService.instance.addListener(_onPushChanged);
  }

  @override
  void dispose() {
    UnifiedPushService.instance.removeListener(_onPushChanged);
    super.dispose();
  }

  void _onPushChanged() => setState(() {});

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

    await applyNotificationDelivery();
    if (!value) await LocalNotificationsService.instance.cancelAll();
  }

  Future<void> _setPollInterval(int? minutes) async {
    if (minutes == null) return;
    final prefs = context.read<PrefsService>();
    if (minutes == prefs.pollIntervalMinutes) return;
    await prefs.setPollIntervalMinutes(minutes);
    if (prefs.notificationsEnabled &&
        !await UnifiedPushService.instance.isActive()) {
      await rescheduleBackgroundNotificationPoll();
    }
  }

  Future<void> _setDelivery(_Delivery? delivery) async {
    final push = UnifiedPushService.instance;
    if (delivery == _Delivery.polling) {
      await push.disable();
      return;
    }
    if (delivery != _Delivery.unifiedPush) return;

    final distributors = await push.distributorApps();
    if (!mounted) return;
    final String? distributor;
    if (distributors.isEmpty) {
      await _showNoDistributorDialog();
      return;
    } else if (distributors.length == 1) {
      distributor = distributors.single.package;
    } else {
      distributor = await _pickDistributor(distributors);
    }
    if (distributor == null) return;

    final failure = await push.enable(distributor);
    if (!mounted) return;
    if (failure != null) {
      _showFailure(failure);
      return;
    }
    if (push.status == UnifiedPushStatus.connecting) {
      final status = await showDialog<UnifiedPushStatus>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _ConnectingDialog(),
      );
      if (status == null) await push.disable();
    }
    if (!mounted) return;
    if (push.status == UnifiedPushStatus.active) {
      showAppToast(message: m.settings.deliveryEnabled);
    } else if (push.status == UnifiedPushStatus.failed) {
      _showFailure(push.failure ?? UnifiedPushFailure.registrationFailed);
    }
  }

  void _showFailure(UnifiedPushFailure failure) => showAppToast(
    message: switch (failure) {
      UnifiedPushFailure.serverUnsupported => m.settings.serverNoWebPush,
      UnifiedPushFailure.noDistributor => m.settings.deliveryNoDistributor,
      UnifiedPushFailure.registrationFailed => m.settings.deliveryFailed,
    },
    kind: ToastKind.error,
  );

  Future<void> _showSetupGuide() => showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final steps = [
        m.settings.pushSetupStep1,
        m.settings.pushSetupStep2,
        m.settings.pushSetupStep3,
      ];
      return AlertDialog(
        title: Text(m.settings.pushSetup),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, step) in steps.indexed)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        child: Text(
                          '${i + 1}',
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(step)),
                    ],
                  ),
                ),
              Text(
                m.settings.pushSetupNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse(_distributorsUrl),
              mode: LaunchMode.externalApplication,
            ),
            child: Text(m.settings.learnMore),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(m.common.closeDialog),
          ),
        ],
      );
    },
  );

  Future<void> _showNoDistributorDialog() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(m.settings.noDistributorTitle),
      content: Text(m.settings.noDistributorBody),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            launchUrl(
              Uri.parse(_distributorsUrl),
              mode: LaunchMode.externalApplication,
            );
          },
          child: Text(m.settings.learnMore),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(m.common.closeDialog),
        ),
      ],
    ),
  );

  Future<String?> _pickDistributor(List<DistributorApp> distributors) =>
      showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(m.settings.chooseDistributor),
          contentPadding: const EdgeInsetsDirectional.only(top: 12, bottom: 16),
          children: [
            for (final d in distributors)
              ListTile(
                contentPadding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                leading: d.icon != null
                    ? Image.memory(d.icon!, width: 40, height: 40)
                    : const Icon(Icons.apps, size: 40),
                title: Text(d.label),
                subtitle: Text(d.package),
                onTap: () => Navigator.of(context).pop(d.package),
              ),
          ],
        ),
      );

  String _pollIntervalLabel(int minutes) => switch (minutes) {
    15 => m.settings.pollInterval15m,
    30 => m.settings.pollInterval30m,
    60 => m.settings.pollInterval1h,
    120 => m.settings.pollInterval2h,
    360 => m.settings.pollInterval6h,
    _ => '$minutes min',
  };

  String _deliveryLabel(_Delivery delivery) => switch (delivery) {
    _Delivery.polling => m.settings.deliveryPolling,
    _Delivery.unifiedPush => m.settings.deliveryUnifiedPush,
  };

  String _deliveryStatus(UnifiedPushService push, bool enabled) {
    if (!enabled) return m.settings.deliveryPollingBody;
    final name = _distributorName(push);
    return switch (push.status) {
      UnifiedPushStatus.active => m.settings.deliveryActive(name),
      UnifiedPushStatus.failed => switch (push.failure) {
        UnifiedPushFailure.noDistributor => m.settings.deliveryNoDistributor,
        UnifiedPushFailure.serverUnsupported =>
          m.settings.deliveryServerUnsupported,
        _ => m.settings.deliveryFailed,
      },
      _ => m.settings.deliveryConnecting(name),
    };
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PrefsService>();
    final notificationsEnabled = prefs.notificationsEnabled;
    final pushEnabled = prefs.unifiedPushEnabled;
    final push = UnifiedPushService.instance;

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: Text(m.settings.notificationsSection)),
      body: SettingsList(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(m.settings.enableNotifications),
            subtitle: Text(m.settings.enableNotificationsBody),
            value: notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          if (UnifiedPushService.isSupported)
            DropdownSettingTile<_Delivery>(
              icon: Icons.bolt_outlined,
              title: m.settings.delivery,
              subtitle: _deliveryStatus(push, pushEnabled),
              value: pushEnabled ? _Delivery.unifiedPush : _Delivery.polling,
              options: _Delivery.values,
              labelOf: _deliveryLabel,
              onChanged: _setDelivery,
              enabled: notificationsEnabled,
            ),
          if (UnifiedPushService.isSupported)
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text(m.settings.pushSetup),
              subtitle: Text(m.settings.pushSetupSubtitle),
              onTap: _showSetupGuide,
            ),
          DropdownSettingTile<int>(
            icon: Icons.timer_outlined,
            title: m.settings.pollInterval,
            subtitle: _pollIntervalLabel(prefs.pollIntervalMinutes),
            value: prefs.pollIntervalMinutes,
            options: _pollOptions,
            labelOf: _pollIntervalLabel,
            onChanged: _setPollInterval,
            enabled:
                notificationsEnabled &&
                !(pushEnabled && push.status == UnifiedPushStatus.active),
          ),
        ],
      ),
    );
  }
}

/// Waits on the distributor and the server, closing with the status they
/// settle on, or with null when cancelled.
class _ConnectingDialog extends StatefulWidget {
  const _ConnectingDialog();

  @override
  State<_ConnectingDialog> createState() => _ConnectingDialogState();
}

class _ConnectingDialogState extends State<_ConnectingDialog> {
  final _push = UnifiedPushService.instance;
  Timer? _slowTimer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _push.addListener(_onChanged);
    _slowTimer = Timer(_slowConnect, () {
      if (mounted) setState(() => _slow = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _onChanged());
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _push.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    final status = _push.status;
    if (status == UnifiedPushStatus.connecting) {
      setState(() {});
      return;
    }
    _push.removeListener(_onChanged);
    Navigator.of(context).pop(status);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _distributorName(_push);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              m.settings.deliveryConnecting(name),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (_slow) ...[
              const SizedBox(height: 12),
              Text(
                m.settings.connectingSlow(name),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _push.removeListener(_onChanged);
              Navigator.of(context).pop();
            },
            child: Text(m.common.cancel),
          ),
        ],
      ),
    );
  }
}
