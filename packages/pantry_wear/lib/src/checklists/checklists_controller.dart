import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/models/shopping_reminder.dart';
import 'package:pantry_core/models/shopping_review.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/models/store.dart';
import 'package:pantry_core/services/category_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/services/shopping_service.dart';
import 'package:pantry_core/services/store_service.dart';
import 'package:pantry_core/sync/pending_overlay.dart';
import 'package:pantry_core/sync/sync_ids.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/utils/currencies.dart';

import '../scope/wear_scope.dart';
import '../services/wear_mirror_client.dart';
import '../services/wear_ongoing_activity.dart';
import '../services/wear_tile_service.dart';
import '../widgets/wear_metrics.dart';

/// Browsing a list, or walking a trip. A live session is a different pager,
/// not a mode of one page, so this is what the shell swaps its sections on.
enum ChecklistMode { browse, session }

/// What a group of rows has in common. Both wear the entity's own icon and
/// colour, and the chip naming whichever one is in force is dropped from the
/// row — the header is already saying it.
enum ChecklistGrouping { category, store }

/// Everything the checklists page draws, and every write it makes.
///
/// Reads are cache-first and never blocking: a loading state ends on a
/// request's *outcome*, not its success, so a watch out of range shows what it
/// last knew rather than a spinner. Writes go to core's [SyncQueue] — the same
/// queue and the same executor the phone uses — so an in-store check survives
/// a dead link.
class ChecklistsController extends ChangeNotifier {
  ChecklistsController();

  /// A controller holding a fixed answer, for pumping the real widget tree
  /// without a server. Nothing here polls or subscribes: [start] is what does
  /// that, and a seeded controller is never started.
  @visibleForTesting
  ChecklistsController.seeded({
    required int houseId,
    ChecklistList? list,
    List<ChecklistList> lists = const [],
    List<ListItem> items = const [],
    List<ListItem> done = const [],
    List<ListItem> removed = const [],
    List<Category> categories = const [],
    List<Store> stores = const [],
    ShoppingSession? session,
    ShoppingReview? review,
    List<ShoppingReminder> reminders = const [],
    String itemSort = 'custom',
  }) {
    _itemSort = itemSort;
    _houseId = houseId;
    _list = list;
    _lists = lists;
    _items = items;
    _done = done;
    _removed = removed;
    _categories = {for (final c in categories) c.id: c};
    _stores = {for (final s in stores) s.id: s};
    _session = session;
    _review = review;
    _reminders = reminders;
    _loading = false;
  }

  final _checklists = ChecklistService.instance;
  final _shopping = ShoppingService.instance;
  final _sync = SyncManager.instance;
  final _scope = WearScope.instance;
  final _mirror = WearMirrorClient.instance;
  final _chip = WearOngoingActivityService.instance;

  int? _houseId;
  int? get houseId => _houseId;

  String? _houseName;

  ChecklistList? _list;

  /// The list being browsed, or the synthetic all-lists entry. Null in a
  /// session, which spans several lists and so has no current one.
  ChecklistList? get list => _list;

  List<ChecklistList> _lists = const [];
  List<ChecklistList> get lists => _lists;

  ShoppingSession? _session;
  ShoppingSession? get session => _session;

  ShoppingReview? _review;

  /// The bought log grouped by store, as the server computes it. What the
  /// summary is drawn from, so finishing a trip describes it without asking
  /// for it.
  ShoppingReview? get review => _review;

  List<ShoppingReminder> _reminders = const [];

  /// The house's reminders, every moment and every enabled state. The
  /// progression page picks the moment it is at out of them.
  List<ShoppingReminder> get reminders => _reminders;

  ChecklistMode get mode =>
      _session == null ? ChecklistMode.browse : ChecklistMode.session;

  List<ListItem> _items = const [];

  /// What is still to check off: undone items when browsing, what is left to
  /// buy in a session.
  List<ListItem> get items => _items;

  List<ListItem> _done = const [];

  /// Checked items — the collapsible section when browsing, a page of its own
  /// in a session.
  List<ListItem> get done => _done;

  List<ListItem> _removed = const [];

  /// Session only: items taken off this trip but still on their list.
  List<ListItem> get removed => _removed;

  Map<int, Category> _categories = const {};
  Map<int, Store> _stores = const {};

