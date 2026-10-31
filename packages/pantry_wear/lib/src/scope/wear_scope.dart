import 'package:flutter/foundation.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';

/// What the watch is looking at: one `(house, list)` pair.
///
/// It is the phone's pair, not a second model — `lastHouseId` and
/// `selectedListId`, read and written where the phone reads and writes them —
/// so a pairing seed lands in the same two places a wearer's own choice does.
/// Both are device-local: nothing server-side records which house or list you
/// were looking at.
///
/// [kAllListsId] and [kAllInventoriesId] are legal lists, not modes.
///
/// The Inventories page has a pair of its own, [inventory]: the same house,
/// and its own list in `selectedInventoryId`, so each page reopens where it
/// was left and the Tile and deep links keep following the lists page.
class WearScope extends ChangeNotifier {
  WearScope._({this.forInventories = false});

  static final WearScope instance = WearScope._();

  /// The Inventories page's scope.
  static final WearScope inventory = WearScope._(forInventories: true);

  /// Whether this scope picks among inventories only.
  final bool forInventories;

  int? get houseId => PrefsService.instance.lastHouseId;

  int? get listId => forInventories
      ? ChecklistService.instance.selectedInventoryId
      : ChecklistService.instance.selectedListId;

  set _listId(int? id) {
    if (forInventories) {
      ChecklistService.instance.selectedInventoryId = id;
    } else {
      ChecklistService.instance.selectedListId = id;
    }
  }

  bool get isAllLists => listId == kAllListsId;

  /// Said once when a remembered household stopped existing and the watch
  /// moved on without asking. Read and cleared by whoever shows it.
  ///
  /// The phone can fall back silently because its switcher is one tap from the
  /// title; here the household control is two pages away, so "your items are
  /// gone and these are someone else's" earns a line of explanation. A first
  /// run has nothing to explain and sets nothing.
  String? _fellBackTo;

  String? takeFallbackNotice() {
    final notice = _fellBackTo;
    _fellBackTo = null;
    return notice;
  }

  /// The house to show, given everything the watch knows about. Falls back to
  /// the first house the server returns when the remembered one has stopped
  /// existing — the same signal the phone reads — so a house leaving under the
  /// wearer never blocks.
  Future<int?> resolveHouse(List<House> houses) async {
    if (houses.isEmpty) return null;
    final current = houseId;
    if (current != null && houses.any((h) => h.id == current)) return current;
    final fallback = houses.first;
    if (current != null) _fellBackTo = m.wear.nowShowing(fallback.name);
    await selectHouse(fallback.id, notify: false);
    return fallback.id;
  }

  /// The list to show within [lists], which are the current house's active
  /// lists. One rule for every trigger — no seed, a deleted or archived list,
  /// a changed house: the **lowest `sortOrder`** list. The lists page lands on
  /// a real list, never on the meta view by default; the Inventories page
  /// lands on "All inventories" whenever there are several to gather.
  ///
  /// Archived and trashed lists cannot appear here at all: `getLists` returns
  /// active lists only, and the watch never calls the other two endpoints.
  Future<int?> resolveList(List<ChecklistList> lists) async {
    final current = listId;
    final allInventories = ServerFeature.inventoryAllView;
    if (current == kAllListsId && !forInventories) return current;
    if (current == kAllInventoriesId && allInventories) return current;
    if (current != null && lists.any((l) => l.id == current)) return current;
    if (lists.isEmpty) return null;
    if (forInventories && allInventories && lists.length >= 2) {
      await selectList(kAllInventoriesId, notify: false);
      return kAllInventoriesId;
    }
    final lowest = lists.reduce((a, b) => b.sortOrder < a.sortOrder ? b : a);
    await selectList(lowest.id, notify: false);
    return lowest.id;
  }

  /// [notify] is what tells the pages scope moved under them, and the two
  /// `resolve` methods above pass it false.
  ///
  /// They are called from inside a read that is *already* going to draw the
  /// scope they land on, so announcing it there does not tell anybody anything
  /// — it re-enters the read instead, and a first sign-in resolves both the
  /// house and the list, which is two more reads racing the one that started
  /// them. Announcing belongs to the wearer's own choice, which nothing is
  /// otherwise expecting.
  Future<void> selectHouse(int id, {bool notify = true}) async {
    if (houseId == id) return;
    await PrefsService.instance.setLastHouseId(id);
    // The house is the two pages' shared half: both move with it.
    if (notify) {
      instance.notifyListeners();
      inventory.notifyListeners();
    }
  }

  Future<void> selectList(int id, {bool notify = true}) async {
    if (listId == id) return;
    _listId = id;
    _pruneItemCache();
    if (notify) notifyListeners();
  }

  /// Scope is also what bounds the watch's item cache: leaving a list is what
  /// drops its snapshot, so nothing accumulates and nothing has to be evicted.
  /// That is a stronger guarantee than any byte ceiling, whose worst bug
  /// deletes the offline copy the watch exists to keep.
  ///
  /// The "All" views are the exception that proves it: their rows *are* every
  /// list's own cached snapshot, so they are all in scope. A session needs no
  /// exception — its items live in the shopping cache, which this never
  /// touches. Both pages' lists are in scope, the Inventories page's too.
  static void _pruneItemCache() {
    final kept = <int>[];
    for (final scope in [instance, inventory]) {
      final id = scope.listId;
      if (id == null) continue;
      if (isAllListsId(id)) return;
      kept.add(id);
    }
    if (kept.isEmpty) return;
    ChecklistService.instance.invalidateItems(keepListIds: kept);
  }

  /// Arrival from a deep link or the Tile. Both levels persist, exactly as
  /// they do on the phone, so `pantry://list/<houseId>/<listId>` means the
  /// same thing on both devices.
  Future<void> open(int house, int list) async {
    await selectHouse(house);
    await selectList(list);
  }

  /// A live session takes the watch over wherever it is being shopped, so the
  /// house follows it. The list does not: a session spans several, and leaving
  /// the remembered one alone is what makes closing a session need no rule of
  /// its own.
  Future<void> adoptSessionHouse(int house) => selectHouse(house);
}
