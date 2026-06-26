import 'package:pantry/models/checklist.dart';
import 'package:pantry/services/api_client.dart';
import 'package:pantry/services/auth_service.dart';
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
    return _fetchAllItems(
      '/houses/$houseId/lists/$listId/items',
      sortBy: sortBy,
    );
  }

  /// Aggregate items across every (non-deleted) list in the house. Backs the
  /// synthetic "All lists" meta view. Items carry their real `listId` so all
  /// per-item operations resolve correctly against the underlying list.
  Future<List<ListItem>> getHouseItems(
    int houseId, {
    String sortBy = 'newest',
  }) async {
    return _fetchAllItems('/houses/$houseId/items', sortBy: sortBy);
  }

  /// Page through an items endpoint until every item is retrieved. The server
  /// caps the number of items returned per request, so a single call silently
  /// drops the trailing items of long lists — when sorted by category that
  /// looks like the last categories disappearing entirely (issue #80).
  Future<List<ListItem>> _fetchAllItems(
    String path, {
    required String sortBy,
  }) async {
    const pageSize = 500;
    final all = <ListItem>[];
    var offset = 0;
    while (true) {
      final page = await ApiClient.instance.get<List, List<ListItem>>(
        path,
        query: {
          'sortBy': sortBy,
          'limit': pageSize.toString(),
          'offset': offset.toString(),
        },
        fromJson: (data) => data
            .map((e) => ListItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      all.addAll(page);
      if (page.length < pageSize) break;
      offset += pageSize;
    }
    return all;
  }

  Future<Map<String, dynamic>> getHousePrefs(int houseId) async {
    return ApiClient.instance.get<Map<String, dynamic>, Map<String, dynamic>>(
      '/houses/$houseId/prefs',
      fromJson: (data) => data,
    );
  }

  Future<String> getItemSortPref(int houseId) async {
    return ApiClient.instance.get<Map<String, dynamic>, String>(
      '/houses/$houseId/prefs',
      fromJson: (data) => data['checklistItemSort'] as String? ?? 'custom',
    );
  }

  Future<void> setItemSortPref(int houseId, String sort) async {
    await ApiClient.instance.put<Map<String, dynamic>, void>(
      '/houses/$houseId/prefs',
      body: {'checklistItemSort': sort},
      fromJson: (_) {},
    );
  }

  Future<void> setShowAddedByPref(int houseId, bool value) async {
    await ApiClient.instance.put<Map<String, dynamic>, void>(
      '/houses/$houseId/prefs',
      body: {'showAddedBy': value},
      fromJson: (_) {},
    );
  }

  Future<void> setListSortPref(int houseId, String sort) async {
    await ApiClient.instance.put<Map<String, dynamic>, void>(
      '/houses/$houseId/prefs',
      body: {'checklistListSort': sort},
      fromJson: (_) {},
    );
  }

  Future<void> reorderLists(
    int houseId,
    List<({int id, int sortOrder})> order,
  ) async {
    await ApiClient.instance.post<Map<String, dynamic>, void>(
      '/houses/$houseId/lists/reorder',
      body: {
        'items': order
            .map((e) => {'id': e.id, 'sortOrder': e.sortOrder})
            .toList(),
      },
      fromJson: (_) {},
    );
  }

  /// Sort lists according to a sort mode (custom, newest, oldest, name_asc,
  /// name_desc). Returns a new list; the input is not mutated.
  static List<ChecklistList> sortLists(
    Iterable<ChecklistList> lists,
    String sort,
  ) {
    final out = lists.toList();
    switch (sort) {
      case 'newest':
        out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'oldest':
        out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case 'name_asc':
        out.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case 'name_desc':
        out.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
      case 'custom':
      default:
        out.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return out;
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

  Future<ChecklistList> createList(
    int houseId, {
    required String name,
    String? description,
    String? icon,
    String? color,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, ChecklistList>(
      '/houses/$houseId/lists',
      body: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (icon != null && icon.isNotEmpty) 'icon': icon,
        if (color != null && color.isNotEmpty) 'color': color,
      },
      fromJson: (data) => ChecklistList.fromJson(data),
    );
  }

  Future<void> deleteList(int houseId, int listId) async {
    await ApiClient.instance.delete('/houses/$houseId/lists/$listId');
  }

  Future<List<ChecklistList>> getDeletedLists(
    int houseId, {
    int limit = 200,
    int offset = 0,
  }) async {
    return ApiClient.instance.get<List, List<ChecklistList>>(
      '/houses/$houseId/lists/trash',
      query: {'limit': limit.toString(), 'offset': offset.toString()},
      fromJson: (data) => data
          .map((e) => ChecklistList.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ChecklistList> restoreList(int houseId, int listId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ChecklistList>(
      '/houses/$houseId/lists/$listId/restore',
      fromJson: (data) => ChecklistList.fromJson(data),
    );
  }

  Future<void> permanentlyDeleteList(int houseId, int listId) async {
    await ApiClient.instance.delete('/houses/$houseId/lists/$listId/permanent');
  }

  Future<void> emptyListsTrash(int houseId) async {
    await ApiClient.instance.delete('/houses/$houseId/lists/trash');
  }

  Future<ChecklistList> updateList(
    int houseId,
    int listId, {
    String? name,
    String? description,
    String? icon,
    String? color,
    int? sortOrder,
    bool? deleteOnDoneDefault,
  }) async {
    return ApiClient.instance.patch<Map<String, dynamic>, ChecklistList>(
      '/houses/$houseId/lists/$listId',
      body: {
        'name': ?name,
        'description': ?description,
        'icon': ?icon,
        'color': ?color,
        'sortOrder': ?sortOrder,
        'deleteOnDoneDefault': ?deleteOnDoneDefault,
      },
      fromJson: (data) => ChecklistList.fromJson(data),
    );
  }

  Future<ListItem> moveItem(
    int houseId,
    int listId,
    int itemId, {
    required int targetListId,
  }) async {
    return ApiClient.instance.patch<Map<String, dynamic>, ListItem>(
      '/houses/$houseId/lists/$listId/items/$itemId',
      body: {'targetListId': targetListId},
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  Future<ListItem> copyItem(
    int houseId,
    int listId,
    int itemId, {
    required int targetListId,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, ListItem>(
      '/houses/$houseId/lists/$listId/items/$itemId/copy',
      body: {'targetListId': targetListId},
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  Future<ListItem> createItem(
    int houseId,
    int listId, {
    required String name,
    String? description,
    String? quantity,
    int? categoryId,
    String? rrule,
    bool? repeatFromCompletion,
    bool? deleteOnDone,
  }) async {
    final loginName = AuthService.instance.credentials?.loginName;
    return ApiClient.instance.post<Map<String, dynamic>, ListItem>(
      '/houses/$houseId/lists/$listId/items',
      body: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (quantity != null && quantity.isNotEmpty) 'quantity': quantity,
        'categoryId': ?categoryId,
        if (rrule != null && rrule.isNotEmpty) 'rrule': rrule,
        'repeatFromCompletion': ?repeatFromCompletion,
        'deleteOnDone': ?deleteOnDone,
        'addedBy': ?loginName,
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
    bool? deleteOnDone,
  }) async {
    return ApiClient.instance.patch<Map<String, dynamic>, ListItem>(
      '/houses/$houseId/lists/$listId/items/$itemId',
      body: {
        'name': ?name,
        'description': ?description,
        'quantity': ?quantity,
        if (clearCategory) 'categoryId': 0,
        if (!clearCategory && categoryId != null) 'categoryId': categoryId,
        'rrule': ?rrule,
        'repeatFromCompletion': ?repeatFromCompletion,
        'deleteOnDone': ?deleteOnDone,
      },
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  Future<void> deleteItem(int houseId, int listId, int itemId) async {
    await ApiClient.instance.delete(
      '/houses/$houseId/lists/$listId/items/$itemId',
    );
  }

  Future<List<ListItem>> getDeletedItems(
    int houseId,
    int listId, {
    int limit = 200,
    int offset = 0,
  }) async {
    return ApiClient.instance.get<List, List<ListItem>>(
      '/houses/$houseId/lists/$listId/items/trash',
      query: {'limit': limit.toString(), 'offset': offset.toString()},
      fromJson: (data) => data
          .map((e) => ListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ListItem> restoreItem(int houseId, int listId, int itemId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ListItem>(
      '/houses/$houseId/lists/$listId/items/$itemId/restore',
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  Future<void> permanentlyDeleteItem(
    int houseId,
    int listId,
    int itemId,
  ) async {
    await ApiClient.instance.delete(
      '/houses/$houseId/lists/$listId/items/$itemId/permanent',
    );
  }

  Future<void> emptyTrash(int houseId, int listId) async {
    await ApiClient.instance.delete(
      '/houses/$houseId/lists/$listId/items/trash',
    );
  }

  Future<ListItem> toggleItem(int houseId, int listId, int itemId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ListItem>(
      '/houses/$houseId/lists/$listId/items/$itemId/toggle',
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  Future<ListItem> uploadItemImage(
    int houseId,
    int listId,
    int itemId, {
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    return ApiClient.instance.uploadMultipart<Map<String, dynamic>, ListItem>(
      '/houses/$houseId/lists/$listId/items/$itemId/image',
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      fieldName: 'image',
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  Future<void> deleteItemImage(int houseId, int listId, int itemId) async {
    await ApiClient.instance.delete(
      '/houses/$houseId/lists/$listId/items/$itemId/image',
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