  /// The house's own sort preferences, which are house data rather than device
  /// settings — they come down with the house and mean the same thing on the
  /// phone, the web app and here.
  String _itemSort = 'custom';
  String _categorySort = 'custom';
  String _storeSort = 'name_asc';

  /// What the list is bucketed by. The house's item sort decides it, exactly as
  /// on the phone — except in a session, which never groups by store because
  /// the store it is standing in is already named in the rail.
  ///
  /// The `store-sort` capability is deliberately not consulted: it gates the
  /// picker that *sets* the pref, and the watch has no picker. A house whose
  /// pref already says `store` is grouped by store, the same way the phone
  /// renders it.
  ChecklistGrouping get grouping =>
      _itemSort == 'store' && mode == ChecklistMode.browse
      ? ChecklistGrouping.store
      : ChecklistGrouping.category;

  List<Category> get sortedCategories =>
      CategoryService.sortCategories(_categories.values, _categorySort);

  List<Store> get sortedStores =>
      StoreService.sortStores(_stores.values, _storeSort);

  Category? categoryOf(ListItem item) => _categories[item.categoryId];

  /// The store to name on a row. An item can carry several; the one that means
  /// something on the wrist is the store you are standing in, and otherwise the
  /// first the item lists.
  Store? storeOf(ListItem item) {
    if (item.storeIds.isEmpty) return null;
    final active = _session?.activeStoreId;
    if (active != null && item.storeIds.contains(active)) {
      return _stores[active];
    }
    return _stores[item.storeIds.first];
  }

  Store? storeById(int? id) => id == null ? null : _stores[id];

  /// The list a row is on. A house holds a handful, so the scan costs less
  /// than the map it would otherwise be kept in.
  ChecklistList? listOf(ListItem item) {
    for (final l in _lists) {
      if (l.id == item.listId) return l;
    }
    return null;
  }

  /// True when every row on screen is on the list the rail already names, so a
  /// chip naming it would repeat the header — the same rule that drops the
  /// chip naming the current grouping. The all-lists view spans several, and a
  /// trip spans several while the rail names the shop instead.
  bool get railNamesList =>
      _session == null && _list != null && _list!.id != kAllListsId;

  bool _loading = true;
  bool get isLoading => _loading;

  /// True when there is nothing to scope to — no house the wearer can see.
  /// The watch cannot fix this itself; pairing and house switching live
  /// elsewhere.
  bool get hasNoScope => _houseId == null;

  /// The last write the server refused, for the page to say so and put the row
  /// back. Cleared once shown.
  String? _dropped;
  String? get droppedMessage => _dropped;
  void clearDropped() {
    if (_dropped == null) return;
    _dropped = null;
    notifyListeners();
  }

  /// Check state the wearer has asked for but the server has not confirmed.
  /// Kept until the op leaves the queue, so a poll landing mid-flight cannot
  /// flicker a row back.
  final _doneOverride = <int, bool>{};

  /// Whether the watch face is carrying the trip chip, as far as this process
  /// knows — null until the first read settles. A notification outlives the
  /// process that posted it, so a launch has nothing to remember and has to act
  /// on what it finds: a trip means post, and no trip means cancel whatever a
  /// trip closed on the phone left behind.
  bool? _chipUp;

  bool _active = true;
  bool _disposed = false;
  Timer? _poll;
  StreamSubscription<SyncOpApplied>? _applied;
  StreamSubscription<SyncOpSkipped>? _skipped;

  Future<void> start() async {
    _applied ??= _sync.onApplied.listen(_onApplied);
    _skipped ??= _sync.onSkipped.listen(_onSkipped);
    _scope.addListener(_onScopeChanged);
    _mirror.addListener(_onMirrored);
    await _loadFromCache();
    _schedulePoll();
    unawaited(refresh());
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    _applied?.cancel();
    _skipped?.cancel();
    _scope.removeListener(_onScopeChanged);
    _mirror.removeListener(_onMirrored);
    super.dispose();
  }

