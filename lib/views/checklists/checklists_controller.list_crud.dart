part of 'checklists_controller.dart';

extension ChecklistsControllerListCrud on ChecklistsController {
  Future<void> reorderLists(int oldIndex, int newIndex) async {
    if (_listSort != 'custom') return;
    if (oldIndex == newIndex) return;

    final ordered = sortedLists;
    final moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);

    final order = <Map<String, int>>[];
    for (var i = 0; i < ordered.length; i++) {
      order.add({'id': ordered[i].id, 'sortOrder': i});
    }

    final byId = {for (final l in _lists) l.id: l};
    _lists = [
      for (var i = 0; i < ordered.length; i++)
        byId[ordered[i].id]!.copyWith(sortOrder: i),
    ];
    _checklistService.cacheLists(houseId, _lists);
    notifyListeners();

    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.reorder,
        houseId: houseId,
        body: {'order': order},
        createdAt: _now(),
      ),
    );
  }

  Future<ChecklistList> createList({
    required String name,
    String? description,
    String? icon,
    String? color,
  }) async {
    final tempId = _sync.newTempId();
    final synthetic = ChecklistList(
      id: tempId,
      houseId: houseId,
      name: name,
      description: description,
      icon: icon ?? 'list',
      color: color,
      sortOrder: _lists.length,
      createdAt: _now(),
      updatedAt: _now(),
    );
    _lists = [..._lists, synthetic];
    _checklistService.cacheLists(houseId, _lists);
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.create,
        houseId: houseId,
        tempEntityId: tempId,
        body: {
          'name': name,
          'description': ?description,
          'icon': ?icon,
          'color': ?color,
        },
        createdAt: _now(),
      ),
    );
    return synthetic;
  }

  Future<void> updateList(
    ChecklistList list, {
    required String name,
    required String icon,
    String? color,
  }) async {
    if (list.id == kAllListsId) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final unchanged =
        trimmed == list.name && icon == list.icon && color == list.color;
    if (unchanged) return;

    final optimistic = list.copyWith(
      name: trimmed,
      icon: icon,
      color: color,
      updatedAt: _now(),
    );
    _lists = [for (final l in _lists) l.id == list.id ? optimistic : l];
    if (_currentList?.id == list.id) _currentList = optimistic;
    _checklistService.cacheLists(houseId, _lists);
    notifyListeners();

    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.update,
        houseId: houseId,
        entityId: list.id < 0 ? null : list.id,
        tempEntityId: list.id < 0 ? list.id : null,
        body: {'name': trimmed, 'icon': icon, 'color': ?color},
        createdAt: _now(),
      ),
    );
  }

  Future<void> setListDeleteOnDoneDefault(bool value) async {
    final list = _currentList;
    if (list == null || list.id == kAllListsId) return;
    if (list.deleteOnDoneDefault == value) return;

    final optimistic = list.copyWith(
      deleteOnDoneDefault: value,
      updatedAt: _now(),
    );
    _currentList = optimistic;
    _lists = [for (final l in _lists) l.id == optimistic.id ? optimistic : l];
    _checklistService.cacheLists(houseId, _lists);
    notifyListeners();

    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.update,
        houseId: houseId,
        entityId: list.id < 0 ? null : list.id,
        tempEntityId: list.id < 0 ? list.id : null,
        body: {'deleteOnDoneDefault': value},
        createdAt: _now(),
      ),
    );
  }

  Future<void> setListHideProgressHero(bool value) async {
    final list = _currentList;
    if (list == null) return;
    if (list.hideProgressHero == value) return;

    // The All-lists view is synthetic — there's no server list to sync, so its
    // toggle lives in local prefs (keyed by id 0). Reflect it on the in-memory
    // sentinel so the card hides/shows immediately.
    if (list.id == kAllListsId) {
      _currentList = list.copyWith(hideProgressHero: value, updatedAt: _now());
      await PrefsService.instance.setAllListsProgressHeroHidden(value);
      notifyListeners();
      return;
    }

    // Client-only: the server has no progress card, so persist the dismissal
    // in local prefs instead of syncing it. [_applyLocalListPrefs] re-applies
    // it after every refresh so the card stays hidden.
    await PrefsService.instance.setListProgressHeroHidden(list.id, value);

    final updated = list.copyWith(hideProgressHero: value);
    _currentList = updated;
    _lists = [for (final l in _lists) l.id == updated.id ? updated : l];
    _checklistService.cacheLists(houseId, _lists);
    notifyListeners();
  }

  // -- Lists trash (the lists themselves) --

  Future<void> loadTrashedLists() async {
    try {
      _trashedLists = await _checklistService.getDeletedLists(houseId);
      notifyListeners();
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to load trashed lists: $e');
      rethrow;
    }
  }

  Future<void> deleteList(ChecklistList list) async {
    _lists.removeWhere((l) => l.id == list.id);
    _checklistService.cacheLists(houseId, _lists);
    if (_currentList?.id == list.id) {
      final next = _lists.isNotEmpty ? _lists.first : null;
      if (next != null) {
        await selectList(next);
      } else {
        _currentList = null;
        _items = [];
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.delete,
        houseId: houseId,
        entityId: list.id < 0 ? null : list.id,
        tempEntityId: list.id < 0 ? list.id : null,
        createdAt: _now(),
      ),
    );
  }

  Future<void> restoreList(ChecklistList list) async {
    _trashedLists.removeWhere((l) => l.id == list.id);
    final exists = _lists.any((l) => l.id == list.id);
    if (!exists) {
      _lists = [..._lists, list];
      _checklistService.cacheLists(houseId, _lists);
    }
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.restore,
        houseId: houseId,
        entityId: list.id,
        createdAt: _now(),
      ),
    );
  }

  Future<void> permanentlyDeleteList(ChecklistList list) async {
    _trashedLists.removeWhere((l) => l.id == list.id);
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.permanentDelete,
        houseId: houseId,
        entityId: list.id,
        createdAt: _now(),
      ),
    );
  }

  Future<void> emptyListsTrash() async {
    _trashedLists = [];
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.emptyTrash,
        houseId: houseId,
        createdAt: _now(),
      ),
    );
  }

  // -- Lists archive (the lists themselves) --
  //
  // The archive is the whole-list mirror of the item-level archive: a hidden
  // second state that behaves like trash but is never bulk-emptied or
  // auto-purged. It's served by a dedicated online-only endpoint, so
  // archive/unarchive call the service directly (rather than the offline sync
  // queue the trash actions use) and reconcile the active index optimistically.

  Future<void> loadArchivedLists() async {
    try {
      _archivedLists = await _checklistService.getArchivedLists(houseId);
      notifyListeners();
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to load archived lists: $e');
      rethrow;
    }
  }

  Future<void> archiveList(ChecklistList list) async {
    // Optimistically drop it from the active index and step off it if current.
    _lists.removeWhere((l) => l.id == list.id);
    _checklistService.cacheLists(houseId, _lists);
    if (_currentList?.id == list.id) {
      final next = _lists.isNotEmpty ? _lists.first : null;
      if (next != null) {
        await selectList(next);
      } else {
        _currentList = null;
        _items = [];
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
    try {
      await _checklistService.archiveList(houseId, list.id);
    } catch (e) {
      // Roll the list back onto the active index so it isn't lost on failure.
      if (!_lists.any((l) => l.id == list.id)) {
        _lists = [..._lists, _withLocalListPrefs(list)];
        _checklistService.cacheLists(houseId, _lists);
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> unarchiveList(ChecklistList list) async {
    _archivedLists.removeWhere((l) => l.id == list.id);
    final existed = _lists.any((l) => l.id == list.id);
    if (!existed) {
      _lists = [..._lists, _withLocalListPrefs(list)];
      _checklistService.cacheLists(houseId, _lists);
    }
    notifyListeners();
    try {
      final restored = await _checklistService.unarchiveList(houseId, list.id);
      final reconciled = _withLocalListPrefs(restored);
      final i = _lists.indexWhere((l) => l.id == list.id);
      if (i != -1) {
        _lists[i] = reconciled;
        if (_currentList?.id == list.id) _currentList = reconciled;
        _checklistService.cacheLists(houseId, _lists);
        notifyListeners();
      }
    } catch (e) {
      // Undo the optimistic re-add so the list stays put in the archive view.
      if (!existed) {
        _lists.removeWhere((l) => l.id == list.id);
        _checklistService.cacheLists(houseId, _lists);
      }
      if (!_archivedLists.any((l) => l.id == list.id)) {
        _archivedLists = [..._archivedLists, list];
      }
      notifyListeners();
      rethrow;
    }
  }
}
