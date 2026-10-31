import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/custom_field.dart';
import 'package:pantry_core/models/item_defaults.dart';
import 'package:pantry_core/models/list_kind.dart';
import 'package:pantry_core/models/list_recurrence.dart';
import 'package:pantry_core/models/list_template.dart';
import 'package:pantry_core/models/stock.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/cache_store.dart';
import 'package:pantry_core/services/server_version_service.dart';

part 'checklist_service.lists.dart';
part 'checklist_service.items.dart';
part 'checklist_service.batch.dart';
part 'checklist_service.templates.dart';

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
  if (ServerFeature.itemPricePerStore) {
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

/// Serialize [customFields] for the item create/update body. `null` omits the
/// field (values unchanged); a list — even empty — is sent so an update can
/// clear every value. Sent only on servers advertising `custom-fields`; older
/// servers ignore custom fields entirely, so nothing is emitted for them.
Map<String, dynamic> customFieldsBody(List<FieldValue>? customFields) {
  if (customFields == null || !ServerFeature.customFields) {
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
  static const _selectedInventoryKey = 'selectedInventoryId';

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

  /// The list open in the Inventories tab, kept apart from [selectedListId] —
  /// which the widgets and the watch follow — so the two tabs each reopen on
  /// their own list.
  int? get selectedInventoryId => cache.get<int>(_selectedInventoryKey);
  set selectedInventoryId(int? id) => cache.set(_selectedInventoryKey, id);

  /// Transient (in-memory) request to open an item's detail once its list is
  /// loaded — set by an item deep link, consumed by the checklists view.
  int? pendingOpenItemId;

  /// Transient request to open the next inventory shown on its Needs restock
  /// filter — set by a stock summary notification.
  bool pendingNeedsRestockFilter = false;

  // -- List kinds --

  static const _kindsKey = 'listKinds';

  /// The kind of every list seen, so a call that only knows a list id (a
  /// queued op replayed after a relaunch, an item edit) reaches the resource
  /// serving that kind. Persisted alongside the lists themselves.
  Map<int, ListKind>? _kinds;

  Map<int, ListKind> get _kindMap => _kinds ??= {
    for (final MapEntry(:key, :value)
        in (cache.get<Map>(_kindsKey) ?? const {}).entries)
      ?int.tryParse('$key'): ListKind.parse(value),
  };

  /// The kind of list [listId], or a checklist when it has never been seen —
  /// which is every list on servers without [ServerFeature.listKinds].
  ListKind kindOf(int listId) => _kindMap[listId] ?? ListKind.checklist;

  void rememberKinds(Iterable<ChecklistList> lists) {
    var changed = false;
    for (final l in lists) {
      if (isAllListsId(l.id)) continue;
      if (_kindMap[l.id] != l.kind) {
        _kindMap[l.id] = l.kind;
        changed = true;
      }
    }
    if (!changed) return;
    cache.set(_kindsKey, {
      for (final e in _kindMap.entries) '${e.key}': e.value.wire,
    });
  }

  ChecklistList _remember(ChecklistList list) {
    rememberKinds([list]);
    return list;
  }

  List<ChecklistList> _rememberAll(List<ChecklistList> lists) {
    rememberKinds(lists);
    return lists;
  }

  /// `/houses/{houseId}/{resource}/{listId}` for the resource serving the
  /// list's kind.
  String listPath(int houseId, int listId) =>
      '/houses/$houseId/${kindOf(listId).resource}/$listId';

  String kindPath(int houseId, ListKind kind) =>
      '/houses/$houseId/${kind.resource}';

  /// The cached checklists of [houseId]. Templates and inventories are kept
  /// apart (see [getCachedListsOfEveryKind]) so the widgets, shopping and the
  /// watch, which only ever deal in checklists, never see them.
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

  /// Every cached list of [houseId], checklists first, then the other kinds in
  /// navigation order. `null` when not even the checklists were ever cached.
  List<ChecklistList>? getCachedListsOfEveryKind(int houseId) {
    final checklists = getCachedLists(houseId);
    if (checklists == null || !ServerFeature.listKinds) return checklists;
    return [
      ...checklists,
      for (final kind in ListKind.values)
        if (!kind.isChecklist)
          ...?cache.getKeyedList(
            _kindListsPrefix(kind),
            '$houseId',
            ChecklistList.fromJson,
          ),
    ];
  }

  /// Cache lists of any kind, each kind under its own key.
  void cacheListsOfEveryKind(int houseId, List<ChecklistList> lists) {
    rememberKinds(lists);
    for (final kind in ListKind.values) {
      final ofKind = [
        for (final l in lists)
          if (l.kind == kind) l,
      ];
      if (kind.isChecklist) {
        cacheLists(houseId, ofKind);
      } else {
        cache.setKeyedList(
          _kindListsPrefix(kind),
          '$houseId',
          ofKind,
          (l) => l.toJson(),
        );
      }
    }
  }

  /// The cached lists of one [kind], without touching the other kinds' caches.
  List<ChecklistList>? getCachedListsOfKind(int houseId, ListKind kind) {
    if (kind.isChecklist) return getCachedLists(houseId);
    return cache.getKeyedList(
      _kindListsPrefix(kind),
      '$houseId',
      ChecklistList.fromJson,
    );
  }

  void cacheListsOfKind(int houseId, ListKind kind, List<ChecklistList> lists) {
    rememberKinds(lists);
    if (kind.isChecklist) return cacheLists(houseId, lists);
    cache.setKeyedList(
      _kindListsPrefix(kind),
      '$houseId',
      lists,
      (l) => l.toJson(),
    );
  }

  static String _kindListsPrefix(ListKind kind) => '${kind.resource}Lists';

  List<ListItem>? getCachedItems(int listId) =>
      cache.getKeyedList(_itemsPrefix, '$listId', ListItem.fromJson);

  void cacheItems(int listId, List<ListItem> items) {
    cache.setKeyedList(_itemsPrefix, '$listId', items, (i) => i.toJson());
  }

  /// Drops every cached item list but [keepListId]'s and [keepListIds]'.
  void invalidateItems({
    int? keepListId,
    Iterable<int> keepListIds = const [],
  }) {
    cache.removeKeyed(
      _itemsPrefix,
      keepKeys: {
        if (keepListId != null) '$keepListId',
        for (final id in keepListIds) '$id',
      },
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

  /// The item sort of one list ([kAllListsId] for the All-lists view). A list
  /// with no stored choice answers with the house-wide `checklistItemSort`.
  Future<String> getListItemSort(int houseId, int listId) async {
    return ApiClient.instance.get<Map<String, dynamic>, String>(
      '/houses/$houseId/lists/$listId/prefs',
      fromJson: (data) => data['itemSort'] as String? ?? 'custom',
    );
  }

  Future<void> setListItemSort(int houseId, int listId, String sort) async {
    await ApiClient.instance.put<Map<String, dynamic>, void>(
      '/houses/$houseId/lists/$listId/prefs',
      body: {'itemSort': sort},
      fromJson: (_) {},
    );
  }

  /// The item sort last seen for [listId], falling back to the house-wide sort
  /// when the server keeps one sort per house or this list was never fetched.
  String cachedItemSort(int houseId, int listId) {
    final perList = ServerFeature.listItemSort
        ? cache.get<String>('itemSort:$houseId:$listId')
        : null;
    return perList ??
        cache.get<String>('sortBy:$houseId') ??
        cache.get<String>('sortBy') ??
        'custom';
  }

  void cacheItemSort(int houseId, int listId, String sort) =>
      cache.set('itemSort:$houseId:$listId', sort);

  /// Caches a user's sort choice for [listId] under the key [cachedItemSort]
  /// reads it back from: per list on `pref-list-item-sort` servers, per house
  /// otherwise.
  void rememberItemSort(int houseId, int listId, String sort) {
    if (ServerFeature.listItemSort) {
      cacheItemSort(houseId, listId, sort);
    } else {
      cache.set('sortBy:$houseId', sort);
    }
  }

  /// Re-keys a cached per-list sort when an optimistic list's temp id binds to
  /// its server id.
  void rebindItemSort(int houseId, int tempId, int realId) {
    final sort = cache.get<String>('itemSort:$houseId:$tempId');
    if (sort == null) return;
    cacheItemSort(houseId, realId, sort);
    cache.removeKey('itemSort:$houseId:$tempId');
  }

  Future<void> setItemSortPref(int houseId, String sort) async {
    await ApiClient.instance.put<Map<String, dynamic>, void>(
      '/houses/$houseId/prefs',
      body: {'checklistItemSort': sort},
      fromJson: (_) {},
    );
  }

  /// Whether this member gets the house's daily stock summaries.
  Future<bool> getStockSummaryPref(int houseId) async {
    return ApiClient.instance.get<Map<String, dynamic>, bool>(
      '/houses/$houseId/prefs',
      fromJson: (data) => data['notifyStockSummary'] as bool? ?? true,
    );
  }

  Future<void> setStockSummaryPref(int houseId, bool value) async {
    await ApiClient.instance.put<Map<String, dynamic>, void>(
      '/houses/$houseId/prefs',
      body: {'notifyStockSummary': value},
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
