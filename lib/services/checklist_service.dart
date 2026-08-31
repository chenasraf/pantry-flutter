import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/custom_field.dart';
import 'package:pantry/services/api_client.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/cache_store.dart';
import 'package:pantry/services/server_version_service.dart';

/// Capability advertised by servers that store a price per store (the `prices`
/// array). Absent on older servers, which keep the flat single-price fields.
const kItemPricePerStoreFeature = 'item-price-per-store';

/// Serialize a [prices] value for the item create/update body, adapting to what
/// the server supports. `null` omits the field entirely (prices unchanged).
///
/// On `item-price-per-store` servers the full array is sent. On older servers
/// the prices collapse to the store-less (default) entry sent as the legacy
/// flat fields; when there's no usable store-less price an update clears it via
/// the `priceType: ''` sentinel and a create sends nothing.
Map<String, dynamic> itemPriceBody(
  List<ItemPrice>? prices, {
  required bool isUpdate,
}) {
  if (prices == null) return const {};
  if (hasFeature(kItemPricePerStoreFeature)) {
    return {'prices': prices.map((p) => p.toJson()).toList()};
  }
  ItemPrice? storeless;
  for (final p in prices) {
    if (p.storeId == null) {
      storeless = p;
      break;
    }
  }
  final usable =
      storeless != null &&
      (storeless.priceType == 'set' || storeless.priceType == 'range') &&
      storeless.priceMin != null;
  if (!usable) return isUpdate ? {'priceType': ''} : const {};
  return {
    'priceType': storeless.priceType,
    'priceMin': storeless.priceMin,
    if (storeless.priceMax != null) 'priceMax': storeless.priceMax,
    if (storeless.priceCurrency != null)
      'priceCurrency': storeless.priceCurrency,
  };
}

/// Capability advertised by servers that store per-item custom-field values.
const kCustomFieldsFeature = 'custom-fields';

/// Serialize [customFields] for the item create/update body. `null` omits the
/// field (values unchanged); a list — even empty — is sent so an update can
/// clear every value. Sent only on servers advertising `custom-fields`; older
/// servers ignore custom fields entirely, so nothing is emitted for them.
Map<String, dynamic> customFieldsBody(List<FieldValue>? customFields) {
  if (customFields == null || !hasFeature(kCustomFieldsFeature)) {
    return const {};
  }
  return {'customFields': customFields.map((v) => v.toJson()).toList()};
}

class ChecklistService {
  ChecklistService._();
  static final ChecklistService instance = ChecklistService._();

  final cache = CacheStore('checklist_cache.json');

  static const _listsPrefix = 'lists';
  static const _itemsPrefix = 'items';
  static const _selectedListKey = 'selectedListId';

  // Legacy single-house lists cache (before the snapshot was keyed per house):
  // a single `houseId` marker meant switching houses offline wiped the other
  // house's snapshot. Kept as a read-only fallback so the first offline session
  // after upgrading still finds the most-recently-used house; superseded by the
  // first per-house write.
  static const _legacyListsKey = 'lists';
  static const _legacyHouseIdKey = 'houseId';

  // -- Cache accessors --

  int? get selectedListId => cache.get<int>(_selectedListKey);
  set selectedListId(int? id) => cache.set(_selectedListKey, id);

  /// Transient (in-memory) request to open an item's detail once its list is
  /// loaded — set by an item deep link, consumed by the checklists view.
  int? pendingOpenItemId;

  List<ChecklistList>? getCachedLists(int houseId) {
    final scoped = cache.getKeyedList(
      _listsPrefix,
      '$houseId',
      ChecklistList.fromJson,
    );
    if (scoped != null) return scoped;
    // Legacy fallback: the old global slot only holds the most-recently-used
    // house, so honor it until this house gets its first per-house write.
    if (cache.get<int>(_legacyHouseIdKey) == houseId) {
      return cache.getList(_legacyListsKey, ChecklistList.fromJson);
    }
    return null;
  }

