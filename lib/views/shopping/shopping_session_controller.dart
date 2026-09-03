import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart' as models;
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/member.dart';
import 'package:pantry_core/models/shopping_estimate.dart';
import 'package:pantry_core/models/shopping_presence_entry.dart';
import 'package:pantry_core/models/shopping_reminder.dart';
import 'package:pantry_core/models/shopping_review.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/models/store.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/category_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/services/shopping_service.dart';
import 'package:pantry_core/services/store_service.dart';
import 'package:pantry_core/sync/sync_ids.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';

/// A contiguous run of items under one category, for the grouped dense view.
/// [category] is null for the Uncategorized run (always rendered last, matching
/// the server's ordering).
class ShoppingItemGroup {
  final models.Category? category;
  final List<ListItem> items;

  const ShoppingItemGroup({required this.category, required this.items});
}

/// Drives the live dense shopping screen: the store-narrowed to-buy list, this
/// session's checked log, and house presence. Polls items + review + heartbeat
/// together; checking an item is optimistic and reconciled on the next poll.
class ShoppingSessionController extends ChangeNotifier {
  ShoppingSessionController({required ShoppingSession session})
    : _session = session,
      houseId = session.houseId;

  final int houseId;
  ShoppingService get _service => ShoppingService.instance;

  ShoppingSession _session;
  ShoppingSession get session => _session;
  int get sessionId => _session.id;

  List<ListItem> _items = [];
  List<ListItem> get items => _items;

  /// This session's checked log (server-computed). Drives the Done drawer and
  /// in-cart count; session-scoped via [ShoppingService.getReview] so items
  /// checked on earlier trips today aren't folded in.
  ShoppingReview? _review;

  /// Flat list of everything checked off on this trip, for the Done drawer.
  /// Items unchecked locally but still reported as checked by the server (see
  /// [_uncheckedPending]) are filtered out so the drawer reacts instantly.
  List<ListItem> get doneItems => [
    for (final s in _review?.stores ?? const <ShoppingReviewStore>[])
      for (final i in s.items)
        if (!_uncheckedPending.contains(i.id)) i,
  ];

  /// Per-currency estimate of this trip's checked items — the Done drawer total.
  ShoppingEstimate get doneEstimate => _review?.grandTotal ?? const [];

  int get inCartCount => doneItems.length;

  List<ShoppingPresenceEntry> _presence = [];
  List<ShoppingPresenceEntry> get presence => _presence;

  Map<int, models.Category> _categories = {};
  Map<int, Store> _stores = {};
  Map<int, Store> get stores => _stores;

  Map<String, Member> _members = {};
  Map<String, Member> get members => _members;

  List<ShoppingReminder> _reminders = [];

  /// Enabled reminders for a moment, in position order — surfaced on advance /
  /// close. Empty until reminders load.
  List<ShoppingReminder> remindersFor(ShoppingReminderMoment moment) =>
      (_reminders.where((r) => r.enabled && r.showOn == moment).toList()
        ..sort((a, b) => a.position.compareTo(b.position)));

  final String? currentUserId = AuthService.instance.credentials?.loginName;

  bool _loading = true;
  bool get isLoading => _loading;
  String? _error;
  String? get error => _error;

  bool _disposed = false;
  StreamSubscription<SyncOpApplied>? _appliedSub;
  StreamSubscription<SyncOpSkipped>? _skippedSub;

  @override
  void dispose() {
    _disposed = true;
    _appliedSub?.cancel();
    _skippedSub?.cancel();
    super.dispose();
  }

  bool _isOwnCheckOp(SyncOp op) =>
      op.entity == SyncEntity.shoppingCheck &&
      op.houseId == houseId &&
      op.parentId == sessionId;

  bool _isOwnSkipOp(SyncOp op) =>
      op.entity == SyncEntity.shoppingSkip &&
      op.houseId == houseId &&
      op.parentId == sessionId;

