import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/models/member.dart';
import 'package:pantry/services/api_client.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/category_service.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/house_service.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/sync/sync_ids.dart';
import 'package:pantry/sync/sync_manager.dart';
import 'package:pantry/sync/sync_op.dart';

/// Sentinel id used by the synthetic "All lists" meta view. Real list ids on
/// the backend are always positive; temp ids minted by SyncManager are
/// negative. `0` is unused by both, which keeps the sentinel disjoint.
const int kAllListsId = 0;

/// Builds the synthetic "All lists" entry. Never persisted, never reordered;
/// the switcher surfaces it manually at position 0.
ChecklistList allListsSentinel(int houseId) => ChecklistList(
  id: kAllListsId,
  houseId: houseId,
  name: m.checklists.allLists,
  icon: 'all-lists',
  sortOrder: -1 << 30,
  createdAt: 0,
  updatedAt: 0,
  // The sentinel isn't a server entity, so its progress-card visibility is
  // persisted locally (under id 0) rather than synced like real lists.
  hideProgressHero: PrefsService.instance.allListsProgressHeroHidden,
);

/// Replaces items in [current] with their same-id counterpart from [updated],
/// leaving order and any non-matching items untouched. Backs the move (meta
/// view) and set-category reconciliation, where the server returns the affected
/// items to overlay. Pure, so it can be unit tested without the controller.
List<ListItem> reconcileReplaceById(
  List<ListItem> current,
  List<ListItem> updated,
) {
  final byId = {for (final i in updated) i.id: i};
  return [for (final i in current) byId[i.id] ?? i];
}

/// Drops every item in [current] whose id is in [removeIds]. Backs the delete
/// reconciliation and the per-list move (moved items leave the source view).
/// Pure, so it can be unit tested without the controller.
List<ListItem> reconcileRemoveIds(List<ListItem> current, Set<int> removeIds) =>
    [
      for (final i in current)
        if (!removeIds.contains(i.id)) i,
    ];

/// Index at which a newly added [item] should slot into [items] so the
/// optimistic insert matches the order the server returns for [sortBy].
///
/// The server orders these views purely by their sort key (created_at, name,
/// category rank) and does *not* group done items at the end — done rows are
/// interleaved by the same key. So we scan the whole list rather than stopping
/// at the first done row (the old boundary that yanked new items to the top
/// whenever a done item sorted early); the view re-partitions active/done for
/// display, and a freshly added item has the newest created_at, so ties
/// resolve to the end of their group exactly as the server would.
///
/// [categoryRankOf] maps a categoryId (null = uncategorized) to its display
/// rank; only consulted for the 'category' sort. Pure, so it can be unit
/// tested without the controller's singleton dependencies.
int checklistInsertIndex(
  List<ListItem> items,
  String sortBy,
  ListItem item,
  int Function(int? categoryId) categoryRankOf,
) {
  switch (sortBy) {
    case 'category':
      final myRank = categoryRankOf(item.categoryId);
      for (var i = 0; i < items.length; i++) {
        if (categoryRankOf(items[i].categoryId) > myRank) return i;
      }
      return items.length;
    case 'name_asc':
      final key = item.name.toLowerCase();
      for (var i = 0; i < items.length; i++) {
        if (items[i].name.toLowerCase().compareTo(key) > 0) return i;
      }
      return items.length;
    case 'name_desc':
      final key = item.name.toLowerCase();
      for (var i = 0; i < items.length; i++) {
        if (items[i].name.toLowerCase().compareTo(key) < 0) return i;
      }
      return items.length;
    case 'oldest':
      for (var i = 0; i < items.length; i++) {
        if (items[i].createdAt > item.createdAt) return i;
      }
      return items.length;
    case 'newest':
      for (var i = 0; i < items.length; i++) {
        if (items[i].createdAt < item.createdAt) return i;
      }
      return items.length;
    case 'custom':
    default:
      return 0;
  }
}

class ChecklistsController extends ChangeNotifier {
  final int houseId;

  /// Effective capabilities for the house this controller serves. The view
  /// keeps this fresh from the current house; gating is UX only (the server
  /// enforces and a 403 surfaces a snackbar). Defaults to all-allowed so the
  /// controller behaves normally before the view assigns real permissions.
  HousePermissions permissions = HousePermissions.unrestricted;

