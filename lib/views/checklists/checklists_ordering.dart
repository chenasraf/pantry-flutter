import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/prefs_service.dart';

/// Sentinel id used by the synthetic "All lists" meta view. Real list ids on
/// the backend are always positive; temp ids minted by SyncManager are
/// negative. `0` is unused by both, which keeps the sentinel disjoint.
const int kAllListsId = 0;

/// Builds the synthetic "All lists" entry. Never persisted, never reordered;
/// the switcher surfaces it manually at position 0.
ChecklistList allListsSentinel(int houseId) => ChecklistList(
  id: kAllListsId,
  houseId: houseId,
  name: m.checklists.allLists,
  icon: 'all-lists',
  sortOrder: -1 << 30,
  createdAt: 0,
  updatedAt: 0,
  // The sentinel isn't a server entity, so its progress-card visibility is
  // persisted locally (under id 0) rather than synced like real lists.
  hideProgressHero: PrefsService.instance.allListsProgressHeroHidden,
);

/// Replaces items in [current] with their same-id counterpart from [updated],
/// leaving order and any non-matching items untouched. Backs the move (meta
/// view) and set-category reconciliation, where the server returns the affected
/// items to overlay. Pure, so it can be unit tested without the controller.
List<ListItem> reconcileReplaceById(
  List<ListItem> current,
  List<ListItem> updated,
) {
  final byId = {for (final i in updated) i.id: i};
  return [for (final i in current) byId[i.id] ?? i];
}

/// Drops every item in [current] whose id is in [removeIds]. Backs the delete
/// reconciliation and the per-list move (moved items leave the source view).
/// Pure, so it can be unit tested without the controller.
List<ListItem> reconcileRemoveIds(List<ListItem> current, Set<int> removeIds) =>
    [
      for (final i in current)
        if (!removeIds.contains(i.id)) i,
    ];

/// Index at which a newly added [item] should slot into [items] so the
/// optimistic insert matches the order the server returns for [sortBy].
///
/// The server interleaves done rows by the same sort key rather than grouping
/// them at the end, so this scans the whole list instead of stopping at the
/// first done row. [categoryRankOf] maps a categoryId (null = uncategorized) to
/// its display rank; only consulted for the 'category' sort. Pure.
int checklistInsertIndex(
  List<ListItem> items,
  String sortBy,
  ListItem item,
  int Function(int? categoryId) categoryRankOf,
) {
  switch (sortBy) {
    case 'category':
      final myRank = categoryRankOf(item.categoryId);
      for (var i = 0; i < items.length; i++) {
        if (categoryRankOf(items[i].categoryId) > myRank) return i;
      }
      return items.length;
    case 'name_asc':
      final key = item.name.toLowerCase();
      for (var i = 0; i < items.length; i++) {
        if (items[i].name.toLowerCase().compareTo(key) > 0) return i;
      }
      return items.length;
    case 'name_desc':
      final key = item.name.toLowerCase();
      for (var i = 0; i < items.length; i++) {
        if (items[i].name.toLowerCase().compareTo(key) < 0) return i;
      }
      return items.length;
    case 'oldest':
      for (var i = 0; i < items.length; i++) {
        if (items[i].createdAt > item.createdAt) return i;
      }
      return items.length;
    case 'newest':
      for (var i = 0; i < items.length; i++) {
        if (items[i].createdAt < item.createdAt) return i;
      }
      return items.length;
    case 'custom':
    default:
      // The server assigns a new item `max(sortOrder)+1` on add, so the
      // optimistic position is the end of the custom-ordered list. The created
      // item's real sortOrder comes back in the response and is reconciled
      // then — this is only the optimistic slot.
      return items.length;
  }
}

