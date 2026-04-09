import 'package:pantry/models/checklist.dart';
import 'package:pantry/services/api_client.dart';
import 'package:pantry/services/cache_store.dart';

class ChecklistService {
  ChecklistService._();
  static final ChecklistService instance = ChecklistService._();

  final cache = CacheStore('checklist_cache.json');

  static const _listsKey = 'lists';
  static const _itemsPrefix = 'items';
  static const _houseIdKey = 'houseId';
  static const _selectedListKey = 'selectedListId';

  // -- Cache accessors --

  int? get selectedListId => cache.get<int>(_selectedListKey);
  set selectedListId(int? id) => cache.set(_selectedListKey, id);

  List<ChecklistList>? getCachedLists(int houseId) {
    if (cache.get<int>(_houseIdKey) != houseId) return null;
    return cache.getList(_listsKey, ChecklistList.fromJson);
  }

  void cacheLists(int houseId, List<ChecklistList> lists) {
    cache.set(_houseIdKey, houseId);
    cache.setList(_listsKey, lists, (l) => l.toJson());
  }

  List<ListItem>? getCachedItems(int listId) =>
      cache.getKeyedList(_itemsPrefix, '$listId', ListItem.fromJson);

  void cacheItems(int listId, List<ListItem> items) {
    cache.setKeyedList(_itemsPrefix, '$listId', items, (i) => i.toJson());
  }

  void invalidateItems({int? keepListId}) {
    cache.removeKeyed(
      _itemsPrefix,
      keepKey: keepListId != null ? '$keepListId' : null,
    );
  }

  // -- API --

  Future<List<ChecklistList>> getLists(int houseId) async {
    return ApiClient.instance.get<List, List<ChecklistList>>(
      '/houses/$houseId/lists',
      fromJson: (data) => data
          .map((e) => ChecklistList.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<ListItem>> getItems(
    int houseId,
    int listId, {
    String sortBy = 'custom',
  }) async {
    return ApiClient.instance.get<List, List<ListItem>>(
      '/houses/$houseId/lists/$listId/items',
      query: {'sortBy': sortBy},
      fromJson: (data) => data
          .map((e) => ListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<String> getItemSortPref(int houseId) async {
    return ApiClient.instance.get<Map<String, dynamic>, String>(
      '/houses/$houseId/prefs/checklist-item-sort',
      fromJson: (data) => data['sort'] as String? ?? 'custom',
    );
  }

  Future<void> setItemSortPref(int houseId, String sort) async {
    await ApiClient.instance.put<Map<String, dynamic>, void>(
      '/houses/$houseId/prefs/checklist-item-sort',
      body: {'sort': sort},
      fromJson: (_) {},
    );
  }

  Uri itemImagePreviewUri(
    int houseId,
    int fileId,
    String owner, {
    int size = 128,
  }) {
    return ApiClient.instance.buildUri('/houses/$houseId/image-preview', {
      'fileId': fileId.toString(),
      'owner': owner,
      'size': size.toString(),
    });
  }

  Future<ListItem> createItem(
    int houseId,
    int listId, {
    required String name,
    String? description,
    String? quantity,
    int? categoryId,
    String? rrule,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, ListItem>(
      '/houses/$houseId/lists/$listId/items',
      body: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (quantity != null && quantity.isNotEmpty) 'quantity': quantity,
        if (categoryId != null) 'categoryId': categoryId,
        if (rrule != null && rrule.isNotEmpty) 'rrule': rrule,
      },
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  Future<ListItem> updateItem(
    int houseId,
    int listId,
    int itemId, {
    String? name,
    String? description,
    String? quantity,
    int? categoryId,
    bool clearCategory = false,
    String? rrule,
    bool? repeatFromCompletion,
  }) async {
    return ApiClient.instance.patch<Map<String, dynamic>, ListItem>(
      '/houses/$houseId/lists/$listId/items/$itemId',
      body: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (quantity != null) 'quantity': quantity,
        if (clearCategory) 'categoryId': 0,
        if (!clearCategory && categoryId != null) 'categoryId': categoryId,
        if (rrule != null) 'rrule': rrule,
        if (repeatFromCompletion != null)
          'repeatFromCompletion': repeatFromCompletion,
      },
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  Future<void> deleteItem(int houseId, int listId, int itemId) async {
    await ApiClient.instance.delete(
      '/houses/$houseId/lists/$listId/items/$itemId',
    );
  }

  Future<ListItem> toggleItem(int houseId, int listId, int itemId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ListItem>(
      '/houses/$houseId/lists/$listId/items/$itemId/toggle',
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  Future<void> reorderItems(
    int houseId,
    int listId,
    List<({int id, int sortOrder})> order,
  ) async {
    await ApiClient.instance.post<Map<String, dynamic>, void>(
      '/houses/$houseId/lists/$listId/items/reorder',
      body: {
        'items': order
            .map((e) => {'id': e.id, 'sortOrder': e.sortOrder})
            .toList(),
      },
      fromJson: (_) {},
    );
  }
}
