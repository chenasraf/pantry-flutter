import 'package:pantry/services/cache_store.dart';
import 'package:pantry/sync/sync_op.dart';

/// Resolves temp negative IDs (assigned client-side for optimistic creates)
/// to real server IDs once a `create` op has flushed. Persisted alongside
/// the queue so an app restart mid-queue still rewrites pending ops.
class IdRemap {
  final CacheStore _store;
  final Map<String, int> _map = {};

  IdRemap(this._store);

  Future<void> load() async {
    await _store.load();
    final raw = _store.get<Map>('remap');
    if (raw == null) return;
    _map.clear();
    for (final entry in raw.entries) {
      final v = entry.value;
      if (v is int) _map[entry.key as String] = v;
    }
  }

  String _key(SyncEntity entity, int tempId) => '${entity.name}:$tempId';

  int? resolve(SyncEntity entity, int tempId) => _map[_key(entity, tempId)];

  void bind(SyncEntity entity, int tempId, int realId) {
    _map[_key(entity, tempId)] = realId;
    _persist();
  }

  void forget(SyncEntity entity, int tempId) {
    _map.remove(_key(entity, tempId));
    _persist();
  }

  Future<void> clear() async {
    _map.clear();
    await _store.clear();
  }

  void _persist() => _store.set('remap', Map<String, dynamic>.from(_map));

  /// Rewrite a pending op so any temp id it references becomes the real id
  /// once known. Returns the rewritten op (or the same op if nothing changed).
  SyncOp rewrite(SyncOp op) {
    if (op.op == SyncOpKind.batch) return _rewriteBatch(op);
    var result = op;
    final tempId = op.tempEntityId;
    if (tempId != null) {
      final real = resolve(op.entity, tempId);
      if (real != null) result = result.copyWith(entityId: real);
    }
    // A checklist-item create/update carries its store attachments in
    // body['storeIds']; any of those may be a temp id when the store was
    // created in the same offline session. Remap each to its real id where
    // resolved (unlike the scalar categoryId, which has this same latent gap).
    if (result.entity == SyncEntity.checklistItem) {
      result = _rewriteItemStoreIds(result);
    }
    return result;
  }

  SyncOp _rewriteItemStoreIds(SyncOp op) {
    final storeIds = (op.body['storeIds'] as List?)?.cast<int>();
    if (storeIds == null) return op;
    final mapped = [
      for (final id in storeIds)
        id < 0 ? (resolve(SyncEntity.store, id) ?? id) : id,
    ];
    if (_sameInts(mapped, storeIds)) return op;
    final body = Map<String, dynamic>.from(op.body);
    body['storeIds'] = mapped;
    return op.copyWith(body: body);
  }

  /// Batch ops carry their references in the body, not [SyncOp.entityId]:
  /// the item ids being acted on, plus an optional target list (move/copy) or
  /// category (set-category), any of which may be a temp id when the item /
  /// list / category was created in the same offline session. Rewrites each to
  /// its real id where resolved; unresolved temp ids are left in place (the
  /// manager holds the op until the create flushes).
  SyncOp _rewriteBatch(SyncOp op) {
    final body = Map<String, dynamic>.from(op.body);
    var changed = false;

    final ids = (body['itemIds'] as List?)?.cast<int>();
    if (ids != null) {
      final mapped = [
        for (final id in ids)
          id < 0 ? (resolve(SyncEntity.checklistItem, id) ?? id) : id,
      ];
      if (!_sameInts(mapped, ids)) {
        body['itemIds'] = mapped;
        changed = true;
      }
    }

    final target = body['targetListId'];
    if (target is int && target < 0) {
      final real = resolve(SyncEntity.checklistList, target);
      if (real != null) {
        body['targetListId'] = real;
        changed = true;
      }
    }

    final cat = body['categoryId'];
    if (cat is int && cat < 0) {
      final real = resolve(SyncEntity.category, cat);
      if (real != null) {
        body['categoryId'] = real;
        changed = true;
      }
    }

    return changed ? op.copyWith(body: body) : op;
  }

  static bool _sameInts(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
