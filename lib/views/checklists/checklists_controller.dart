import 'package:flutter/foundation.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/services/category_service.dart';
import 'package:pantry/services/checklist_service.dart';

class ChecklistsController extends ChangeNotifier {
  final int houseId;

  ChecklistsController({required this.houseId});

  List<ChecklistList> _lists = [];
  List<ChecklistList> get lists => _lists;

  ChecklistList? _currentList;
  ChecklistList? get currentList => _currentList;

  List<ListItem> _items = [];
  List<ListItem> get items => _items;

  Map<int, models.Category> _categories = {};
  Map<int, models.Category> get categories => _categories;

  String _sortBy = 'custom';
  String get sortBy => _sortBy;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  ChecklistService get _checklistService => ChecklistService.instance;
  CategoryService get _categoryService => CategoryService.instance;

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

      // Sort pref is non-fatal
      try {
        _sortBy = await _checklistService.getItemSortPref(houseId);
        _checklistService.cache.set('sortBy', _sortBy);
      } catch (e) {
        debugPrint('[ChecklistsController] Failed to load sort pref: $e');
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
      if (_currentList?.id == list.id) {
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

  Future<void> setSortBy(String sort) async {
    if (sort == _sortBy) return;
    _sortBy = sort;
    _checklistService.cache.set('sortBy', sort);
    notifyListeners();

    // Persist to server
    _checklistService.setItemSortPref(houseId, sort);

    // Reload items with new sort
    if (_currentList != null) {
      _checklistService.invalidateItems();
      await selectList(_currentList!);
    }
  }

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

  Future<ListItem> addItem({
    required String name,
    String? description,
    String? quantity,
    int? categoryId,
    String? rrule,
  }) async {
    final item = await _checklistService.createItem(
      houseId,
      _currentList!.id,
      name: name,
      description: description,
      quantity: quantity,
      categoryId: categoryId,
      rrule: rrule,
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
    );
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = updated;
      _checklistService.cacheItems(_currentList!.id, List.of(_items));
      notifyListeners();
    }
    return updated;
  }

  Future<void> deleteItem(ListItem item) async {
    await _checklistService.deleteItem(houseId, item.listId, item.id);
    _items.removeWhere((i) => i.id == item.id);
    _checklistService.cacheItems(_currentList!.id, List.of(_items));
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
      _items[index] = updated;
      _checklistService.cacheItems(item.listId, List.of(_items));
      notifyListeners();
    } catch (e) {
      // Revert on failure
      _items[index] = item;
      _checklistService.cacheItems(item.listId, List.of(_items));
      notifyListeners();
    }
  }
}
