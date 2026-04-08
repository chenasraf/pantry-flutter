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

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  ChecklistService get _service => ChecklistService.instance;

  Future<void> load() async {
    _error = null;

    // Restore from cache immediately
    final cachedLists = _service.getCachedLists(houseId);
    if (cachedLists != null && _lists.isEmpty) {
      _lists = cachedLists;
      if (_lists.isNotEmpty) {
        final savedId = _service.selectedListId;
        _currentList =
            (savedId != null
                ? _lists.cast<ChecklistList?>().firstWhere(
                    (l) => l!.id == savedId,
                    orElse: () => null,
                  )
                : null) ??
            _lists.first;
        final cached = _service.getCachedItems(_currentList!.id);
        if (cached != null) {
          _items = cached;
          _isLoading = false;
          notifyListeners();
        }
      }
    }

    if (_lists.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _service.getLists(houseId),
        CategoryService.instance.getCategories(houseId),
      ]);

      _lists = results[0] as List<ChecklistList>;
      _service.cacheLists(houseId, _lists);
      final cats = results[1] as List<models.Category>;
      _categories = {for (final c in cats) c.id: c};

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
      _error = m.checklists.failedToLoad;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectList(ChecklistList list) async {
    _currentList = list;
    _service.selectedListId = list.id;

    // Show cached items immediately, or spinner if no cache for this list
    final cached = _service.getCachedItems(list.id);
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
      final freshItems = await _service.getItems(houseId, list.id);
      _service.cacheItems(list.id, freshItems);
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

  Future<void> refresh() async {
    await load();
    _service.invalidateCache(keepListId: _currentList?.id);
  }

  Future<void> toggleItem(ListItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    // Optimistic update
    _items[index] = item.copyWith(done: !item.done);
    _service.cacheItems(item.listId, List.of(_items));
    notifyListeners();

    try {
      final updated = await _service.toggleItem(houseId, item.listId, item.id);
      _items[index] = updated;
      _service.cacheItems(item.listId, List.of(_items));
      notifyListeners();
    } catch (e) {
      // Revert on failure
      _items[index] = item;
      _service.cacheItems(item.listId, List.of(_items));
      notifyListeners();
    }
  }
}