  ChecklistsController({required this.houseId}) {
    _appliedSub = SyncManager.instance.onApplied.listen(_onSyncApplied);
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

  @override
  void dispose() {
    _disposed = true;
    _appliedSub?.cancel();
    super.dispose();
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

  String _sortBy = 'custom';
  String get sortBy => _sortBy;

  String _categorySort = 'custom';
  String get categorySort => _categorySort;

  String _listSort = 'custom';
  String get listSort => _listSort;

  List<ChecklistList> get sortedLists =>
      ChecklistService.sortLists(_lists, _listSort);

  bool _showAddedBy = false;
  bool get showAddedBy => _showAddedBy;

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
  /// "my data is gone" while offline (issue #92).
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
  bool get canBatchCopy => selectedItems.isNotEmpty && permissions.canCopyItems;
  // Archive/unarchive are gated on canEditLists, not canDeleteItems.
  bool get canBatchArchive => _allSelectedWritable && permissions.canEditLists;
  // Trash restore is gated on canDeleteItems (the same permission trash uses).
  bool get canBatchRestore =>
      _allSelectedWritable && permissions.canDeleteItems;

  ChecklistService get _checklistService => ChecklistService.instance;
  CategoryService get _categoryService => CategoryService.instance;
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

      _lists = _applyLocalListPrefs(results[0] as List<ChecklistList>);
      _checklistService.cacheLists(houseId, _lists);

      final cats = results[1] as List<models.Category>;
      _categories = {for (final c in cats) c.id: c};

      // House prefs (sort + showAddedBy + categorySort) are non-fatal
      try {
        final prefs = await _checklistService.getHousePrefs(houseId);
        ServerVersionService.instance.observeHousePrefs(prefs);
        _sortBy = prefs['checklistItemSort'] as String? ?? 'custom';
        _showAddedBy = prefs['showAddedBy'] as bool? ?? false;
        _categorySort = prefs['categorySort'] as String? ?? 'custom';
        _listSort = prefs['checklistListSort'] as String? ?? 'custom';
        _checklistService.cache.set('sortBy:$houseId', _sortBy);
        _checklistService.cache.set('showAddedBy:$houseId', _showAddedBy);
        _checklistService.cache.set('categorySort:$houseId', _categorySort);
        _checklistService.cache.set('listSort:$houseId', _listSort);
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
      // infinite spinner (issue #87). Fire-and-forget; never blocks the UI.
      unawaited(_precacheListItems());
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
  /// currently viewing, so they're available offline (issue #87, #92). Skips
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
    _listSort =
        cache.get<String>('listSort:$houseId') ??
        cache.get<String>('listSort') ??
        'custom';

    final cachedMembers = _houseService.getCachedMembers(houseId);
    if (cachedMembers != null) {
      _members = {for (final m in cachedMembers) m.userId: m};
    }

    final cachedCats = _categoryService.getCached(houseId);
    if (cachedCats != null && _categories.isEmpty) {
      _categories = {for (final c in cachedCats) c.id: c};
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
      // empty state (issue #92). Show it first, then refresh in place.
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

  /// Overlays un-acked local mutations onto a freshly fetched server
  /// snapshot. The pending sync queue is exactly the set of records the
  /// server may not yet reflect, so for those ids the local optimistic state
  /// wins and every other record takes the server's version. Without this a
  /// background refresh that lands while a toggle/edit/create is still in
  /// flight momentarily reverts the item, then the op's response flips it
  /// back — a visible flicker.
  ///
  /// [server] holds only the records for the view being refreshed (one list,
  /// or the whole house in meta mode); intersecting the house-wide pending
  /// set with the current `_items`/`server` keeps it correctly scoped.
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
        _error = m.checklists.failedToLoadItems;
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
        _error = m.checklists.failedToLoadItems;
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

  Future<void> setSortBy(String sort) async {
    if (sort == _sortBy) return;
    _sortBy = sort;
    _checklistService.cache.set('sortBy:$houseId', sort);
    notifyListeners();

    unawaited(_persistSortPref(sort));

    if (_currentList != null) {
      // Only the current list's cached snapshot is now stale-ordered; drop just
      // that one so the other lists keep their offline caches (issue #92). The
      // re-warm below refreshes them in the new order while online.
      if (!isMetaMode) _checklistService.invalidateItemsFor(_currentList!.id);
      await selectList(_currentList!, refreshInPlace: true);
      unawaited(_precacheListItems());
    }
  }

  Future<void> _persistSortPref(String sort) async {
    try {
      await _checklistService.setItemSortPref(houseId, sort);
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to persist sort pref: $e');
    }
  }

  Future<void> onCategoriesChanged() async {
    try {
      final results = await Future.wait([
        _checklistService.getHousePrefs(houseId),
        _categoryService.getCategories(houseId),
      ]);
      final prefs = results[0] as Map<String, dynamic>;
      final cats = results[1] as List<models.Category>;
      _categorySort = prefs['categorySort'] as String? ?? 'custom';
      _categories = {for (final c in cats) c.id: c};
      _checklistService.cache.set('categorySort:$houseId', _categorySort);

      if (_sortBy == 'category') _resortItemsByCategory();
      notifyListeners();
    } catch (e) {
      debugPrint(
        '[ChecklistsController] Failed to refresh after categories changed: $e',
      );
    }
  }

  void _resortItemsByCategory() {
    final sorted = sortedCategories;
    final rank = <int, int>{};
    for (var i = 0; i < sorted.length; i++) {
      rank[sorted[i].id] = i;
    }
    const uncategorizedRank = 1 << 30;
    int rankOf(int? id) =>
        id == null ? uncategorizedRank : (rank[id] ?? uncategorizedRank);

    List<ListItem> stableByCategory(Iterable<ListItem> source) {
      final indexed = source.toList().asMap().entries.toList();
      indexed.sort((a, b) {
        final r = rankOf(
          a.value.categoryId,
        ).compareTo(rankOf(b.value.categoryId));
        return r != 0 ? r : a.key.compareTo(b.key);
      });
      return indexed.map((e) => e.value).toList();
    }

    final unchecked = stableByCategory(_items.where((i) => !i.done));
    final checked = stableByCategory(_items.where((i) => i.done));
    _items = [...unchecked, ...checked];
    if (_currentList != null) {
      _checklistService.cacheItems(_currentList!.id, List.of(_items));
    }
  }

  /// Position at which [item] should be inserted into [target] (defaulting to
  /// the live `_items`) to keep the active sort intact. Uses [effectiveSortBy]
  /// so it agrees with the order the server returns for the current view.
  int _insertIndexFor(ListItem item, [List<ListItem>? target]) {
    final sorted = sortedCategories;
    final rank = <int, int>{};
    for (var i = 0; i < sorted.length; i++) {
      rank[sorted[i].id] = i;
    }
    const uncategorizedRank = 1 << 30;
    int rankOf(int? id) =>
        id == null ? uncategorizedRank : (rank[id] ?? uncategorizedRank);

    return checklistInsertIndex(
      target ?? _items,
      effectiveSortBy,
      item,
      rankOf,
    );
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

  Future<void> setListSort(String sort) async {
    if (sort == _listSort) return;
    _listSort = sort;
    _checklistService.cache.set('listSort:$houseId', sort);
    notifyListeners();

    unawaited(_persistListSortPref(sort));
  }

  Future<void> _persistListSortPref(String sort) async {
    try {
      await _checklistService.setListSortPref(houseId, sort);
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to persist list sort pref: $e');
    }
  }

  Future<void> reorderLists(int oldIndex, int newIndex) async {
    if (_listSort != 'custom') return;
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex == newIndex) return;

    final ordered = sortedLists;
    final moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);

    final order = <Map<String, int>>[];
    for (var i = 0; i < ordered.length; i++) {
      order.add({'id': ordered[i].id, 'sortOrder': i});
    }

    final byId = {for (final l in _lists) l.id: l};
    _lists = [
      for (var i = 0; i < ordered.length; i++)
        byId[ordered[i].id]!.copyWith(sortOrder: i),
    ];
    _checklistService.cacheLists(houseId, _lists);
    notifyListeners();

    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.reorder,
        houseId: houseId,
        body: {'order': order},
        createdAt: _now(),
      ),
    );
  }

  Future<void> reorderItems(
    List<ListItem> partition,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex == newIndex) return;
    if (_currentList == null) return;
    // Meta view aggregates across lists; per-list sort_order is meaningless
    // here.
    if (isMetaMode) return;

    final item = partition.removeAt(oldIndex);
    partition.insert(newIndex, item);

    final order = <Map<String, int>>[];
    for (var i = 0; i < partition.length; i++) {
      order.add({'id': partition[i].id, 'sortOrder': i});
    }

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

    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.reorder,
        houseId: houseId,
        parentId: _currentList!.id,
        body: {'order': order},
        createdAt: _now(),
      ),
    );
  }

  Future<void> refresh() async {
    // `load()` re-fetches the current list and re-warms every other list's
    // offline cache via `_precacheListItems`. Wiping the non-current caches
    // here (the old behavior) raced that warm-up and, if the user went offline
    // before it finished, left those lists showing nothing (issue #92).
    await load();
  }

  Future<ChecklistList> createList({
    required String name,
    String? description,
    String? icon,
    String? color,
  }) async {
    final tempId = _sync.newTempId();
    final synthetic = ChecklistList(
      id: tempId,
      houseId: houseId,
      name: name,
      description: description,
      icon: icon ?? 'list',
      color: color,
      sortOrder: _lists.length,
      createdAt: _now(),
      updatedAt: _now(),
    );
    _lists = [..._lists, synthetic];
    _checklistService.cacheLists(houseId, _lists);
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.create,
        houseId: houseId,
        tempEntityId: tempId,
        body: {
          'name': name,
          'description': ?description,
          'icon': ?icon,
          'color': ?color,
        },
        createdAt: _now(),
      ),
    );
    return synthetic;
  }

  Future<void> updateList(
    ChecklistList list, {
    required String name,
    required String icon,
    String? color,
  }) async {
    if (list.id == kAllListsId) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final unchanged =
        trimmed == list.name && icon == list.icon && color == list.color;
    if (unchanged) return;

    final optimistic = list.copyWith(
      name: trimmed,
      icon: icon,
      color: color,
      updatedAt: _now(),
    );
    _lists = [for (final l in _lists) l.id == list.id ? optimistic : l];
    if (_currentList?.id == list.id) _currentList = optimistic;
    _checklistService.cacheLists(houseId, _lists);
    notifyListeners();

    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.update,
        houseId: houseId,
        entityId: list.id < 0 ? null : list.id,
        tempEntityId: list.id < 0 ? list.id : null,
        body: {'name': trimmed, 'icon': icon, 'color': ?color},
        createdAt: _now(),
      ),
    );
  }

  Future<void> setListDeleteOnDoneDefault(bool value) async {
    final list = _currentList;
    if (list == null || list.id == kAllListsId) return;
    if (list.deleteOnDoneDefault == value) return;

    final optimistic = list.copyWith(
      deleteOnDoneDefault: value,
      updatedAt: _now(),
    );
    _currentList = optimistic;
    _lists = [for (final l in _lists) l.id == optimistic.id ? optimistic : l];
    _checklistService.cacheLists(houseId, _lists);
    notifyListeners();

    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.update,
        houseId: houseId,
        entityId: list.id < 0 ? null : list.id,
        tempEntityId: list.id < 0 ? list.id : null,
        body: {'deleteOnDoneDefault': value},
        createdAt: _now(),
      ),
    );
  }

  Future<void> setListHideProgressHero(bool value) async {
    final list = _currentList;
    if (list == null) return;
    if (list.hideProgressHero == value) return;

    // The All-lists view is synthetic — there's no server list to sync, so its
    // toggle lives in local prefs (keyed by id 0). Reflect it on the in-memory
    // sentinel so the card hides/shows immediately.
    if (list.id == kAllListsId) {
      _currentList = list.copyWith(hideProgressHero: value, updatedAt: _now());
      await PrefsService.instance.setAllListsProgressHeroHidden(value);
      notifyListeners();
      return;
    }

    // Client-only: the server has no progress card, so persist the dismissal
    // in local prefs instead of syncing it. [_applyLocalListPrefs] re-applies
    // it after every refresh so the card stays hidden.
    await PrefsService.instance.setListProgressHeroHidden(list.id, value);

    final updated = list.copyWith(hideProgressHero: value);
    _currentList = updated;
    _lists = [for (final l in _lists) l.id == updated.id ? updated : l];
    _checklistService.cacheLists(houseId, _lists);
    notifyListeners();
  }

  Future<void> moveItem(ListItem item, int targetListId) async {
    // Cross-list move is online-only for v1 — its semantics interact with
    // both source and target list caches in ways that don't simplify well
    // through the basic SyncOp shapes. Falls back to a direct API call.
    final updated = await _checklistService.moveItem(
      houseId,
      item.listId,
      item.id,
      targetListId: targetListId,
    );
    if (isMetaMode) {
      // Meta view aggregates across lists — the item didn't leave the view,
      // it just changed listId.
      final idx = _items.indexWhere((i) => i.id == item.id);
      if (idx != -1) _items[idx] = updated;
      _cacheVisibleItems();
    } else {
      _items.removeWhere((i) => i.id == item.id);
      _checklistService.cacheItems(_currentList!.id, List.of(_items));
    }
    notifyListeners();
  }

  Future<void> copyItem(ListItem item, int targetListId) async {
    // Online-only for the same reason as [moveItem] — the new item lives on
    // a list the user isn't currently viewing, so cache reconciliation
    // doesn't fit the per-list SyncOp shapes.
    final created = await _checklistService.copyItem(
      houseId,
      item.listId,
      item.id,
      targetListId: targetListId,
    );
    if (isMetaMode) {
      // Meta view aggregates across lists — surface the new copy alongside
      // the original.
      _items = [created, ..._items];
      _cacheVisibleItems();
    }
    notifyListeners();
  }

  // -- Batch (group) actions --
  //
  // House-scoped and offline-capable: each applies a best-effort optimistic
  // mutation, enqueues a single `batch` SyncOp, and clears the selection. The
  // authoritative server envelope is reconciled later in [_onSyncApplied].
  // Client-side gating only lets writable items into move/delete/category, so
  // in practice `skipped` covers just items that vanished server-side — which
  // optimistic removal already matches.

  /// Persist the current `_items` snapshot to the cache slot backing the
  /// active view: the concrete list's slot, or the shared All-lists aggregate
  /// slot ([kAllListsId]) in meta mode. Routing every item-cache write through
  /// here keeps the All-lists view — and optimistic edits made from it —
  /// available offline alongside the per-list caches (issue #92).
  void _cacheVisibleItems([int? listId]) {
    final key = isMetaMode ? kAllListsId : (listId ?? _currentList?.id);
    if (key == null) return;
    _checklistService.cacheItems(key, List.of(_items));
  }

  void _cacheCurrentItems() => _cacheVisibleItems();

  void _enqueueBatch(
    String action,
    List<int> itemIds, {
    Map<String, dynamic> extra = const {},
  }) {
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.batch,
        houseId: houseId,
        body: {'batchAction': action, 'itemIds': itemIds, ...extra},
        createdAt: _now(),
      ),
    );
  }

  void batchMove(int targetListId) {
    final ids = _selectedItemIds.toList();
    if (ids.isEmpty) return;
    // Per-list view: the moved items leave immediately. Meta view keeps them
    // (their listId only changes once the server confirms via _onSyncApplied).
    if (!isMetaMode) {
      _items = reconcileRemoveIds(_items, ids.toSet());
      _cacheCurrentItems();
    }
    _enqueueBatch('move', ids, extra: {'targetListId': targetListId});
    exitSelection();
  }

  void batchCopy(int targetListId) {
    final ids = _selectedItemIds.toList();
    if (ids.isEmpty) return;
    // Copies live on another list (or arrive in the meta view only once the
    // server returns them), so there's nothing to show optimistically.
    _enqueueBatch('copy', ids, extra: {'targetListId': targetListId});
    exitSelection();
  }

  void batchDelete({bool permanent = false}) {
    final ids = _selectedItemIds.toList();
    if (ids.isEmpty) return;
    _items = reconcileRemoveIds(_items, ids.toSet());
    _cacheCurrentItems();
    _enqueueBatch('delete', ids, extra: {if (permanent) 'permanent': true});
    exitSelection();
  }

  void batchArchive() {
    final ids = _selectedItemIds.toList();
    if (ids.isEmpty) return;
    // Archived items leave the active view immediately.
    _items = reconcileRemoveIds(_items, ids.toSet());
    if (!isSoftView) _cacheCurrentItems();
    _enqueueBatch('archive', ids, extra: {'archive': true});
    exitSelection();
  }

  void batchUnarchive() {
    final ids = _selectedItemIds.toList();
    if (ids.isEmpty) return;
    // Unarchived items leave the archive view and return to the active list.
    _items = reconcileRemoveIds(_items, ids.toSet());
    if (!isSoftView) _cacheCurrentItems();
    _enqueueBatch('archive', ids, extra: {'archive': false});
    exitSelection();
  }

  /// Bulk-restore trashed items. There's no batch-restore endpoint, so this
  /// enqueues a per-id restore (the same op the single-item restore uses).
  void batchRestore() {
    final items = List.of(selectedItems);
    if (items.isEmpty) return;
    // Restored items leave the trash view and return to the active list.
    _items = reconcileRemoveIds(_items, {for (final i in items) i.id});
    if (!isSoftView) _cacheCurrentItems();
    for (final item in items) {
      _sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.restore,
          houseId: houseId,
          parentId: item.listId,
          entityId: item.id,
          createdAt: _now(),
        ),
      );
    }
    exitSelection();
  }

  void batchSetCategory(int? categoryId) {
    final ids = _selectedItemIds.toList();
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    _items = [
      for (final i in _items)
        idSet.contains(i.id)
            ? i.copyWith(
                categoryId: categoryId,
                clearCategory: categoryId == null,
                updatedAt: _now(),
              )
            : i,
    ];
    _cacheCurrentItems();
    _enqueueBatch('category', ids, extra: {'categoryId': categoryId});
    exitSelection();
  }

  /// Reconciles the authoritative envelope from a flushed `batch` op back into
  /// the view — see [_onSyncApplied].
  void _reconcileBatchApplied(SyncOp op, PantryBatchResult result) {
    switch (op.body['batchAction'] as String?) {
      case 'move':
        if (isMetaMode) {
          // Adopt the returned items (now carrying their new listId).
          _items = reconcileReplaceById(_items, result.items);
        } else {
          // Direction-aware: a returned item now living on the current list
          // moved *in* (keep/insert it — this is how an undo-move-back lands);
          // one living elsewhere moved *out* (remove it).
          final currentId = _currentList?.id;
          final movedOut = {
            for (final i in result.items)
              if (i.listId != currentId) i.id,
          };
          var next = reconcileRemoveIds(_items, movedOut);
          final present = {for (final i in next) i.id};
          final incoming = [
            for (final i in result.items)
              if (i.listId == currentId) i,
          ];
          next = reconcileReplaceById(next, incoming);
          for (final i in incoming) {
            if (!present.contains(i.id)) next.insert(_insertIndexFor(i), i);
          }
          _items = next;
          _cacheCurrentItems();
        }
      case 'copy':
        if (isMetaMode && result.items.isNotEmpty) {
          final existing = {for (final i in _items) i.id};
          final fresh = [
            for (final i in result.items)
              if (!existing.contains(i.id)) i,
          ];
          if (fresh.isNotEmpty) _items = [...fresh, ..._items];
        }
      case 'category':
        _items = reconcileReplaceById(_items, result.items);
        _cacheCurrentItems();
      case 'delete':
      case 'archive':
        // Optimistic removal already applied; nothing to overlay.
        break;
    }
    notifyListeners();
  }

  // -- Batch undo --
  //
  // Each reverses a group action from the pre-action item snapshots the view
  // captured, reusing the same batch ops (or per-id restore for delete).

  /// Return every item to the list it came from. Items may have originated on
  /// different lists, so the reverse move is grouped per source list.
  void undoBatchMove(List<ListItem> items) {
    if (items.isEmpty) return;
    if (isMetaMode) {
      _items = reconcileReplaceById(_items, items);
    } else {
      final existing = {for (final i in _items) i.id};
      for (final it in items) {
        if (it.listId == _currentList?.id && !existing.contains(it.id)) {
          _items.insert(_insertIndexFor(it), it);
        }
      }
      _cacheCurrentItems();
    }
    final bySource = <int, List<int>>{};
    for (final it in items) {
      bySource.putIfAbsent(it.listId, () => []).add(it.id);
    }
    for (final entry in bySource.entries) {
      _enqueueBatch('move', entry.value, extra: {'targetListId': entry.key});
    }
    notifyListeners();
  }

  /// Restore every soft-deleted item. There's no batch-restore endpoint, so
  /// this enqueues a per-id restore (the same op the single-item undo uses).
  void undoBatchDelete(List<ListItem> items) {
    if (items.isEmpty || _isTrashMode) return;
    final existing = {for (final i in _items) i.id};
    for (final item in items) {
      if (existing.contains(item.id)) continue;
      final restored = item.copyWith(clearDeletedAt: true, updatedAt: _now());
      _items.insert(_insertIndexFor(restored), restored);
      _sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.restore,
          houseId: houseId,
          parentId: item.listId,
          entityId: item.id,
          createdAt: _now(),
        ),
      );
    }
    _cacheCurrentItems();
    notifyListeners();
  }

  /// Reverse a bulk archive done from the active view: unarchive each snapshot
  /// back into the active list (no batch-unarchive coalescing needed here — a
  /// per-id unarchive is the same op the single-item undo uses).
  void undoBatchArchive(List<ListItem> items) {
    if (items.isEmpty || isSoftView) return;
    final existing = {for (final i in _items) i.id};
    for (final item in items) {
      if (existing.contains(item.id)) continue;
      final restored = item.copyWith(clearArchivedAt: true, updatedAt: _now());
      _items.insert(_insertIndexFor(restored), restored);
      _sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.unarchive,
          houseId: houseId,
          parentId: item.listId,
          entityId: item.id,
          createdAt: _now(),
        ),
      );
    }
    _cacheCurrentItems();
    notifyListeners();
  }

  /// Reverse a bulk unarchive done from the archive view: re-archive each
  /// snapshot so it returns to the archive list it left.
  void undoBatchUnarchive(List<ListItem> items) {
    if (items.isEmpty || !_isArchiveMode) return;
    final existing = {for (final i in _items) i.id};
    for (final item in items) {
      if (existing.contains(item.id)) continue;
      _items.insert(_insertIndexFor(item), item);
      _sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.archive,
          houseId: houseId,
          parentId: item.listId,
          entityId: item.id,
          createdAt: _now(),
        ),
      );
    }
    notifyListeners();
  }

  /// Reverse a bulk restore done from the trash view: re-trash each snapshot so
  /// it returns to the trash list it left.
  void undoBatchRestore(List<ListItem> items) {
    if (items.isEmpty || !_isTrashMode) return;
    final existing = {for (final i in _items) i.id};
    for (final item in items) {
      if (existing.contains(item.id)) continue;
      _items.insert(_insertIndexFor(item), item);
      _sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.delete,
          houseId: houseId,
          parentId: item.listId,
          entityId: item.id,
          createdAt: _now(),
        ),
      );
    }
    notifyListeners();
  }

  /// Return every item to its original category. Items may have had different
  /// categories, so the reverse is grouped per original category.
  void undoBatchSetCategory(List<ListItem> items) {
    if (items.isEmpty) return;
    final byId = {for (final it in items) it.id: it};
    _items = [
      for (final i in _items)
        if (byId[i.id] case final original?)
          i.copyWith(
            categoryId: original.categoryId,
            clearCategory: original.categoryId == null,
            updatedAt: _now(),
          )
        else
          i,
    ];
    _cacheCurrentItems();
    final byCategory = <int?, List<int>>{};
    for (final it in items) {
      byCategory.putIfAbsent(it.categoryId, () => []).add(it.id);
    }
    for (final entry in byCategory.entries) {
      _enqueueBatch('category', entry.value, extra: {'categoryId': entry.key});
    }
    notifyListeners();
  }

  Future<ListItem> addItem({
    required String name,
    String? description,
    String? quantity,
    int? categoryId,
    String? rrule,
    bool? repeatFromCompletion,
    bool? deleteOnDone,
  }) async {
    final list = _currentList;
    if (list == null || list.id == kAllListsId) {
      throw StateError(
        list == null
            ? 'No list selected'
            : 'Use addItemTo() when no real list is selected',
      );
    }
    return addItemTo(
      targetListId: list.id,
      name: name,
      description: description,
      quantity: quantity,
      categoryId: categoryId,
      rrule: rrule,
      repeatFromCompletion: repeatFromCompletion,
      deleteOnDone: deleteOnDone,
    );
  }

  /// Adds an item to a specific list. Used by the All-lists view (where there
  /// is no implicit target) and as the underlying implementation of
  /// [addItem]. When the meta view is active, the per-list cache is not
  /// touched — the next time that list is opened it'll refetch.
  Future<ListItem> addItemTo({
    required int targetListId,
    required String name,
    String? description,
    String? quantity,
    int? categoryId,
    String? rrule,
    bool? repeatFromCompletion,
    bool? deleteOnDone,
  }) async {
    final listId = targetListId;
    final tempId = _sync.newTempId();
    final loginName = AuthService.instance.credentials?.loginName;
    final synthetic = ListItem(
      id: tempId,
      listId: listId,
      name: name,
      description: description,
      categoryId: categoryId,
      quantity: quantity,
      done: false,
      rrule: rrule,
      repeatFromCompletion: repeatFromCompletion ?? false,
      deleteOnDone: deleteOnDone ?? false,
      addedBy: loginName,
      sortOrder: 0,
      createdAt: _now(),
      updatedAt: _now(),
    );
    _items.insert(_insertIndexFor(synthetic), synthetic);
    // In meta mode `_items` is the aggregate across every list, so it's cached
    // under the All-lists slot rather than the target list's — the target list
    // refetches (and re-caches its own slot) when next opened.
    _cacheVisibleItems(listId);
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.create,
        houseId: houseId,
        parentId: listId,
        tempEntityId: tempId,
        body: {
          'name': name,
          'description': ?description,
          'quantity': ?quantity,
          'categoryId': ?categoryId,
          'rrule': ?rrule,
          'repeatFromCompletion': ?repeatFromCompletion,
          'deleteOnDone': ?deleteOnDone,
        },
        createdAt: _now(),
      ),
    );
    return synthetic;
  }

  /// Finds an active (non-deleted) item in [targetListId] whose name matches
  /// [name] case-insensitively after trimming. Backs the "reuse existing
  /// items" flow. Works in both per-list and All-lists (meta) mode — in meta
  /// mode `_items` aggregates across lists, so the listId filter scopes the
  /// match to the chosen target list. Returns null if there's no match.
  ListItem? findExistingItem(int targetListId, String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final item in _items) {
      if (item.listId != targetListId) continue;
      if (item.deletedAt != null) continue;
      if (item.name.trim().toLowerCase() == normalized) return item;
    }
    return null;
  }

  /// Reuse an existing item instead of creating a duplicate: if it's currently
  /// done, toggle it back to active; if already active, do nothing.
  Future<void> reuseItem(ListItem item) async {
    if (item.done) await toggleItem(item);
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
    bool? deleteOnDone,
  }) async {
    final updated = item.copyWith(
      name: name,
      description: description,
      quantity: quantity,
      categoryId: categoryId,
      clearCategory: clearCategory,
      rrule: rrule,
      repeatFromCompletion: repeatFromCompletion,
      deleteOnDone: deleteOnDone,
      updatedAt: _now(),
    );
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = updated;
      _cacheVisibleItems(item.listId);
      notifyListeners();
    }
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.update,
        houseId: houseId,
        parentId: item.listId,
        entityId: item.id < 0 ? null : item.id,
        tempEntityId: item.id < 0 ? item.id : null,
        body: {
          'name': ?name,
          'description': ?description,
          'quantity': ?quantity,
          if (clearCategory) 'clearCategory': true,
          'categoryId': ?categoryId,
          'rrule': ?rrule,
          'repeatFromCompletion': ?repeatFromCompletion,
          'deleteOnDone': ?deleteOnDone,
        },
        createdAt: _now(),
      ),
    );
    return updated;
  }

  Future<ListItem> uploadItemImage(
    ListItem item, {
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (item.id < 0) {
      // Photo uploads are online-only and need a real server id — bail
      // until the optimistic create has resolved.
      throw StateError('Cannot upload image before item create syncs');
    }
    final updated = await _checklistService.uploadItemImage(
      houseId,
      item.listId,
      item.id,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = updated;
      _cacheVisibleItems(item.listId);
      notifyListeners();
    }
    return updated;
  }

  Future<void> deleteItemImage(ListItem item) async {
    if (item.id < 0) return;
    await _checklistService.deleteItemImage(houseId, item.listId, item.id);
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item.copyWith(clearImage: true, updatedAt: _now());
      _cacheVisibleItems(item.listId);
      notifyListeners();
    }
  }

  Future<void> deleteItem(ListItem item) async {
    _items.removeWhere((i) => i.id == item.id);
    _cacheVisibleItems(item.listId);
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.delete,
        houseId: houseId,
        parentId: item.listId,
        entityId: item.id < 0 ? null : item.id,
        tempEntityId: item.id < 0 ? item.id : null,
        createdAt: _now(),
      ),
    );
  }

  Future<void> restoreItem(ListItem item) async {
    _items.removeWhere((i) => i.id == item.id);
    if (!_isTrashMode) {
      _items.add(item.copyWith(clearDeletedAt: true, updatedAt: _now()));
      _cacheVisibleItems(item.listId);
    }
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.restore,
        houseId: houseId,
        parentId: item.listId,
        entityId: item.id,
        createdAt: _now(),
      ),
    );
  }

  Future<void> permanentlyDeleteItem(ListItem item) async {
    _items.removeWhere((i) => i.id == item.id);
    if (!isSoftView) {
      _cacheVisibleItems(item.listId);
    }
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.permanentDelete,
        houseId: houseId,
        parentId: item.listId,
        entityId: item.id,
        createdAt: _now(),
      ),
    );
  }

  /// Archive an active item. Mirrors [deleteItem] but sets `archivedAt` instead
  /// of `deletedAt`; the item leaves the active list for the archive view.
  Future<void> archiveItem(ListItem item) async {
    _items.removeWhere((i) => i.id == item.id);
    _cacheVisibleItems(item.listId);
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.archive,
        houseId: houseId,
        parentId: item.listId,
        entityId: item.id < 0 ? null : item.id,
        tempEntityId: item.id < 0 ? item.id : null,
        createdAt: _now(),
      ),
    );
  }

  /// Return an archived item to the active list. Mirrors [restoreItem]: from
  /// the archive view the item just leaves; from the active list (undo of a
  /// just-archived item) it reappears with `archivedAt` cleared.
  Future<void> unarchiveItem(ListItem item) async {
    _items.removeWhere((i) => i.id == item.id);
    if (!_isArchiveMode) {
      _items.add(item.copyWith(clearArchivedAt: true, updatedAt: _now()));
      _cacheVisibleItems(item.listId);
    }
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.unarchive,
        houseId: houseId,
        parentId: item.listId,
        entityId: item.id,
        createdAt: _now(),
      ),
    );
  }

  Future<void> emptyTrash() async {
    if (_currentList == null || _currentList!.id == kAllListsId) return;
    if (_isTrashMode) {
      _items = [];
      notifyListeners();
    }
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.emptyTrash,
        houseId: houseId,
        parentId: _currentList!.id,
        createdAt: _now(),
      ),
    );
  }

  // -- Lists trash (the lists themselves) --

  Future<void> loadTrashedLists() async {
    try {
      _trashedLists = await _checklistService.getDeletedLists(houseId);
      notifyListeners();
    } catch (e) {
      debugPrint('[ChecklistsController] Failed to load trashed lists: $e');
      rethrow;
    }
  }

  Future<void> deleteList(ChecklistList list) async {
    _lists.removeWhere((l) => l.id == list.id);
    _checklistService.cacheLists(houseId, _lists);
    if (_currentList?.id == list.id) {
      final next = _lists.isNotEmpty ? _lists.first : null;
      if (next != null) {
        await selectList(next);
      } else {
        _currentList = null;
        _items = [];
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.delete,
        houseId: houseId,
        entityId: list.id < 0 ? null : list.id,
        tempEntityId: list.id < 0 ? list.id : null,
        createdAt: _now(),
      ),
    );
  }

  Future<void> restoreList(ChecklistList list) async {
    _trashedLists.removeWhere((l) => l.id == list.id);
    final exists = _lists.any((l) => l.id == list.id);
    if (!exists) {
      _lists = [..._lists, list];
      _checklistService.cacheLists(houseId, _lists);
    }
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.restore,
        houseId: houseId,
        entityId: list.id,
        createdAt: _now(),
      ),
    );
  }

  Future<void> permanentlyDeleteList(ChecklistList list) async {
    _trashedLists.removeWhere((l) => l.id == list.id);
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.permanentDelete,
        houseId: houseId,
        entityId: list.id,
        createdAt: _now(),
      ),
    );
  }

  Future<void> emptyListsTrash() async {
    _trashedLists = [];
    notifyListeners();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistList,
        op: SyncOpKind.emptyTrash,
        houseId: houseId,
        createdAt: _now(),
      ),
    );
  }

  Future<void> toggleItem(ListItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    _items[index] = item.copyWith(done: !item.done, updatedAt: _now());
    _cacheVisibleItems(item.listId);
    notifyListeners();

    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.toggle,
        houseId: houseId,
        parentId: item.listId,
        entityId: item.id < 0 ? null : item.id,
        tempEntityId: item.id < 0 ? item.id : null,
        createdAt: _now(),
      ),
    );
  }

  // -- Sync callback --

  void _onSyncApplied(SyncOpApplied applied) {
    final tempId = applied.op.tempEntityId;
    switch (applied.op.entity) {
      case SyncEntity.checklistList:
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
            _items.removeWhere((i) => i.id == entity.id || i.id == tempId);
            _cacheVisibleItems();
            notifyListeners();
            return;
          }
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
      case SyncEntity.note:
        break;
    }
  }
}
