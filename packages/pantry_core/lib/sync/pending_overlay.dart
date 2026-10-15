import 'package:pantry_core/models/checklist.dart';

/// Lay the un-acked local state back over a snapshot of the same records.
///
/// **Nothing writes a cache key without first overlaying the queue over it.**
/// The queue is what the user asked for; a snapshot — fetched, mirrored or
/// restored — is only ever a rendering of what the server knew when it was
/// taken. A snapshot that predates a queued write is not wrong about the
/// server, it is just older than the user's intent, so applying it unchanged
/// flips the row back under the wearer's finger.
///
/// [pending] names the ids with a queued op (see `SyncManager.pendingItemIds`),
/// [local] holds the values already on screen or already in the cache, and
/// [server] is the incoming snapshot. A pending id takes its local value; a
/// pending id that is gone locally is a queued delete and stays gone; every
/// other id takes the server's.
///
/// Optimistic creates are the leftovers: rows the server has never returned.
/// [insertIndex] decides where each one lands in the merged list — a caller
/// that renders in a particular sort supplies it, so a refresh arriving before
/// the create acks does not yank the new row to the top. Without it they are
/// appended.
List<ListItem> overlayPendingItems({
  required List<ListItem> server,
  required List<ListItem> local,
  required Set<int> pending,
  int Function(ListItem item, List<ListItem> into)? insertIndex,
}) => _overlayPending(
  server: server,
  local: local,
  pending: pending,
  idOf: (i) => i.id,
  insertIndex: insertIndex,
);

/// [overlayPendingItems] for the lists themselves; [pending] comes from
/// `SyncManager.pendingListRecordIds`.
List<ChecklistList> overlayPendingLists({
  required List<ChecklistList> server,
  required List<ChecklistList> local,
  required Set<int> pending,
}) => _overlayPending(
  server: server,
  local: local,
  pending: pending,
  idOf: (l) => l.id,
);

List<T> _overlayPending<T>({
  required List<T> server,
  required List<T> local,
  required Set<int> pending,
  required int Function(T record) idOf,
  int Function(T record, List<T> into)? insertIndex,
}) {
  if (pending.isEmpty) return server;

  final localById = {for (final l in local) idOf(l): l};
  final out = <T>[];
  for (final s in server) {
    if (pending.contains(idOf(s))) {
      final mine = localById[idOf(s)];
      if (mine != null) out.add(mine);
    } else {
      out.add(s);
    }
  }

  final present = out.map(idOf).toSet();
  final localOnly = [
    for (final l in local)
      if (pending.contains(idOf(l)) && !present.contains(idOf(l))) l,
  ];
  if (localOnly.isEmpty) return out;
  if (insertIndex == null) return [...out, ...localOnly];

  // Resolve every slot against the untouched snapshot first, then splice from
  // the back. `localOnly` follows display order, so those indices are
  // non-decreasing; inserting highest-first keeps the earlier ones valid and
  // preserves the relative order of ties.
  final slots = [for (final l in localOnly) (l, insertIndex(l, out))];
  for (final (item, at) in slots.reversed) {
    out.insert(at.clamp(0, out.length), item);
  }
  return out;
}
