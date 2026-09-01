part of 'checklists_controller.dart';

extension ChecklistsControllerItemCrud on ChecklistsController {
  Future<void> moveItem(ListItem item, int targetListId) async {
    // Cross-list move is online-only for v1 — its semantics interact with
    // both source and target list caches in ways that don't simplify well
    // through the basic SyncOp shapes. Falls back to a direct API call.
    final updated = await _checklistService.moveItem(
      houseId,
      item.listId,
      item.id,
      targetListId: targetListId,
    );
    if (isMetaMode) {
      // Meta view aggregates across lists — the item didn't leave the view,
      // it just changed listId.
      final idx = _items.indexWhere((i) => i.id == item.id);
      if (idx != -1) _items[idx] = updated;
      _cacheVisibleItems();
    } else {
      _items.removeWhere((i) => i.id == item.id);
      _checklistService.cacheItems(_currentList!.id, List.of(_items));
    }
    notifyListeners();
  }

  Future<void> copyItem(ListItem item, int targetListId) async {
    // Online-only for the same reason as [moveItem] — the new item lives on
    // a list the user isn't currently viewing, so cache reconciliation
    // doesn't fit the per-list SyncOp shapes.
    final created = await _checklistService.copyItem(
      houseId,
      item.listId,
      item.id,
      targetListId: targetListId,
    );
    if (isMetaMode) {
      // Meta view aggregates across lists — surface the new copy alongside
      // the original.
      _items = [created, ..._items];
      _cacheVisibleItems();
    }
    notifyListeners();
  }

  Future<ListItem> addItem({
    required String name,
    String? description,
    String? quantity,
    int? categoryId,
    List<int>? storeIds,
    List<int>? labelIds,
    String? rrule,
    bool? repeatFromCompletion,
    bool? deleteOnDone,
    String? barcode,
    List<ItemPrice>? prices,
    List<FieldValue>? customFields,
  }) async {
    final list = _currentList;
    if (list == null || list.id == kAllListsId) {
      throw StateError(
        list == null
            ? 'No list selected'
            : 'Use addItemTo() when no real list is selected',
      );
    }
    return addItemTo(
      targetListId: list.id,
      name: name,
      description: description,
      quantity: quantity,
      categoryId: categoryId,
      storeIds: storeIds,
      labelIds: labelIds,
      rrule: rrule,
      repeatFromCompletion: repeatFromCompletion,
      deleteOnDone: deleteOnDone,
      barcode: barcode,
      prices: prices,
      customFields: customFields,
    );
  }

