import 'package:flutter/foundation.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/prefs_service.dart';

/// What the watch is looking at: one `(house, list)` pair.
///
/// It is the phone's pair, not a second model — `lastHouseId` and
/// `selectedListId`, read and written where the phone reads and writes them —
/// so a pairing seed lands in the same two places a wearer's own choice does.
/// Both are device-local: nothing server-side records which house or list you
/// were looking at.
///
/// [kAllListsId] is a legal list, not a mode.
class WearScope extends ChangeNotifier {
  WearScope._();

  static final WearScope instance = WearScope._();

  int? get houseId => PrefsService.instance.lastHouseId;

  int? get listId => ChecklistService.instance.selectedListId;

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
    await selectHouse(fallback.id);
    return fallback.id;
  }

  /// The list to show within [lists], which are the current house's active
  /// lists. One rule for every trigger — no seed, a deleted or archived list,
  /// a changed house: the **lowest `sortOrder`** list. The watch lands on a
  /// real list, never on the meta view by default.
  ///
  /// Archived and trashed lists cannot appear here at all: `getLists` returns
  /// active lists only, and the watch never calls the other two endpoints.
  Future<int?> resolveList(List<ChecklistList> lists) async {
    final current = listId;
    if (current == kAllListsId) return current;
    if (current != null && lists.any((l) => l.id == current)) return current;
    if (lists.isEmpty) return null;
    final lowest = lists.reduce((a, b) => b.sortOrder < a.sortOrder ? b : a);
    await selectList(lowest.id);
    return lowest.id;
  }

  Future<void> selectHouse(int id) async {
    if (houseId == id) return;
    await PrefsService.instance.setLastHouseId(id);
    notifyListeners();
  }

  Future<void> selectList(int id) async {
    if (listId == id) return;
    ChecklistService.instance.selectedListId = id;
    _pruneItemCache();
    notifyListeners();
  }

  /// Scope is also what bounds the watch's item cache: leaving a list is what
  /// drops its snapshot, so nothing accumulates and nothing has to be evicted.
  /// That is a stronger guarantee than any byte ceiling, whose worst bug
  /// deletes the offline copy the watch exists to keep.
  ///
  /// The all-lists view is the exception that proves it: its rows *are* every
  /// list's own cached snapshot, so they are all in scope. A session needs no
  /// exception — its items live in the shopping cache, which this never
  /// touches.
  void _pruneItemCache() {
    final id = listId;
    if (id == null || id == kAllListsId) return;
    ChecklistService.instance.invalidateItems(keepListId: id);
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
