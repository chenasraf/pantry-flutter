import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/cache_store.dart';
import 'package:pantry_core/sync/conflict_resolver.dart';
import 'package:pantry_core/sync/id_remap.dart';
import 'package:pantry_core/sync/sync_executor.dart';
import 'package:pantry_core/sync/sync_ids.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/sync/sync_queue.dart';

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

  /// True when the queue holds work from an offline period — an op enqueued
  /// while disconnected or a queue persisted from a previous session. Drives
  /// the user-avatar sync indicator (a single-op flush while online does not
  /// flip it). Cleared once the queue fully drains.
  final ValueNotifier<bool> hasBacklog = ValueNotifier(false);

  final _appliedController = StreamController<SyncOpApplied>.broadcast();
  Stream<SyncOpApplied> get onApplied => _appliedController.stream;

  final _skippedController = StreamController<SyncOpSkipped>.broadcast();
  Stream<SyncOpSkipped> get onSkipped => _skippedController.stream;

  final _reconnectController = StreamController<void>.broadcast();

  /// Fires when connectivity transitions from offline back to online. Lets
  /// cache-first controllers re-warm the offline snapshots they couldn't fetch
  /// while disconnected — e.g. lists whose items were never pre-cached because
  /// the app was used offline from a fresh install.
  Stream<void> get onReconnect => _reconnectController.stream;

  /// Ceiling on delivery attempts for a single op. Past this we treat the op
  /// as poison and dead-letter it (drop + emit skipped) rather than retry it
  /// forever — an endlessly-failing head op would otherwise block every op
  /// queued behind it, so changes made after it never sync.
  static const _maxAttempts = 8;

  bool _online = true;
  bool _flushing = false;
  Timer? _retryTimer;
  bool _initialized = false;

  bool get isOnline => _online;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    // main() awaits this on the pre-first-frame path, so a corrupt or
    // version-incompatible on-disk queue must degrade to empty rather than
    // throw — an unhandled error here aborts main() before runApp() and
    // freezes the splash.
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
      // A fresh online session gets a full retry budget: only *consecutive*
      // online failures should count toward dead-lettering, so attempts spent
      // before we dropped offline don't erode a still-syncable op.
      _queue.resetAttempts();
      unawaited(flushNow());
      if (_reconnectController.hasListener) _reconnectController.add(null);
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
    await _reconnectController.close();
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
  /// whole warm-up when any op is queued.
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
        case SyncEntity.store:
        case SyncEntity.label:
        case SyncEntity.note:
        case SyncEntity.customField:
        case SyncEntity.shoppingCheck:
        case SyncEntity.shoppingSkip:
          break;
      }
    }
    return out;
  }

  /// Item ids in [sessionId] that still have a pending Shopping Mode *check*
  /// (create) op queued for [houseId]. The dense shopping view hides these from
  /// its to-buy list so an un-synced offline check — or a still-flushing one —
  /// isn't resurrected by a poll. Uncheck (delete) ops are excluded: they must
  /// bring the item back, not hide it.
  Set<int> pendingShoppingCheckedIds(int houseId, int sessionId) {
    final out = <int>{};
    for (final raw in _queue.all()) {
      if (raw.entity != SyncEntity.shoppingCheck) continue;
      if (raw.houseId != houseId || raw.parentId != sessionId) continue;
      if (raw.op != SyncOpKind.create) continue;
      final id = raw.entityId;
      if (id != null) out.add(id);
    }
    return out;
  }

  /// Item ids in [sessionId] that still have a pending Shopping Mode *uncheck*
  /// (delete) op queued for [houseId]. The dense shopping view keeps these out
  /// of the Done drawer — and, when they belong to the active store, back on the
  /// to-buy list — until a fetch reflects the uncheck. The mirror of
  /// [pendingShoppingCheckedIds]: only delete ops count, since a re-check
  /// (create) must move the item off the list again.
  Set<int> pendingShoppingUncheckedIds(int houseId, int sessionId) {
    final out = <int>{};
    for (final raw in _queue.all()) {
      if (raw.entity != SyncEntity.shoppingCheck) continue;
      if (raw.houseId != houseId || raw.parentId != sessionId) continue;
      if (raw.op != SyncOpKind.delete) continue;
      final id = raw.entityId;
      if (id != null) out.add(id);
    }
    return out;
  }

  /// Item ids in [sessionId] that still have a pending Shopping Mode *skip*
  /// (create) op queued for [houseId] — items removed from this trip whose
  /// removal hasn't synced yet. The dense shopping view hides these from its
  /// to-buy list so an un-synced offline removal isn't resurrected by a poll.
  /// Unskip (delete) ops are excluded: undoing a removal must bring the item
  /// back, not hide it — the mirror of [pendingShoppingCheckedIds].
  Set<int> pendingShoppingSkippedIds(int houseId, int sessionId) {
    final out = <int>{};
    for (final raw in _queue.all()) {
      if (raw.entity != SyncEntity.shoppingSkip) continue;
      if (raw.houseId != houseId || raw.parentId != sessionId) continue;
      if (raw.op != SyncOpKind.create) continue;
      final id = raw.entityId;
      if (id != null) out.add(id);
    }
    return out;
  }

  /// Item ids in [sessionId] that still have a pending Shopping Mode *unskip*
  /// (delete) op queued for [houseId] — items being restored to the trip whose
  /// restore hasn't synced yet. The "Removed" section drops these so a stale
  /// fetch of removed items can't resurrect them mid-restore. The mirror of
  /// [pendingShoppingSkippedIds].
  Set<int> pendingShoppingUnskippedIds(int houseId, int sessionId) {
    final out = <int>{};
    for (final raw in _queue.all()) {
      if (raw.entity != SyncEntity.shoppingSkip) continue;
      if (raw.houseId != houseId || raw.parentId != sessionId) continue;
      if (raw.op != SyncOpKind.delete) continue;
      final id = raw.entityId;
      if (id != null) out.add(id);
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
        if (op.entity == SyncEntity.checklistItem &&
            (_itemHasUnresolvedStores(op) || _itemHasUnresolvedLabels(op))) {
          // A checklist-item create/update attaches a store or label whose
          // create is still ahead in the queue — hold it so we never send a
          // temp store/label id.
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
          if (e.statusCode == 0) {
            // Offline fast-fail from the pre-flight connectivity guard. Don't
            // spend the op's retry budget on it — the flush resumes from this
            // same head op once connectivity returns.
            status.value = _online ? SyncStatus.syncing : SyncStatus.offline;
            return;
          }
          if (_onRetryableFailure(op, e.toString())) continue;
          return;
        } catch (e) {
          if (_onRetryableFailure(op, e.toString())) continue;
          return;
        }
      }
      status.value = _online ? SyncStatus.idle : SyncStatus.offline;
      hasBacklog.value = false;
    } finally {
      _flushing = false;
    }
  }

  /// A checklist-item op that attaches stores is dispatchable only once every
  /// store id in its body has resolved to a real (non-negative) server id.
  bool _itemHasUnresolvedStores(SyncOp op) {
    final storeIds = (op.body['storeIds'] as List?)?.cast<int>();
    if (storeIds == null) return false;
    return storeIds.any((id) => id < 0);
  }

  /// A checklist-item op that attaches labels is dispatchable only once every
  /// label id in its body has resolved to a real (non-negative) server id.
  bool _itemHasUnresolvedLabels(SyncOp op) {
    final labelIds = (op.body['labelIds'] as List?)?.cast<int>();
    if (labelIds == null) return false;
    return labelIds.any((id) => id < 0);
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
    final storeIds = (op.body['storeIds'] as List?)?.cast<int>();
    if (storeIds != null && storeIds.any((id) => id < 0)) return true;
    final labelIds = (op.body['labelIds'] as List?)?.cast<int>();
    if (labelIds != null && labelIds.any((id) => id < 0)) return true;
    return false;
  }

  /// React to a transient/server-side failure on the head op. Retries with
  /// backoff until [_maxAttempts], then dead-letters so the queue keeps
  /// draining instead of wedging behind it forever.
  ///
  /// Returns true when dead-lettered (caller should `continue` onto the next
  /// op), false when a retry was scheduled (caller should stop and wait).
  bool _onRetryableFailure(SyncOp op, String error) {
    final attempt = op.attemptCount + 1;
    if (attempt >= _maxAttempts) {
      debugPrint(
        '[SyncManager] dead-lettering op ${op.uuid} after $attempt attempts: $error',
      );
      _deadLetter(op, 'exhausted');
      return true;
    }
    _queue.update(op.copyWith(attemptCount: attempt, lastError: error));
    status.value = SyncStatus.error;
    final delay = _backoff(attempt);
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (_online) unawaited(flushNow());
    });
    return false;
  }

  /// Drop [op] from the queue and, when it was an optimistic create, reconcile
  /// the ops queued behind it. Same-record follow-ups (update/delete on a row
  /// that now never existed) are dropped; cross-entity references to the dead
  /// temp id are stripped so the dependent op can still flush — an item keeps
  /// syncing, just without the failed category/store. A dangling temp reference
  /// would otherwise re-wedge the queue, since the flush loop holds any op still
  /// pointing at an unresolved temp id.
  void _deadLetter(SyncOp op, String reason) {
    _queue.pop(op.uuid);
    if (op.op == SyncOpKind.create && op.tempEntityId != null) {
      _cascadeDeadCreate(op.entity, op.tempEntityId!);
    }
    pendingCount.value = _queue.length;
    _skippedController.add(SyncOpSkipped(op, reason));
  }

  void _cascadeDeadCreate(SyncEntity entity, int tempId) {
    final rebuilt = <SyncOp>[];
    for (final o in _queue.all()) {
      // A follow-up addressing the never-created row itself can never land.
      // (Reorder ops are house-scoped and carry the id in their body instead,
      // so they fall through to reference-stripping below.)
      if (o.entity == entity &&
          o.op != SyncOpKind.reorder &&
          (o.tempEntityId == tempId || o.effectiveEntityId == tempId)) {
        continue;
      }
      final kept = _stripDeadReference(o, entity, tempId);
      if (kept != null) rebuilt.add(kept);
    }
    _queue.replaceAll(rebuilt);
  }

  /// Returns [o] with any reference to the dead ([entity], [tempId]) removed,
  /// or null when the op cannot survive without it and must be dropped.
  SyncOp? _stripDeadReference(SyncOp o, SyncEntity entity, int tempId) {
    if (o.op == SyncOpKind.reorder && o.entity == entity) {
      return _pruneReorder(o, tempId);
    }
    switch (entity) {
      case SyncEntity.category:
        if (o.body['categoryId'] == tempId) {
          final body = Map<String, dynamic>.of(o.body);
          // A batch set-category keeps a null target (clears the category on
          // its items); a create/update simply drops the field.
          if (o.op == SyncOpKind.batch) {
            body['categoryId'] = null;
          } else {
            body.remove('categoryId');
          }
          return o.copyWith(body: body);
        }
      case SyncEntity.store:
        final storeIds = (o.body['storeIds'] as List?)?.cast<int>();
        if (storeIds != null && storeIds.contains(tempId)) {
          final body = Map<String, dynamic>.of(o.body)
            ..['storeIds'] = storeIds.where((s) => s != tempId).toList();
          return o.copyWith(body: body);
        }
      case SyncEntity.label:
        final labelIds = (o.body['labelIds'] as List?)?.cast<int>();
        if (labelIds != null && labelIds.contains(tempId)) {
          final body = Map<String, dynamic>.of(o.body)
            ..['labelIds'] = labelIds.where((l) => l != tempId).toList();
          return o.copyWith(body: body);
        }
      case SyncEntity.checklistList:
        // An item whose parent list was never created cannot exist.
        if (o.entity == SyncEntity.checklistItem && o.parentId == tempId) {
          return null;
        }
        if (o.op == SyncOpKind.batch && o.body['targetListId'] == tempId) {
          return null;
        }
      case SyncEntity.checklistItem:
        final itemIds = (o.body['itemIds'] as List?)?.cast<int>();
        if (itemIds != null && itemIds.contains(tempId)) {
          final remaining = itemIds.where((i) => i != tempId).toList();
          if (remaining.isEmpty) return null;
          return o.copyWith(
            body: Map<String, dynamic>.of(o.body)..['itemIds'] = remaining,
          );
        }
      case SyncEntity.note:
        break;
      case SyncEntity.customField:
        // Field-definition ops address their own record by id (rewritten by
        // the id-remap), never another entity's temp id in their body.
        break;
      case SyncEntity.shoppingCheck:
      case SyncEntity.shoppingSkip:
        // Shopping checks/skips reference real item/session ids, never a temp
        // create, so they can't hold a dead reference.
        break;
    }
    return o;
  }

  /// Drops the dead id from a reorder op's `order` list, returning null when
  /// nothing remains to reorder.
  SyncOp? _pruneReorder(SyncOp o, int deadId) {
    final order = (o.body['order'] as List?)?.cast<Map>();
    if (order == null) return o;
    final kept = order.where((e) => e['id'] != deadId).toList();
    if (kept.isEmpty) return null;
    return o.copyWith(body: Map<String, dynamic>.of(o.body)..['order'] = kept);
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

  /// Drives the poison-op path directly (the real trigger is exhausting
  /// retries mid-flush, which needs a live server to fail against).
  @visibleForTesting
  void deadLetterForTest(SyncOp op) => _deadLetter(op, 'exhausted');
}
