import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/member.dart';
import 'package:pantry/models/shopping_presence_entry.dart';
import 'package:pantry/models/shopping_reminder.dart';
import 'package:pantry/models/shopping_review.dart';
import 'package:pantry/models/shopping_session.dart';
import 'package:pantry/models/store.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/category_service.dart';
import 'package:pantry/services/house_service.dart';
import 'package:pantry/services/shopping_service.dart';
import 'package:pantry/services/store_service.dart';
import 'package:pantry/sync/sync_ids.dart';
import 'package:pantry/sync/sync_manager.dart';
import 'package:pantry/sync/sync_op.dart';

/// A contiguous run of items under one category, for the grouped dense view.
/// [category] is null for the Uncategorized run (always rendered last, matching
/// the server's ordering).
class ShoppingItemGroup {
  final models.Category? category;
  final List<ListItem> items;

  const ShoppingItemGroup({required this.category, required this.items});
}

/// Drives the live dense shopping screen: the store-narrowed to-buy list, the
/// done-today tally, and house presence. Polls items + heartbeat + done-today
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

  ShoppingDoneToday? _doneToday;
  ShoppingDoneToday? get doneToday => _doneToday;
  int get inCartCount => _doneToday?.count ?? 0;

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

  /// Watch the sync queue so a check that flushes (or gets dropped) reconciles
  /// this view promptly instead of waiting for the next ~1-min poll.
  void _bindSync() {
    _appliedSub ??= SyncManager.instance.onApplied.listen((e) {
      // A check landed on the server — refresh the done-today tally so the
      // in-cart count / drawer catch up. The item list is already optimistic.
      if (_isOwnCheckOp(e.op)) unawaited(_refreshDoneToday());
    });
    _skippedSub ??= SyncManager.instance.onSkipped.listen((e) {
      // A check was dropped (e.g. the session closed, or a 4xx) — un-hide the
      // item so it returns to the list on the next fetch.
      if (_isOwnCheckOp(e.op) && e.op.op == SyncOpKind.create) {
        final id = e.op.entityId;
        if (id != null) _checkedPending.remove(id);
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
  /// what's still to buy at the active store. Approximated from done-today
  /// (single-trip-per-day is the common case) to avoid a heavy review poll.
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

  /// Items checked locally whose removal the server hasn't caught up to yet.
  /// The check endpoint and the item query are eventually consistent, so an
  /// immediate re-fetch can still return a just-checked item as unchecked —
  /// which would make it flicker back onto the list. We hide these ids from any
  /// fetch result until a fetch stops returning them (server confirmed).
  final Set<int> _checkedPending = {};

  Future<void> _refreshLiveData({required bool includeHeartbeat}) async {
    final results = await Future.wait([
      _service.getItems(houseId, sessionId),
      _service.getDoneToday(houseId),
      if (includeHeartbeat)
        _service.heartbeat(houseId)
      else
        _service.getPresence(houseId),
    ]);
    final fetched = results[0] as List<ListItem>;
    // Hide any item with a pending check op (offline / still flushing) plus any
    // we optimistically checked that the server still returns (eventual
    // consistency). Drop an id from the hidden set only once it is neither
    // queue-pending nor still listed by the server — i.e. fully confirmed gone.
    final queuePending = SyncManager.instance.pendingShoppingCheckedIds(
      houseId,
      sessionId,
    );
    _checkedPending.removeWhere(
      (id) => !queuePending.contains(id) && !fetched.any((i) => i.id == id),
    );
    _checkedPending.addAll(queuePending);
    _items = fetched.where((i) => !_checkedPending.contains(i.id)).toList();
    _doneToday = results[1] as ShoppingDoneToday;
    _presence = results[2] as List<ShoppingPresenceEntry>;
    notifyListeners();
  }

  Future<void> _refreshDoneToday() async {
    try {
      _doneToday = await _service.getDoneToday(houseId);
      notifyListeners();
    } catch (e) {
      debugPrint('[ShoppingSessionController] done-today refresh failed: $e');
    }
  }

  /// Optimistically remove [item] and enqueue the check on the sync queue, so
  /// it survives offline / spotty in-store connectivity and flushes when
  /// possible. The id is held in [_checkedPending] (and reflected in the queue)
  /// so an eventually-consistent re-fetch can't flicker it back; the sync
  /// subscriptions reconcile once the op lands or is dropped.
  Future<void> checkItem(ListItem item) async {
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
