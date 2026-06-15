import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/member.dart';
import 'package:pantry/services/category_service.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/house_service.dart';
import 'package:pantry/services/server_version_service.dart';

class ChecklistsController extends ChangeNotifier {
  final int houseId;

  ChecklistsController({required this.houseId});

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  List<ChecklistList> _lists = [];
  List<ChecklistList> get lists => _lists;

  ChecklistList? _currentList;
  ChecklistList? get currentList => _currentList;

  List<ListItem> _items = [];
  List<ListItem> get items => _items;

  Map<int, models.Category> _categories = {};
  Map<int, models.Category> get categories => _categories;

  List<models.Category> get sortedCategories =>
      CategoryService.sortCategories(_categories.values, _categorySort);

  String _sortBy = 'custom';
  String get sortBy => _sortBy;

  String _categorySort = 'custom';
  String get categorySort => _categorySort;

  String _listSort = 'custom';
  String get listSort => _listSort;

  List<ChecklistList> get sortedLists =>
      ChecklistService.sortLists(_lists, _listSort);

  bool _showAddedBy = false;
  bool get showAddedBy => _showAddedBy;

  Map<String, Member> _members = {};
  Map<String, Member> get members => _members;

  bool _isTrashMode = false;
  bool get isTrashMode => _isTrashMode;

  List<ChecklistList> _trashedLists = [];
  List<ChecklistList> get trashedLists => _trashedLists;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  ChecklistService get _checklistService => ChecklistService.instance;
  CategoryService get _categoryService => CategoryService.instance;
  HouseService get _houseService => HouseService.instance;

  Future<void> load() async {
    _error = null;

    // Restore all from cache
    _restoreFromCache();

    if (_lists.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _checklistService.getLists(houseId),
        _categoryService.getCategories(houseId),
      ]);

      _lists = results[0] as List<ChecklistList>;
      _checklistService.cacheLists(houseId, _lists);

      final cats = results[1] as List<models.Category>;
      _categories = {for (final c in cats) c.id: c};

      // House prefs (sort + showAddedBy + categorySort) are non-fatal
      try {
        final prefs = await _checklistService.getHousePrefs(houseId);
        // The presence of `showAddedBy` in the response is the discriminator
        // for the `item-authors` feature on pre-capability servers.
        ServerVersionService.instance.observeHousePrefs(prefs);
        _sortBy = prefs['checklistItemSort'] as String? ?? 'custom';
        _showAddedBy = prefs['showAddedBy'] as bool? ?? false;
        _categorySort = prefs['categorySort'] as String? ?? 'custom';
        _listSort = prefs['checklistListSort'] as String? ?? 'custom';
        _checklistService.cache.set('sortBy', _sortBy);
        _checklistService.cache.set('showAddedBy', _showAddedBy);
        _checklistService.cache.set('categorySort', _categorySort);
        _checklistService.cache.set('listSort', _listSort);
      } catch (e) {
        debugPrint('[ChecklistsController] Failed to load house prefs: $e');
      }

      // Members lookup is non-fatal
      try {
        final list = await _houseService.getMembers(houseId);
        _members = {for (final m in list) m.userId: m};
      } catch (e) {
        debugPrint('[ChecklistsController] Failed to load members: $e');
      }

