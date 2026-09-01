part of 'checklist_service.dart';

extension ChecklistServiceItems on ChecklistService {
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
  /// looks like the last categories disappearing entirely.
  Future<List<ListItem>> _fetchAllItems(
    String path, {
    required String sortBy,
  }) async {
    const pageSize = 500;
    final all = <ListItem>[];
    final seenIds = <int>{};
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
      var added = 0;
      for (final item in page) {
        if (seenIds.add(item.id)) {
          all.add(item);
          added++;
        }
      }
      // A short page is the last page. `added == 0` guards against a server
      // that ignores `offset` and returns the same page every request — left
      // unchecked that loops forever, appending until the app runs out of
      // memory.
      if (page.length < pageSize || added == 0) break;
      offset += pageSize;
    }
    return all;
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
    List<int>? storeIds,
    List<int>? labelIds,
    String? rrule,
    bool? repeatFromCompletion,
    bool? deleteOnDone,
    String? barcode,
    List<ItemPrice>? prices,
    List<FieldValue>? customFields,
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
        'storeIds': ?storeIds,
        'labelIds': ?labelIds,
        if (rrule != null && rrule.isNotEmpty) 'rrule': rrule,
        'repeatFromCompletion': ?repeatFromCompletion,
        'deleteOnDone': ?deleteOnDone,
        'addedBy': ?loginName,
        'barcode': ?barcode,
        // Adapts to the server: `prices` array on item-price-per-store servers,
        // legacy flat fields otherwise. null omits (no prices).
        ...itemPriceBody(prices, isUpdate: false),
        // Custom-field values ride the item; null omits, sent only when the
        // server advertises the capability.
        ...customFieldsBody(customFields),
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
    List<int>? storeIds,
    List<int>? labelIds,
    String? rrule,
    bool? repeatFromCompletion,
    bool? deleteOnDone,
    String? barcode,
    List<ItemPrice>? prices,
    List<FieldValue>? customFields,
  }) async {
    return ApiClient.instance.patch<Map<String, dynamic>, ListItem>(
      '/houses/$houseId/lists/$listId/items/$itemId',
      body: {
        'name': ?name,
        'description': ?description,
        'quantity': ?quantity,
        if (clearCategory) 'categoryId': 0,
        if (!clearCategory && categoryId != null) 'categoryId': categoryId,
        // Stores have no clear-sentinel: null omits (unchanged), [] clears.
        'storeIds': ?storeIds,
        // Labels mirror stores: null omits (unchanged), [] clears.
        'labelIds': ?labelIds,
        'rrule': ?rrule,
        'repeatFromCompletion': ?repeatFromCompletion,
        'deleteOnDone': ?deleteOnDone,
        'barcode': ?barcode,
        // Prices mirror stores: null omits (unchanged), an empty list clears
        // all prices, otherwise the full set replaces the item's prices. On
        // legacy servers this collapses to the store-less flat fields.
        ...itemPriceBody(prices, isUpdate: true),
        // Custom fields mirror prices: null omits (unchanged), an empty list
        // clears every value, otherwise the set replaces the item's values.
        ...customFieldsBody(customFields),
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

  Future<List<ListItem>> getArchivedItems(
    int houseId,
    int listId, {
    int limit = 200,
    int offset = 0,
  }) async {
    return ApiClient.instance.get<List, List<ListItem>>(
      '/houses/$houseId/lists/$listId/items/archive',
      query: {'limit': limit.toString(), 'offset': offset.toString()},
      fromJson: (data) => data
          .map((e) => ListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ListItem> archiveItem(int houseId, int listId, int itemId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ListItem>(
      '/houses/$houseId/lists/$listId/items/$itemId/archive',
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  Future<ListItem> unarchiveItem(int houseId, int listId, int itemId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ListItem>(
      '/houses/$houseId/lists/$listId/items/$itemId/unarchive',
      fromJson: (data) => ListItem.fromJson(data),
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