  void cacheLists(int houseId, List<ChecklistList> lists) {
    cache.setKeyedList(_listsPrefix, '$houseId', lists, (l) => l.toJson());
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

  /// Drop only the cached items for [listId], leaving every other list's
  /// offline snapshot intact. Used when a change affects a single list so we
  /// don't wipe the offline caches the other lists rely on.
  void invalidateItemsFor(int listId) =>
      cache.removeKey('$_itemsPrefix:$listId');

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

  Future<String> getLastCurrencyPref(int houseId) async {
    return ApiClient.instance.get<Map<String, dynamic>, String>(
      '/houses/$houseId/prefs',
      fromJson: (data) => data['lastCurrency'] as String? ?? 'USD',
    );
  }

  Future<void> setLastCurrencyPref(int houseId, String code) async {
    await ApiClient.instance.put<Map<String, dynamic>, void>(
      '/houses/$houseId/prefs',
      body: {'lastCurrency': code},
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

  Future<List<ChecklistList>> getArchivedLists(
    int houseId, {
    int limit = 200,
    int offset = 0,
  }) async {
    return ApiClient.instance.get<List, List<ChecklistList>>(
      '/houses/$houseId/lists/archive',
      query: {'limit': limit.toString(), 'offset': offset.toString()},
      fromJson: (data) => data
          .map((e) => ChecklistList.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ChecklistList> archiveList(int houseId, int listId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ChecklistList>(
      '/houses/$houseId/lists/$listId/archive',
      fromJson: (data) => ChecklistList.fromJson(data),
    );
  }

  Future<ChecklistList> unarchiveList(int houseId, int listId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ChecklistList>(
      '/houses/$houseId/lists/$listId/unarchive',
      fromJson: (data) => ChecklistList.fromJson(data),
    );
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

  // -- Batch (group) item operations --
  //
  // House-scoped: a selection can span multiple source lists, so the server
  // resolves each item's own source list. All return a [PantryBatchResult]
  // envelope; `skipped` carries ids the server refused for access reasons.

  Future<PantryBatchResult> batchMoveItems(
    int houseId, {
    required List<int> itemIds,
    required int targetListId,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, PantryBatchResult>(
      '/houses/$houseId/items/batch/move',
      body: {'itemIds': itemIds, 'targetListId': targetListId},
      fromJson: (data) => PantryBatchResult.fromJson(data),
    );
  }

  Future<PantryBatchResult> batchCopyItems(
    int houseId, {
    required List<int> itemIds,
    required int targetListId,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, PantryBatchResult>(
      '/houses/$houseId/items/batch/copy',
      body: {'itemIds': itemIds, 'targetListId': targetListId},
      fromJson: (data) => PantryBatchResult.fromJson(data),
    );
  }

  Future<PantryBatchResult> batchDeleteItems(
    int houseId, {
    required List<int> itemIds,
    bool permanent = false,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, PantryBatchResult>(
      '/houses/$houseId/items/batch/delete',
      body: {'itemIds': itemIds, if (permanent) 'permanent': true},
      fromJson: (data) => PantryBatchResult.fromJson(data),
    );
  }

  Future<PantryBatchResult> batchArchiveItems(
    int houseId, {
    required List<int> itemIds,
    bool archive = true,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, PantryBatchResult>(
      '/houses/$houseId/items/batch/archive',
      body: {'itemIds': itemIds, 'archive': archive},
      fromJson: (data) => PantryBatchResult.fromJson(data),
    );
  }

  Future<PantryBatchResult> batchSetCategory(
    int houseId, {
    required List<int> itemIds,
    required int? categoryId,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, PantryBatchResult>(
      '/houses/$houseId/items/batch/category',
      body: {'itemIds': itemIds, 'categoryId': categoryId},
      fromJson: (data) => PantryBatchResult.fromJson(data),
    );
  }

  Future<PantryBatchResult> batchSetStores(
    int houseId, {
    required List<int> itemIds,
    required List<int> storeIds,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, PantryBatchResult>(
      '/houses/$houseId/items/batch/stores',
      body: {'itemIds': itemIds, 'storeIds': storeIds},
      fromJson: (data) => PantryBatchResult.fromJson(data),
    );
  }

  /// Replaces the label set on every item (an empty list clears them),
  /// mirroring `batch/stores`. Returns the [PantryBatchResult] envelope.
  Future<PantryBatchResult> batchSetLabels(
    int houseId, {
    required List<int> itemIds,
    required List<int> labelIds,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, PantryBatchResult>(
      '/houses/$houseId/items/batch/labels',
      body: {'itemIds': itemIds, 'labelIds': labelIds},
      fromJson: (data) => PantryBatchResult.fromJson(data),
    );
  }

  /// Clears the done-state on every checked item in one request.
  /// Idempotent: already-unchecked items are left alone and omitted from the
  /// returned `items`. Permission `canCheckItems`.
  Future<PantryBatchResult> batchUncheckItems(
    int houseId, {
    required List<int> itemIds,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, PantryBatchResult>(
      '/houses/$houseId/items/batch/uncheck',
      body: {'itemIds': itemIds},
      fromJson: (data) => PantryBatchResult.fromJson(data),
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
