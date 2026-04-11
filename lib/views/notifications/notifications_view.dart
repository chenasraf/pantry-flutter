import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/notification.dart';
import 'package:pantry/services/deep_link_service.dart';
import 'notifications_controller.dart';

class NotificationsView extends StatefulWidget {
  final NotificationsController controller;

  const NotificationsView({super.key, required this.controller});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  @override
  void initState() {
    super.initState();
    widget.controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.controller,
      child: const _NotificationsBody(),
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody();

  void _openNotification(BuildContext context, NcNotification n) {
    final target = n.target;
    if (target == null) return;
    final tab = switch (target) {
      NotificationTarget.checklists => 0,
      NotificationTarget.photos => 1,
      NotificationTarget.notes => 2,
    };
    DeepLinkService.instance.push(DeepLink(tabIndex: tab, houseId: n.houseId));
    // Pop back to home so it consumes the deep link.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(m.notifications.title),
        actions: [
          if (controller.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: m.notifications.dismissAll,
              onPressed: controller.dismissAll,
            ),
        ],
      ),
      body: _buildBody(context, controller),
    );
  }

  Widget _buildBody(BuildContext context, NotificationsController controller) {
    if (controller.isLoading && controller.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null && controller.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(m.notifications.failedToLoad, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.load,
                child: Text(m.common.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          children: [
            const SizedBox(height: 100),
            Center(child: Text(m.notifications.empty)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.separated(
        itemCount: controller.notifications.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final n = controller.notifications[index];
          return _NotificationTile(
            notification: n,
            onDismiss: () => controller.dismiss(n),
            onTap: () => _openNotification(context, n),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NcNotification notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(notification.notificationId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
      ),
      child: ListTile(
        onTap: notification.target != null ? onTap : null,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.notifications,
            color: theme.colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          notification.subject,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: notification.message.isNotEmpty
            ? Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Text(
          _formatRelative(notification.parsedDatetime),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String _formatRelative(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inMinutes < 1) return m.notifications.justNow;
    if (diff.inHours < 1) return m.notifications.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return m.notifications.hoursAgo(diff.inHours);
    return m.notifications.daysAgo(diff.inDays);
  }
}
