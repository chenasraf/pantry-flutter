import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
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
  // A held queue waits on the user rather than the network, so it names what
  // they have to do instead of looking like a sync that is still running.
  if (status == SyncStatus.error) {
    final auth = AuthService.instance;
    if (auth.isUnauthorized.value) {
      return (
        icon: Icons.lock_outline,
        color: scheme.error,
        label: m.common.sessionExpiredTitle,
      );
    }
    if (auth.serverRedirect.value != null) {
      return (
        icon: Icons.swap_horiz,
        color: scheme.error,
        label: m.common.serverMovedTitle,
      );
    }
  }
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
    final auth = AuthService.instance;
    return ListenableBuilder(
      // Read by [syncStatusPresentation] to say why a held queue is held.
      listenable: Listenable.merge([auth.isUnauthorized, auth.serverRedirect]),
      builder: (context, _) => ValueListenableBuilder<SyncStatus>(
        valueListenable: manager.status,
        builder: (context, status, _) => ValueListenableBuilder<int>(
          valueListenable: manager.pendingCount,
          builder: (context, pending, _) => ValueListenableBuilder<bool>(
            valueListenable: manager.hasBacklog,
            builder: (context, hasBacklog, _) =>
                builder(context, status, pending, hasBacklog),
          ),
        ),
      ),
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

/// App-bar action that shows changes on their way to the server: a spinner
/// while the queue drains, a brief check once it has, and the offline or
/// error state while it can't. Unlike [SyncStatusAvatarBadge] it surfaces
/// every online flush, for screens whose edits give no other sign of landing
/// (a drag-to-reorder looks the same saved or not).
class SyncActivityIndicator extends StatefulWidget {
  const SyncActivityIndicator({super.key});

  /// How long the "saved" check stays up after the queue drains.
  @visibleForTesting
  static Duration doneDuration = const Duration(seconds: 2);

  @override
  State<SyncActivityIndicator> createState() => _SyncActivityIndicatorState();
}

class _SyncActivityIndicatorState extends State<SyncActivityIndicator> {
  final _manager = SyncManager.instance;
  bool _wasBusy = false;
  bool _showDone = false;
  Timer? _doneTimer;

  @override
  void initState() {
    super.initState();
    _wasBusy = _isBusy;
    _manager.status.addListener(_onChanged);
    _manager.pendingCount.addListener(_onChanged);
  }

  @override
  void dispose() {
    _doneTimer?.cancel();
    _manager.status.removeListener(_onChanged);
    _manager.pendingCount.removeListener(_onChanged);
    super.dispose();
  }

  bool get _isBusy =>
      _manager.pendingCount.value > 0 &&
      _manager.status.value == SyncStatus.syncing;

  /// Status and pending count notify separately, so a drain passes through a
  /// half-updated state (idle with one pending, or syncing with none). The
  /// busy flag is held across it and only a full drain turns it into "done".
  void _onChanged() {
    final status = _manager.status.value;
    final drained =
        _manager.pendingCount.value == 0 && status == SyncStatus.idle;
    if (_isBusy) {
      _wasBusy = true;
      _doneTimer?.cancel();
      _showDone = false;
    } else if (_wasBusy && drained) {
      _wasBusy = false;
      _showDone = true;
      _doneTimer?.cancel();
      _doneTimer = Timer(SyncActivityIndicator.doneDuration, () {
        if (mounted) setState(() => _showDone = false);
      });
    } else if (status == SyncStatus.offline || status == SyncStatus.error) {
      _wasBusy = false;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = _manager.status.value;
    final pending = _manager.pendingCount.value;

    final Widget? content;
    if (status == SyncStatus.error) {
      content = IconButton(
        key: const ValueKey('error'),
        icon: Icon(Icons.sync_problem, color: scheme.error),
        tooltip: '${m.sync.syncError} · ${m.sync.retry}',
        onPressed: _manager.flushNow,
      );
    } else if (status == SyncStatus.offline && pending > 0) {
      content = Tooltip(
        key: const ValueKey('offline'),
        message: m.sync.pendingChanges(pending),
        child: _slot(Icon(Icons.cloud_off_outlined, color: scheme.secondary)),
      );
    } else if (_isBusy) {
      content = Tooltip(
        key: const ValueKey('busy'),
        message: m.sync.syncing,
        child: _slot(
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.primary,
            ),
          ),
        ),
      );
    } else if (_showDone) {
      content = Tooltip(
        key: const ValueKey('done'),
        message: m.sync.synced,
        child: _slot(Icon(Icons.cloud_done_outlined, color: scheme.primary)),
      );
    } else {
      content = null;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: content ?? const SizedBox.shrink(key: ValueKey('none')),
    );
  }

  /// Sized like an [IconButton] so the actions beside it don't shift when the
  /// state changes between a tappable and a non-tappable one.
  Widget _slot(Widget child) =>
      SizedBox.square(dimension: 48, child: Center(child: child));
}
