import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/services/background_notification_task.dart';
import 'package:pantry/services/local_notifications_service.dart';
import 'package:pantry/services/prefs_service.dart';

class NotificationsIntroView extends StatefulWidget {
  final VoidCallback onDone;

  const NotificationsIntroView({super.key, required this.onDone});

  @override
  State<NotificationsIntroView> createState() => _NotificationsIntroViewState();
}

class _NotificationsIntroViewState extends State<NotificationsIntroView> {
  bool _working = false;

  Future<void> _enable() async {
    setState(() => _working = true);
    final granted = await LocalNotificationsService.instance
        .requestPermission();
    if (!mounted) return;

    if (!granted) {
      setState(() => _working = false);
      await _showPermissionDeniedDialog();
      await _complete(enabled: false);
      return;
    }

    await PrefsService.instance.setNotificationsEnabled(true);
    await registerBackgroundNotificationPoll();
    await _complete(enabled: true);
  }

  Future<void> _skip() async {
    await PrefsService.instance.setNotificationsEnabled(false);
    await _complete(enabled: false);
  }

  Future<void> _complete({required bool enabled}) async {
    await PrefsService.instance.setNotificationsIntroSeen(true);
    if (mounted) widget.onDone();
  }

  Future<void> _showPermissionDeniedDialog() async {
    final intro = m.notificationsIntro;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(intro.permissionDeniedTitle),
        content: Text(intro.permissionDeniedBody),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(intro.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intro = m.notificationsIntro;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          size: 56,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        intro.title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        intro.body,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      _Bullet(icon: Icons.group_outlined, text: intro.bullet1),
                      const SizedBox(height: 12),
                      _Bullet(icon: Icons.dns_outlined, text: intro.bullet2),
                      const SizedBox(height: 12),
                      _Bullet(
                        icon: Icons.schedule_outlined,
                        text: intro.bullet3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _working ? null : _enable,
                icon: _working
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.notifications_active),
                label: Text(intro.enableButton),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _working ? null : _skip,
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(intro.skipButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Bullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
