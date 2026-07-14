import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry/services/api_client.dart';
import 'package:pantry/services/cache_store.dart';
import 'package:pantry/sync/conflict_resolver.dart';
import 'package:pantry/sync/id_remap.dart';
import 'package:pantry/sync/sync_executor.dart';
import 'package:pantry/sync/sync_ids.dart';
import 'package:pantry/sync/sync_op.dart';
import 'package:pantry/sync/sync_queue.dart';

enum SyncStatus { idle, syncing, offline, error }

/// Emitted on the [SyncManager.onApplied] stream after each successful op,
/// so controllers can swap a temp record for the canonical server one.
class SyncOpApplied {
  final SyncOp op;
  final Object? entity;
  final int? boundRealId;

  const SyncOpApplied(this.op, this.entity, this.boundRealId);
}

/// Emitted when an op is dropped — either rejected by the conflict
/// resolver, exhausted retries, or rejected by a 4xx that isn't worth
/// retrying. Controllers can use this to refresh their view from the
/// server.
class SyncOpSkipped {
  final SyncOp op;
  final String reason;

  const SyncOpSkipped(this.op, this.reason);
}

class SyncManager {
  SyncManager._();
  static final SyncManager instance = SyncManager._();

  final SyncQueue _queue = SyncQueue(CacheStore('sync_queue.json'));
  final IdRemap _remap = IdRemap(CacheStore('sync_id_remap.json'));
  final SyncExecutor _executor = const SyncExecutor();
  final ConflictResolver _resolver = const ConflictResolver();

  final ValueNotifier<SyncStatus> status = ValueNotifier(SyncStatus.idle);
  final ValueNotifier<int> pendingCount = ValueNotifier(0);

  /// True when the current queue contents originated from an offline period —
  /// either an op enqueued while disconnected, or a queue persisted from a
  /// previous session. Drives whether the [SyncStatusBanner] surfaces the
  /// sync activity; a single-op flush while online does not flip this.
  /// Cleared once the queue fully drains.
  final ValueNotifier<bool> hasBacklog = ValueNotifier(false);

  final _appliedController = StreamController<SyncOpApplied>.broadcast();
  Stream<SyncOpApplied> get onApplied => _appliedController.stream;

  final _skippedController = StreamController<SyncOpSkipped>.broadcast();
  Stream<SyncOpSkipped> get onSkipped => _skippedController.stream;

  bool _online = true;
  bool _flushing = false;
  Timer? _retryTimer;
  bool _initialized = false;

