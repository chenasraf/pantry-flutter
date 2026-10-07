import 'dart:async';

import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/sync/sync_ids.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';

/// The account-scoped Pantry prefs this app changes, kept in [PrefsService]'s
/// cache so readers stay synchronous and offline-safe.
///
/// A write lands in the cache immediately and reaches the server through the
/// sync queue, so a setting changed offline sticks rather than snapping back.
class UserPrefsService {
  UserPrefsService._();
  static final UserPrefsService instance = UserPrefsService._();

  StreamSubscription<SyncOpSkipped>? _skipped;

  /// A write the server refused leaves the cache holding a value the account
  /// never took; refetching puts the server's back.
  void init() {
    _skipped ??= SyncManager.instance.onSkipped
        .where((s) => s.op.entity == SyncEntity.userPrefs)
        .listen((_) => unawaited(AuthService.instance.fetchUserPrefs()));
  }

  /// Caches the keys of a fetched prefs object. A key is absent when the
  /// server predates the capability behind it, which leaves the cached value
  /// alone; a key with a write still queued is skipped too, since the server's
  /// value is the one that write replaces.
  Future<void> hydrate(Map<String, dynamic> prefs) async {
    final pending = SyncManager.instance.pendingUserPrefs();
    T? fresh<T>(String key) =>
        pending.containsKey(key) ? null : prefs[key] as T?;

    final cache = PrefsService.instance;
    final reuse = fresh<String>('reuseExistingItems');
    final suggestArchived = fresh<bool>('suggestArchivedItems');
    final fillName = fresh<bool>('barcodeFillName');
    final fillCategory = fresh<bool>('barcodeFillCategory');
    final fillImage = fresh<bool>('barcodeFillImage');
    await Future.wait([
      if (reuse != null) cache.setReuseExistingItemsCache(reuse),
      if (suggestArchived != null)
        cache.setSuggestArchivedItemsCache(suggestArchived),
      if (fillName != null) cache.setBarcodeFillNameCache(fillName),
      if (fillCategory != null) cache.setBarcodeFillCategoryCache(fillCategory),
      if (fillImage != null) cache.setBarcodeFillImageCache(fillImage),
    ]);
  }

  Future<void> setReuseExistingItems(String value) async {
    await PrefsService.instance.setReuseExistingItemsCache(value);
    _enqueue({'reuseExistingItems': value});
  }

  Future<void> setSuggestArchivedItems(bool value) async {
    await PrefsService.instance.setSuggestArchivedItemsCache(value);
    _enqueue({'suggestArchivedItems': value});
  }

  Future<void> setBarcodeFill({bool? name, bool? category, bool? image}) async {
    final cache = PrefsService.instance;
    await Future.wait([
      if (name != null) cache.setBarcodeFillNameCache(name),
      if (category != null) cache.setBarcodeFillCategoryCache(category),
      if (image != null) cache.setBarcodeFillImageCache(image),
    ]);
    _enqueue({
      'barcodeFillName': ?name,
      'barcodeFillCategory': ?category,
      'barcodeFillImage': ?image,
    });
  }

  void _enqueue(Map<String, Object> patch) {
    if (patch.isEmpty) return;
    SyncManager.instance.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.userPrefs,
        op: SyncOpKind.update,
        houseId: 0,
        body: patch,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
