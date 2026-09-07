import 'package:flutter/foundation.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/shopping_reminder.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/models/store.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/shopping_service.dart';
import 'package:pantry_core/services/store_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';

import '../scope/wear_scope.dart';

/// What a trip is started with, and the one call that starts it.
///
/// Cache-first like every other read on the watch: the page draws from whatever
/// the last session left behind and the fetch fills in behind it, so a wearer
/// standing in a doorway is not looking at a spinner. Starting itself is the
/// exception — it is online-only, because a queued create would leave the watch
/// showing a trip the server has never heard of.
class StartTripController extends ChangeNotifier {
  StartTripController({required this.houseId});

  /// A controller holding a fixed answer, for pumping the page without a
  /// server. Nothing here fetches: [load] is what does that.
  @visibleForTesting
  StartTripController.seeded({
    required this.houseId,
    List<ChecklistList> lists = const [],
    Map<int, List<ListItem>> itemsByList = const {},
    List<Store> stores = const [],
    List<ShoppingReminder> reminders = const [],
    String storeSort = 'name_asc',
    int? scopeListId,
  }) {
    _lists = lists;
    _itemsByList = {...itemsByList};
    _stores = {for (final s in stores) s.id: s};
    _reminders = _startRemindersOf(reminders);
    _storeSort = storeSort;
    _seedSelection(scopeListId);
  }

  final int houseId;

  final _shopping = ShoppingService.instance;
  final _checklists = ChecklistService.instance;

  var _starting = false;
  bool get isStarting => _starting;

  /// Why the last start failed, drawn where a blocked button's reason is drawn
  /// and cleared by the next attempt. It stands rather than flashing past: the
  /// wearer's choices are still on screen, and the button is what to try again.
  String? _error;
  String? get error => _error;

  List<ChecklistList> _lists = const [];
  List<ChecklistList> get lists => _lists;

  Map<int, List<ListItem>> _itemsByList = {};
  Map<int, Store> _stores = const {};

  List<ShoppingReminder> _reminders = const [];

  /// The enabled `on_start` reminders in the order the house put them, which is
  /// the only moment this page is the right place to read.
  List<ShoppingReminder> get reminders => _reminders;

  String _storeSort = 'name_asc';

  final _selectedListIds = <int>{};
  Set<int> get selectedListIds => _selectedListIds;

  final _enabledStoreIds = <int>{};
  Set<int> get enabledStoreIds => _enabledStoreIds;

  /// Stores the selected lists' un-done items reference, in the house's own
  /// order. Leg order is the house's `storeSort` and nothing on the watch
  /// reorders it — there is no room to drag, and the phone already can.
  var _availableStoreIds = <int>[];
  List<Store> get availableStores => [
    for (final id in _availableStoreIds) ?_stores[id],
  ];

  var _private = false;
  bool get isPrivate => _private;

  void setPrivate(bool value) {
    if (_private == value) return;
    _private = value;
    notifyListeners();
  }

  /// Whether a trip can be started at all, and why not when it cannot. The
  /// button says the reason rather than sitting there dead: a control a wearer
  /// can see but not use has to account for itself.
  String? get blockedReason {
    if (!SyncManager.instance.isOnline) return m.wear.needsConnection;
    if (_selectedListIds.isEmpty) return m.wear.pickAList;
    return null;
  }

  var _seeded = false;

  /// Cache first, then the server. Both pass through [_seedSelection], so a
  /// watch that has never seen this house still opens ready to start once the
  /// fetch lands.
  Future<void> load() async {
    _readCache();
    notifyListeners();
    await _fetch();
    notifyListeners();
  }

  void _readCache() {
    _lists = _activeOnly(_checklists.getCachedLists(houseId) ?? const []);
    _stores = {
      for (final s in StoreService.instance.getCached(houseId) ?? const [])
        s.id: s,
    };
    _reminders = _startRemindersOf(
      _shopping.getCachedReminders(houseId) ?? const [],
    );
    _storeSort =
        _checklists.cache.get<String>('storeSort:$houseId') ?? _storeSort;
    for (final list in _lists) {
      _itemsByList[list.id] = _checklists.getCachedItems(list.id) ?? const [];
    }
    _seedSelection(WearScope.instance.listId);
  }

