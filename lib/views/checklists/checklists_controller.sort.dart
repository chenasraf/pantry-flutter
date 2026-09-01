part of 'checklists_controller.dart';

extension ChecklistsControllerSort on ChecklistsController {
  Future<void> setSortBy(String sort) async {
    if (sort == _sortBy) return;
    _sortBy = sort;
    _checklistService.cache.set('sortBy:$houseId', sort);
    notifyListeners();

    unawaited(_persistSortPref(sort));

    if (_currentList != null) {
      // Only the current list's cached snapshot is now stale-ordered; drop just
      // that one so the other lists keep their offline caches. The
      // re-warm below refreshes them in the new order while online.
      if (!isMetaMode) _checklistService.invalidateItemsFor(_currentList!.id);
      await selectList(_currentList!, refreshInPlace: true);
      unawaited(_precacheListItems());
    }
  }

  Future<void> _persistSortPref(String sort) async {
    try {
      await _checklistService.setItemSortPref(houseId, sort);
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to persist sort pref: $e');
    }
  }

  Future<void> onCategoriesChanged() async {
    try {
      final results = await Future.wait([
        _checklistService.getHousePrefs(houseId),
        _categoryService.getCategories(houseId),
      ]);
      final prefs = results[0] as Map<String, dynamic>;
      final cats = results[1] as List<models.Category>;
      _categorySort = prefs['categorySort'] as String? ?? 'custom';
      _categories = {for (final c in cats) c.id: c};
      _checklistService.cache.set('categorySort:$houseId', _categorySort);

      if (_sortBy == 'category') _resortItemsByCategory();
      notifyListeners();

      // Re-scoping a category detaches it from items on other lists server-side
      // (their `categoryId` is cleared), so the current view's cached items may
      // now be stale. Refetch them so a detached item doesn't keep showing a
      // category it no longer has. Only relevant when scoping is available.
      if (hasFeature('category-lists') && _currentList != null && !isSoftView) {
        await selectList(_currentList!, refreshInPlace: true);
      }
    } catch (e) {
      debugPrint(
        '[ChecklistsController] Failed to refresh after categories changed: $e',
      );
    }
  }

  /// Refetch just the categories and adopt them, keeping the on-disk cache
  /// honest. Used after a server-side cascade (a permanent list delete) prunes
  /// scoped categories out from under us.
  Future<void> _refreshCategories() async {
    try {
      final cats = await _categoryService.getCategories(houseId);
      _categories = {for (final c in cats) c.id: c};
      notifyListeners();
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to refresh categories: $e');
    }
  }

  /// Refetch just the labels and adopt them, keeping the on-disk cache honest.
  /// Used after a server-side cascade (a permanent list delete) prunes scoped
  /// labels out from under us.
  Future<void> _refreshLabels() async {
    try {
      final labels = await _labelService.getLabels(houseId);
      _labels = {for (final l in labels) l.id: l};
      notifyListeners();
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to refresh labels: $e');
    }
  }

  Future<void> onStoresChanged() async {
    if (!hasFeature('stores')) return;
    try {
      final results = await Future.wait([
        _checklistService.getHousePrefs(houseId),
        _storeService.getStores(houseId),
      ]);
      final prefs = results[0] as Map<String, dynamic>;
      final stores = results[1] as List<models.Store>;
      _storeSort = prefs['storeSort'] as String? ?? 'name_asc';
      _stores = {for (final s in stores) s.id: s};
      _checklistService.cache.set('storeSort:$houseId', _storeSort);
      notifyListeners();
    } catch (e) {
      debugPrint(
        '[ChecklistsController] Failed to refresh after stores changed: $e',
      );
    }
  }

  Future<void> onLabelsChanged() async {
    if (!hasFeature('labels')) return;
    try {
      final results = await Future.wait([
        _checklistService.getHousePrefs(houseId),
        _labelService.getLabels(houseId),
      ]);
      final prefs = results[0] as Map<String, dynamic>;
      final labels = results[1] as List<models.Label>;
      _labelSort = prefs['labelSort'] as String? ?? 'name_asc';
      _labels = {for (final l in labels) l.id: l};
      _checklistService.cache.set('labelSort:$houseId', _labelSort);
      notifyListeners();

      // Re-scoping a label detaches it from items on other lists server-side,
      // so the current view's cached items may now be stale. Refetch them so a
      // detached item doesn't keep showing a label it no longer has. Only
      // relevant when scoping is available.
      if (hasFeature('label-lists') && _currentList != null && !isSoftView) {
        await selectList(_currentList!, refreshInPlace: true);
      }
    } catch (e) {
      debugPrint(
        '[ChecklistsController] Failed to refresh after labels changed: $e',
      );
    }
  }

