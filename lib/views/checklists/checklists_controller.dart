import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart' as models;
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/custom_field.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/models/label.dart' as models;
import 'package:pantry_core/models/member.dart';
import 'package:pantry_core/models/store.dart' as models;
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/category_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/custom_field_service.dart';
import 'package:pantry_core/services/label_service.dart';
import 'package:pantry_core/services/store_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry/services/image_cache_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_ids.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'checklists_ordering.dart';
export 'checklists_ordering.dart';

part 'checklists_controller.batch.dart';
part 'checklists_controller.item_crud.dart';
part 'checklists_controller.list_crud.dart';
part 'checklists_controller.sort.dart';

class ChecklistsController extends ChangeNotifier {
  final int houseId;

  /// Effective capabilities for the house this controller serves. The view
  /// keeps this fresh from the current house; gating is UX only (the server
  /// enforces and a 403 surfaces a snackbar). Defaults to all-allowed so the
  /// controller behaves normally before the view assigns real permissions.
  HousePermissions permissions = HousePermissions.unrestricted;

  ChecklistsController({required this.houseId}) {
    _appliedSub = SyncManager.instance.onApplied.listen(_onSyncApplied);
    _reconnectSub = SyncManager.instance.onReconnect.listen(_onReconnect);
  }

  /// True when the synthetic "All lists" entry is selected.
  bool get isMetaMode => _currentList?.id == kAllListsId;

  /// Whether the current concrete list permits item writes. A view-only shared
  /// list is read-only; everything else is writable (and the granular house
  /// caps still apply on top). The synthetic "All lists" sentinel carries no
  /// share fields, so it reports writable — per-item gating there goes through
  /// [isItemWritable]. Only meaningful when the server advertises `share-users`.
  bool get isCurrentListWritable => _currentList?.isWritable ?? true;

  /// Whether [item]'s own list permits writes. Used by the All-lists view,
  /// where each item belongs to a different underlying list with its own share
  /// level. Falls back to writable when the list isn't loaded.
  bool isItemWritable(ListItem item) {
    final list = _lists.cast<ChecklistList?>().firstWhere(
      (l) => l?.id == item.listId,
      orElse: () => null,
    );
    return list?.isWritable ?? true;
  }

  /// Whether the add-item affordance should be offered for the current view.
  /// Requires the house `canAddItems` cap and — outside the All-lists view — a
  /// writable current list. In All-lists mode the target list varies per add,
  /// so writability is enforced per-target server-side (a 403 surfaces the
  /// permission snackbar).
  bool get canAddItemsHere {
    if (!permissions.canAddItems) return false;
    if (isMetaMode) return true;
    return isCurrentListWritable;
  }

  /// Whether the current concrete list's settings (name/icon/color) may be
  /// edited, folding the per-list share permission into the house cap.
  bool get canEditCurrentListSettings => _currentList == null
      ? permissions.canEditLists
      : _currentList!.canEditSettingsWith(permissions.canEditLists);

  /// Effective sort for the current view. The meta view can't honor the
  /// per-list custom order, so it falls back to newest without persisting.
  String get effectiveSortBy =>
      isMetaMode && _sortBy == 'custom' ? 'newest' : _sortBy;

  bool _disposed = false;
  StreamSubscription<SyncOpApplied>? _appliedSub;
  StreamSubscription<void>? _reconnectSub;

  /// Image uploads staged against items whose optimistic create hasn't synced
  /// yet, keyed by the item's negative temp id. Drained in `_onSyncApplied`
  /// once the create resolves to a real server id.
  final Map<int, _PendingImageUpload> _pendingImageUploads = {};

  @override
  void dispose() {
    _disposed = true;
    _appliedSub?.cancel();
    _reconnectSub?.cancel();
    super.dispose();
  }