      if (_lists.isNotEmpty) {
        final target = _currentList != null
            ? _lists.cast<ChecklistList?>().firstWhere(
                    (l) => l!.id == _currentList!.id,
                    orElse: () => null,
                  ) ??
                  _lists.first
            : _lists.first;
        await selectList(target);
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to load: $e');
      if (_lists.isEmpty) {
        _error = m.checklists.failedToLoad;
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _restoreFromCache() {
    // Sort preference
    _sortBy = _checklistService.cache.get<String>('sortBy') ?? 'custom';
    _showAddedBy = _checklistService.cache.get<bool>('showAddedBy') ?? false;
    _categorySort =
        _checklistService.cache.get<String>('categorySort') ?? 'custom';
    _listSort = _checklistService.cache.get<String>('listSort') ?? 'custom';

    // Members
    final cachedMembers = _houseService.getCachedMembers(houseId);
    if (cachedMembers != null) {
      _members = {for (final m in cachedMembers) m.userId: m};
    }

    // Categories
    final cachedCats = _categoryService.getCached(houseId);
    if (cachedCats != null && _categories.isEmpty) {
      _categories = {for (final c in cachedCats) c.id: c};
    }

    // Lists + items
    final cachedLists = _checklistService.getCachedLists(houseId);
    if (cachedLists != null && _lists.isEmpty) {
      _lists = cachedLists;
      if (_lists.isNotEmpty) {
        final savedId = _checklistService.selectedListId;
        _currentList =
            (savedId != null
                ? _lists.cast<ChecklistList?>().firstWhere(
                    (l) => l!.id == savedId,
                    orElse: () => null,
                  )
                : null) ??
            _lists.first;
        final cachedItems = _checklistService.getCachedItems(_currentList!.id);
        if (cachedItems != null) {
          _items = cachedItems;
          _isLoading = false;
          notifyListeners();
        }
      }
    }
  }

  Future<void> selectList(ChecklistList list) async {
    _currentList = list;
    _checklistService.selectedListId = list.id;

    if (_isTrashMode) {
      _items = [];
      _isLoading = true;
      notifyListeners();
      await _loadTrashItems(list);
      return;
    }

    // Show cached items immediately, or spinner if no cache for this list
    final cached = _checklistService.getCachedItems(list.id);
    if (cached != null) {
      _items = cached;
      _isLoading = false;
      notifyListeners();
    } else {
      _items = [];
      _isLoading = true;
      notifyListeners();
    }

    // Fetch fresh data in background
    try {
      final freshItems = await _checklistService.getItems(
        houseId,
        list.id,
        sortBy: _sortBy,
      );
      _checklistService.cacheItems(list.id, freshItems);
      if (_currentList?.id == list.id && !_isTrashMode) {
        _items = freshItems;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to load items: $e');
      if (cached == null) {
        _error = m.checklists.failedToLoadItems;
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadTrashItems(ChecklistList list) async {
    try {
      final trashItems = await _checklistService.getDeletedItems(
        houseId,
        list.id,
      );
      if (_currentList?.id == list.id && _isTrashMode) {
        _items = trashItems;
        _error = null;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to load trash: $e');
      if (_currentList?.id == list.id && _isTrashMode) {
        _error = m.checklists.failedToLoadItems;
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> setTrashMode(bool enabled) async {
    if (_isTrashMode == enabled) return;
    _isTrashMode = enabled;
    if (_currentList != null) {
      await selectList(_currentList!);
    } else {
      notifyListeners();
    }
  }

  Future<void> setSortBy(String sort) async {
    if (sort == _sortBy) return;
    _sortBy = sort;
    _checklistService.cache.set('sortBy', sort);
    notifyListeners();

    // Fire-and-forget the server persist so a slow or failing pref write
    // never blocks the item reload.
    unawaited(_persistSortPref(sort));

    // Reload items with new sort
    if (_currentList != null) {
      _checklistService.invalidateItems();
      await selectList(_currentList!);
    }
  }

  Future<void> _persistSortPref(String sort) async {
    try {
      await _checklistService.setItemSortPref(houseId, sort);
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to persist sort pref: $e');
    }
  }

  /// Refetch categories + categorySort pref and resort items locally if the
  /// active item sort is "category". Used after the manage-categories view
  /// closes so we don't have to refetch the full item list just to reflect a
  /// new category ordering.
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
      _checklistService.cache.set('categorySort', _categorySort);

      if (_sortBy == 'category') _resortItemsByCategory();
      notifyListeners();
    } catch (e) {
      debugPrint(
        '[ChecklistsController] Failed to refresh after categories changed: $e',
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

    // Stable sort by category rank, preserving the existing order within each
    // category. We sort the undone and done partitions independently so the
    // checked/unchecked split in the UI keeps working. Dart's List.sort is
    // not guaranteed stable, so we tie-break on the original index.
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

  Future<void> setShowAddedBy(bool value) async {
    if (value == _showAddedBy) return;
    _showAddedBy = value;
    _checklistService.cache.set('showAddedBy', value);
    notifyListeners();

    try {
      await _checklistService.setShowAddedByPref(houseId, value);
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to persist showAddedBy: $e');
    }
  }

  Future<void> setListSort(String sort) async {
    if (sort == _listSort) return;
    _listSort = sort;
    _checklistService.cache.set('listSort', sort);
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

  Future<void> reorderLists(int oldIndex, int newIndex) async {
    if (_listSort != 'custom') return;
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex == newIndex) return;

    final ordered = sortedLists;
    final moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);

    final order = <({int id, int sortOrder})>[];
    for (var i = 0; i < ordered.length; i++) {
      order.add((id: ordered[i].id, sortOrder: i));
    }

    final byId = {for (final l in _lists) l.id: l};
    _lists = [
      for (var i = 0; i < ordered.length; i++)
        _withSortOrder(byId[ordered[i].id]!, i),
    ];
    _checklistService.cacheLists(houseId, _lists);
    notifyListeners();

    try {
      await _checklistService.reorderLists(houseId, order);
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to reorder lists: $e');
    }
  }

  ChecklistList _withSortOrder(ChecklistList list, int sortOrder) =>
      ChecklistList(
        id: list.id,
        houseId: list.houseId,
        name: list.name,
        description: list.description,
        icon: list.icon,
        color: list.color,
        sortOrder: sortOrder,
        deleteOnDoneDefault: list.deleteOnDoneDefault,
        createdAt: list.createdAt,
        updatedAt: list.updatedAt,
      );

  Future<void> reorderItems(
    List<ListItem> partition,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex == newIndex) return;

    final item = partition.removeAt(oldIndex);
    partition.insert(newIndex, item);

    // Reassign sortOrder within the partition
    final order = <({int id, int sortOrder})>[];
    for (var i = 0; i < partition.length; i++) {
      order.add((id: partition[i].id, sortOrder: i));
    }

    // Rebuild full items list preserving partition order
    final unchecked = _items.where((i) => !i.done).toList();
    final checked = _items.where((i) => i.done).toList();
    final isUncheckedPartition = partition.isNotEmpty && !partition.first.done;
    if (isUncheckedPartition) {
      _items = [...partition, ...checked];
    } else {
      _items = [...unchecked, ...partition];
    }

    _checklistService.cacheItems(_currentList!.id, List.of(_items));
    notifyListeners();

    try {
      await _checklistService.reorderItems(houseId, _currentList!.id, order);
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to reorder: $e');
    }
  }

  Future<void> refresh() async {
    await load();
    _checklistService.invalidateItems(keepListId: _currentList?.id);
  }

  Future<ChecklistList> createList({
    required String name,
    String? description,
    String? icon,
    String? color,
  }) async {
    final list = await _checklistService.createList(
      houseId,
      name: name,
      description: description,
      icon: icon,
      color: color,
    );
    _lists = [..._lists, list];
    _checklistService.cacheLists(houseId, _lists);
    notifyListeners();
    return list;
  }

  Future<void> setListDeleteOnDoneDefault(bool value) async {
    final list = _currentList;
    if (list == null || list.deleteOnDoneDefault == value) return;

    final previous = list;
    final optimistic = list.copyWith(deleteOnDoneDefault: value);
    _currentList = optimistic;
    _lists = [for (final l in _lists) l.id == optimistic.id ? optimistic : l];
    _checklistService.cacheLists(houseId, _lists);
    notifyListeners();

    try {
      final updated = await _checklistService.updateList(
        houseId,
        list.id,
        deleteOnDoneDefault: value,
      );
      _currentList = _currentList?.id == updated.id ? updated : _currentList;
      _lists = [for (final l in _lists) l.id == updated.id ? updated : l];
      _checklistService.cacheLists(houseId, _lists);
      notifyListeners();
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to update list default: $e');
      _currentList = _currentList?.id == previous.id ? previous : _currentList;
      _lists = [for (final l in _lists) l.id == previous.id ? previous : l];
      _checklistService.cacheLists(houseId, _lists);
      notifyListeners();
    }
  }

  Future<void> moveItem(ListItem item, int targetListId) async {
    await _checklistService.moveItem(
      houseId,
      item.listId,
      item.id,
      targetListId: targetListId,
    );
    _items.removeWhere((i) => i.id == item.id);
    _checklistService.cacheItems(_currentList!.id, List.of(_items));
    notifyListeners();
  }

  Future<ListItem> addItem({
    required String name,
    String? description,
    String? quantity,
    int? categoryId,
    String? rrule,
    bool? deleteOnDone,
  }) async {
    final item = await _checklistService.createItem(
      houseId,
      _currentList!.id,
      name: name,
      description: description,
      quantity: quantity,
      categoryId: categoryId,
      rrule: rrule,
      deleteOnDone: deleteOnDone,
    );
    _items.insert(0, item);
    _checklistService.cacheItems(_currentList!.id, List.of(_items));
    notifyListeners();
    return item;
  }

  Future<ListItem> updateItem(
    ListItem item, {
    String? name,
    String? description,
    String? quantity,
    int? categoryId,
    bool clearCategory = false,
    String? rrule,
    bool? repeatFromCompletion,
    bool? deleteOnDone,
  }) async {
    final updated = await _checklistService.updateItem(
      houseId,
      item.listId,
      item.id,
      name: name,
      description: description,
      quantity: quantity,
      categoryId: categoryId,
      clearCategory: clearCategory,
      rrule: rrule,
      repeatFromCompletion: repeatFromCompletion,
      deleteOnDone: deleteOnDone,
    );
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = updated;
      _checklistService.cacheItems(_currentList!.id, List.of(_items));
      notifyListeners();
    }
    return updated;
  }

  Future<ListItem> uploadItemImage(
    ListItem item, {
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
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
      _checklistService.cacheItems(_currentList!.id, List.of(_items));
      notifyListeners();
    }
    return updated;
  }

  Future<void> deleteItemImage(ListItem item) async {
    await _checklistService.deleteItemImage(houseId, item.listId, item.id);
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      // Clear image fields locally
      _items[index] = ListItem(
        id: item.id,
        listId: item.listId,
        name: item.name,
        description: item.description,
        categoryId: item.categoryId,
        quantity: item.quantity,
        done: item.done,
        doneAt: item.doneAt,
        doneBy: item.doneBy,
        rrule: item.rrule,
        repeatFromCompletion: item.repeatFromCompletion,
        deleteOnDone: item.deleteOnDone,
        nextDueAt: item.nextDueAt,
        imageFileId: null,
        imageUploadedBy: null,
        addedBy: item.addedBy,
        sortOrder: item.sortOrder,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      );
      _checklistService.cacheItems(_currentList!.id, List.of(_items));
      notifyListeners();
    }
  }

  Future<void> deleteItem(ListItem item) async {
    await _checklistService.deleteItem(houseId, item.listId, item.id);
    _items.removeWhere((i) => i.id == item.id);
    _checklistService.cacheItems(_currentList!.id, List.of(_items));
    notifyListeners();
  }

  Future<ListItem> restoreItem(ListItem item) async {
    final restored = await _checklistService.restoreItem(
      houseId,
      item.listId,
      item.id,
    );
    _items.removeWhere((i) => i.id == item.id);
    if (!_isTrashMode) {
      _items.add(restored);
      _checklistService.cacheItems(_currentList!.id, List.of(_items));
    }
    notifyListeners();
    return restored;
  }

  Future<void> permanentlyDeleteItem(ListItem item) async {
    await _checklistService.permanentlyDeleteItem(
      houseId,
      item.listId,
      item.id,
    );
    _items.removeWhere((i) => i.id == item.id);
    if (!_isTrashMode) {
      _checklistService.cacheItems(_currentList!.id, List.of(_items));
    }
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    if (_currentList == null) return;
    await _checklistService.emptyTrash(houseId, _currentList!.id);
    if (_isTrashMode) {
      _items = [];
      notifyListeners();
    }
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
    await _checklistService.deleteList(houseId, list.id);
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
  }

  Future<void> restoreList(ChecklistList list) async {
    final restored = await _checklistService.restoreList(houseId, list.id);
    _trashedLists.removeWhere((l) => l.id == list.id);
    final exists = _lists.any((l) => l.id == restored.id);
    if (!exists) {
      _lists = [..._lists, restored];
      _checklistService.cacheLists(houseId, _lists);
    }
    notifyListeners();
  }

  Future<void> permanentlyDeleteList(ChecklistList list) async {
    await _checklistService.permanentlyDeleteList(houseId, list.id);
    _trashedLists.removeWhere((l) => l.id == list.id);
    notifyListeners();
  }

  Future<void> emptyListsTrash() async {
    await _checklistService.emptyListsTrash(houseId);
    _trashedLists = [];
    notifyListeners();
  }

  Future<void> toggleItem(ListItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    // Optimistic update
    _items[index] = item.copyWith(done: !item.done);
    _checklistService.cacheItems(item.listId, List.of(_items));
    notifyListeners();

    try {
      final updated = await _checklistService.toggleItem(
        houseId,
        item.listId,
        item.id,
      );
      // If toggling caused a soft-delete (deleteOnDone), drop it from active list.
      if (updated.deletedAt != null) {
        _items.removeWhere((i) => i.id == item.id);
      } else {
        final i = _items.indexWhere((x) => x.id == item.id);
        if (i != -1) _items[i] = updated;
      }
      _checklistService.cacheItems(item.listId, List.of(_items));
      notifyListeners();
    } catch (e) {
      // Revert on failure
      final i = _items.indexWhere((x) => x.id == item.id);
      if (i != -1) {
        _items[i] = item;
      } else {
        _items.insert(index.clamp(0, _items.length), item);
      }
      _checklistService.cacheItems(item.listId, List.of(_items));
      notifyListeners();
    }
  }
}