  /// Watch the sync queue so a check/skip that flushes (or gets dropped)
  /// reconciles this view promptly instead of waiting for the next ~1-min poll.
  void _bindSync() {
    _appliedSub ??= SyncManager.instance.onApplied.listen((e) {
      // A check landed on the server — refresh the session review so the Done
      // drawer / in-cart count catch up. The item list is already optimistic.
      // An uncheck (delete) landing instead pulls the full list so the item
      // slots back onto the to-buy list in server-sorted order.
      if (_isOwnCheckOp(e.op)) {
        if (e.op.op == SyncOpKind.delete) {
          unawaited(
            _refreshLiveData(includeHeartbeat: false).catchError((_) {}),
          );
        } else {
          unawaited(_refreshReview());
        }
        return;
      }
      // An unskip (delete) landed — pull the fresh list to slot the item back
      // into server-sorted order. A skip (create) landing needs no refresh: it
      // is already hidden optimistically and now excluded server-side, and
      // refreshing mid-flush could re-hide it when a skip+unskip pair flushes.
      if (_isOwnSkipOp(e.op) && e.op.op == SyncOpKind.delete) {
        unawaited(_refreshLiveData(includeHeartbeat: false).catchError((_) {}));
      }
    });
    _skippedSub ??= SyncManager.instance.onSkipped.listen((e) {
      // A check/uncheck was dropped (e.g. the session closed, or a 4xx) — clear
      // the matching optimistic guard so the next fetch is authoritative.
      if (_isOwnCheckOp(e.op)) {
        final id = e.op.entityId;
        if (id != null) {
          if (e.op.op == SyncOpKind.create) {
            _checkedPending.remove(id);
          } else if (e.op.op == SyncOpKind.delete) {
            _uncheckedPending.remove(id);
            _uncheckedReinsert.remove(id);
          }
        }
        unawaited(_refreshLiveData(includeHeartbeat: false).catchError((_) {}));
      }
      // A skip/unskip was dropped — un-hide any skip and reconcile from the
      // server so the item lands wherever the server says it belongs.
      if (_isOwnSkipOp(e.op)) {
        if (e.op.op == SyncOpKind.create) {
          final id = e.op.entityId;
          if (id != null) _skippedPending.remove(id);
        }
        unawaited(_refreshLiveData(includeHeartbeat: false).catchError((_) {}));
      }
    });
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  /// Progress across the trip: checked (in cart) vs the sum of checked plus
  /// what's still to buy at the active store. Both come from this session only
  /// (the review), so a second trip on the same day starts back at zero.
  double get progress {
    final total = inCartCount + _items.length;
    if (total == 0) return 0;
    return inCartCount / total;
  }

  /// The store legs in position order — backs the sticky store bar.
  List<ShoppingSessionStore> get orderedStores {
    final list = [..._session.stores]
      ..sort((a, b) => a.position.compareTo(b.position));
    return list;
  }

  /// Position of the active store, or -1 when none is chosen. Store pills at a
  /// lower position render as "past".
  int get activePosition {
    final active = _session.activeStoreId;
    if (active == null) return -1;
    return _session.stores
            .cast<ShoppingSessionStore?>()
            .firstWhere((s) => s!.storeId == active, orElse: () => null)
            ?.position ??
        -1;
  }

  /// Other shoppers attributed to [storeId] (self excluded) — the avatar stack
  /// on each store pill.
  List<ShoppingPresenceEntry> presenceAt(int storeId) => [
    for (final p in _presence)
      if (p.activeStoreId == storeId && p.userId != currentUserId) p,
  ];

  /// Items grouped into contiguous category runs, preserving the server order
  /// (category.sortOrder, item.sortOrder; Uncategorized last).
  List<ShoppingItemGroup> get groupedItems {
    final groups = <ShoppingItemGroup>[];
    int? runCategoryId;
    var run = <ListItem>[];
    void flush() {
      if (run.isEmpty) return;
      groups.add(
        ShoppingItemGroup(category: _categories[runCategoryId], items: run),
      );
      run = [];
    }

    for (final item in _items) {
      if (groups.isEmpty && run.isEmpty) {
        runCategoryId = item.categoryId;
      } else if (item.categoryId != runCategoryId) {
        flush();
        runCategoryId = item.categoryId;
      }
      run.add(item);
    }
    flush();
    return groups;
  }

  Future<void> load() async {
    _bindSync();
    _loading = _items.isEmpty;
    notifyListeners();

    // Reference data (cache-first, best-effort) — never fatal.
    _categories = {
      for (final c in CategoryService.instance.getCached(houseId) ?? const [])
        c.id: c,
    };
    _stores = {
      for (final s in StoreService.instance.getCached(houseId) ?? const [])
        s.id: s,
    };
    _members = {
      for (final mm
          in HouseService.instance.getCachedMembers(houseId) ?? const [])
        mm.userId: mm,
    };
    _reminders = _service.getCachedReminders(houseId) ?? _reminders;

    unawaited(_loadReferenceData());

    try {
      // A session with stores but no active store yet: land on the first so
      // the item list is narrowed to somewhere sensible.
      if (_session.stores.isNotEmpty && _session.activeStoreId == null) {
        try {
          _session = await _service.advance(
            houseId,
            sessionId,
            storeId: orderedStores.first.storeId,
          );
        } catch (e) {
          debugPrint('[ShoppingSessionController] auto-advance failed: $e');
        }
      }
      await _refreshLiveData(includeHeartbeat: true);
      _error = null;
    } catch (_) {
      if (_items.isEmpty) _error = m.shopping.loadItemsFailed;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadReferenceData() async {
    try {
      final results = await Future.wait([
        CategoryService.instance.getCategories(houseId),
        StoreService.instance.getStores(houseId),
        HouseService.instance.getMembers(houseId),
        _service.getReminders(houseId).catchError((_) => <ShoppingReminder>[]),
      ]);
      _categories = {
        for (final c in results[0] as List<models.Category>) c.id: c,
      };
      _stores = {for (final s in results[1] as List<Store>) s.id: s};
      _members = {for (final mm in results[2] as List<Member>) mm.userId: mm};
      _reminders = results[3] as List<ShoppingReminder>;
      notifyListeners();
    } catch (e) {
      debugPrint('[ShoppingSessionController] reference load failed: $e');
    }
  }

  /// Poll: refresh the item list, stamp a heartbeat (returns presence), and
  /// refresh the done-today tally. Called ~1 min while focused.
  Future<void> poll() async {
    try {
      await _refreshLiveData(includeHeartbeat: true);
    } catch (e) {
      debugPrint('[ShoppingSessionController] poll failed: $e');
    }
  }

  /// Items checked locally but not yet reflected by the server. The check
  /// endpoint and item query are eventually consistent, so a just-checked item
  /// can re-appear as unchecked; hide these ids until a fetch stops returning
  /// them.
  final Set<int> _checkedPending = {};

  /// The skip mirror of [_checkedPending]: items removed from this trip
  /// locally, hidden until the skip is confirmed so an offline / still-flushing
  /// removal can't flicker back.
  final Set<int> _skippedPending = {};

  /// The uncheck mirror of [_checkedPending]: items unchecked locally but still
  /// reported as checked by the (eventually consistent) server. Kept out of the
  /// Done drawer until a fetch reflects the uncheck.
  final Set<int> _uncheckedPending = {};

  /// The active-store subset of [_uncheckedPending], keyed by id with the item
  /// to render, so an uncheck lands the item back on the to-buy list instantly.
  /// Cross-store unchecks aren't re-shown here — they belong to another store's
  /// narrowed list and reappear there once synced.
  final Map<int, ListItem> _uncheckedReinsert = {};

  /// Last removed item per id, kept so Undo can restore it in place instantly
  /// without a server re-fetch (which offline can't reach anyway).
  final Map<int, ({ListItem item, int index})> _skipUndo = {};

  /// Items removed from this trip, keyed by id — backs the persistent "Removed"
  /// section. Seeded from the server on load/poll so removals survive restarts,
  /// and mutated optimistically on skip/unskip for instant feedback.
  Map<int, ListItem> _removed = {};

  /// The removed items in name order, for the restore-only "Removed" section.
  List<ListItem> get removedItems =>
      _removed.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Future<void> _refreshLiveData({required bool includeHeartbeat}) async {
    final results = await Future.wait([
      _service.getItems(houseId, sessionId),
      _service.getReview(houseId, sessionId),
      if (includeHeartbeat)
        _service.heartbeat(houseId)
      else
        _service.getPresence(houseId),
      // Guarded: a hiccup fetching the Removed section must not fail the whole
      // poll (items/review/presence). Null keeps the current removed set.
      _service
          .getRemovedItems(houseId, sessionId)
          .then<List<ListItem>?>((v) => v)
          .catchError((_) => null),
    ]);
    final fetched = results[0] as List<ListItem>;
    // Hide items with a pending check op or that the server still returns after
    // an optimistic check. Drop an id only once it is neither queue-pending nor
    // still listed — i.e. fully confirmed gone.
    final queuePending = SyncManager.instance.pendingShoppingCheckedIds(
      houseId,
      sessionId,
    );
    _checkedPending.removeWhere(
      (id) => !queuePending.contains(id) && !fetched.any((i) => i.id == id),
    );
    _checkedPending.addAll(queuePending);
    // Same guard for trip removals (skips). The server already excludes skipped
    // items, so a synced skip simply stops appearing; the hidden set only
    // covers the window before the skip op flushes.
    final queueSkipPending = SyncManager.instance.pendingShoppingSkippedIds(
      houseId,
      sessionId,
    );
    _skippedPending.removeWhere(
      (id) => !queueSkipPending.contains(id) && !fetched.any((i) => i.id == id),
    );
    _skippedPending.addAll(queueSkipPending);
    // Mirror guard for local unchecks. Drop an id only once it is neither
    // uncheck-op-pending nor still listed as checked in the fetched review —
    // i.e. the uncheck is fully confirmed server-side.
    _review = results[1] as ShoppingReview;
    final reviewIds = <int>{
      for (final s in _review!.stores)
        for (final i in s.items) i.id,
    };
    final queueUncheckPending = SyncManager.instance
        .pendingShoppingUncheckedIds(houseId, sessionId);
    _uncheckedPending.removeWhere(
      (id) => !queueUncheckPending.contains(id) && !reviewIds.contains(id),
    );
    _uncheckedPending.addAll(queueUncheckPending);
    // A re-shown item drops out of the reinsert map once the server returns it
    // on the to-buy list itself, or the uncheck is no longer pending.
    _uncheckedReinsert.removeWhere(
      (id, _) =>
          !_uncheckedPending.contains(id) || fetched.any((i) => i.id == id),
    );
    _items = fetched
        .where(
          (i) =>
              !_checkedPending.contains(i.id) &&
              !_skippedPending.contains(i.id),
        )
        .toList();
    for (final item in _uncheckedReinsert.values) {
      if (!_items.any((i) => i.id == item.id)) _items = [..._items, item];
    }
    _presence = results[2] as List<ShoppingPresenceEntry>;
    // Reconcile the Removed section against the server, respecting in-flight
    // skips/unskips so an optimistic change isn't undone by a stale fetch.
    final fetchedRemoved = results[3] as List<ListItem>?;
    if (fetchedRemoved != null) {
      final unskipPending = SyncManager.instance.pendingShoppingUnskippedIds(
        houseId,
        sessionId,
      );
      final next = <int, ListItem>{};
      for (final i in fetchedRemoved) {
        if (unskipPending.contains(i.id)) continue;
        next[i.id] = i;
      }
      // Keep optimistically-skipped items the fetch doesn't reflect yet.
      for (final id in queueSkipPending) {
        if (next.containsKey(id)) continue;
        final item = _removed[id] ?? _skipUndo[id]?.item;
        if (item != null) next[id] = item;
      }
      _removed = next;
    }
    notifyListeners();
  }

  /// Refresh just this session's checked log (the Done drawer / in-cart count)
  /// — used after a check lands so the tally catches up without a full poll.
  Future<void> _refreshReview() async {
    try {
      _review = await _service.getReview(houseId, sessionId);
      notifyListeners();
    } catch (e) {
      debugPrint('[ShoppingSessionController] review refresh failed: $e');
    }
  }

  /// Optimistically remove [item] and enqueue the check so it survives offline /
  /// spotty connectivity. Held in [_checkedPending] so a re-fetch can't flicker
  /// it back; sync subscriptions reconcile once the op lands or is dropped.
  Future<void> checkItem(ListItem item) async {
    _uncheckedPending.remove(item.id);
    _uncheckedReinsert.remove(item.id);
    _checkedPending.add(item.id);
    _items = _items.where((i) => i.id != item.id).toList();
    notifyListeners();
    SyncManager.instance.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.shoppingCheck,
        op: SyncOpKind.create,
        houseId: houseId,
        entityId: item.id,
        parentId: sessionId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Reverse a check from the Done drawer: the item leaves the drawer and, when
  /// it belongs to the active store, returns to the to-buy list. Optimistic and
  /// queued like [checkItem]; reconciled by the sync subscriptions and polls.
  Future<void> uncheckItem(ListItem item) async {
    final storeId = _reviewStoreOf(item.id);
    _checkedPending.remove(item.id);
    _uncheckedPending.add(item.id);
    if (storeId == null || storeId == _session.activeStoreId) {
      _uncheckedReinsert[item.id] = item;
      if (!_items.any((i) => i.id == item.id)) _items = [..._items, item];
    }
    notifyListeners();
    SyncManager.instance.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.shoppingCheck,
        op: SyncOpKind.delete,
        houseId: houseId,
        entityId: item.id,
        parentId: sessionId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// The store an item was checked at per the current review, or null when it's
  /// in the storeless bucket or not found.
  int? _reviewStoreOf(int itemId) {
    for (final s in _review?.stores ?? const <ShoppingReviewStore>[]) {
      if (s.items.any((i) => i.id == itemId)) return s.storeId;
    }
    return null;
  }

  /// Remove [item] from this trip only — off the to-buy list but still on the
  /// checklist (not checked, not deleted). Optimistic and queued like
  /// [checkItem]; reversible via [unskipItem], with [_skipUndo] enabling
  /// instant in-place restore.
  Future<void> skipItem(ListItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    _skipUndo[item.id] = (item: item, index: index < 0 ? 0 : index);
    _skippedPending.add(item.id);
    _items = _items.where((i) => i.id != item.id).toList();
    _removed = {..._removed, item.id: item};
    notifyListeners();
    SyncManager.instance.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.shoppingSkip,
        op: SyncOpKind.create,
        houseId: houseId,
        entityId: item.id,
        parentId: sessionId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Undo a trip removal: bring [itemId] back and queue the unskip. Restores it
  /// at its pre-removal position optimistically; the unskip landing later
  /// reconciles it to the server's sorted order.
  Future<void> unskipItem(int itemId) async {
    final undo = _skipUndo.remove(itemId);
    _skippedPending.remove(itemId);
    if (undo != null && !_items.any((i) => i.id == itemId)) {
      final list = [..._items];
      list.insert(undo.index.clamp(0, list.length), undo.item);
      _items = list;
    }
    _removed = {..._removed}..remove(itemId);
    notifyListeners();
    SyncManager.instance.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.shoppingSkip,
        op: SyncOpKind.delete,
        houseId: houseId,
        entityId: itemId,
        parentId: sessionId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Move to [storeId] and adopt the returned session (new active store, so the
  /// next item fetch is narrowed differently).
  Future<void> advance(int storeId) async {
    _session = await _service.advance(houseId, sessionId, storeId: storeId);
    notifyListeners();
    await _refreshLiveData(includeHeartbeat: false);
  }

  Future<void> setPrivacy(bool isPrivate) async {
    final previous = _session;
    _session = ShoppingSessionPrivacy.withPrivacy(_session, isPrivate);
    notifyListeners();
    try {
      _session = await _service.setPrivacy(
        houseId,
        sessionId,
        isPrivate: isPrivate,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[ShoppingSessionController] privacy toggle failed: $e');
      _session = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<ShoppingSession> close() async {
    _session = await _service.close(houseId, sessionId);
    notifyListeners();
    return _session;
  }

  /// Refresh the session DTO from the server (e.g. after billed edits on the
  /// review screen) so the store bar reflects any changes.
  Future<void> refreshSession() async {
    final current = await _service.getCurrentSession();
    if (current != null && current.id == sessionId) {
      _session = current;
      notifyListeners();
    }
  }
}

/// Copy a session with a new privacy flag without a full [ShoppingSession]
/// copyWith (the DTO is otherwise immutable-by-construction here).
extension ShoppingSessionPrivacy on ShoppingSession {
  static ShoppingSession withPrivacy(ShoppingSession s, bool isPrivate) =>
      ShoppingSession(
        id: s.id,
        houseId: s.houseId,
        userId: s.userId,
        listIds: s.listIds,
        stores: s.stores,
        activeStoreId: s.activeStoreId,
        includeUnassigned: s.includeUnassigned,
        isPrivate: isPrivate,
        billedTotal: s.billedTotal,
        billedCurrency: s.billedCurrency,
        lastSeenAt: s.lastSeenAt,
        live: s.live,
        closedAt: s.closedAt,
        createdAt: s.createdAt,
        updatedAt: s.updatedAt,
      );
}