  bool get isOnline => _online;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    // Loading persisted sync state runs on the pre-first-frame startup path
    // (main() awaits this). A corrupt or version-incompatible on-disk queue
    // must degrade to an empty queue rather than throw — an unhandled error
    // here aborts main() before runApp() and freezes the splash. Drop the
    // bad state and let the app start clean.
    try {
      await Future.wait([_queue.load(), _remap.load()]);
    } catch (e) {
      debugPrint('[SyncManager] Failed to load persisted sync state: $e');
      await _queue.clear();
      await _remap.clear();
    }
    SyncIds.seedTempIds(
      _queue.all().map((o) => o.tempEntityId).whereType<int>(),
    );
    pendingCount.value = _queue.length;
    if (!_queue.isEmpty) hasBacklog.value = true;
    status.value = _queue.isEmpty
        ? (_online ? SyncStatus.idle : SyncStatus.offline)
        : (_online ? SyncStatus.syncing : SyncStatus.offline);
    if (_online && !_queue.isEmpty) {
      unawaited(flushNow());
    }
  }

  /// Externally-supplied connectivity signal. The top-level
  /// `OfflineBuilder` from package:flutter_offline forwards changes here
  /// so the manager doesn't need to know how connectivity is detected.
  void setOnline(bool online) {
    final wasOnline = _online;
    _online = online;
    if (!online) {
      // Any unsynced work now becomes a backlog once we reconnect.
      if (!_queue.isEmpty) hasBacklog.value = true;
      status.value = SyncStatus.offline;
    } else if (!wasOnline) {
      if (!_queue.isEmpty) hasBacklog.value = true;
      unawaited(flushNow());
    } else if (_queue.isEmpty) {
      status.value = SyncStatus.idle;
    }
  }

  /// Clears the queue and id-remap. Called at logout.
  Future<void> reset() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    await _queue.clear();
    await _remap.clear();
    pendingCount.value = 0;
    hasBacklog.value = false;
    status.value = SyncStatus.idle;
  }

  Future<void> dispose() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    await _appliedController.close();
    await _skippedController.close();
  }

  // -- Public op helpers --

  /// Mint a fresh temp id for an optimistic create.
  int newTempId() => SyncIds.newTempEntityId();

  /// Ids of every checklist item in [houseId] that still has an un-acked op
  /// in the queue — both the real id (once known, via id-remap) and the
  /// original temp id, so an item matches whether or not its optimistic
  /// create has resolved yet. Controllers use this to keep optimistic state
  /// authoritative when a background fetch returns a snapshot that predates a
  /// pending op (the check-then-flicker-back race).
  Set<int> pendingItemIds(int houseId) {
    final out = <int>{};
    for (final raw in _queue.all()) {
      if (raw.entity != SyncEntity.checklistItem) continue;
      if (raw.houseId != houseId) continue;
      if (raw.op == SyncOpKind.batch) {
        // Batch ops address many items via the body — count both the temp and
        // (once bound) real ids so a mid-flight batch keeps its items pinned.
        for (final ids in [
          (raw.body['itemIds'] as List?)?.cast<int>(),
          (_remap.rewrite(raw).body['itemIds'] as List?)?.cast<int>(),
        ]) {
          if (ids != null) out.addAll(ids);
        }
        continue;
      }
      final id = _remap.rewrite(raw).effectiveEntityId;
      if (id != null) out.add(id);
      if (raw.tempEntityId != null) out.add(raw.tempEntityId!);
    }
    return out;
  }

  /// List ids in [houseId] that still have an un-acked op in the queue —
  /// either a list-level op (create/update/…) or an item op whose `parentId`
  /// names the list. Pre-caching uses this to skip only the lists whose cached
  /// snapshot would clobber a pending optimistic change, instead of bailing the
  /// whole warm-up when any op is queued (issue #92).
  ///
  /// Returns `null` when the queue holds a house-scoped batch op: those address
  /// items across lists via the body, so the affected lists can't be resolved
  /// cheaply and callers should treat every list as potentially pending.
  Set<int>? pendingListIds(int houseId) {
    final out = <int>{};
    for (final raw in _queue.all()) {
      if (raw.houseId != houseId) continue;
      final op = _remap.rewrite(raw);
      if (op.op == SyncOpKind.batch) return null;
      switch (op.entity) {
        case SyncEntity.checklistItem:
          final pid = op.parentId;
          if (pid != null) out.add(pid);
        case SyncEntity.checklistList:
          final id = op.effectiveEntityId;
          if (id != null) out.add(id);
          if (raw.tempEntityId != null) out.add(raw.tempEntityId!);
        case SyncEntity.category:
        case SyncEntity.note:
          break;
      }
    }
    return out;
  }

  /// Enqueue an op. Returns immediately. If online, kicks the flush loop.
  void enqueue(SyncOp op) {
    _queue.enqueue(op);
    pendingCount.value = _queue.length;
    if (_online) {
      unawaited(flushNow());
    } else {
      hasBacklog.value = true;
      status.value = SyncStatus.offline;
    }
  }

  /// Force a flush attempt. Safe to call concurrently.
  Future<void> flushNow() async {
    if (_flushing) return;
    if (_queue.isEmpty) {
      status.value = _online ? SyncStatus.idle : SyncStatus.offline;
      return;
    }
    _flushing = true;
    status.value = SyncStatus.syncing;
    try {
      _queue.merge();
      pendingCount.value = _queue.length;

      while (!_queue.isEmpty) {
        final raw = _queue.peek()!;
        final op = _remap.rewrite(raw);
        if (op.op != SyncOpKind.create &&
            op.tempEntityId != null &&
            op.entityId == null) {
          // References a temp id whose create hasn't resolved yet — retry
          // after the preceding create completes.
          break;
        }
        if (op.op == SyncOpKind.batch && _batchHasUnresolvedRefs(op)) {
          // A batch op still points at a temp item / list / category whose
          // create is ahead of it in the queue — wait for that to flush.
          break;
        }
        try {
          final result = await _executor.execute(op);
          int? bound;
          if (op.op == SyncOpKind.create &&
              op.tempEntityId != null &&
              result.entity != null) {
            final realId = serverIdOf(result.entity);
            if (realId != null) {
              _remap.bind(op.entity, op.tempEntityId!, realId);
              bound = realId;
              final rewritten = _queue
                  .all()
                  .map((q) => q.uuid == op.uuid ? q : _remap.rewrite(q))
                  .toList();
              _queue.replaceAll(rewritten);
            }
          }
          _queue.pop(op.uuid);
          pendingCount.value = _queue.length;
          _appliedController.add(SyncOpApplied(op, result.entity, bound));
        } on ApiException catch (e) {
          if (e.statusCode == 409) {
            _queue.pop(op.uuid);
            pendingCount.value = _queue.length;
            _skippedController.add(SyncOpSkipped(op, 'conflict'));
            continue;
          }
          if (e.statusCode == 404 &&
              (op.op == SyncOpKind.update ||
                  op.op == SyncOpKind.delete ||
                  op.op == SyncOpKind.toggle ||
                  op.op == SyncOpKind.restore ||
                  op.op == SyncOpKind.permanentDelete ||
                  op.op == SyncOpKind.archive ||
                  op.op == SyncOpKind.unarchive)) {
            _queue.pop(op.uuid);
            pendingCount.value = _queue.length;
            _skippedController.add(SyncOpSkipped(op, 'gone'));
            _resolver.shouldApply(
              op,
              serverUpdatedAt: null,
              serverDeletedAt: 0,
            );
            continue;
          }
          if (e.statusCode >= 400 && e.statusCode < 500) {
            debugPrint(
              '[SyncManager] dropping op ${op.uuid} on ${e.statusCode}: ${e.message}',
            );
            _queue.pop(op.uuid);
            pendingCount.value = _queue.length;
            _skippedController.add(SyncOpSkipped(op, 'http_${e.statusCode}'));
            continue;
          }
          _scheduleRetry(op, e.toString());
          return;
        } catch (e) {
          _scheduleRetry(op, e.toString());
          return;
        }
      }
      status.value = _online ? SyncStatus.idle : SyncStatus.offline;
      hasBacklog.value = false;
    } finally {
      _flushing = false;
    }
  }

  /// A rewritten batch op is dispatchable only once every id it references
  /// resolves to a real (non-negative) server id.
  bool _batchHasUnresolvedRefs(SyncOp op) {
    final ids = (op.body['itemIds'] as List?)?.cast<int>() ?? const [];
    if (ids.any((id) => id < 0)) return true;
    final target = op.body['targetListId'];
    if (target is int && target < 0) return true;
    final cat = op.body['categoryId'];
    if (cat is int && cat < 0) return true;
    return false;
  }

  void _scheduleRetry(SyncOp op, String error) {
    final attempt = op.attemptCount + 1;
    _queue.update(op.copyWith(attemptCount: attempt, lastError: error));
    status.value = SyncStatus.error;
    final delay = _backoff(attempt);
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (_online) unawaited(flushNow());
    });
  }

  Duration _backoff(int attempt) {
    const base = Duration(seconds: 1);
    const cap = Duration(minutes: 5);
    final ms = base.inMilliseconds * (1 << (attempt - 1).clamp(0, 8));
    final clamped = ms > cap.inMilliseconds ? cap.inMilliseconds : ms;
    return Duration(milliseconds: clamped);
  }

  // -- Test hooks --

  @visibleForTesting
  SyncQueue get queueForTest => _queue;
  @visibleForTesting
  IdRemap get remapForTest => _remap;
}
