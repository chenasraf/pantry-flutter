part of 'checklist_service.dart';

extension ChecklistServiceItems on ChecklistService {
  Future<List<ListItem>> getItems(
    int houseId,
    int listId, {
    String sortBy = 'custom',
  }) async {
    return _fetchAllItems('${listPath(houseId, listId)}/items', sortBy: sortBy);
  }

  /// Aggregate items across every (non-deleted) list of [kind] in the house.
  /// Backs the synthetic "All lists" and "All inventories" meta views. Items
  /// carry their real `listId` so all per-item operations resolve correctly
  /// against the underlying list.
  Future<List<ListItem>> getHouseItems(
    int houseId, {
    String sortBy = 'newest',
    ListKind kind = ListKind.checklist,
  }) async {
    final path = kind.isChecklist
        ? '/houses/$houseId/items'
        : '${kindPath(houseId, kind)}/items';
    return _fetchAllItems(path, sortBy: sortBy);
  }

  Future<List<ListItem>> _fetchAllItems(String path, {required String sortBy}) {
    return ApiClient.instance.getAll(
      path,
      query: {'sortBy': sortBy},
      fromJson: ListItem.fromJson,
      idOf: (item) => item.id,
    );
  }

  Future<ListItem> moveItem(
    int houseId,
    int listId,
    int itemId, {
    required int targetListId,
  }) async {
    return ApiClient.instance.patch<Map<String, dynamic>, ListItem>(
      '${listPath(houseId, listId)}/items/$itemId',
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
      '${listPath(houseId, listId)}/items/$itemId/copy',
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
    StockMode? stockMode,
    StockLevel? stockLevel,
    String? target,
    String? reorderPoint,
    int? expiresAt,
    int? shelfLifeDays,
  }) async {
    final loginName = AuthService.instance.credentials?.loginName;
    return ApiClient.instance.post<Map<String, dynamic>, ListItem>(
      '${listPath(houseId, listId)}/items',
      body: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (quantity != null && quantity.isNotEmpty) 'quantity': quantity,
        'categoryId': ?categoryId,
        'storeIds': ?storeIds,
        'labelIds': ?labelIds,
        if (kindOf(listId).hasRecurrence) ...{
          if (rrule != null && rrule.isNotEmpty) 'rrule': rrule,
          'repeatFromCompletion': ?repeatFromCompletion,
          'deleteOnDone': ?deleteOnDone,
        },
        'addedBy': ?loginName,
        'barcode': ?barcode,
        // Adapts to the server: `prices` array on item-price-per-store servers,
        // legacy flat fields otherwise. null omits (no prices).
        ...itemPriceBody(prices, isUpdate: false),
        // Custom-field values ride the item; null omits, sent only when the
        // server advertises the capability.
        ...customFieldsBody(customFields),
        if (!kindOf(listId).isChecklist) ...{
          'stockMode': ?stockMode?.wire,
          'stockLevel': ?stockLevel?.wire,
          'target': ?target,
          'reorderPoint': ?reorderPoint,
          'expiresAt': ?expiresAt,
          'shelfLifeDays': ?shelfLifeDays,
        },
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
    StockMode? stockMode,
    StockLevel? stockLevel,
    String? target,
    String? reorderPoint,
    int? expiresAt,
    int? shelfLifeDays,
    bool? autoLink,
    bool? quantityPinned,
  }) async {
    return ApiClient.instance.patch<Map<String, dynamic>, ListItem>(
      '${listPath(houseId, listId)}/items/$itemId',
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
        if (kindOf(listId).hasRecurrence) ...{
          'rrule': ?rrule,
          'repeatFromCompletion': ?repeatFromCompletion,
          'deleteOnDone': ?deleteOnDone,
        },
        'barcode': ?barcode,
        // Prices mirror stores: null omits (unchanged), an empty list clears
        // all prices, otherwise the full set replaces the item's prices. On
        // legacy servers this collapses to the store-less flat fields.
        ...itemPriceBody(prices, isUpdate: true),
        // Custom fields mirror prices: null omits (unchanged), an empty list
        // clears every value, otherwise the set replaces the item's values.
        ...customFieldsBody(customFields),
        if (!kindOf(listId).isChecklist) ...{
          'stockMode': ?stockMode?.wire,
          'stockLevel': ?stockLevel?.wire,
          'target': ?target,
          'reorderPoint': ?reorderPoint,
          'expiresAt': ?expiresAt,
          'shelfLifeDays': ?shelfLifeDays,
        },
        if (kindOf(listId) == ListKind.inventory) 'autoLink': ?autoLink,
        if (kindOf(listId).isChecklist) 'quantityPinned': ?quantityPinned,
      },
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  /// Link inventory item [itemId] to checklist item [targetItemId], replacing
  /// any link it has.
  Future<ListItem> linkItem(
    int houseId,
    int listId,
    int itemId,
    int targetItemId,
  ) async {
    return ApiClient.instance.post<Map<String, dynamic>, ListItem>(
      '${listPath(houseId, listId)}/items/$itemId/link',
      body: {'targetItemId': targetItemId},
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  /// Unlink inventory item [itemId]. The server turns its auto-link off too.
  Future<ListItem> unlinkItem(int houseId, int listId, int itemId) async {
    return ApiClient.instance.deleteWithResult<Map<String, dynamic>, ListItem>(
      '${listPath(houseId, listId)}/items/$itemId/link',
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  /// Checklist items inventory [listId]'s items can be linked to: live and
  /// archived items on checklists the caller can edit, minus those already
  /// linked from this inventory.
  Future<List<StockLinkRow>> linkTargets(
    int houseId,
    int listId, {
    String search = '',
    int limit = 50,
  }) async {
    return ApiClient.instance.get<List, List<StockLinkRow>>(
      '${listPath(houseId, listId)}/link-targets',
      query: {'search': search, 'limit': '$limit'},
      fromJson: StockLinkRow.listFrom,
    );
  }

  Future<void> deleteItem(int houseId, int listId, int itemId) async {
    await ApiClient.instance.delete(
      '${listPath(houseId, listId)}/items/$itemId',
    );
  }

  Future<List<ListItem>> getDeletedItems(int houseId, int listId) {
    return ApiClient.instance.getAll(
      '${listPath(houseId, listId)}/items/trash',
      fromJson: ListItem.fromJson,
      idOf: (item) => item.id,
    );
  }

  Future<ListItem> restoreItem(int houseId, int listId, int itemId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ListItem>(
      '${listPath(houseId, listId)}/items/$itemId/restore',
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  Future<void> permanentlyDeleteItem(
    int houseId,
    int listId,
    int itemId,
  ) async {
    await ApiClient.instance.delete(
      '${listPath(houseId, listId)}/items/$itemId/permanent',
    );
  }

  Future<void> emptyTrash(int houseId, int listId) async {
    await ApiClient.instance.delete('${listPath(houseId, listId)}/items/trash');
  }

  Future<List<ListItem>> getArchivedItems(int houseId, int listId) {
    return ApiClient.instance.getAll(
      '${listPath(houseId, listId)}/items/archive',
      fromJson: ListItem.fromJson,
      idOf: (item) => item.id,
    );
  }

  Future<ListItem> archiveItem(int houseId, int listId, int itemId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ListItem>(
      '${listPath(houseId, listId)}/items/$itemId/archive',
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  Future<ListItem> unarchiveItem(int houseId, int listId, int itemId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ListItem>(
      '${listPath(houseId, listId)}/items/$itemId/unarchive',
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  Future<ListItem> toggleItem(int houseId, int listId, int itemId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ListItem>(
      '${listPath(houseId, listId)}/items/$itemId/toggle',
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
      '${listPath(houseId, listId)}/items/$itemId/image',
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      fieldName: 'image',
      fromJson: (data) => ListItem.fromJson(data),
    );
  }

  Future<void> deleteItemImage(int houseId, int listId, int itemId) async {
    await ApiClient.instance.delete(
      '${listPath(houseId, listId)}/items/$itemId/image',
    );
  }

  Future<void> reorderItems(
    int houseId,
    int listId,
    List<({int id, int sortOrder})> order,
  ) async {
    await ApiClient.instance.post<Map<String, dynamic>, void>(
      '${listPath(houseId, listId)}/items/reorder',
      body: {
        'items': order
            .map((e) => {'id': e.id, 'sortOrder': e.sortOrder})
            .toList(),
      },
      fromJson: (_) {},
    );
  }
}
