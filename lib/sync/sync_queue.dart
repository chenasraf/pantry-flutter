import 'package:pantry/services/cache_store.dart';
import 'package:pantry/sync/sync_op.dart';

/// Persistent FIFO of pending sync operations.
///
/// Ordering within an entity is preserved exactly; `merge()` collapses
/// redundant ops on the same record (see the offline-sync plan for the
/// full rule set).
class SyncQueue {
  final CacheStore _store;
  final List<SyncOp> _ops = [];

  SyncQueue(this._store);

  static const _key = 'ops';

  Future<void> load() async {
    await _store.load();
    final stored =
        _store.getList<SyncOp>(_key, (j) => SyncOp.fromJson(j)) ?? const [];
    _ops
      ..clear()
      ..addAll(stored);
  }

  void _persist() => _store.setList(_key, _ops, (op) => op.toJson());

  List<SyncOp> all() => List.unmodifiable(_ops);

  int get length => _ops.length;
  bool get isEmpty => _ops.isEmpty;

  SyncOp? peek() => _ops.isEmpty ? null : _ops.first;

  void enqueue(SyncOp op) {
    _ops.add(op);
    _persist();
  }

  void pop(String uuid) {
    _ops.removeWhere((o) => o.uuid == uuid);
    _persist();
  }

  void update(SyncOp op) {
    final i = _ops.indexWhere((o) => o.uuid == op.uuid);
    if (i == -1) return;
    _ops[i] = op;
    _persist();
  }

  Future<void> clear() async {
    _ops.clear();
    await _store.clear();
  }

  /// Replace the queue contents from a (possibly mutated) snapshot. Used by
  /// merging and id-remap rewriting at flush time.
  void replaceAll(Iterable<SyncOp> ops) {
    _ops
      ..clear()
      ..addAll(ops);
    _persist();
  }

  /// Find ops referencing a specific (entity, id) — used by controllers to
  /// detect already-queued mutations on a record they're rendering.
  Iterable<SyncOp> forRecord(SyncEntity entity, int id) =>
      _ops.where((o) => o.entity == entity && o.effectiveEntityId == id);

  /// Collapse redundant ops in-place, preserving order across distinct
  /// records. Returns the number of ops removed.
  int merge() {
    if (_ops.length < 2) return 0;

    final before = _ops.length;
    final result = <SyncOp>[];

    // Group consecutive runs by (entity, effectiveEntityId) but preserve
    // global ordering by walking the list once and folding into result.
    // We then do a second pass that lets later ops cancel earlier ones on
    // the same record across the entire queue (the rules don't require
    // adjacency).

    // Build an index: most-recent-op-by-record while we copy.
    for (final op in _ops) {
      result.add(op);
    }

    // Apply rules. We iterate to a fixed point so chained collapses settle.
    bool changed = true;
    while (changed) {
      changed = false;
      changed = _applyEmptyTrash(result) || changed;
      changed = _applyDeletePairs(result) || changed;
      changed = _applyArchivePairs(result) || changed;
      changed = _applyTogglePairs(result) || changed;
      changed = _applyUpdateCollapse(result) || changed;
      changed = _applyReorderCollapse(result) || changed;
      changed = _applyCreateFolds(result) || changed;
    }

    _ops
      ..clear()
      ..addAll(result);
    _persist();
    return before - _ops.length;
  }

  bool _applyEmptyTrash(List<SyncOp> ops) {
    bool changed = false;
    for (var i = 0; i < ops.length; i++) {
      final op = ops[i];
      if (op.op != SyncOpKind.emptyTrash) continue;
      final parent = op.parentId ?? op.houseId;
      final before = ops.length;
      ops.removeWhere(
        (o) =>
            o.uuid != op.uuid &&
            o.entity == op.entity &&
            (o.op == SyncOpKind.restore ||
                o.op == SyncOpKind.permanentDelete) &&
            ((op.parentId == null && o.houseId == op.houseId) ||
                o.parentId == parent),
      );
      // Only report progress when something was actually collapsed. The
      // emptyTrash op itself is never removed here, so signalling `changed`
      // unconditionally kept merge()'s fixed-point loop spinning forever
      // whenever a lone emptyTrash op sat in the queue — freezing startup
      // when SyncManager flushed it.
      if (ops.length != before) changed = true;
    }
    return changed;
  }

