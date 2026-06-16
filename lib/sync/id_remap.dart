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
    final tempId = op.tempEntityId;
    if (tempId == null) return op;
    final real = resolve(op.entity, tempId);
    if (real == null) return op;
    return op.copyWith(entityId: real);
  }
}