  /// A snapshot landed in the caches this page reads, so re-read them. It is
  /// the same read a poll would have done, arriving without the request.
  void _onMirrored() {
    _schedulePoll();
    unawaited(_loadFromCache());
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  /// Only a page on screen polls. A Dart timer keeps firing while the watch
  /// sleeps — measured at 219 ticks through one doze window — so pausing is
  /// what stops the app draining the battery in a pocket, not an optimisation.
  void setActive(bool active) {
    if (_active == active) return;
    _active = active;
    if (active) {
      _schedulePoll();
      // Waking is the moment the watch has been off the link for however long
      // the wrist was down, so it asks rather than waiting to be told.
      unawaited(_mirror.requestMirror());
      // Coming back to a trip still being walked is the one thing that extends
      // the chip, and it is what makes an expiry mid-shop recoverable.
      _syncChip(renewing: true);
      unawaited(refresh());
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  void _schedulePoll() {
    _poll?.cancel();
    if (!_active) return;
    final interval = pollInterval;
    if (interval == null) return;
    _poll = Timer.periodic(interval, (_) => unawaited(refresh()));
  }

  /// How often to re-read, or null when the wearer has turned polling off.
  ///
  /// Stretched while snapshots are arriving, because an arrival is the phone
  /// saying it is alive and pushing — and never stopped, because the mirror is
  /// an accelerator and a watch that stopped polling would be trusting it.
  Duration? get pollInterval {
    final seconds = PrefsService.instance.wearPollSeconds;
    if (seconds <= 0) return null;
    final landed = _mirror.landedAt;
    final fresh =
        landed != null &&
        DateTime.now().difference(landed) < WearMetrics.mirrorFreshFor;
    return Duration(seconds: seconds * (fresh ? WearMetrics.pollStretch : 1));
  }

  void _onScopeChanged() {
    unawaited(_loadFromCache().then((_) => refresh()));
  }

  // -- Reading ---------------------------------------------------------------

  /// Everything the watch can answer without the network. Runs before the
  /// first fetch and again whenever scope moves, so the page draws immediately
  /// with whatever the last session left behind.
  ///
  /// The shell holds its first frame until this resolves, so the gate ends on
  /// the read *finishing* rather than on it succeeding: a throw anywhere inside
  /// would otherwise leave the watch on a bare ground plane with nothing left
  /// to end it.
  Future<void> _loadFromCache() async {
    try {
      await _readCache();
    } finally {
      _loading = false;
      _syncChip();
      _emit();
    }
  }

  /// Draw the watch-face chip while a trip is live, and take it down when there
  /// is none.
  ///
  /// [renewing] re-posts a chip that is already up, which is the only thing
  /// that restarts the half hour Android gives it — so it is passed by a resume
  /// and by nothing else. Without it this is a no-op unless the trip's
  /// existence actually changed, which keeps a poll from redrawing a system
  /// surface once a minute.
  void _syncChip({bool renewing = false}) {
    final live = _session != null;
    if (live == _chipUp && !(live && renewing)) return;
    _chipUp = live;
    unawaited(live ? _chip.post() : _chip.cancel());
  }

  Future<void> _readCache() async {
    final houses = HouseService.instance.getCached() ?? const [];
    _houseId = await _scope.resolveHouse(houses) ?? _scope.houseId;
    _dropped ??= _scope.takeFallbackNotice();
    final house = _houseId;
    if (house == null) return;
    _houseName = _nameOfHouse(houses, house);

    _categories = {
      for (final c in CategoryService.instance.getCached(house) ?? const [])
        c.id: c,
    };
    _stores = {
      for (final s in StoreService.instance.getCached(house) ?? const [])
        s.id: s,
    };
    _restoreHousePrefs(house);
    _lists = _checklists.getCachedLists(house) ?? const [];
    _reminders = _shopping.getCachedReminders(house) ?? _reminders;
    // The cache is where the trip lives, and memory is a projection of it —
    // every writer records the trip before this runs. A watch's process dies
    // constantly, and a trip only discoverable online would put the wearer
    // back in browse mode standing in the middle of a shop.
    _session = _shopping.getCachedSession();
    final session = _session;
    // A trip read back from the cache is still a mirrored scope, and the phone
    // cannot push what it has not been told the watch is showing.
    _mirror.setSession(session?.id);
    if (session == null) {
      final listId = await _scope.resolveList(_lists) ?? _scope.listId;
      _list = _listFor(listId, house);
      _applyItems(_cachedItems(listId));
      _publishTile();
    } else {
      final cached = _shopping.getCachedItems(session.id);
      if (cached != null) {
        _items = _withoutPendingSessionWrites(cached, house, session.id);
      }
    }
  }

  /// The house's sort prefs as the phone last cached them, under the phone's
  /// own keys — one house pref, one cached answer, whichever device fetched it.
  void _restoreHousePrefs(int house) {
    final cache = _checklists.cache;
    _itemSort = cache.get<String>('sortBy:$house') ?? _itemSort;
    _categorySort = cache.get<String>('categorySort:$house') ?? _categorySort;
    _storeSort = cache.get<String>('storeSort:$house') ?? _storeSort;
  }

  /// The currency a billed total is offered in — the house's own remembered
  /// one, under the phone's key, so the figure a wearer types at a till is
  /// already denominated the way the last one was.
  String get lastCurrency {
    final house = _houseId;
    if (house == null) return defaultCurrency;
    return _checklists.cache.get<String>('lastCurrency:$house') ??
        defaultCurrency;
  }

  /// House prefs are never fatal: a failed read leaves the cached answer in
  /// place, and the list keeps the grouping it already had.
  Future<void> _refreshHousePrefs(int house) async {
    try {
      final prefs = await _checklists.getHousePrefs(house);
      ServerVersionService.instance.observeHousePrefs(prefs);
      _itemSort = prefs['checklistItemSort'] as String? ?? 'custom';
      _categorySort = prefs['categorySort'] as String? ?? 'custom';
      _storeSort = prefs['storeSort'] as String? ?? 'name_asc';
      final cache = _checklists.cache;
      cache.set('sortBy:$house', _itemSort);
      cache.set('categorySort:$house', _categorySort);
      cache.set('storeSort:$house', _storeSort);
      cache.set(
        'lastCurrency:$house',
        prefs['lastCurrency'] as String? ?? defaultCurrency,
      );
    } catch (_) {}
  }

  ChecklistList? _listFor(int? id, int house) {
    if (id == null) return null;
    if (id == kAllListsId) {
      return ChecklistList(
        id: kAllListsId,
        houseId: house,
        name: m.checklists.allLists,
        icon: 'all-lists',
        sortOrder: -1 << 30,
        createdAt: 0,
        updatedAt: 0,
      );
    }
    for (final l in _lists) {
      if (l.id == id) return l;
    }
    return null;
  }

  /// The all-lists view has no cache key of its own: it is the union of the
  /// per-list snapshots, which is exactly what a fetch writes back.
  List<ListItem> _cachedItems(int? listId) {
    if (listId == null) return const [];
    if (listId != kAllListsId) {
      return _checklists.getCachedItems(listId) ?? const [];
    }
    return [for (final l in _lists) ...?_checklists.getCachedItems(l.id)];
  }

  /// One pass over everything the page shows. Nothing here throws: a failed
  /// leg leaves the cached answer in place and the next poll tries again.
  Future<void> refresh() async {
    await _refreshHouses();
    await _refreshSession();
    // A trip the poll or the mirror has just found is a trip that became live
    // without anyone opening a page, which is one of the three moments the chip
    // is posted.
    _syncChip();
    if (_session != null) {
      await _refreshSessionItems();
    } else {
      await _refreshBrowse();
    }
    _loading = false;
    _emit();
  }

  /// A house the watch has never seen cannot come from the cache, and a house
  /// that has stopped existing has to stop being the scope — both are the same
  /// read.
  Future<void> _refreshHouses() async {
    try {
      final houses = await HouseService.instance.getHouses();
      _houseId = await _scope.resolveHouse(houses) ?? _houseId;
      _dropped ??= _scope.takeFallbackNotice();
      final house = _houseId;
      if (house != null) _houseName = _nameOfHouse(houses, house);
    } catch (_) {}
  }

  String? _nameOfHouse(List<House> houses, int id) {
    for (final h in houses) {
      if (h.id == id) return h.name;
    }
    return null;
  }

  /// Hand the list Tile what it draws, every time the answer is re-read.
  ///
  /// The lists are the current house's active ones, which is the same notion
  /// of "lists" the switcher offers — a Tile that offered a different set
  /// would be a second scope for the wearer to reconcile. Publishing is
  /// unconditional and cheap: native drops a payload identical to the one it
  /// holds, so nothing wakes the Tile unless a list was renamed, added or
  /// removed.
  void _publishTile() {
    final house = _houseId;
    if (house == null) return;
    unawaited(
      WearTileService.instance.publish(
        houseId: house,
        houseName: _houseName,
        lists: _lists,
      ),
    );
  }

  Future<void> _refreshSession() async {
    try {
      final live = await _shopping.getCurrentSession();
      final was = _session?.id;
      _session = live;
      // A different trip's bought log is not this one's, and the summary is
      // drawn from it.
      if (live?.id != was) _review = null;
      // A trip's items are their own mirrored scope, so the phone has to hear
      // about it the same way it hears about the list.
      _mirror.setSession(live?.id);
      if (live == null) {
        // Closing a trip needs no rule of its own: the remembered list is
        // still there when the session was in this house, and invalid — so
        // the lowest-sortOrder rule picks — when it was in another.
        if (was != null) await _loadFromCache();
        return;
      }
      if (live.houseId != _houseId) {
        await _scope.adoptSessionHouse(live.houseId);
        _houseId = live.houseId;
        await _loadReferenceSets();
      }
      _list = null;
    } catch (_) {
      // A trip cannot be discovered offline. Whatever mode the watch is in
      // stays put rather than collapsing to browse on a dropped request.
    }
  }

  Future<void> _loadReferenceSets() async {
    final house = _houseId;
    if (house == null) return;
    await _refreshHousePrefs(house);
    try {
      final categories = await CategoryService.instance.getCategories(house);
      _categories = {for (final c in categories) c.id: c};
    } catch (_) {}
    try {
      final stores = await StoreService.instance.getStores(house);
      _stores = {for (final s in stores) s.id: s};
    } catch (_) {}
  }

  Future<void> _refreshBrowse() async {
    final house = _houseId;
    if (house == null) return;
    await _loadReferenceSets();
    try {
      final lists = await _checklists.getLists(house);
      _lists = lists;
      _checklists.cacheLists(house, lists);
      final listId = await _scope.resolveList(lists) ?? _scope.listId;
      _list = _listFor(listId, house);
      _publishTile();
    } catch (_) {}

    final listId = _list?.id;
    if (listId == null) return;
    try {
      // The cached copy is read before the fetch is written over it: it is the
      // local half of the overlay, and on a device whose process dies as
      // readily as a watch's it is the only place a check made by a previous
      // launch still exists.
      final held = _cachedItems(listId);
      final fetched = listId == kAllListsId
          ? await _checklists.getHouseItems(house)
          : await _checklists.getItems(house, listId);
      final overlaid = _withPendingWrites(fetched, held, house);
      if (listId == kAllListsId) {
        _cacheByList(overlaid);
      } else {
        _checklists.cacheItems(listId, overlaid);
      }
      _applyItems(overlaid);
    } catch (_) {}
  }

  /// A fetched snapshot describes what the server knew, which is older than
  /// anything still in the queue. The queue wins — over this snapshot as over
  /// a mirrored one — or a poll landing between a check and its drain flips
  /// the row back under the wearer's finger, and the cache write behind it
  /// makes the reversal outlive the process.
  List<ListItem> _withPendingWrites(
    List<ListItem> fetched,
    List<ListItem> held,
    int house,
  ) => overlayPendingItems(
    server: fetched,
    local: held,
    pending: _sync.pendingItemIds(house),
  );

  void _cacheByList(List<ListItem> items) {
    final byList = <int, List<ListItem>>{};
    for (final item in items) {
      byList.putIfAbsent(item.listId, () => []).add(item);
    }
    byList.forEach(_checklists.cacheItems);
  }

  Future<void> _refreshSessionItems() async {
    final house = _houseId;
    final session = _session;
    if (house == null || session == null) return;
    try {
      final items = await _shopping.getItems(house, session.id);
      _items = _withoutPendingSessionWrites(items, house, session.id);
    } catch (_) {
      // The last snapshot — the watch's own or a mirrored one — is a better
      // answer mid-aisle than an empty trip.
      final cached = _shopping.getCachedItems(session.id);
      if (cached != null) {
        _items = _withoutPendingSessionWrites(cached, house, session.id);
      }
    }
    try {
      final review = await _shopping.getReview(house, session.id);
      _review = review;
      _done = [
        for (final ShoppingReviewStore store in review.stores) ...store.items,
      ];
    } catch (_) {}
    try {
      _removed = await _shopping.getRemovedItems(house, session.id);
    } catch (_) {}
  }

  /// The queue wins over any snapshot. An item checked or taken off the trip
  /// while the write is still queued must not come back because a poll landed
  /// first — and one being put back must not stay hidden.
  List<ListItem> _withoutPendingSessionWrites(
    List<ListItem> items,
    int house,
    int sessionId,
  ) {
    final hidden = {
      ..._sync.pendingShoppingCheckedIds(house, sessionId),
      ..._sync.pendingShoppingSkippedIds(house, sessionId),
    };
    return [
      for (final item in items)
        if (!hidden.contains(item.id)) item,
    ];
  }

  /// Split a fetched snapshot into what is left and what is checked, with any
  /// still-queued check laid over the top.
  void _applyItems(List<ListItem> fetched) {
    final house = _houseId;
    if (house != null) {
      final pending = _sync.pendingItemIds(house);
      _doneOverride.removeWhere((id, _) => !pending.contains(id));
    }
    final resolved = [
      for (final item in fetched)
        _doneOverride.containsKey(item.id)
            ? item.copyWith(done: _doneOverride[item.id])
            : item,
    ];
    _items = [
      for (final i in resolved)
        if (!i.done) i,
    ];
    _done = [
      for (final i in resolved)
        if (i.done) i,
    ];
  }

  /// Whether the server answered the last request that reached it. What the
  /// lifecycle verbs refuse on, and what a page draws their refusal from.
  bool get isOnline => _sync.isOnline;

  /// The house's reminders, cache first and then the server. Asked for by the
  /// page that reads them rather than fetched on every poll: they are the one
  /// thing on a trip that changes on the scale of weeks.
  Future<void> loadReminders() async {
    final house = _houseId;
    if (house == null) return;
    final cached = _shopping.getCachedReminders(house);
    if (cached != null) {
      _reminders = cached;
      _emit();
    }
    try {
      _reminders = await _shopping.getReminders(house);
      _emit();
    } catch (_) {}
  }

  // -- The trip's lifecycle ---------------------------------------------------

  /// Move the trip to [storeId], which may be any leg it carries — so tapping
  /// an earlier one goes back.
  ///
  /// Online only. `getItems` is narrowed by the active store server-side, so a
  /// queued advance would leave the watch showing the previous shop's items
  /// while claiming to be at the next.
  Future<bool> advanceTo(int storeId) async {
    final house = _houseId;
    final session = _session;
    if (house == null || session == null || !_sync.isOnline) return false;
    try {
      _session = await _shopping.advance(house, session.id, storeId: storeId);
    } catch (_) {
      return false;
    }
    _emit();
    await _refreshSessionItems();
    _emit();
    return true;
  }

  /// End the trip. Irreversible server-side, which is why the summary that
  /// confirms it comes first.
  ///
  /// Online only for the same reason as [advanceTo], plus one of its own: a
  /// queued close would have to vanish the session pager on a write that has
  /// not happened.
  Future<bool> closeTrip() async {
    final house = _houseId;
    final session = _session;
    if (house == null || session == null || !_sync.isOnline) return false;
    try {
      await _shopping.close(house, session.id);
    } on ShoppingSessionConflict {
      // Already closed, by a retry of this same tap or by the phone. The trip
      // is over, which is what was asked for.
    } catch (_) {
      return false;
    }
    _session = null;
    _review = null;
    _done = const [];
    _removed = const [];
    _mirror.setSession(null);
    await _loadFromCache();
    _emit();
    return true;
  }

  /// What was paid at [storeId]'s till — null for the trip's storeless
  /// fallback — with anything still queued laid over the trip the server last
  /// described, so the figure on screen is the one that was typed.
  ({double? total, String? currency}) billedFor(int? storeId) {
    const none = (total: null, currency: null);
    final house = _houseId;
    final session = _session;
    if (house == null || session == null) return none;
    final pending = _sync.pendingSessionBilled(house, session.id)[storeId];
    if (pending != null) return pending;
    if (storeId == null) {
      return (total: session.billedTotal, currency: session.billedCurrency);
    }
    for (final leg in session.stores) {
      if (leg.storeId == storeId) {
        return (total: leg.billedTotal, currency: leg.billedCurrency);
      }
    }
    return none;
  }

  /// Record what a till charged. Queued, not sent: it is the one figure
  /// entered at the till, and a till is where the link is worst.
  ///
  /// A null [total] clears the figure, which is what an emptied field means.
  void setBilled({
    required int? storeId,
    required double? total,
    required String currency,
  }) {
    final house = _houseId;
    final session = _session;
    if (house == null || session == null) return;
    // Under the phone's own key, so the next total this house is asked for
    // opens on the currency the last one was given in.
    _checklists.cache.set('lastCurrency:$house', currency);
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.shoppingSession,
        op: SyncOpKind.update,
        houseId: house,
        parentId: session.id,
        entityId: storeId,
        body: {
          'billedTotal': total,
          'billedCurrency': total == null ? null : currency,
        },
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    _emit();
  }

  // -- Writing ---------------------------------------------------------------

  /// Check or uncheck an item on its list. The row reads as done straight
  /// away — the write is what is being delayed, not the feedback.
  void setDone(ListItem item, bool done) {
    final house = _houseId;
    if (house == null || item.done == done) return;
    _doneOverride[item.id] = done;
    final updated = item.copyWith(
      done: done,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _items = [
      for (final i in _items)
        if (i.id != item.id) i,
    ];
    _done = [
      for (final i in _done)
        if (i.id != item.id) i,
    ];
    (done ? _done : _items).add(updated);
    _writeThrough(updated);
    _emit();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.toggle,
        houseId: house,
        parentId: item.listId,
        entityId: item.id < 0 ? null : item.id,
        tempEntityId: item.id < 0 ? item.id : null,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Fold an optimistic change back into the list's cached snapshot, so a
  /// relaunch before the queue drains still shows what the wearer did.
  void _writeThrough(ListItem item) {
    final cached = _checklists.getCachedItems(item.listId);
    if (cached == null) return;
    _checklists.cacheItems(item.listId, [
      for (final i in cached)
        if (i.id == item.id) item else i,
    ]);
  }

  /// Mark an item bought on this trip. A different verb from [setDone]: it
  /// writes a check-log row against the session rather than the item's own
  /// done state.
  void checkItem(ListItem item) => _sessionWrite(
    item.id,
    SyncEntity.shoppingCheck,
    SyncOpKind.create,
    removeFrom: _Collection.items,
    addTo: _Collection.done,
    item: item,
  );

  void uncheckItem(ListItem item) => _sessionWrite(
    item.id,
    SyncEntity.shoppingCheck,
    SyncOpKind.delete,
    removeFrom: _Collection.done,
    addTo: _Collection.items,
    item: item,
  );

  void skipItem(ListItem item) => _sessionWrite(
    item.id,
    SyncEntity.shoppingSkip,
    SyncOpKind.create,
    removeFrom: _Collection.items,
    addTo: _Collection.removed,
    item: item,
  );

  void unskipItem(ListItem item) => _sessionWrite(
    item.id,
    SyncEntity.shoppingSkip,
    SyncOpKind.delete,
    removeFrom: _Collection.removed,
    addTo: _Collection.items,
    item: item,
  );

  void _sessionWrite(
    int itemId,
    SyncEntity entity,
    SyncOpKind op, {
    required _Collection removeFrom,
    required _Collection addTo,
    required ListItem item,
  }) {
    final house = _houseId;
    final session = _session;
    if (house == null || session == null) return;
    _move(item, removeFrom, addTo);
    _emit();
    _sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: entity,
        op: op,
        houseId: house,
        entityId: itemId,
        parentId: session.id,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void _move(ListItem item, _Collection from, _Collection to) {
    List<ListItem> without(List<ListItem> source) => [
      for (final i in source)
        if (i.id != item.id) i,
    ];
    switch (from) {
      case _Collection.items:
        _items = without(_items);
      case _Collection.done:
        _done = without(_done);
      case _Collection.removed:
        _removed = without(_removed);
    }
    switch (to) {
      case _Collection.items:
        _items = [..._items, item];
      case _Collection.done:
        _done = [..._done, item];
      case _Collection.removed:
        _removed = [..._removed, item];
    }
  }

  // -- Reconciling with the queue -------------------------------------------

  void _onApplied(SyncOpApplied event) {
    if (event.op.houseId != _houseId) return;
    if (event.op.entity == SyncEntity.checklistItem) {
      _doneOverride.remove(event.op.effectiveEntityId);
    }
    unawaited(refresh());
  }

  /// A dropped op is the one case where the row has to go back: the server
  /// refused the write, so the state the wearer saw was never true.
  void _onSkipped(SyncOpSkipped event) {
    if (event.op.houseId != _houseId) return;
    _doneOverride.remove(event.op.effectiveEntityId);
    _dropped = m.sync.syncError;
    unawaited(refresh());
  }
}

enum _Collection { items, done, removed }
