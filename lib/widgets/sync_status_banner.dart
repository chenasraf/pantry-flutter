import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/sync/sync_manager.dart';

/// Compact bar shown above the main content when there are pending sync
/// ops or a sync error. Also the canonical mount point for
/// `flutter_offline`'s OfflineBuilder: it feeds connectivity state into
/// [SyncManager] so the queue can flush as soon as the device reconnects.
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return OfflineBuilder(
      connectivityBuilder: (context, connectivity, child) {
        final online = !connectivity.contains(ConnectivityResult.none);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SyncManager.instance.setOnline(online);
        });
        return child;
      },
      // If connectivity_plus can't initialize (test, headless), assume
      // online and let the queue flush attempts surface real errors.
      errorBuilder: (_) => const _StatusListener(),
      child: const _StatusListener(),
    );
  }
}

class _StatusListener extends StatelessWidget {
  const _StatusListener();

  @override
  Widget build(BuildContext context) {
    final manager = SyncManager.instance;
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: manager.status,
      builder: (context, status, _) {
        return ValueListenableBuilder<int>(
          valueListenable: manager.pendingCount,
          builder: (context, pending, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: manager.hasBacklog,
              builder: (context, hasBacklog, _) {
                // Only surface the banner when there's something the user
                // should care about: an unsynced backlog from an offline
                // period, or a sync error. A single online op-flush keeps
                // the banner hidden so checking a box stays silent.
                final shouldShow = hasBacklog || status == SyncStatus.error;
                if (!shouldShow) return const SizedBox.shrink();
                return _Bar(status: status, pending: pending);
              },
            );
          },
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  final SyncStatus status;
  final int pending;
  const _Bar({required this.status, required this.pending});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg, icon, label) = switch (status) {
      SyncStatus.offline => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.cloud_off_outlined,
        pending > 0 ? m.sync.pendingChanges(pending) : m.sync.offline,
      ),
      SyncStatus.syncing => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.sync,
        m.sync.syncing,
      ),
      SyncStatus.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline,
        m.sync.syncError,
      ),
      SyncStatus.idle => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.cloud_done_outlined,
        m.sync.pendingChanges(pending),
      ),
    };

    return Material(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: fg),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (status == SyncStatus.error)
                TextButton(
                  onPressed: () => SyncManager.instance.flushNow(),
                  style: TextButton.styleFrom(foregroundColor: fg),
                  child: Text(m.sync.retry),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
