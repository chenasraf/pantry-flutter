import 'dart:convert';

import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/shopping_history_row.dart';
import 'package:pantry/models/shopping_presence_entry.dart';
import 'package:pantry/models/shopping_reminder.dart';
import 'package:pantry/models/shopping_review.dart';
import 'package:pantry/models/shopping_session.dart';
import 'package:pantry/services/api_client.dart';
import 'package:pantry/services/cache_store.dart';

/// Scope of a history query: the caller's own trips, or every visible trip in
/// the house (housemates' private trips excluded server-side).
enum ShoppingHistoryScope {
  mine('mine'),
  house('house');

  const ShoppingHistoryScope(this.wire);
  final String wire;
}

/// Singleton wrapping the 21 Shopping Mode endpoints via [ApiClient.instance].
/// Mirrors [StoreService]. Live session/item/presence data is polled, so it is
/// not cached; reminders are cached for offline surfacing.
class ShoppingService {
  ShoppingService._();
  static final ShoppingService instance = ShoppingService._();

  final cache = CacheStore('shopping_cache.json');

  ApiClient get _api => ApiClient.instance;

  String _base(int houseId) => '/houses/$houseId/shopping';

  // -- Sessions --------------------------------------------------------------

  /// (1) Global discovery of the caller's single live session, or null when
  /// idle. Not house-scoped; the returned session carries its own `houseId`.
  /// Safe to call on launch and before the start screen — no side effects.
  Future<ShoppingSession?> getCurrentSession() {
    return _api.get<dynamic, ShoppingSession?>(
      '/shopping/sessions/current',
      fromJson: _sessionOrNull,
    );
  }

  /// (2) Create a session over the given scope. Sessions start public; toggle
  /// privacy later via [setPrivacy]. Throws [ShoppingSessionConflict] (from a
  /// 409) carrying the existing live session when one is already in progress.
  Future<ShoppingSession> createSession(
    int houseId, {
    required List<int> listIds,
    required List<int> storeIds,
    bool includeUnassigned = true,
  }) async {
    try {
      return await _api.post<Map<String, dynamic>, ShoppingSession>(
        '${_base(houseId)}/sessions',
        body: {
          'listIds': listIds,
          'storeIds': storeIds,
          'includeUnassigned': includeUnassigned,
        },
        fromJson: ShoppingSession.fromJson,
      );
    } on ApiException catch (e) {
      final existing = _sessionFromErrorBody(e);
      if (e.statusCode == 409 && existing != null) {
        throw ShoppingSessionConflict(existing);
      }
      rethrow;
    }
  }

  /// (3) Move to [storeId] (must be one of the session's stores). Sets
  /// `activeStoreId` and returns the updated session.
  Future<ShoppingSession> advance(
    int houseId,
    int sessionId, {
    required int storeId,
  }) {
    return _api.post<Map<String, dynamic>, ShoppingSession>(
      '${_base(houseId)}/sessions/$sessionId/advance',
      body: {'storeId': storeId},
      fromJson: ShoppingSession.fromJson,
    );
  }

  /// (4) Close the session (irreversible). Throws [ShoppingSessionConflict]
  /// (from a 409) carrying the already-closed session when called twice.
  Future<ShoppingSession> close(int houseId, int sessionId) async {
    try {
      return await _api.post<Map<String, dynamic>, ShoppingSession>(
        '${_base(houseId)}/sessions/$sessionId/close',
        fromJson: ShoppingSession.fromJson,
      );
    } on ApiException catch (e) {
      final existing = _sessionFromErrorBody(e);
      if (e.statusCode == 409 && existing != null) {
        throw ShoppingSessionConflict(existing);
      }
      rethrow;
    }
  }

  /// (5) Toggle whether the session is hidden from housemates' presence and
  /// house-scoped history.
  Future<ShoppingSession> setPrivacy(
    int houseId,
    int sessionId, {
    required bool isPrivate,
  }) {
    return _api.patch<Map<String, dynamic>, ShoppingSession>(
      '${_base(houseId)}/sessions/$sessionId/privacy',
      body: {'isPrivate': isPrivate},
      fromJson: ShoppingSession.fromJson,
    );
  }

