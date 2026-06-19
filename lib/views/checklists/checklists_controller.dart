import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/member.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/category_service.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/house_service.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/sync/sync_ids.dart';
import 'package:pantry/sync/sync_manager.dart';
import 'package:pantry/sync/sync_op.dart';

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
);

class ChecklistsController extends ChangeNotifier {
  final int houseId;

  ChecklistsController({required this.houseId}) {
    _appliedSub = SyncManager.instance.onApplied.listen(_onSyncApplied);
  }

  /// True when the synthetic "All lists" entry is selected.
  bool get isMetaMode => _currentList?.id == kAllListsId;

  /// Effective sort for the current view. The meta view can't honor the
  /// per-list custom order, so it falls back to newest without persisting.
  String get effectiveSortBy =>
      isMetaMode && _sortBy == 'custom' ? 'newest' : _sortBy;

  bool _disposed = false;
  StreamSubscription<SyncOpApplied>? _appliedSub;

  @override
  void dispose() {
    _disposed = true;
    _appliedSub?.cancel();
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
  SyncManager get _sync => SyncManager.instance;

  int _now() => DateTime.now().millisecondsSinceEpoch;

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
        ServerVersionService.instance.observeHousePrefs(prefs);
        _sortBy = prefs['checklistItemSort'] as String? ?? 'custom';
        _showAddedBy = prefs['showAddedBy'] as bool? ?? false;
        _categorySort = prefs['categorySort'] as String? ?? 'custom';
        _listSort = prefs['checklistListSort'] as String? ?? 'custom';
        _checklistService.cache.set('sortBy:$houseId', _sortBy);
        _checklistService.cache.set('showAddedBy:$houseId', _showAddedBy);
        _checklistService.cache.set('categorySort:$houseId', _categorySort);
        _checklistService.cache.set('listSort:$houseId', _listSort);
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
        if (_currentList?.id == kAllListsId &&
            hasFeature('checklist-all-view')) {
          // Stay on the meta view — falling back to `_lists.first` would
          // flicker the per-list view in between refreshes.
          await selectList(allListsSentinel(houseId));
        } else {
          final target = _currentList != null
              ? _lists.cast<ChecklistList?>().firstWhere(
                      (l) => l!.id == _currentList!.id,
                      orElse: () => null,
                    ) ??
                    _lists.first
              : _lists.first;
          await selectList(target);
        }
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
    final cache = _checklistService.cache;
    // Fall back to the legacy global key for installs that cached prefs
    // before they were scoped per-house. First scoped write overwrites it.
    _sortBy =
        cache.get<String>('sortBy:$houseId') ??
        cache.get<String>('sortBy') ??
        'custom';
    _showAddedBy =
        cache.get<bool>('showAddedBy:$houseId') ??
        cache.get<bool>('showAddedBy') ??
        false;
    _categorySort =
        cache.get<String>('categorySort:$houseId') ??
        cache.get<String>('categorySort') ??
        'custom';
    _listSort =
        cache.get<String>('listSort:$houseId') ??
        cache.get<String>('listSort') ??
        'custom';

    final cachedMembers = _houseService.getCachedMembers(houseId);
    if (cachedMembers != null) {
      _members = {for (final m in cachedMembers) m.userId: m};
    }

    final cachedCats = _categoryService.getCached(houseId);
    if (cachedCats != null && _categories.isEmpty) {
      _categories = {for (final c in cachedCats) c.id: c};
    }

    final cachedLists = _checklistService.getCachedLists(houseId);
    if (cachedLists != null && _lists.isEmpty) {
      _lists = cachedLists;
      if (_lists.isNotEmpty) {
        final savedId = _checklistService.selectedListId;
        if (savedId == kAllListsId && hasFeature('checklist-all-view')) {
          _currentList = allListsSentinel(houseId);
        } else {
          _currentList =
              (savedId != null
                  ? _lists.cast<ChecklistList?>().firstWhere(
                      (l) => l!.id == savedId,
                      orElse: () => null,
                    )
                  : null) ??
              _lists.first;
          final cachedItems = _checklistService.getCachedItems(
            _currentList!.id,
          );
          if (cachedItems != null) {
            _items = cachedItems;
            _isLoading = false;
            notifyListeners();
          }
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
      // Meta view has no trash of its own — exit trash mode silently.
      if (list.id == kAllListsId) {
        _isTrashMode = false;
        _isLoading = false;
        notifyListeners();
      } else {
        await _loadTrashItems(list);
        return;
      }
    }

    if (list.id == kAllListsId) {
      // On the first entry we have no prior items; subsequent refreshes keep
      // the previous list visible so the user sees an in-place swap rather
      // than an empty-state flash.
      if (_items.isEmpty) {
        _isLoading = true;
        notifyListeners();
      }
      try {
        final fresh = await _checklistService.getHouseItems(
          houseId,
          sortBy: effectiveSortBy,
        );
        if (_currentList?.id == kAllListsId && !_isTrashMode) {
          _items = fresh;
          _isLoading = false;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('[ChecklistsController] Failed to load house items: $e');
        if (_currentList?.id == kAllListsId) {
          _error = m.checklists.failedToLoadItems;
          _isLoading = false;
          notifyListeners();
        }
      }
      return;
    }

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
    // Meta view has no trash of its own — ignore.
    if (enabled && isMetaMode) return;
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
    _checklistService.cache.set('sortBy:$houseId', sort);
    notifyListeners();

    unawaited(_persistSortPref(sort));

    if (_currentList != null) {
      if (!isMetaMode) _checklistService.invalidateItems();
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

  int _insertIndexFor(ListItem item) {
    final firstDone = _items.indexWhere((i) => i.done);
    final lastUnchecked = firstDone == -1 ? _items.length : firstDone;

    switch (_sortBy) {
      case 'category':
        final sorted = sortedCategories;
        final rank = <int, int>{};
        for (var i = 0; i < sorted.length; i++) {
          rank[sorted[i].id] = i;
        }
        const uncategorizedRank = 1 << 30;
        int rankOf(int? id) =>
            id == null ? uncategorizedRank : (rank[id] ?? uncategorizedRank);
        final myRank = rankOf(item.categoryId);
        for (var i = 0; i < lastUnchecked; i++) {
          if (rankOf(_items[i].categoryId) > myRank) return i;
        }
        return lastUnchecked;
      case 'name_asc':
        final key = item.name.toLowerCase();
        for (var i = 0; i < lastUnchecked; i++) {
          if (_items[i].name.toLowerCase().compareTo(key) > 0) return i;
        }
        return lastUnchecked;
      case 'name_desc':
        final key = item.name.toLowerCase();
        for (var i = 0; i < lastUnchecked; i++) {
          if (_items[i].name.toLowerCase().compareTo(key) < 0) return i;
        }
        return lastUnchecked;
      case 'oldest':
        return lastUnchecked;
      case 'newest':
      case 'custom':
      default:
        return 0;
    }
  }

  Future<void> setShowAddedBy(bool value) async {
    if (value == _showAddedBy) return;
    _showAddedBy = value;
    _checklistService.cache.set('showAddedBy:$houseId', value);
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

  Future<void> reorderLists(int oldIndex, int newIndex) async {
    if (_listSort != 'custom') return;
    if (newIndex > oldIndex) newIndex--;
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

  Future<void> reorderItems(
    List<ListItem> partition,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex == newIndex) return;
    if (_currentList == null) return;
    // Meta view aggregates across lists; per-list sort_order is meaningless
    // here.
    if (isMetaMode) return;

    final item = partition.removeAt(oldIndex);
    partition.insert(newIndex, item);

    final order = <Map<String, int>>[];
    for (var i = 0; i < partition.length; i++) {
      order.add({'id': partition[i].id, 'sortOrder': i});
    }

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

    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.reorder,
        houseId: houseId,
        parentId: _currentList!.id,
        body: {'order': order},
        createdAt: _now(),
      ),
    );
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
    } else {
      _items.removeWhere((i) => i.id == item.id);
      _checklistService.cacheItems(_currentList!.id, List.of(_items));
    }
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
      rrule: rrule,
      deleteOnDone: deleteOnDone,
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
    String? rrule,
    bool? deleteOnDone,
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
      quantity: quantity,
      done: false,
      rrule: rrule,
      repeatFromCompletion: false,
      deleteOnDone: deleteOnDone ?? false,
      addedBy: loginName,
      sortOrder: 0,
      createdAt: _now(),
      updatedAt: _now(),
    );
    _items.insert(_insertIndexFor(synthetic), synthetic);
    // In meta mode `_items` is the aggregate across every list — caching it
    // under a single listId would clobber that list's per-list cache. Skip
    // the cache write; the target list will refetch when next opened.
    if (!isMetaMode) {
      _checklistService.cacheItems(listId, List.of(_items));
    }
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
          'rrule': ?rrule,
          'deleteOnDone': ?deleteOnDone,
        },
        createdAt: _now(),
      ),
    );
    return synthetic;
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
    final updated = item.copyWith(
      name: name,
      description: description,
      quantity: quantity,
      categoryId: categoryId,
      clearCategory: clearCategory,
      rrule: rrule,
      repeatFromCompletion: repeatFromCompletion,
      deleteOnDone: deleteOnDone,
      updatedAt: _now(),
    );
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = updated;
      if (!isMetaMode) {
        _checklistService.cacheItems(item.listId, List.of(_items));
      }
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
          'rrule': ?rrule,
          'repeatFromCompletion': ?repeatFromCompletion,
          'deleteOnDone': ?deleteOnDone,
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
      // Photo uploads are online-only and need a real server id — bail
      // until the optimistic create has resolved.
      throw StateError('Cannot upload image before item create syncs');
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
      if (!isMetaMode) {
        _checklistService.cacheItems(item.listId, List.of(_items));
      }
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
      if (!isMetaMode) {
        _checklistService.cacheItems(item.listId, List.of(_items));
      }
      notifyListeners();
    }
  }

  Future<void> deleteItem(ListItem item) async {
    _items.removeWhere((i) => i.id == item.id);
    if (!isMetaMode) {
      _checklistService.cacheItems(item.listId, List.of(_items));
    }
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
      if (!isMetaMode) {
        _checklistService.cacheItems(item.listId, List.of(_items));
      }
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
    if (!_isTrashMode && !isMetaMode) {
      _checklistService.cacheItems(item.listId, List.of(_items));
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

  Future<void> toggleItem(ListItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    _items[index] = item.copyWith(done: !item.done, updatedAt: _now());
    if (!isMetaMode) {
      _checklistService.cacheItems(item.listId, List.of(_items));
    }
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

  // -- Sync callback --

  void _onSyncApplied(SyncOpApplied applied) {
    final tempId = applied.op.tempEntityId;
    switch (applied.op.entity) {
      case SyncEntity.checklistList:
        final entity = applied.entity;
        if (entity is ChecklistList) {
          if (tempId != null) {
            final i = _lists.indexWhere((l) => l.id == tempId);
            if (i != -1) {
              _lists[i] = entity;
              if (_currentList?.id == tempId) _currentList = entity;
              _checklistService.cacheLists(houseId, _lists);
              notifyListeners();
              return;
            }
          }
          final j = _lists.indexWhere((l) => l.id == entity.id);
          if (j != -1) {
            _lists[j] = entity;
            if (_currentList?.id == entity.id) _currentList = entity;
            _checklistService.cacheLists(houseId, _lists);
            notifyListeners();
          }
        }
      case SyncEntity.checklistItem:
        final entity = applied.entity;
        if (entity is ListItem) {
          final meta = isMetaMode;
          // If toggle caused soft-delete (deleteOnDone), drop it.
          if (entity.deletedAt != null) {
            _items.removeWhere((i) => i.id == entity.id || i.id == tempId);
            if (!meta && _currentList?.id == entity.listId) {
              _checklistService.cacheItems(entity.listId, List.of(_items));
            }
            notifyListeners();
            return;
          }
          if (tempId != null) {
            final i = _items.indexWhere((it) => it.id == tempId);
            if (i != -1) {
              _items[i] = entity;
              if (!meta) {
                _checklistService.cacheItems(entity.listId, List.of(_items));
              }
              notifyListeners();
              return;
            }
          }
          final j = _items.indexWhere((it) => it.id == entity.id);
          if (j != -1) {
            _items[j] = entity;
            if (!meta) {
              _checklistService.cacheItems(entity.listId, List.of(_items));
            }
            notifyListeners();
          }
        }
      case SyncEntity.category:
        final entity = applied.entity;
        if (entity is models.Category) {
          if (tempId != null) {
            _categories.remove(tempId);
          }
          _categories[entity.id] = entity;
          notifyListeners();
        }
      case SyncEntity.note:
        break;
    }
  }
}