  /// Every leg is its own try: a house with no reminders, or a store read that
  /// drops, must not cost the wearer the lists they came here to pick.
  Future<void> _fetch() async {
    try {
      _lists = _activeOnly(await _checklists.getLists(houseId));
    } catch (_) {}
    try {
      final stores = await StoreService.instance.getStores(houseId);
      _stores = {for (final s in stores) s.id: s};
    } catch (_) {}
    try {
      _reminders = _startRemindersOf(await _shopping.getReminders(houseId));
    } catch (_) {}
    try {
      final prefs = await _checklists.getHousePrefs(houseId);
      _storeSort = prefs['storeSort'] as String? ?? _storeSort;
    } catch (_) {}
    for (final list in _lists) {
      // The cached copy is the answer until a fetch beats it, so a list whose
      // items never arrive still contributes the stores it last knew about.
      try {
        _itemsByList[list.id] = await _checklists.getItems(houseId, list.id);
      } catch (_) {
        _itemsByList[list.id] ??=
            _checklists.getCachedItems(list.id) ?? const [];
      }
    }
    _seedSelection(WearScope.instance.listId);
    _recomputeStores();
  }

  /// The watch's own scope, so the page opens ready to start: the list being
  /// browsed, or every list when the scope is the all-lists view.
  ///
  /// Once. A later fetch that adds a list must not undo a choice the wearer has
  /// already made on top of it.
  void _seedSelection(int? scopeListId) {
    if (_seeded) {
      _recomputeStores();
      return;
    }
    if (_lists.isEmpty) return;
    _seeded = true;
    final scoped = scopeListId != null && scopeListId != kAllListsId
        ? _lists.where((l) => l.id == scopeListId).map((l) => l.id)
        : _lists.map((l) => l.id);
    _selectedListIds
      ..clear()
      ..addAll(scoped.isEmpty ? _lists.map((l) => l.id) : scoped);
    _recomputeStores();
  }

  void selectLists(Set<int> ids) {
    _selectedListIds
      ..clear()
      ..addAll(ids);
    _recomputeStores();
    notifyListeners();
  }

  void enableStores(Set<int> ids) {
    _enabledStoreIds
      ..clear()
      ..addAll(ids.where(_availableStoreIds.contains));
    notifyListeners();
  }

  /// Which stores the trip can offer, and which of them are on. A store that
  /// stops being referenced drops off; one that starts being referenced is
  /// enabled, because the wearer picked the list it came in on.
  void _recomputeStores() {
    final available = <int>{};
    for (final listId in _selectedListIds) {
      for (final item in _itemsByList[listId] ?? const <ListItem>[]) {
        if (item.done || item.deletedAt != null || item.archivedAt != null) {
          continue;
        }
        available.addAll(item.storeIds.where(_stores.containsKey));
      }
    }
    final order = StoreService.sortStores(_stores.values, _storeSort);
    final ordered = [
      for (final store in order)
        if (available.contains(store.id)) store.id,
    ];
    final added = {
      for (final id in ordered)
        if (!_availableStoreIds.contains(id)) id,
    };
    _availableStoreIds = ordered;
    _enabledStoreIds
      ..removeWhere((id) => !available.contains(id))
      ..addAll(added);
  }

  /// Create the trip, or take back the one the server says is already running.
  ///
  /// Privacy is a second call by construction — `createSession` takes no
  /// `isPrivate` — and the trip is not held hostage to it: a private trip that
  /// starts public is a trip, where a refused start is nothing at all. It is
  /// never applied to a resumed trip, which is somebody's trip already and not
  /// this page's to reclassify.
  Future<ShoppingSession?> start() async {
    if (_starting || blockedReason != null) return null;
    _starting = true;
    _error = null;
    notifyListeners();
    try {
      ShoppingSession session;
      var created = true;
      try {
        session = await _shopping.createSession(
          houseId,
          listIds: _selectedListIds.toList(),
          storeIds: [
            for (final id in _availableStoreIds)
              if (_enabledStoreIds.contains(id)) id,
          ],
        );
      } on ShoppingSessionConflict catch (conflict) {
        // A 409 carries the live trip, which is exactly what *resume* means —
        // the same button, with nothing left to create.
        session = conflict.session;
        created = false;
      }
      if (created && _private && !session.isPrivate) {
        try {
          session = await _shopping.setPrivacy(
            houseId,
            session.id,
            isPrivate: true,
          );
        } catch (_) {}
      }
      return session;
    } catch (_) {
      _error = m.shopping.startFailed;
      return null;
    } finally {
      _starting = false;
      notifyListeners();
    }
  }

  /// The all-lists entry is a scope, not a list the server will accept, and a
  /// trip is over real lists only.
  static List<ChecklistList> _activeOnly(List<ChecklistList> lists) => [
    for (final list in lists)
      if (list.id > 0) list,
  ];

  static List<ShoppingReminder> _startRemindersOf(List<ShoppingReminder> all) =>
      [
        for (final r in all)
          if (r.enabled && r.showOn == ShoppingReminderMoment.onStart) r,
      ]..sort((a, b) => a.position.compareTo(b.position));
}