/// True-order reconstruction for a drag-to-reorder. Only
/// [dragId] moves; every other item — checked items *and* items in other groups
/// — keeps its stored `sortOrder` slot. The dragged item is re-slotted next to
/// its new neighbour within [scope], the ordered items the drag was constrained
/// to (the whole active partition in custom sort, a category block in category
/// sort, a store column in store sort).
///
/// [allItems] is every item currently in the list (done + not-done); [scope]
/// includes the dragged item and is in display order; [dropIndex] is the target
/// position within [scope] *with the dragged item removed* (i.e. the index the
/// reorderable's `onReorderItem` already adjusted for the removed item).
///
/// Returns the full renumbered order (every item `0..n`) to POST to the reorder
/// endpoint, or an empty list when [dragId] isn't in [scope] (a no-op drop).
/// Pure, so it can be unit tested without the controller.
List<({int id, int sortOrder})> reorderToTrueOrder(
  List<ListItem> allItems,
  List<ListItem> scope,
  int dragId,
  int dropIndex,
) {
  final draggedIndex = scope.indexWhere((i) => i.id == dragId);
  if (draggedIndex == -1) return const [];
  final dragged = scope[draggedIndex];

  // New order *within the scope* after the drop.
  final without = [
    for (final i in scope)
      if (i.id != dragId) i,
  ];
  final clamped = dropIndex < 0
      ? 0
      : (dropIndex > without.length ? without.length : dropIndex);
  final reordered = [...without]..insert(clamped, dragged);

  // Full true order = all items sorted by (sortOrder, then name) — the stored
  // order the server persists.
  final trueOrder = [...allItems]
    ..sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  final origIndex = trueOrder.indexWhere((i) => i.id == dragId);
  final finalOrder = [
    for (final i in trueOrder)
      if (i.id != dragId) i,
  ];

  final pos = reordered.indexWhere((i) => i.id == dragId);
  final predecessor = pos > 0 ? reordered[pos - 1] : null;
  final successor = pos < reordered.length - 1 ? reordered[pos + 1] : null;

  final int insertAt;
  if (predecessor != null) {
    insertAt = finalOrder.indexWhere((i) => i.id == predecessor.id) + 1;
  } else if (successor != null) {
    insertAt = finalOrder.indexWhere((i) => i.id == successor.id);
  } else {
    // Dragged item is alone in its scope — keep its original slot.
    insertAt = origIndex == -1 ? finalOrder.length : origIndex;
  }

  finalOrder.insert(insertAt, dragged);
  return [
    for (var i = 0; i < finalOrder.length; i++)
      (id: finalOrder[i].id, sortOrder: i),
  ];
}

/// Re-seeds `sortOrder` from a chosen [basis] for the "Reset custom order to …"
/// action, leaving the list hand-reorderable afterwards. A pure client
/// computation over the existing reorder endpoint — no server endpoint.
///
/// [basis] is `dateAdded` (oldest first), `name_asc`, or `name_desc`.
/// [categoryOrder] is the category ids in header order, supplied *only* in
/// category sort so the reseed keeps the category grouping (uncategorized last);
/// null elsewhere for a flat reseed. Pure, for unit testing.
List<({int id, int sortOrder})> reseedOrder(
  List<ListItem> items,
  String basis,
  List<int>? categoryOrder,
) {
  int cmp(ListItem a, ListItem b) {
    switch (basis) {
      case 'name_asc':
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case 'name_desc':
        return b.name.toLowerCase().compareTo(a.name.toLowerCase());
      default: // dateAdded — oldest first
        return a.createdAt.compareTo(b.createdAt);
    }
  }

  final ordered = [...items];
  if (categoryOrder != null) {
    const maxRank = 1 << 30;
    int rankOf(int? catId) {
      if (catId == null) return maxRank;
      final idx = categoryOrder.indexOf(catId);
      return idx == -1 ? maxRank : idx;
    }

    ordered.sort((a, b) {
      final r = rankOf(a.categoryId).compareTo(rankOf(b.categoryId));
      return r != 0 ? r : cmp(a, b);
    });
  } else {
    ordered.sort(cmp);
  }
  return [
    for (var i = 0; i < ordered.length; i++) (id: ordered[i].id, sortOrder: i),
  ];
}