  /// Adds an item to a specific list. Used by the All-lists view (where there
  /// is no implicit target) and as the underlying implementation of
  /// [addItem]. When the meta view is active, the per-list cache is not
  /// touched — the next time that list is opened it'll refetch.
  Future<ListItem> addItemTo({
    required int targetListId,
    required String name,
    String? description,
    String? quantity,
    int? categoryId,
    List<int>? storeIds,
    List<int>? labelIds,
    String? rrule,
    bool? repeatFromCompletion,
    bool? deleteOnDone,
    String? barcode,
    List<ItemPrice>? prices,
    List<FieldValue>? customFields,
  }) async {
    final listId = targetListId;
    final tempId = _sync.newTempId();
    final loginName = AuthService.instance.credentials?.loginName;
    final synthetic = ListItem(
      id: tempId,
      listId: listId,
      name: name,
      description: description,
      categoryId: categoryId,
      storeIds: storeIds ?? const [],
      labelIds: labelIds ?? const [],
      quantity: quantity,
      done: false,
      rrule: rrule,
      repeatFromCompletion: repeatFromCompletion ?? false,
      deleteOnDone: deleteOnDone ?? false,
      addedBy: loginName,
      barcode: barcode,
      prices: prices ?? const [],
      customFields: customFields ?? const [],
      sortOrder: 0,
      createdAt: _now(),
      updatedAt: _now(),
    );
    _items.insert(_insertIndexFor(synthetic), synthetic);
    // In meta mode `_items` is the aggregate across every list, so it's cached
    // under the All-lists slot rather than the target list's — the target list
    // refetches (and re-caches its own slot) when next opened.
    _cacheVisibleItems(listId);
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.create,
        houseId: houseId,
        parentId: listId,
        tempEntityId: tempId,
        body: {
          'name': name,
          'description': ?description,
          'quantity': ?quantity,
          'categoryId': ?categoryId,
          'storeIds': ?storeIds,
          'labelIds': ?labelIds,
          'rrule': ?rrule,
          'repeatFromCompletion': ?repeatFromCompletion,
          'deleteOnDone': ?deleteOnDone,
          'barcode': ?barcode,
          if (prices != null) 'prices': prices.map((p) => p.toJson()).toList(),
          if (customFields != null)
            'customFields': customFields.map((v) => v.toJson()).toList(),
        },
        createdAt: _now(),
      ),
    );
    return synthetic;
  }

  /// Finds an active (non-deleted) item in [targetListId] whose name matches
  /// [name] case-insensitively after trimming. Backs the "reuse existing
  /// items" flow. Works in both per-list and All-lists (meta) mode — in meta
  /// mode `_items` aggregates across lists, so the listId filter scopes the
  /// match to the chosen target list. Returns null if there's no match.
  ListItem? findExistingItem(int targetListId, String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final item in _items) {
      if (item.listId != targetListId) continue;
      if (item.deletedAt != null) continue;
      if (item.name.trim().toLowerCase() == normalized) return item;
    }
    return null;
  }

  /// Reuse an existing item instead of creating a duplicate: if it's currently
  /// done, toggle it back to active; if already active, do nothing.
  Future<void> reuseItem(ListItem item) async {
    if (item.done) await toggleItem(item);
  }

  /// Archived items on [listId] currently available as reuse suggestions.
  /// Returns what's loaded now (empty until the first fetch resolves); pair with
  /// [ensureArchivedReuseLoaded] to trigger that fetch.
  List<ListItem> archivedReuseCandidates(int listId) =>
      _archivedReuse[listId] ?? const [];

  /// Kick off the one-time lazy fetch of [listId]'s archived items for reuse
  /// suggestions. A no-op once requested. Merges the server result with any
  /// items archived locally this session (which the server may not have synced
  /// yet) and notifies listeners so the suggestions refresh.
  void ensureArchivedReuseLoaded(int listId) {
    if (_archivedReuseRequested.contains(listId)) return;
    _archivedReuseRequested.add(listId);
    unawaited(_fetchArchivedReuse(listId));
  }

  Future<void> _fetchArchivedReuse(int listId) async {
    try {
      final items = await _checklistService.getArchivedItems(houseId, listId);
      final fetchedIds = {for (final i in items) i.id};
      final sessionExtras = [
        for (final e in _archivedReuse[listId] ?? const <ListItem>[])
          if (!fetchedIds.contains(e.id)) e,
      ];
      _archivedReuse[listId] = [...items, ...sessionExtras];
      notifyListeners();
    } catch (e) {
      debugPrint(
        '[ChecklistsController] Failed to load archived reuse candidates: $e',
      );
      // Allow a later search to retry the fetch.
      _archivedReuseRequested.remove(listId);
    }
  }

  /// Reflect a just-archived item in the reuse suggestions immediately, without
  /// waiting for a server refetch or sync. No-op until the list's archive has
  /// been requested for suggestions.
  void _addToArchivedReuse(ListItem archived) {
    final list = _archivedReuse[archived.listId];
    if (list == null) return;
    if (list.any((i) => i.id == archived.id)) return;
    _archivedReuse[archived.listId] = [archived, ...list];
  }

  void _removeFromArchivedReuse(ListItem item) =>
      _archivedReuse[item.listId]?.removeWhere((i) => i.id == item.id);

  /// Reuse an archived suggestion: unarchive it back onto the active list, and
  /// if it was done, toggle it active so it returns as a fresh unchecked item.
  /// Drops it from the archived-reuse set so it isn't offered again.
  Future<void> reuseArchivedItem(ListItem item) async {
    await unarchiveItem(item);
    if (item.done) {
      final restored = _items.firstWhere(
        (i) => i.id == item.id,
        orElse: () => item,
      );
      if (restored.done) await toggleItem(restored);
    }
  }

  Future<ListItem> updateItem(
    ListItem item, {
    String? name,
    String? description,
    String? quantity,
    int? categoryId,
    bool clearCategory = false,
    List<int>? storeIds,
    List<int>? labelIds,
    String? rrule,
    bool? repeatFromCompletion,
    bool? deleteOnDone,
    String? barcode,
    List<ItemPrice>? prices,
    List<FieldValue>? customFields,
  }) async {
    final updated = item.copyWith(
      name: name,
      description: description,
      quantity: quantity,
      categoryId: categoryId,
      clearCategory: clearCategory,
      storeIds: storeIds,
      labelIds: labelIds,
      rrule: rrule,
      repeatFromCompletion: repeatFromCompletion,
      deleteOnDone: deleteOnDone,
      barcode: barcode,
      // null leaves prices unchanged; a list (even empty) replaces them.
      prices: prices,
      // Same contract for custom-field values.
      customFields: customFields,
      updatedAt: _now(),
    );
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = updated;
      _cacheVisibleItems(item.listId);
      notifyListeners();
    }
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.update,
        houseId: houseId,
        parentId: item.listId,
        entityId: item.id < 0 ? null : item.id,
        tempEntityId: item.id < 0 ? item.id : null,
        body: {
          'name': ?name,
          'description': ?description,
          'quantity': ?quantity,
          if (clearCategory) 'clearCategory': true,
          'categoryId': ?categoryId,
          'storeIds': ?storeIds,
          'labelIds': ?labelIds,
          'rrule': ?rrule,
          'repeatFromCompletion': ?repeatFromCompletion,
          'deleteOnDone': ?deleteOnDone,
          'barcode': ?barcode,
          if (prices != null) 'prices': prices.map((p) => p.toJson()).toList(),
          if (customFields != null)
            'customFields': customFields.map((v) => v.toJson()).toList(),
        },
        createdAt: _now(),
      ),
    );
    return updated;
  }

  Future<ListItem> uploadItemImage(
    ListItem item, {
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (item.id < 0) {
      // Photo uploads need a real server id, but this item's optimistic create
      // hasn't synced yet (its id is still the negative temp id). Stash the
      // upload keyed by that temp id; `_onSyncApplied` fires it once the create
      // resolves to a real id. Returning the item unchanged keeps
      // the save flow succeeding — the image lands a moment later.
      _pendingImageUploads[item.id] = _PendingImageUpload(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
      return item;
    }
    final updated = await _checklistService.uploadItemImage(
      houseId,
      item.listId,
      item.id,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = updated;
      _cacheVisibleItems(item.listId);
      notifyListeners();
    }
    return updated;
  }

  Future<void> deleteItemImage(ListItem item) async {
    if (item.id < 0) return;
    await _checklistService.deleteItemImage(houseId, item.listId, item.id);
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item.copyWith(clearImage: true, updatedAt: _now());
      _cacheVisibleItems(item.listId);
      notifyListeners();
    }
  }

  Future<void> deleteItem(ListItem item) async {
    _items.removeWhere((i) => i.id == item.id);
    _cacheVisibleItems(item.listId);
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.delete,
        houseId: houseId,
        parentId: item.listId,
        entityId: item.id < 0 ? null : item.id,
        tempEntityId: item.id < 0 ? item.id : null,
        createdAt: _now(),
      ),
    );
  }

  Future<void> restoreItem(ListItem item) async {
    _items.removeWhere((i) => i.id == item.id);
    if (!_isTrashMode) {
      _items.add(item.copyWith(clearDeletedAt: true, updatedAt: _now()));
      _cacheVisibleItems(item.listId);
    }
    notifyListeners();
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

  Future<void> permanentlyDeleteItem(ListItem item) async {
    _items.removeWhere((i) => i.id == item.id);
    if (!isSoftView) {
      _cacheVisibleItems(item.listId);
    }
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.permanentDelete,
        houseId: houseId,
        parentId: item.listId,
        entityId: item.id,
        createdAt: _now(),
      ),
    );
  }

  /// Archive an active item. Mirrors [deleteItem] but sets `archivedAt` instead
  /// of `deletedAt`; the item leaves the active list for the archive view.
  Future<void> archiveItem(ListItem item) async {
    _items.removeWhere((i) => i.id == item.id);
    _addToArchivedReuse(item.copyWith(archivedAt: _now()));
    _cacheVisibleItems(item.listId);
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.archive,
        houseId: houseId,
        parentId: item.listId,
        entityId: item.id < 0 ? null : item.id,
        tempEntityId: item.id < 0 ? item.id : null,
        createdAt: _now(),
      ),
    );
  }

  /// Return an archived item to the active list. Mirrors [restoreItem]: from
  /// the archive view the item just leaves; from the active list (undo of a
  /// just-archived item) it reappears with `archivedAt` cleared.
  Future<void> unarchiveItem(ListItem item) async {
    _items.removeWhere((i) => i.id == item.id);
    _removeFromArchivedReuse(item);
    if (!_isArchiveMode) {
      _items.add(item.copyWith(clearArchivedAt: true, updatedAt: _now()));
      _cacheVisibleItems(item.listId);
    }
    notifyListeners();
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

  Future<void> emptyTrash() async {
    if (_currentList == null || _currentList!.id == kAllListsId) return;
    if (_isTrashMode) {
      _items = [];
      notifyListeners();
    }
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.emptyTrash,
        houseId: houseId,
        parentId: _currentList!.id,
        createdAt: _now(),
      ),
    );
  }

  Future<void> toggleItem(ListItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    _items[index] = item.copyWith(done: !item.done, updatedAt: _now());
    _cacheVisibleItems(item.listId);
    notifyListeners();

    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.toggle,
        houseId: houseId,
        parentId: item.listId,
        entityId: item.id < 0 ? null : item.id,
        tempEntityId: item.id < 0 ? item.id : null,
        createdAt: _now(),
      ),
    );
  }

  /// Uploads an image that was staged against [tempId] before the item's
  /// optimistic create had a real server id, now that the create resolved to
  /// [item]. Fire-and-forget: the originating save call already
  /// returned, so failures are logged rather than surfaced.
  void _flushPendingImageUpload(int tempId, ListItem item) {
    final pending = _pendingImageUploads.remove(tempId);
    if (pending == null) return;
    unawaited(
      uploadItemImage(
        item,
        bytes: pending.bytes,
        fileName: pending.fileName,
        mimeType: pending.mimeType,
      ).catchError((Object e) {
        debugPrint('[Checklists] deferred image upload failed: $e');
        return item;
      }),
    );
  }
}