  void _resortItemsByCategory() {
    final sorted = sortedCategories;
    final rank = <int, int>{};
    for (var i = 0; i < sorted.length; i++) {
      rank[sorted[i].id] = i;
    }
    const uncategorizedRank = 1 << 30;
    int rankOf(int? id) =>
        id == null ? uncategorizedRank : (rank[id] ?? uncategorizedRank);

    List<ListItem> stableByCategory(Iterable<ListItem> source) {
      final indexed = source.toList().asMap().entries.toList();
      indexed.sort((a, b) {
        final r = rankOf(
          a.value.categoryId,
        ).compareTo(rankOf(b.value.categoryId));
        return r != 0 ? r : a.key.compareTo(b.key);
      });
      return indexed.map((e) => e.value).toList();
    }

    final unchecked = stableByCategory(_items.where((i) => !i.done));
    final checked = stableByCategory(_items.where((i) => i.done));
    _items = [...unchecked, ...checked];
    if (_currentList != null) {
      _checklistService.cacheItems(_currentList!.id, List.of(_items));
    }
  }

  /// Position at which [item] should be inserted into [target] (defaulting to
  /// the live `_items`) to keep the active sort intact. Uses [effectiveSortBy]
  /// so it agrees with the order the server returns for the current view.
  int _insertIndexFor(ListItem item, [List<ListItem>? target]) {
    final sorted = sortedCategories;
    final rank = <int, int>{};
    for (var i = 0; i < sorted.length; i++) {
      rank[sorted[i].id] = i;
    }
    const uncategorizedRank = 1 << 30;
    int rankOf(int? id) =>
        id == null ? uncategorizedRank : (rank[id] ?? uncategorizedRank);

    return checklistInsertIndex(
      target ?? _items,
      effectiveSortBy,
      item,
      rankOf,
    );
  }

  Future<void> setListSort(String sort) async {
    if (sort == _listSort) return;
    _listSort = sort;
    _checklistService.cache.set('listSort:$houseId', sort);
    notifyListeners();

    unawaited(_persistListSortPref(sort));
  }

  Future<void> _persistListSortPref(String sort) async {
    try {
      await _checklistService.setListSortPref(houseId, sort);
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to persist list sort pref: $e');
    }
  }

  /// Re-orders `_items` into the display order the current sort implies after a
  /// drag has rewritten `sortOrder`. Custom and store sort read straight from
  /// `sortOrder` (store grouping re-sorts each column itself, so only presence
  /// matters); category sort groups by category rank first, then `sortOrder`
  /// within each category — mirroring the server's `sortBy=category` order.
  List<ListItem> _displaySorted(List<ListItem> items) {
    int bySortOrder(ListItem a, ListItem b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }

    final sorted = [...items];
    if (effectiveSortBy == 'category') {
      final ranked = sortedCategories;
      final rank = <int, int>{};
      for (var i = 0; i < ranked.length; i++) {
        rank[ranked[i].id] = i;
      }
      const uncategorizedRank = 1 << 30;
      int rankOf(int? id) =>
          id == null ? uncategorizedRank : (rank[id] ?? uncategorizedRank);
      sorted.sort((a, b) {
        final r = rankOf(a.categoryId).compareTo(rankOf(b.categoryId));
        return r != 0 ? r : bySortOrder(a, b);
      });
    } else {
      sorted.sort(bySortOrder);
    }
    return sorted;
  }

