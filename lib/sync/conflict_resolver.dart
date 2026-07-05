import 'package:pantry/sync/sync_op.dart';

/// Pure last-write-wins resolver: apply the op iff the local intent is
/// newer than the latest known server `updatedAt`. Server tombstones
/// (`deletedAt`) always win — once a record is gone, we don't revive it
/// through a pending update.
class ConflictResolver {
  const ConflictResolver();

  /// [serverUpdatedAt] / [serverDeletedAt] are unix-ms timestamps from the
  /// canonical server record. Either may be null when the server has no
  /// record (e.g. an item that was already permanently deleted).
  bool shouldApply(
    SyncOp op, {
    required int? serverUpdatedAt,
    int? serverDeletedAt,
  }) {
    // If the server has tombstoned a record, any pending update/toggle/
    // reorder is dropped. Restore is allowed only if it's strictly newer.
    if (serverDeletedAt != null) {
      switch (op.op) {
        case SyncOpKind.update:
        case SyncOpKind.toggle:
        case SyncOpKind.reorder:
          return false;
        case SyncOpKind.restore:
          return op.createdAt > serverDeletedAt;
        case SyncOpKind.delete:
          // Already deleted server-side; nothing to do.
          return false;
        case SyncOpKind.permanentDelete:
        case SyncOpKind.emptyTrash:
        case SyncOpKind.create:
        // Batch ops are house-scoped over many items; a single record's
        // tombstone doesn't invalidate the group action (the server skips
        // any gone member itself).
        case SyncOpKind.batch:
          return true;
      }
    }
    if (serverUpdatedAt == null) {
      // Server has nothing newer to compare against — apply.
      return true;
    }
    // Pure LWW on updatedAt.
    return op.createdAt > serverUpdatedAt;
  }
}
