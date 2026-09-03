import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/sync/sync_manager.dart';

/// How a sync status should be presented — icon, accent colour and label.
/// Null means there is nothing the user needs to see.
typedef SyncStatusPresentation = ({IconData icon, Color color, String label});

/// Resolve the current sync state into a presentation, or null when it should
/// stay hidden. Surface only an unsynced backlog from an offline period or a
/// sync error — a single online op-flush stays silent.
SyncStatusPresentation? syncStatusPresentation(
  BuildContext context, {
  required SyncStatus status,
  required int pending,
  required bool hasBacklog,
}) {
  final shouldShow = hasBacklog || status == SyncStatus.error;
  if (!shouldShow) return null;
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    SyncStatus.offline => (
      icon: Icons.cloud_off_outlined,
      color: scheme.secondary,
      label: pending > 0 ? m.sync.pendingChanges(pending) : m.sync.offline,
    ),
    SyncStatus.syncing => (
      icon: Icons.sync,
      color: scheme.primary,
      label: m.sync.syncing,
    ),
    SyncStatus.error => (
      icon: Icons.error_outline,
      color: scheme.error,
      label: m.sync.syncError,
    ),
    SyncStatus.idle => (
      icon: Icons.cloud_done_outlined,
      color: scheme.secondary,
      label: m.sync.pendingChanges(pending),
    ),
  };
}

/// Rebuilds [builder] whenever the sync status, pending count or backlog flag
/// changes. Keeps the three [ValueListenableBuilder]s in one place so callers
/// (avatar badge, menu tile) don't each re-nest them.
class SyncStatusBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    SyncStatus status,
    int pending,
    bool hasBacklog,
  )
  builder;

  const SyncStatusBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final manager = SyncManager.instance;
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: manager.status,
      builder: (context, status, _) => ValueListenableBuilder<int>(
        valueListenable: manager.pendingCount,
        builder: (context, pending, _) => ValueListenableBuilder<bool>(
          valueListenable: manager.hasBacklog,
          builder: (context, hasBacklog, _) =>
              builder(context, status, pending, hasBacklog),
        ),
      ),
    );
  }
}

/// Invisible widget that feeds `flutter_offline`'s connectivity signal into
/// [SyncManager] so the queue flushes as soon as the device reconnects — the
/// connectivity feed needs a mount point in the tree.
class SyncConnectivityListener extends StatelessWidget {
  const SyncConnectivityListener({super.key});

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
      // If connectivity_plus can't initialize (test, headless), assume online
      // and let the queue's flush attempts surface any real errors.
      errorBuilder: (_) => const SizedBox.shrink(),
      child: const SizedBox.shrink(),
    );
  }
}

/// Overlays a small status dot on the bottom-end corner of [child] (the user
/// avatar) whenever there's a sync state worth surfacing. [ringColor] should
/// match the surface the avatar sits on so the dot reads as separate from it.
class SyncStatusAvatarBadge extends StatelessWidget {
  final Widget child;
  final Color ringColor;

  const SyncStatusAvatarBadge({
    super.key,
    required this.child,
    required this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    return SyncStatusBuilder(
      builder: (context, status, pending, hasBacklog) {
        final info = syncStatusPresentation(
          context,
          status: status,
          pending: pending,
          hasBacklog: hasBacklog,
        );
        if (info == null) return child;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            PositionedDirectional(
              bottom: -1,
              end: -1,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: ringColor,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: info.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    info.icon,
                    size: 9,
                    color: _onColor(context, info.color),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _onColor(BuildContext context, Color color) {
    final scheme = Theme.of(context).colorScheme;
    if (color == scheme.error) return scheme.onError;
    if (color == scheme.primary) return scheme.onPrimary;
    return scheme.onSecondary;
  }
}