  /// (6) Set the session-level billed total (storeless grand-total fallback).
  Future<ShoppingSession> setSessionBilled(
    int houseId,
    int sessionId, {
    double? billedTotal,
    String? billedCurrency,
  }) {
    return _api.patch<Map<String, dynamic>, ShoppingSession>(
      '${_base(houseId)}/sessions/$sessionId',
      body: {'billedTotal': billedTotal, 'billedCurrency': billedCurrency},
      fromJson: ShoppingSession.fromJson,
    );
  }

  /// (7) Set a per-store billed total (the actual paid at that store's till).
  Future<ShoppingSession> setStoreBilled(
    int houseId,
    int sessionId,
    int storeId, {
    double? billedTotal,
    String? billedCurrency,
  }) {
    return _api.patch<Map<String, dynamic>, ShoppingSession>(
      '${_base(houseId)}/sessions/$sessionId/stores/$storeId',
      body: {'billedTotal': billedTotal, 'billedCurrency': billedCurrency},
      fromJson: ShoppingSession.fromJson,
    );
  }

  // -- Items -----------------------------------------------------------------

  /// (8) The flat, ordered, store-narrowed list of what to buy now (unchecked
  /// & in-scope). Client groups by category. Re-query each poll.
  Future<List<ListItem>> getItems(int houseId, int sessionId) {
    return _api.get<List, List<ListItem>>(
      '${_base(houseId)}/sessions/$sessionId/items',
      fromJson: (data) => data
          .map((e) => ListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// (9) Mark an item bought — an explicit action, not a field edit. Returns
  /// only success; re-fetch [getItems] to reconcile.
  Future<void> checkItem(int houseId, int sessionId, int itemId) async {
    await _api.post<Map<String, dynamic>, void>(
      '${_base(houseId)}/sessions/$sessionId/items/$itemId/check',
      fromJson: (_) {},
    );
  }

  /// (10) Reverse a check. Returns only success; re-fetch [getItems].
  Future<void> uncheckItem(int houseId, int sessionId, int itemId) async {
    await _api.post<Map<String, dynamic>, void>(
      '${_base(houseId)}/sessions/$sessionId/items/$itemId/uncheck',
      fromJson: (_) {},
    );
  }

  // -- Review / done-today ---------------------------------------------------

  /// (11) The bought log grouped by store (server-computed, authoritative).
  Future<ShoppingReview> getReview(int houseId, int sessionId) {
    return _api.get<Map<String, dynamic>, ShoppingReview>(
      '${_base(houseId)}/sessions/$sessionId/review',
      fromJson: ShoppingReview.fromJson,
    );
  }

  /// (12) My check-log for today (my timezone), house-scoped. Polled in the
  /// dense view's Done-today drawer.
  Future<ShoppingDoneToday> getDoneToday(int houseId) {
    return _api.get<Map<String, dynamic>, ShoppingDoneToday>(
      '${_base(houseId)}/sessions/done-today',
      fromJson: ShoppingDoneToday.fromJson,
    );
  }

  // -- Presence --------------------------------------------------------------

  /// (13) Stamp liveness and get the current house presence in one round-trip.
  /// Called ~1 min by an active shopper; pause on blur, fire on refocus.
  Future<List<ShoppingPresenceEntry>> heartbeat(int houseId) {
    return _api.post<List, List<ShoppingPresenceEntry>>(
      '${_base(houseId)}/presence/heartbeat',
      fromJson: _parsePresence,
    );
  }

  /// (14) Read-only house presence; needs no live session (someone at home can
  /// watch who's out).
  Future<List<ShoppingPresenceEntry>> getPresence(int houseId) {
    return _api.get<List, List<ShoppingPresenceEntry>>(
      '${_base(houseId)}/presence',
      fromJson: _parsePresence,
    );
  }

  // -- Reminders -------------------------------------------------------------

  List<ShoppingReminder>? getCachedReminders(int houseId) =>
      cache.getKeyedList('reminders', '$houseId', ShoppingReminder.fromJson);

  /// (15) List the house's reminders (all moments, all enabled states).
  Future<List<ShoppingReminder>> getReminders(int houseId) async {
    final reminders = await _api.get<List, List<ShoppingReminder>>(
      '${_base(houseId)}/reminders',
      fromJson: (data) => data
          .map((e) => ShoppingReminder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    cache.setKeyedList('reminders', '$houseId', reminders, (r) => r.toJson());
    return reminders;
  }

  /// (16) Create a reminder at a moment.
  Future<ShoppingReminder> createReminder(
    int houseId, {
    required String text,
    required ShoppingReminderMoment showOn,
    bool? enabled,
  }) {
    return _api.post<Map<String, dynamic>, ShoppingReminder>(
      '${_base(houseId)}/reminders',
      body: {'text': text, 'showOn': showOn.wire, 'enabled': ?enabled},
      fromJson: ShoppingReminder.fromJson,
    );
  }

  /// (17) Edit a reminder's text, moment, enabled state, or position.
  Future<ShoppingReminder> updateReminder(
    int houseId,
    int reminderId, {
    String? text,
    ShoppingReminderMoment? showOn,
    bool? enabled,
    int? position,
  }) {
    return _api.patch<Map<String, dynamic>, ShoppingReminder>(
      '${_base(houseId)}/reminders/$reminderId',
      body: {
        'text': ?text,
        'showOn': ?showOn?.wire,
        'enabled': ?enabled,
        'position': ?position,
      },
      fromJson: ShoppingReminder.fromJson,
    );
  }

  /// (18) Delete a reminder.
  Future<void> deleteReminder(int houseId, int reminderId) {
    return _api.delete('${_base(houseId)}/reminders/$reminderId');
  }

  /// (19) Reorder reminders in one call — [reminderIds] in the desired order
  /// become their new positions.
  Future<List<ShoppingReminder>> reorderReminders(
    int houseId,
    List<int> reminderIds,
  ) {
    return _api.patch<List, List<ShoppingReminder>>(
      '${_base(houseId)}/reminders/reorder',
      body: {'reminderIds': reminderIds},
      fromJson: (data) => data
          .map((e) => ShoppingReminder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // -- History ---------------------------------------------------------------

  /// (20) Read-only list of closed trips (Phase 3). Scope selects mine vs
  /// house-wide.
  Future<List<ShoppingHistoryRow>> getHistory(
    int houseId, {
    ShoppingHistoryScope scope = ShoppingHistoryScope.mine,
    int limit = 30,
    int offset = 0,
  }) {
    return _api.get<List, List<ShoppingHistoryRow>>(
      '${_base(houseId)}/sessions/history',
      query: {'scope': scope.wire, 'limit': '$limit', 'offset': '$offset'},
      fromJson: (data) => data
          .map((e) => ShoppingHistoryRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// (21) The read-only review of one past trip (same shape as live review).
  Future<ShoppingReview> getSummary(int houseId, int sessionId) {
    return _api.get<Map<String, dynamic>, ShoppingReview>(
      '${_base(houseId)}/sessions/$sessionId/summary',
      fromJson: ShoppingReview.fromJson,
    );
  }

  // -- Helpers ---------------------------------------------------------------

  static List<ShoppingPresenceEntry> _parsePresence(List data) => data
      .map((e) => ShoppingPresenceEntry.fromJson(e as Map<String, dynamic>))
      .toList();

  /// `GET /current` returns `null` (or an empty payload) when idle; only build
  /// a session from a non-empty object.
  static ShoppingSession? _sessionOrNull(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      if (data.isEmpty || data['id'] == null) return null;
      return ShoppingSession.fromJson(data);
    }
    return null;
  }

  /// Extract the live/closed session the server echoes in a 409 body. The body
  /// is the raw OCS envelope string; dig out `ocs.data`.
  static ShoppingSession? _sessionFromErrorBody(ApiException e) {
    try {
      final decoded = jsonDecode(e.message);
      final data = decoded is Map ? (decoded['ocs']?['data'] ?? decoded) : null;
      if (data is Map<String, dynamic> && data['id'] != null) {
        return ShoppingSession.fromJson(data);
      }
    } catch (_) {
      // Not a JSON body / unexpected shape — caller falls back to the raw error.
    }
    return null;
  }
}

/// Thrown by [ShoppingService.createSession] / [ShoppingService.close] on a 409,
/// carrying the session the server returned so the UI can offer Resume / End.
class ShoppingSessionConflict implements Exception {
  final ShoppingSession session;
  const ShoppingSessionConflict(this.session);

  @override
  String toString() => 'ShoppingSessionConflict(session ${session.id})';
}