  bool _applyDeletePairs(List<SyncOp> ops) {
    bool changed = false;
    for (var i = 0; i < ops.length; i++) {
      final a = ops[i];
      if (a.op != SyncOpKind.delete) continue;
      // delete + restore on same record → drop both
      final restoreIdx = ops.indexWhere(
        (b) =>
            b != a &&
            b.entity == a.entity &&
            b.effectiveEntityId == a.effectiveEntityId &&
            b.op == SyncOpKind.restore,
        i + 1,
      );
      if (restoreIdx != -1) {
        ops.removeAt(restoreIdx);
        ops.remove(a);
        changed = true;
        return true;
      }
      // delete + permanentDelete → keep only permanentDelete
      final permIdx = ops.indexWhere(
        (b) =>
            b != a &&
            b.entity == a.entity &&
            b.effectiveEntityId == a.effectiveEntityId &&
            b.op == SyncOpKind.permanentDelete,
        i + 1,
      );
      if (permIdx != -1) {
        ops.remove(a);
        changed = true;
        return true;
      }
      // update + delete → drop the update (earlier update on same record)
      for (var j = 0; j < ops.length; j++) {
        if (j == i) continue;
        final b = ops[j];
        if (b.op == SyncOpKind.update &&
            b.entity == a.entity &&
            b.effectiveEntityId == a.effectiveEntityId) {
          ops.removeAt(j);
          changed = true;
          return true;
        }
      }
      // create (temp) + delete → drop both (never reaches server)
      for (var j = 0; j < ops.length; j++) {
        if (j == i) continue;
        final b = ops[j];
        if (b.op == SyncOpKind.create &&
            b.entity == a.entity &&
            b.tempEntityId != null &&
            (a.tempEntityId == b.tempEntityId ||
                a.effectiveEntityId == b.tempEntityId)) {
          ops.removeAt(j);
          // recompute index for `a`
          final aIdx = ops.indexOf(a);
          if (aIdx != -1) ops.removeAt(aIdx);
          changed = true;
          return true;
        }
      }
    }
    // restore + permanentDelete → keep only permanentDelete
    for (var i = 0; i < ops.length; i++) {
      final a = ops[i];
      if (a.op != SyncOpKind.restore) continue;
      final permIdx = ops.indexWhere(
        (b) =>
            b != a &&
            b.entity == a.entity &&
            b.effectiveEntityId == a.effectiveEntityId &&
            b.op == SyncOpKind.permanentDelete,
        i + 1,
      );
      if (permIdx != -1) {
        ops.remove(a);
        changed = true;
        return true;
      }
    }
    return changed;
  }

  bool _applyArchivePairs(List<SyncOp> ops) {
    bool changed = false;
    for (var i = 0; i < ops.length; i++) {
      final a = ops[i];
      if (a.op != SyncOpKind.archive) continue;
      // archive + unarchive on same record → drop both
      final unarchiveIdx = ops.indexWhere(
        (b) =>
            b != a &&
            b.entity == a.entity &&
            b.effectiveEntityId == a.effectiveEntityId &&
            b.op == SyncOpKind.unarchive,
        i + 1,
      );
      if (unarchiveIdx != -1) {
        ops.removeAt(unarchiveIdx);
        ops.remove(a);
        changed = true;
        return true;
      }
      // archive + permanentDelete → keep only permanentDelete
      final permIdx = ops.indexWhere(
        (b) =>
            b != a &&
            b.entity == a.entity &&
            b.effectiveEntityId == a.effectiveEntityId &&
            b.op == SyncOpKind.permanentDelete,
        i + 1,
      );
      if (permIdx != -1) {
        ops.remove(a);
        changed = true;
        return true;
      }
    }
    // unarchive + permanentDelete → keep only permanentDelete
    for (var i = 0; i < ops.length; i++) {
      final a = ops[i];
      if (a.op != SyncOpKind.unarchive) continue;
      final permIdx = ops.indexWhere(
        (b) =>
            b != a &&
            b.entity == a.entity &&
            b.effectiveEntityId == a.effectiveEntityId &&
            b.op == SyncOpKind.permanentDelete,
        i + 1,
      );
      if (permIdx != -1) {
        ops.remove(a);
        changed = true;
        return true;
      }
    }
    return changed;
  }