  /// Persists a full renumbered order across the list. Shared by the drag
  /// handlers ([reorderItems]) and the "Reset custom order" action
  /// ([resetOrder]): applies the new `sortOrder` to every item, re-sorts the
  /// view, caches, and enqueues one reorder op carrying the whole set.
  void _applyItemOrder(List<({int id, int sortOrder})> order) {
    if (order.isEmpty || _currentList == null) return;
    final orderMap = {for (final o in order) o.id: o.sortOrder};
    _items = [
      for (final i in _items)
        orderMap.containsKey(i.id) ? i.copyWith(sortOrder: orderMap[i.id]) : i,
    ];
    _items = _displaySorted(_items);
    _checklistService.cacheItems(_currentList!.id, List.of(_items));
    notifyListeners();

    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.reorder,
        houseId: houseId,
        parentId: _currentList!.id,
        body: {
          'order': [
            for (final o in order) {'id': o.id, 'sortOrder': o.sortOrder},
          ],
        },
        createdAt: _now(),
      ),
    );
  }

  /// Commit a drag-to-reorder. [scope] is the ordered items the drag was
  /// constrained to (the whole active partition in custom sort, a category
  /// block in category sort, a store column in store sort), including the
  /// dragged item. [oldIndex] indexes the dragged item within [scope];
  /// [newIndex] is its drop position with the dragged item removed (as supplied
  /// by the reorderable's `onReorderItem`).
  ///
  /// Only the dragged item moves: every other item — checked items and items in
  /// other groups — keeps its stored slot, so unchecking returns items to their
  /// true position and a within-group drag doesn't disturb siblings.
  Future<void> reorderItems(
    List<ListItem> scope,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex == newIndex) return;
    if (_currentList == null) return;
    // Meta view aggregates across lists; per-list sort_order is meaningless
    // here.
    if (isMetaMode) return;
    if (oldIndex < 0 || oldIndex >= scope.length) return;

    final order = reorderToTrueOrder(
      _items,
      scope,
      scope[oldIndex].id,
      newIndex,
    );
    _applyItemOrder(order);
  }

  /// Re-seed the custom order from [basis] (`dateAdded` / `name_asc` /
  /// `name_desc`) and leave the list hand-reorderable. In category sort the
  /// reseed keeps the category grouping; elsewhere it's a flat reseed. No-op
  /// in the meta view (no per-list custom order) or when there's nothing to
  /// order.
  Future<void> resetOrder(String basis) async {
    if (_currentList == null || isMetaMode) return;
    if (_items.isEmpty) return;
    // Only the category view needs the grouped reseed, and only when the server
    // orders within-category by sortOrder (same gate as within-group drag);
    // otherwise a flat reseed, which sticks on any server.
    final categoryOrder =
        effectiveSortBy == 'category' && canReorderWithinGroups
        ? [for (final c in sortedCategories) c.id]
        : null;
    final order = reseedOrder(_items, basis, categoryOrder);
    _applyItemOrder(order);
  }

  /// Clear the done-state on every checked item in the current list in one
  /// batch. Gathers *all* done items (unfiltered — "uncheck all in the list",
  /// not just what a search/category filter shows), applies the optimistic
  /// uncheck, and enqueues a single batch op reconciled in [_onSyncApplied].
  void uncheckAll() {
    if (!canUncheckAll) return;
    final ids = [
      for (final i in _items)
        if (i.done && i.deletedAt == null) i.id,
    ];
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    _items = [
      for (final i in _items)
        idSet.contains(i.id) ? i.copyWith(done: false, updatedAt: _now()) : i,
    ];
    _cacheCurrentItems();
    _enqueueBatch('uncheck', ids);
    notifyListeners();
  }

  /// Soft-delete every done item in the current list in one batch. Gathers
  /// *all* done items (unfiltered — "remove all done in the list", not just
  /// what a search/category filter shows), removes them optimistically, and
  /// enqueues a single batch delete op. Returns the removed snapshots so the
  /// caller can offer undo via [undoBatchDelete].
  List<ListItem> removeAllDone() {
    if (!canRemoveAllDone) return const [];
    final removed = [
      for (final i in _items)
        if (i.done && i.deletedAt == null) i,
    ];
    if (removed.isEmpty) return const [];
    _items = reconcileRemoveIds(_items, {for (final i in removed) i.id});
    _cacheCurrentItems();
    _enqueueBatch('delete', [for (final i in removed) i.id]);
    notifyListeners();
    return removed;
  }
}
