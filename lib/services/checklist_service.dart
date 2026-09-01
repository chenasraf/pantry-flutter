import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/custom_field.dart';
import 'package:pantry/services/api_client.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/cache_store.dart';
import 'package:pantry/services/server_version_service.dart';

part 'checklist_service.lists.dart';
part 'checklist_service.items.dart';
part 'checklist_service.batch.dart';

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

  // -- House prefs --

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
}