  /// Re-run the cache-first load when connectivity returns, so lists that fell
  /// to the offline/retry view (never opened online, or a fresh offline install)
  /// re-fetch and re-warm their caches on their own.
  void _onReconnect(void _) {
    if (_disposed) return;
    unawaited(load());
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

  /// Categories offered for an item on [listId], applying the effective-list
  /// rule: a list's own scoped categories plus every global one. When [listId]
  /// is null (the All-lists meta view, where the target list isn't chosen yet)
  /// only globals apply. A no-op filter on servers without `category-lists`,
  /// where every category is global.
  List<models.Category> categoriesForList(int? listId) {
    if (!hasFeature('category-lists')) return sortedCategories;
    return [
      for (final c in sortedCategories)
        if (c.listId == null || (listId != null && c.listId == listId)) c,
    ];
  }

  Map<int, models.Store> _stores = {};
  Map<int, models.Store> get stores => _stores;

  List<models.Store> get sortedStores =>
      StoreService.sortStores(_stores.values, _storeSort);

  /// Resolve an item's `storeIds` to the stores that still exist, in name
  /// order. Ids whose store was deleted are silently dropped.
  List<models.Store> storesFor(ListItem item) => [
    for (final s in sortedStores)
      if (item.storeIds.contains(s.id)) s,
  ];

  Map<int, models.Label> _labels = {};
  Map<int, models.Label> get labels => _labels;

  List<models.Label> get sortedLabels =>
      LabelService.sortLabels(_labels.values, _labelSort);

  /// Labels offered for an item on [listId], applying the effective-list rule:
  /// a list's own scoped labels plus every global one. When [listId] is null
  /// (the All-lists meta view) only globals apply. A no-op filter on servers
  /// without `label-lists`, where every label is global. Mirrors
  /// [categoriesForList].
  List<models.Label> labelsForList(int? listId) {
    if (!hasFeature('label-lists')) return sortedLabels;
    return [
      for (final l in sortedLabels)
        if (l.listId == null || (listId != null && l.listId == listId)) l,
    ];
  }

  /// Resolve an item's `labelIds` to the labels that still exist, in sort
  /// order. Ids whose label was deleted are silently dropped.
  List<models.Label> labelsFor(ListItem item) => [
    for (final l in sortedLabels)
      if (item.labelIds.contains(l.id)) l,
  ];

  /// Custom-field definitions for the house, driving the compose bar's
  /// custom-fields tray and its default seeding. Empty unless the
  /// `custom-fields` capability is present. Loaded non-fatally with the rest.
  List<FieldDefinition> _customFieldDefs = const [];
  List<FieldDefinition> get customFieldDefs =>
      hasFeature(kCustomFieldsFeature) ? _customFieldDefs : const [];

  String _sortBy = 'custom';
  String get sortBy => _sortBy;

  String _categorySort = 'custom';
  String get categorySort => _categorySort;

  String _storeSort = 'name_asc';
  String get storeSort => _storeSort;

  String _labelSort = 'name_asc';
  String get labelSort => _labelSort;

  String _listSort = 'custom';
  String get listSort => _listSort;

  List<ChecklistList> get sortedLists =>
      ChecklistService.sortLists(_lists, _listSort);

  bool _showAddedBy = false;
  bool get showAddedBy => _showAddedBy;

  /// Last currency the user picked for an item price in this house. Preselected
  /// when opening the price input on a new item. Defaults to `USD`.
  String _lastCurrency = 'USD';
  String get lastCurrency => _lastCurrency;

  Map<String, Member> _members = {};
  Map<String, Member> get members => _members;

  bool _isTrashMode = false;
  bool get isTrashMode => _isTrashMode;

  bool _isArchiveMode = false;
  bool get isArchiveMode => _isArchiveMode;

  /// True in either read-only lifecycle view (trash or archive). These views
  /// load online-only and suppress the compose bar, progress hero, filters,
  /// reordering and move/copy affordances.
  bool get isSoftView => _isTrashMode || _isArchiveMode;

  List<ChecklistList> _trashedLists = [];
  List<ChecklistList> get trashedLists => _trashedLists;

  List<ChecklistList> _archivedLists = [];
  List<ChecklistList> get archivedLists => _archivedLists;

  /// Archived items per list, folded into the item-reuse suggestions when the
  /// user has enabled "suggest archived items". Fetched lazily the first time a
  /// list's suggestions are searched (see [ensureArchivedReuseLoaded]) and then
  /// kept live: archiving an item adds it here, unarchiving removes it, so the
  /// suggestions stay in sync without a refetch.
  final Map<int, List<ListItem>> _archivedReuse = {};

  /// Lists whose archived-reuse set has a fetch in flight or completed, so the
  /// lazy load fires at most once per list per session.
  final Set<int> _archivedReuseRequested = {};

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// True while items are being re-fetched in place (e.g. a sort change) with
  /// the previous items still on screen. Drives a non-blocking refresh
  /// indicator instead of clearing the list to a loading/empty state.
  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  String? _error;
  String? get error => _error;

  /// True when the current view is showing nothing because the item fetch
  /// failed and there was no cached snapshot to fall back on — as opposed to a
  /// genuinely empty list. Lets the view surface an offline/retry state instead
  /// of the "Nothing on this list yet" empty state, which otherwise reads as
  /// "my data is gone" while offline.
  bool get itemsUnavailable =>
      _error != null && _items.isEmpty && !_isLoading && !isSoftView;

  // -- Multi-select (group actions) --
  //
  // Selection is UI-only local state layered over `_items`. Gated on the
  // `batch-operations` feature; the batch endpoints are house-scoped and
  // online-only, mirroring the single-item cross-list move/copy.

  bool _selectionMode = false;
  bool get selectionMode => _selectionMode;

  final Set<int> _selectedItemIds = {};
  Set<int> get selectedItemIds => _selectedItemIds;
  int get selectedCount => _selectedItemIds.length;

  /// Whether group actions are available at all in this view. Available in the
  /// active list and in both soft views (trash → bulk restore / permanent
  /// delete; archive → bulk unarchive / permanent delete).
  bool get canSelectItems => hasFeature('batch-operations');

  /// The currently-selected items, resolved against the live item list. Ids
  /// whose item has since left the view are silently dropped.
  List<ListItem> get selectedItems {
    final byId = {for (final i in _items) i.id: i};
    return [
      for (final id in _selectedItemIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  void enterSelection([int? seedId]) {
    if (!canSelectItems) return;
    _selectionMode = true;
    if (seedId != null) _selectedItemIds.add(seedId);
    notifyListeners();
  }

  void exitSelection() {
    if (!_selectionMode && _selectedItemIds.isEmpty) return;
    _selectionMode = false;
    _selectedItemIds.clear();
    notifyListeners();
  }

  void toggleSelected(int id) {
    if (!_selectedItemIds.remove(id)) _selectedItemIds.add(id);
    // Leaving selection mode when the last item is deselected keeps the UI
    // from stranding an empty selection bar.
    if (_selectedItemIds.isEmpty) _selectionMode = false;
    notifyListeners();
  }

  void selectAllVisible(Iterable<int> ids) {
    _selectedItemIds.addAll(ids);
    if (_selectedItemIds.isNotEmpty) _selectionMode = true;
    notifyListeners();
  }

  bool isSelected(int id) => _selectedItemIds.contains(id);

  /// Move / delete / set-category require every selected item's source list to
  /// be writable; copy only needs read access, so it allows read-only sources.
  bool get _allSelectedWritable =>
      selectedItems.isNotEmpty && selectedItems.every(isItemWritable);

  bool get canBatchMove => _allSelectedWritable && permissions.canMoveItems;
  bool get canBatchDelete => _allSelectedWritable && permissions.canDeleteItems;
  bool get canBatchCategory => _allSelectedWritable && permissions.canEditLists;
  // Batch store-assignment is gated on the same permission as category, plus the
  // `stores` feature (the action bar hides the button entirely without it).
  bool get hasStoresFeature => hasFeature('stores');
  bool get canBatchStores =>
      hasStoresFeature && _allSelectedWritable && permissions.canEditLists;
  // Batch label-assignment mirrors stores, gated on the `labels` feature.
  bool get hasLabelsFeature => hasFeature('labels');
  bool get canBatchLabels =>
      hasLabelsFeature && _allSelectedWritable && permissions.canEditLists;
  bool get canBatchCopy => selectedItems.isNotEmpty && permissions.canCopyItems;
  // Archive/unarchive are gated on canEditLists, not canDeleteItems.
  bool get canBatchArchive => _allSelectedWritable && permissions.canEditLists;
  // Trash restore is gated on canDeleteItems (the same permission trash uses).
  bool get canBatchRestore =>
      _allSelectedWritable && permissions.canDeleteItems;

  ChecklistService get _checklistService => ChecklistService.instance;
  CategoryService get _categoryService => CategoryService.instance;
  StoreService get _storeService => StoreService.instance;
  LabelService get _labelService => LabelService.instance;
  HouseService get _houseService => HouseService.instance;
  SyncManager get _sync => SyncManager.instance;

  int _now() => DateTime.now().millisecondsSinceEpoch;

  /// The progress card is a client-only feature — the server never stores or
  /// returns its hidden state — so re-apply the locally-persisted per-list
  /// dismissals onto freshly loaded lists. Without this, every refresh would
  /// reset `hideProgressHero` to false and the dismissed card would reappear.
  List<ChecklistList> _applyLocalListPrefs(List<ChecklistList> lists) => [
    for (final l in lists) _withLocalListPrefs(l),
  ];

  ChecklistList _withLocalListPrefs(ChecklistList list) {
    final hidden = PrefsService.instance.isListProgressHeroHidden(list.id);
    return list.hideProgressHero == hidden
        ? list
        : list.copyWith(hideProgressHero: hidden);
  }

  Future<void> load() async {
    _error = null;

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

      _lists = _applyLocalListPrefs(results[0] as List<ChecklistList>);
      _checklistService.cacheLists(houseId, _lists);

      final cats = results[1] as List<models.Category>;
      _categories = {for (final c in cats) c.id: c};

      // Stores are gated on the `stores` capability and fetched non-fatally so
      // a server without the feature (404) doesn't break the whole load.
      if (hasFeature('stores')) {
        try {
          final stores = await _storeService.getStores(houseId);
          _stores = {for (final s in stores) s.id: s};
        } catch (e) {
          debugPrint('[ChecklistsController] Failed to load stores: $e');
        }
      }

      // Labels are gated on the `labels` capability and fetched non-fatally so
      // a server without the feature (404) doesn't break the whole load.
      if (hasFeature('labels')) {
        try {
          final labels = await _labelService.getLabels(houseId);
          _labels = {for (final l in labels) l.id: l};
        } catch (e) {
          debugPrint('[ChecklistsController] Failed to load labels: $e');
        }
      }

      // Custom-field definitions back the compose bar's default seeding; gated
      // on the capability and fetched non-fatally.
      if (hasFeature(kCustomFieldsFeature)) {
        try {
          _customFieldDefs = await CustomFieldService.instance.getFields(
            houseId,
          );
        } catch (e) {
          debugPrint('[ChecklistsController] Failed to load custom fields: $e');
        }
      }

      // House prefs are non-fatal
      try {
        final prefs = await _checklistService.getHousePrefs(houseId);
        ServerVersionService.instance.observeHousePrefs(prefs);
        _sortBy = prefs['checklistItemSort'] as String? ?? 'custom';
        _showAddedBy = prefs['showAddedBy'] as bool? ?? false;
        _categorySort = prefs['categorySort'] as String? ?? 'custom';
        _storeSort = prefs['storeSort'] as String? ?? 'name_asc';
        _labelSort = prefs['labelSort'] as String? ?? 'name_asc';
        _listSort = prefs['checklistListSort'] as String? ?? 'custom';
        _lastCurrency = prefs['lastCurrency'] as String? ?? 'USD';
        _checklistService.cache.set('sortBy:$houseId', _sortBy);
        _checklistService.cache.set('showAddedBy:$houseId', _showAddedBy);
        _checklistService.cache.set('categorySort:$houseId', _categorySort);
        _checklistService.cache.set('storeSort:$houseId', _storeSort);
        _checklistService.cache.set('labelSort:$houseId', _labelSort);
        _checklistService.cache.set('listSort:$houseId', _listSort);
        _checklistService.cache.set('lastCurrency:$houseId', _lastCurrency);
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
        // Honor the persisted selection (e.g. a home-screen widget tap that
        // wrote `selectedListId` out-of-band) over the list currently shown;
        // during normal use the two are identical since `selectList` keeps
        // `selectedListId` in sync.
        final targetId = _checklistService.selectedListId ?? _currentList?.id;
        if (targetId == kAllListsId && hasFeature('checklist-all-view')) {
          // Stay on the meta view — falling back to `_lists.first` would
          // flicker the per-list view in between refreshes.
          await selectList(allListsSentinel(houseId));
        } else {
          final target = targetId != null
              ? _lists.cast<ChecklistList?>().firstWhere(
                      (l) => l!.id == targetId,
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

      // Warm the on-disk cache for the lists we're not currently viewing so
      // opening them later while offline shows cached data instead of an
      // infinite spinner. Fire-and-forget; never blocks the UI. Once every
      // list's items are cached, sweep their images (plus any cached photos)
      // into the offline image store.
      unawaited(
        _precacheListItems().then((_) {
          if (_disposed) return;
          unawaited(ImageCacheService.instance.sweepHouse(houseId));
        }),
      );
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to load: $e');
      if (_lists.isEmpty) {
        _error = m.checklists.failedToLoad;
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Best-effort fetch + cache of items for every list the user isn't
  /// currently viewing, so they're available offline. Skips
  /// optimistic (temp-id) lists and any list with a pending op — caching a
  /// server snapshot there would clobber the un-acked optimistic change. A
  /// per-list fetch failure is skipped (a transient error on one list must not
  /// starve the rest), but going offline stops the pass immediately since every
  /// remaining fetch would just wait out the request timeout.
  Future<void> _precacheListItems() async {
    if (!_sync.isOnline) return;
    // `null` means a house-scoped batch op is queued whose affected lists we
    // can't resolve — stay conservative and skip the warm-up entirely.
    final pendingLists = _sync.pendingListIds(houseId);
    if (pendingLists == null) return;
    final currentId = _currentList?.id;
    for (final list in _lists) {
      if (list.id == currentId || list.id < 0) continue;
      if (pendingLists.contains(list.id)) continue;
      if (!_sync.isOnline) return;
      try {
        final items = await _checklistService.getItems(
          houseId,
          list.id,
          sortBy: _sortBy,
        );
        // A mutation may have landed mid-fetch — don't overwrite a now-pending
        // list's cache with a snapshot that predates the optimistic change.
        if (_sync.pendingListIds(houseId)?.contains(list.id) ?? true) continue;
        _checklistService.cacheItems(list.id, items);
      } on OfflineException {
        // Lost connectivity mid-pass — the rest would only time out.
        return;
      } catch (e) {
        debugPrint('[ChecklistsController] Pre-cache failed (${list.id}): $e');
      }
    }

    // Warm the All-lists aggregate too, so it opens offline like any list. The
    // snapshot spans every list, so only cache it when nothing is pending —
    // otherwise it would predate an un-acked optimistic change. Skipped when
    // the aggregate is the current view (already fetched above) or the server
    // doesn't offer it.
    if (currentId == kAllListsId ||
        !hasFeature('checklist-all-view') ||
        !_sync.isOnline ||
        pendingLists.isNotEmpty) {
      return;
    }
    try {
      final all = await _checklistService.getHouseItems(
        houseId,
        sortBy: _sortBy == 'custom' ? 'newest' : _sortBy,
      );
      if (_sync.pendingListIds(houseId)?.isEmpty ?? false) {
        _checklistService.cacheItems(kAllListsId, all);
      }
    } on OfflineException {
      return;
    } catch (e) {
      debugPrint('[ChecklistsController] Pre-cache (all-lists) failed: $e');
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
    _storeSort =
        cache.get<String>('storeSort:$houseId') ??
        cache.get<String>('storeSort') ??
        'name_asc';
    _labelSort =
        cache.get<String>('labelSort:$houseId') ??
        cache.get<String>('labelSort') ??
        'name_asc';
    _listSort =
        cache.get<String>('listSort:$houseId') ??
        cache.get<String>('listSort') ??
        'custom';
    _lastCurrency =
        cache.get<String>('lastCurrency:$houseId') ??
        cache.get<String>('lastCurrency') ??
        'USD';

    final cachedMembers = _houseService.getCachedMembers(houseId);
    if (cachedMembers != null) {
      _members = {for (final m in cachedMembers) m.userId: m};
    }

    final cachedCats = _categoryService.getCached(houseId);
    if (cachedCats != null && _categories.isEmpty) {
      _categories = {for (final c in cachedCats) c.id: c};
    }

    final cachedStores = _storeService.getCached(houseId);
    if (cachedStores != null && _stores.isEmpty) {
      _stores = {for (final s in cachedStores) s.id: s};
    }

    final cachedDefs = CustomFieldService.instance.getCached(houseId);
    if (cachedDefs != null && _customFieldDefs.isEmpty) {
      _customFieldDefs = cachedDefs;
    }

    final cachedLabels = _labelService.getCached(houseId);
    if (cachedLabels != null && _labels.isEmpty) {
      _labels = {for (final l in cachedLabels) l.id: l};
    }

    final cachedLists = _checklistService.getCachedLists(houseId);
    if (cachedLists != null && _lists.isEmpty) {
      _lists = _applyLocalListPrefs(cachedLists);
      if (_lists.isNotEmpty) {
        final savedId = _checklistService.selectedListId;
        if (savedId == kAllListsId && hasFeature('checklist-all-view')) {
          _currentList = allListsSentinel(houseId);
          // The aggregate has its own cache slot (kAllListsId), so the
          // All-lists view restores offline just like a concrete list.
          final cachedItems = _checklistService.getCachedItems(kAllListsId);
          if (cachedItems != null) {
            _items = cachedItems;
            _isLoading = false;
            notifyListeners();
          }
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

  /// [refreshInPlace] keeps the current items on screen and surfaces a
  /// background refresh indicator while the new data loads, instead of clearing
  /// to an empty/loading state. Used by user-initiated reloads (e.g. a sort
  /// change) so the list doesn't flash empty mid-flight; background polling
  /// leaves it false so its refreshes stay silent.
  Future<void> selectList(
    ChecklistList list, {
    bool refreshInPlace = false,
  }) async {
    final previousListId = _currentList?.id;
    _currentList = list;
    _checklistService.selectedListId = list.id;

    if (isSoftView) {
      _items = [];
      _isLoading = true;
      _isRefreshing = false;
      notifyListeners();
      // Meta view has no trash/archive of its own — exit the soft view silently.
      if (list.id == kAllListsId) {
        _isTrashMode = false;
        _isArchiveMode = false;
        _isLoading = false;
        notifyListeners();
      } else if (_isArchiveMode) {
        await _loadArchiveItems(list);
        return;
      } else {
        await _loadTrashItems(list);
        return;
      }
    }

    if (list.id == kAllListsId) {
      // The aggregate is cached under the sentinel id so the All-lists view
      // opens with data while offline instead of an infinite spinner or an
      // empty state. Show it first, then refresh in place.
      final cachedAll = _checklistService.getCachedItems(kAllListsId);
      if (cachedAll != null) {
        _items = cachedAll;
        _error = null;
        _isLoading = false;
        _isRefreshing = refreshInPlace;
        notifyListeners();
      } else if (_items.isEmpty) {
        // On the first entry we have no prior items; subsequent refreshes keep
        // the previous list visible so the user sees an in-place swap rather
        // than an empty-state flash.
        _isLoading = true;
        _isRefreshing = false;
        notifyListeners();
      } else {
        _isRefreshing = refreshInPlace;
        notifyListeners();
      }
      try {
        final fresh = await _checklistService.getHouseItems(
          houseId,
          sortBy: effectiveSortBy,
        );
        if (_currentList?.id == kAllListsId && !isSoftView) {
          _items = _overlayPending(fresh);
          _error = null;
          _cacheVisibleItems();
          _isLoading = false;
          _isRefreshing = false;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('[ChecklistsController] Failed to load house items: $e');
        if (_currentList?.id == kAllListsId) {
          if (_items.isEmpty) _error = m.checklists.failedToLoadItems;
          _isLoading = false;
          _isRefreshing = false;
          notifyListeners();
        }
      }
      return;
    }

    final cached = _checklistService.getCachedItems(list.id);
    if (cached != null) {
      _items = cached;
      _error = null;
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    } else if (previousListId == list.id && _items.isNotEmpty) {
      // Re-selecting the list we're already showing (e.g. a sort change that
      // invalidated the cache): keep the current items on screen and, when
      // requested, surface a background refresh indicator instead of flashing
      // the empty state.
      _isLoading = false;
      _isRefreshing = refreshInPlace;
      notifyListeners();
    } else {
      _items = [];
      _isLoading = true;
      _isRefreshing = false;
      notifyListeners();
    }

    try {
      final freshItems = await _checklistService.getItems(
        houseId,
        list.id,
        sortBy: _sortBy,
      );
      if (_currentList?.id == list.id && !isSoftView) {
        // Reconcile against pending ops only while this list is still current;
        // `_items` belongs to a different list otherwise.
        final reconciled = _overlayPending(freshItems);
        _items = reconciled;
        _error = null;
        _checklistService.cacheItems(list.id, reconciled);
        _isLoading = false;
        _isRefreshing = false;
        notifyListeners();
      } else {
        _checklistService.cacheItems(list.id, freshItems);
      }
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to load items: $e');
      // Only surface a blocking error when there's nothing to show; if items
      // are still on screen (cached or kept for an in-place refresh), leave
      // them and just drop the refresh indicator.
      if (_items.isEmpty) _error = m.checklists.failedToLoadItems;
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Overlays un-acked local mutations onto a freshly fetched server snapshot:
  /// for ids still in the pending sync queue the local optimistic state wins,
  /// every other record takes the server's. Without this a background refresh
  /// landing mid-flight momentarily reverts the item, then the op's response
  /// flips it back — a visible flicker.
  ///
  /// [server] holds only the records for the view being refreshed (one list, or
  /// the whole house in meta mode).
  List<ListItem> _overlayPending(List<ListItem> server) {
    final pending = _sync.pendingItemIds(houseId);
    if (pending.isEmpty) return server;

    final localById = {for (final i in _items) i.id: i};
    final out = <ListItem>[];
    for (final s in server) {
      if (pending.contains(s.id)) {
        // Un-acked toggle/edit: trust local. If it's gone locally (pending
        // delete) drop it rather than letting the stale snapshot revive it.
        final local = localById[s.id];
        if (local != null) out.add(local);
      } else {
        out.add(s);
      }
    }

    // Optimistic creates the server hasn't returned yet (temp ids). Slot each
    // into the freshly fetched snapshot at the position the active sort
    // dictates instead of blindly prepending — otherwise a refresh that lands
    // before the create acks yanks the new item to the top regardless of sort.
    final present = out.map((i) => i.id).toSet();
    final localOnly = [
      for (final l in _items)
        if (pending.contains(l.id) && !present.contains(l.id)) l,
    ];
    // Resolve each create's slot against the untouched snapshot first, then
    // splice from the back. `localOnly` follows `_items` (display) order, so
    // those indices are non-decreasing; inserting highest-first keeps earlier
    // indices valid and preserves the relative order of ties.
    final slots = [for (final l in localOnly) (l, _insertIndexFor(l, out))];
    for (final (l, at) in slots.reversed) {
      out.insert(at, l);
    }
    return out;
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
        // Keep any rows already on screen (a silent background refresh that
        // failed) rather than replacing them with an error state; only surface
        // the error when there's nothing to show (the initial load).
        if (_items.isEmpty) _error = m.checklists.failedToLoadItems;
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadArchiveItems(ChecklistList list) async {
    try {
      final archivedItems = await _checklistService.getArchivedItems(
        houseId,
        list.id,
      );
      if (_currentList?.id == list.id && _isArchiveMode) {
        _items = archivedItems;
        _error = null;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to load archive: $e');
      if (_currentList?.id == list.id && _isArchiveMode) {
        // Keep any rows already on screen (a silent background refresh that
        // failed) rather than replacing them with an error state; only surface
        // the error when there's nothing to show (the initial load).
        if (_items.isEmpty) _error = m.checklists.failedToLoadItems;
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
    // Trash and archive are mutually exclusive views.
    if (enabled) _isArchiveMode = false;
    if (_currentList != null) {
      await selectList(_currentList!);
    } else {
      notifyListeners();
    }
  }

  Future<void> setArchiveMode(bool enabled) async {
    if (_isArchiveMode == enabled) return;
    // Meta view has no archive of its own — ignore.
    if (enabled && isMetaMode) return;
    _isArchiveMode = enabled;
    // Trash and archive are mutually exclusive views.
    if (enabled) _isTrashMode = false;
    if (_currentList != null) {
      await selectList(_currentList!);
    } else {
      notifyListeners();
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

  /// Remember the currency the user last picked for a real price. Persisted
  /// per house; preselected next time the price input opens on a new item.
  Future<void> setLastCurrency(String code) async {
    if (code == _lastCurrency) return;
    _lastCurrency = code;
    _checklistService.cache.set('lastCurrency:$houseId', code);
    try {
      await _checklistService.setLastCurrencyPref(houseId, code);
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to persist lastCurrency: $e');
    }
  }

  /// Whether within-group drag-to-reorder (category / store sort) is available.
  /// The server orders within-category by `sortOrder` only on newer builds;
  /// on an older server a within-category drag would snap back on refetch, so
  /// gate it on the capability flag. Store within-group ordering is
  /// client-side, but it's gated together for a consistent UX.
  bool get canReorderWithinGroups => hasFeature('custom-order-within-groups');

  /// Whether the "Uncheck all" affordance should be offered. Gated on the new
  /// endpoint's capability flag, plus a writable non-meta list and the
  /// check-items permission.
  bool get canUncheckAll =>
      hasFeature('uncheck-all') &&
      !isMetaMode &&
      isCurrentListWritable &&
      permissions.canCheckItems;

  /// Whether the "Remove all" affordance (bulk soft-delete of every done item)
  /// should be offered. A writable non-meta list in the active view, plus the
  /// delete-items permission.
  bool get canRemoveAllDone =>
      !isMetaMode &&
      !isSoftView &&
      isCurrentListWritable &&
      permissions.canDeleteItems;

  Future<void> refresh() async {
    // `load()` re-fetches the current list and re-warms every other list's
    // offline cache via `_precacheListItems`. Wiping the non-current caches
    // here (the old behavior) raced that warm-up and, if the user went offline
    // before it finished, left those lists showing nothing.
    await load();
  }

  /// Silently re-fetches the current soft view's items in place. Unlike
  /// [selectList]'s soft-view path, it leaves the existing rows on screen while
  /// the new snapshot loads (no empty flash, no spinner), so background polling
  /// keeps trash/archive current without disturbing a read. No-op
  /// outside a soft view or on the meta view (which has no soft view of its own).
  Future<void> refreshSoftView() async {
    if (!isSoftView) return;
    final list = _currentList;
    if (list == null || list.id == kAllListsId) return;
    if (_isArchiveMode) {
      await _loadArchiveItems(list);
    } else {
      await _loadTrashItems(list);
    }
  }

  /// Persist the current `_items` snapshot to the cache slot backing the
  /// active view: the concrete list's slot, or the shared All-lists aggregate
  /// slot ([kAllListsId]) in meta mode. Routing every item-cache write through
  /// here keeps the All-lists view — and optimistic edits made from it —
  /// available offline alongside the per-list caches.
  void _cacheVisibleItems([int? listId]) {
    final key = isMetaMode ? kAllListsId : (listId ?? _currentList?.id);
    if (key == null) return;
    _checklistService.cacheItems(key, List.of(_items));
  }

  void _cacheCurrentItems() => _cacheVisibleItems();

  // -- Sync callback --

  void _onSyncApplied(SyncOpApplied applied) {
    final tempId = applied.op.tempEntityId;
    switch (applied.op.entity) {
      case SyncEntity.checklistList:
        // Permanently deleting a list cascade-deletes its scoped categories on
        // the server (emptying the lists trash does the same for every trashed
        // list). Drop the obvious ones locally and refetch so the category
        // cache doesn't keep offering categories that no longer exist.
        final kind = applied.op.op;
        if (hasFeature('category-lists') &&
            (kind == SyncOpKind.permanentDelete ||
                kind == SyncOpKind.emptyTrash)) {
          final deletedListId = applied.op.entityId;
          if (deletedListId != null) {
            _categories.removeWhere((_, c) => c.listId == deletedListId);
          }
          notifyListeners();
          unawaited(_refreshCategories());
        }
        // Labels cascade the same way: a permanent list delete removes that
        // list's scoped labels (globals untouched). Prune and refetch so the
        // label cache stays honest.
        if (hasFeature('label-lists') &&
            (kind == SyncOpKind.permanentDelete ||
                kind == SyncOpKind.emptyTrash)) {
          final deletedListId = applied.op.entityId;
          if (deletedListId != null) {
            _labels.removeWhere((_, l) => l.listId == deletedListId);
          }
          notifyListeners();
          unawaited(_refreshLabels());
        }
        final entity = applied.entity;
        if (entity is ChecklistList) {
          // Server entities never carry the client-only progress-card state,
          // so overlay the local dismissal before adopting them.
          final reconciled = _withLocalListPrefs(entity);
          if (tempId != null) {
            final i = _lists.indexWhere((l) => l.id == tempId);
            if (i != -1) {
              _lists[i] = reconciled;
              if (_currentList?.id == tempId) _currentList = reconciled;
              _checklistService.cacheLists(houseId, _lists);
              notifyListeners();
              return;
            }
          }
          final j = _lists.indexWhere((l) => l.id == entity.id);
          if (j != -1) {
            _lists[j] = reconciled;
            if (_currentList?.id == entity.id) _currentList = reconciled;
            _checklistService.cacheLists(houseId, _lists);
            notifyListeners();
          }
        }
      case SyncEntity.checklistItem:
        final entity = applied.entity;
        if (entity is PantryBatchResult) {
          _reconcileBatchApplied(applied.op, entity);
          return;
        }
        if (entity is ListItem) {
          // If toggle caused soft-delete (deleteOnDone), drop it. Likewise a
          // synced item that came back archived doesn't belong in the active
          // view (the archive view keeps its own separately-loaded list).
          if (entity.deletedAt != null ||
              (entity.archivedAt != null && !_isArchiveMode)) {
            if (tempId != null) _pendingImageUploads.remove(tempId);
            _items.removeWhere((i) => i.id == entity.id || i.id == tempId);
            _cacheVisibleItems();
            notifyListeners();
            return;
          }
          // A create just bound to a real id — fire any image upload that was
          // staged against the temp id while the create was in flight.
          if (tempId != null) _flushPendingImageUpload(tempId, entity);
          if (tempId != null) {
            final i = _items.indexWhere((it) => it.id == tempId);
            if (i != -1) {
              _items[i] = entity;
              _cacheVisibleItems();
              notifyListeners();
              return;
            }
          }
          final j = _items.indexWhere((it) => it.id == entity.id);
          if (j != -1) {
            _items[j] = entity;
            _cacheVisibleItems();
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
      case SyncEntity.store:
        final entity = applied.entity;
        if (entity is models.Store) {
          if (tempId != null) {
            _stores.remove(tempId);
          }
          _stores[entity.id] = entity;
          notifyListeners();
        }
      case SyncEntity.label:
        final entity = applied.entity;
        if (entity is models.Label) {
          if (tempId != null) {
            _labels.remove(tempId);
          }
          _labels[entity.id] = entity;
          notifyListeners();
        }
      case SyncEntity.note:
      case SyncEntity.customField:
      case SyncEntity.shoppingCheck:
      case SyncEntity.shoppingSkip:
        // Not surfaced in the checklists view — the shopping session controller
        // reconciles its own check/skip ops, and the custom-fields manager
        // reconciles its own definition ops.
        break;
    }
  }
}

/// An image upload staged against an item whose optimistic create hasn't synced
/// yet. Held in [ChecklistsController._pendingImageUploads] until the create
/// resolves to a real server id.
class _PendingImageUpload {
  final List<int> bytes;
  final String fileName;
  final String mimeType;

  const _PendingImageUpload({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });
}
