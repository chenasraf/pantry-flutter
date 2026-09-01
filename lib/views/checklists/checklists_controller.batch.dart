part of 'checklists_controller.dart';

// -- Batch (group) actions --
//
// House-scoped and offline-capable: each applies a best-effort optimistic
// mutation, enqueues a single `batch` SyncOp, and clears the selection. The
// authoritative server envelope is reconciled later in [_onSyncApplied].
// Client-side gating only lets writable items into move/delete/category, so
// in practice `skipped` covers just items that vanished server-side — which
// optimistic removal already matches.
extension ChecklistsControllerBatch on ChecklistsController {
  void _enqueueBatch(
    String action,
    List<int> itemIds, {
    Map<String, dynamic> extra = const {},
  }) {
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.batch,
        houseId: houseId,
        body: {'batchAction': action, 'itemIds': itemIds, ...extra},
        createdAt: _now(),
      ),
    );
  }

  void batchMove(int targetListId) {
    final ids = _selectedItemIds.toList();
    if (ids.isEmpty) return;
    // Per-list view: the moved items leave immediately. Meta view keeps them
    // (their listId only changes once the server confirms via _onSyncApplied).
    if (!isMetaMode) {
      _items = reconcileRemoveIds(_items, ids.toSet());
      _cacheCurrentItems();
    }
    _enqueueBatch('move', ids, extra: {'targetListId': targetListId});
    exitSelection();
  }

  void batchCopy(int targetListId) {
    final ids = _selectedItemIds.toList();
    if (ids.isEmpty) return;
    // Copies live on another list (or arrive in the meta view only once the
    // server returns them), so there's nothing to show optimistically.
    _enqueueBatch('copy', ids, extra: {'targetListId': targetListId});
    exitSelection();
  }

  void batchDelete({bool permanent = false}) {
    final ids = _selectedItemIds.toList();
    if (ids.isEmpty) return;
    _items = reconcileRemoveIds(_items, ids.toSet());
    _cacheCurrentItems();
    _enqueueBatch('delete', ids, extra: {if (permanent) 'permanent': true});
    exitSelection();
  }

  void batchArchive() {
    final items = List.of(selectedItems);
    final ids = _selectedItemIds.toList();
    if (ids.isEmpty) return;
    // Archived items leave the active view immediately.
    _items = reconcileRemoveIds(_items, ids.toSet());
    for (final item in items) {
      _addToArchivedReuse(item.copyWith(archivedAt: _now()));
    }
    if (!isSoftView) _cacheCurrentItems();
    _enqueueBatch('archive', ids, extra: {'archive': true});
    exitSelection();
  }

  void batchUnarchive() {
    final items = List.of(selectedItems);
    final ids = _selectedItemIds.toList();
    if (ids.isEmpty) return;
    // Unarchived items leave the archive view and return to the active list.
    _items = reconcileRemoveIds(_items, ids.toSet());
    for (final item in items) {
      _removeFromArchivedReuse(item);
    }
    if (!isSoftView) _cacheCurrentItems();
    _enqueueBatch('archive', ids, extra: {'archive': false});
    exitSelection();
  }

  /// Bulk-restore trashed items. There's no batch-restore endpoint, so this
  /// enqueues a per-id restore (the same op the single-item restore uses).
  void batchRestore() {
    final items = List.of(selectedItems);
    if (items.isEmpty) return;
    // Restored items leave the trash view and return to the active list.
    _items = reconcileRemoveIds(_items, {for (final i in items) i.id});
    if (!isSoftView) _cacheCurrentItems();
    for (final item in items) {
      _sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.restore,
          houseId: houseId,
          parentId: item.listId,
          entityId: item.id,
          createdAt: _now(),
        ),
      );
    }
    exitSelection();
  }

  void batchSetCategory(int? categoryId) {
    final ids = _selectedItemIds.toList();
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    _items = [
      for (final i in _items)
        idSet.contains(i.id)
            ? i.copyWith(
                categoryId: categoryId,
                clearCategory: categoryId == null,
                updatedAt: _now(),
              )
            : i,
    ];
    _cacheCurrentItems();
    _enqueueBatch('category', ids, extra: {'categoryId': categoryId});
    exitSelection();
  }

  /// Replace the store set on every selected item (an empty list clears them),
  /// mirroring the server's `batch/stores` replace semantics.
  void batchSetStores(List<int> storeIds) {
    final ids = _selectedItemIds.toList();
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    _items = [
      for (final i in _items)
        idSet.contains(i.id)
            ? i.copyWith(storeIds: List.of(storeIds), updatedAt: _now())
            : i,
    ];
    _cacheCurrentItems();
    _enqueueBatch('stores', ids, extra: {'storeIds': storeIds});
    exitSelection();
  }

  /// Replace the label set on every selected item (an empty list clears them),
  /// mirroring the server's `batch/labels` replace semantics.
  void batchSetLabels(List<int> labelIds) {
    final ids = _selectedItemIds.toList();
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    _items = [
      for (final i in _items)
        idSet.contains(i.id)
            ? i.copyWith(labelIds: List.of(labelIds), updatedAt: _now())
            : i,
    ];
    _cacheCurrentItems();
    _enqueueBatch('labels', ids, extra: {'labelIds': labelIds});
    exitSelection();
  }

  /// Reconciles the authoritative envelope from a flushed `batch` op back into
  /// the view — see [_onSyncApplied].
  void _reconcileBatchApplied(SyncOp op, PantryBatchResult result) {
    switch (op.body['batchAction'] as String?) {
      case 'move':
        if (isMetaMode) {
          // Adopt the returned items (now carrying their new listId).
          _items = reconcileReplaceById(_items, result.items);
        } else {
          // Direction-aware: a returned item now living on the current list
          // moved *in* (keep/insert it — this is how an undo-move-back lands);
          // one living elsewhere moved *out* (remove it).
          final currentId = _currentList?.id;
          final movedOut = {
            for (final i in result.items)
              if (i.listId != currentId) i.id,
          };
          var next = reconcileRemoveIds(_items, movedOut);
          final present = {for (final i in next) i.id};
          final incoming = [
            for (final i in result.items)
              if (i.listId == currentId) i,
          ];
          next = reconcileReplaceById(next, incoming);
          for (final i in incoming) {
            if (!present.contains(i.id)) next.insert(_insertIndexFor(i), i);
          }
          _items = next;
          _cacheCurrentItems();
        }
      case 'copy':
        if (isMetaMode && result.items.isNotEmpty) {
          final existing = {for (final i in _items) i.id};
          final fresh = [
            for (final i in result.items)
              if (!existing.contains(i.id)) i,
          ];
          if (fresh.isNotEmpty) _items = [...fresh, ..._items];
        }
      case 'category':
      case 'stores':
      case 'labels':
      case 'uncheck':
        // `uncheck` returns the now-unchecked rows (idempotent: already-active
        // items are omitted). Swapping them by id folds the authoritative
        // done/doneAt/nextDueAt back over the optimistic uncheck.
        _items = reconcileReplaceById(_items, result.items);
        _cacheCurrentItems();
      case 'delete':
      case 'archive':
        // Optimistic removal already applied; nothing to overlay.
        break;
    }
    notifyListeners();
  }

  // -- Batch undo --
  //
  // Each reverses a group action from the pre-action item snapshots the view
  // captured, reusing the same batch ops (or per-id restore for delete).

  /// Return every item to the list it came from. Items may have originated on
  /// different lists, so the reverse move is grouped per source list.
  void undoBatchMove(List<ListItem> items) {
    if (items.isEmpty) return;
    if (isMetaMode) {
      _items = reconcileReplaceById(_items, items);
    } else {
      final existing = {for (final i in _items) i.id};
      for (final it in items) {
        if (it.listId == _currentList?.id && !existing.contains(it.id)) {
          _items.insert(_insertIndexFor(it), it);
        }
      }
      _cacheCurrentItems();
    }
    final bySource = <int, List<int>>{};
    for (final it in items) {
      bySource.putIfAbsent(it.listId, () => []).add(it.id);
    }
    for (final entry in bySource.entries) {
      _enqueueBatch('move', entry.value, extra: {'targetListId': entry.key});
    }
    notifyListeners();
  }

  /// Restore every soft-deleted item. There's no batch-restore endpoint, so
  /// this enqueues a per-id restore (the same op the single-item undo uses).
  void undoBatchDelete(List<ListItem> items) {
    if (items.isEmpty || _isTrashMode) return;
    final existing = {for (final i in _items) i.id};
    for (final item in items) {
      if (existing.contains(item.id)) continue;
      final restored = item.copyWith(clearDeletedAt: true, updatedAt: _now());
      _items.insert(_insertIndexFor(restored), restored);
      _sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.restore,
          houseId: houseId,
          parentId: item.listId,
          entityId: item.id,
          createdAt: _now(),
        ),
      );
    }
    _cacheCurrentItems();
    notifyListeners();
  }

  /// Reverse a bulk archive done from the active view: unarchive each snapshot
  /// back into the active list (no batch-unarchive coalescing needed here — a
  /// per-id unarchive is the same op the single-item undo uses).
  void undoBatchArchive(List<ListItem> items) {
    if (items.isEmpty || isSoftView) return;
    final existing = {for (final i in _items) i.id};
    for (final item in items) {
      if (existing.contains(item.id)) continue;
      _removeFromArchivedReuse(item);
      final restored = item.copyWith(clearArchivedAt: true, updatedAt: _now());
      _items.insert(_insertIndexFor(restored), restored);
      _sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.unarchive,
          houseId: houseId,
          parentId: item.listId,
          entityId: item.id,
          createdAt: _now(),
        ),
      );
    }
    _cacheCurrentItems();
    notifyListeners();
  }

  /// Reverse a bulk unarchive done from the archive view: re-archive each
  /// snapshot so it returns to the archive list it left.
  void undoBatchUnarchive(List<ListItem> items) {
    if (items.isEmpty || !_isArchiveMode) return;
    final existing = {for (final i in _items) i.id};
    for (final item in items) {
      if (existing.contains(item.id)) continue;
      _addToArchivedReuse(item);
      _items.insert(_insertIndexFor(item), item);
      _sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.archive,
          houseId: houseId,
          parentId: item.listId,
          entityId: item.id,
          createdAt: _now(),
        ),
      );
    }
    notifyListeners();
  }

  /// Reverse a bulk restore done from the trash view: re-trash each snapshot so
  /// it returns to the trash list it left.
  void undoBatchRestore(List<ListItem> items) {
    if (items.isEmpty || !_isTrashMode) return;
    final existing = {for (final i in _items) i.id};
    for (final item in items) {
      if (existing.contains(item.id)) continue;
      _items.insert(_insertIndexFor(item), item);
      _sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.delete,
          houseId: houseId,
          parentId: item.listId,
          entityId: item.id,
          createdAt: _now(),
        ),
      );
    }
    notifyListeners();
  }

  /// Return every item to its original category. Items may have had different
  /// categories, so the reverse is grouped per original category.
  void undoBatchSetCategory(List<ListItem> items) {
    if (items.isEmpty) return;
    final byId = {for (final it in items) it.id: it};
    _items = [
      for (final i in _items)
        if (byId[i.id] case final original?)
          i.copyWith(
            categoryId: original.categoryId,
            clearCategory: original.categoryId == null,
            updatedAt: _now(),
          )
        else
          i,
    ];
    _cacheCurrentItems();
    final byCategory = <int?, List<int>>{};
    for (final it in items) {
      byCategory.putIfAbsent(it.categoryId, () => []).add(it.id);
    }
    for (final entry in byCategory.entries) {
      _enqueueBatch('category', entry.value, extra: {'categoryId': entry.key});
    }
    notifyListeners();
  }

  /// Return every item to its original store set. Items may have had different
  /// sets, so the reverse is grouped per original set (keyed by its sorted ids)
  /// into one batch op each.
  void undoBatchSetStores(List<ListItem> items) {
    if (items.isEmpty) return;
    final byId = {for (final it in items) it.id: it};
    _items = [
      for (final i in _items)
        if (byId[i.id] case final original?)
          i.copyWith(storeIds: List.of(original.storeIds), updatedAt: _now())
        else
          i,
    ];
    _cacheCurrentItems();
    final groups = <String, List<int>>{};
    final storeSets = <String, List<int>>{};
    for (final it in items) {
      final key = (List.of(it.storeIds)..sort()).join(',');
      groups.putIfAbsent(key, () => []).add(it.id);
      storeSets[key] = it.storeIds;
    }
    for (final entry in groups.entries) {
      _enqueueBatch(
        'stores',
        entry.value,
        extra: {'storeIds': storeSets[entry.key]!},
      );
    }
    notifyListeners();
  }

  /// Return every item to its original label set. Items may have had different
  /// sets, so the reverse is grouped per original set (keyed by its sorted ids)
  /// into one batch op each. Mirrors [undoBatchSetStores].
  void undoBatchSetLabels(List<ListItem> items) {
    if (items.isEmpty) return;
    final byId = {for (final it in items) it.id: it};
    _items = [
      for (final i in _items)
        if (byId[i.id] case final original?)
          i.copyWith(labelIds: List.of(original.labelIds), updatedAt: _now())
        else
          i,
    ];
    _cacheCurrentItems();
    final groups = <String, List<int>>{};
    final labelSets = <String, List<int>>{};
    for (final it in items) {
      final key = (List.of(it.labelIds)..sort()).join(',');
      groups.putIfAbsent(key, () => []).add(it.id);
      labelSets[key] = it.labelIds;
    }
    for (final entry in groups.entries) {
      _enqueueBatch(
        'labels',
        entry.value,
        extra: {'labelIds': labelSets[entry.key]!},
      );
    }
    notifyListeners();
  }
}