  bool _applyTogglePairs(List<SyncOp> ops) {
    final byRecord = <String, List<int>>{};
    for (var i = 0; i < ops.length; i++) {
      final op = ops[i];
      if (op.op != SyncOpKind.toggle) continue;
      final k = '${op.entity.name}:${op.effectiveEntityId}';
      byRecord.putIfAbsent(k, () => []).add(i);
    }
    bool changed = false;
    for (final indices in byRecord.values) {
      if (indices.length < 2) continue;
      // Even count: cancel all. Odd: keep the most recent (last index).
      final keep = indices.length.isOdd ? indices.last : -1;
      for (final i in indices.reversed) {
        if (i != keep) ops.removeAt(i);
      }
      changed = true;
    }
    return changed;
  }

  bool _applyUpdateCollapse(List<SyncOp> ops) {
    // Merge multiple `update`s on the same record into the latest, with
    // earlier-op fields filled in where the later op didn't specify them.
    final byRecord = <String, List<int>>{};
    for (var i = 0; i < ops.length; i++) {
      final op = ops[i];
      if (op.op != SyncOpKind.update) continue;
      final k = '${op.entity.name}:${op.effectiveEntityId}';
      byRecord.putIfAbsent(k, () => []).add(i);
    }
    bool changed = false;
    for (final indices in byRecord.values) {
      if (indices.length < 2) continue;
      final mergedBody = <String, dynamic>{};
      for (final i in indices) {
        mergedBody.addAll(ops[i].body);
      }
      // Keep the latest op (last index), with merged body.
      final latest = ops[indices.last].copyWith(body: mergedBody);
      // Remove earlier ones (in reverse to preserve indices).
      for (final i in indices.reversed) {
        if (i != indices.last) ops.removeAt(i);
      }
      // Now find the new index of the latest op and replace it.
      final newIdx = ops.indexWhere((o) => o.uuid == latest.uuid);
      if (newIdx != -1) ops[newIdx] = latest;
      changed = true;
    }
    return changed;
  }

  bool _applyReorderCollapse(List<SyncOp> ops) {
    final byParent = <String, List<int>>{};
    for (var i = 0; i < ops.length; i++) {
      final op = ops[i];
      if (op.op != SyncOpKind.reorder) continue;
      final k = '${op.entity.name}:${op.parentId ?? op.houseId}';
      byParent.putIfAbsent(k, () => []).add(i);
    }
    bool changed = false;
    for (final indices in byParent.values) {
      if (indices.length < 2) continue;
      for (final i in indices.reversed) {
        if (i != indices.last) ops.removeAt(i);
      }
      changed = true;
    }
    return changed;
  }

  bool _applyCreateFolds(List<SyncOp> ops) {
    // create(tempId) + update(tempId) → fold update body into create body.
    bool changed = false;
    for (var i = 0; i < ops.length; i++) {
      final c = ops[i];
      if (c.op != SyncOpKind.create) continue;
      final tempId = c.tempEntityId;
      if (tempId == null) continue;
      for (var j = i + 1; j < ops.length; j++) {
        final u = ops[j];
        if (u.op != SyncOpKind.update) continue;
        if (u.entity != c.entity) continue;
        if (u.effectiveEntityId != tempId) continue;
        final mergedBody = <String, dynamic>{...c.body, ...u.body};
        ops[i] = c.copyWith(body: mergedBody);
        ops.removeAt(j);
        changed = true;
        return true;
      }
    }
    return changed;
  }
}
