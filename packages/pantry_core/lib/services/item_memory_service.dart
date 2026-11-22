import 'package:flutter/foundation.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/cache_store.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/name_key.dart';

/// What a household has picked for an item name before: the category it files
/// under, and the amount each list adds it in. Synced from the server and kept
/// on disk, so guesses work offline from the last sync.
class ItemMemoryService {
  ItemMemoryService._();
  static final ItemMemoryService instance = ItemMemoryService._();

  final cache = CacheStore('item_memory_cache.json');

  final Map<int, _HouseMemory> _houses = {};
  final Map<int, Future<void>> _refreshing = {};

  static String _cacheKey(int houseId) => 'house:$houseId';

  _HouseMemory _memoryOf(int houseId) => _houses.putIfAbsent(
    houseId,
    () => _HouseMemory.fromJson(cache.getObject(_cacheKey(houseId))),
  );

  /// Pull what changed since the last sync of [houseId]. Concurrent calls for
  /// one house share a single request; a failure leaves the cached memory as
  /// it was.
  Future<void> refresh(int houseId) {
    if (!ServerFeature.itemMemory) return Future.value();
    return _refreshing[houseId] ??= _fetch(
      houseId,
    ).whenComplete(() => _refreshing.remove(houseId));
  }

  Future<void> _fetch(int houseId) async {
    final memory = _memoryOf(houseId);
    final since = memory.serverTime;
    try {
      final data = await ApiClient.instance
          .get<Map<String, dynamic>, Map<String, dynamic>>(
            '/houses/$houseId/item-memory',
            query: since == null ? null : {'since': '$since'},
            fromJson: (d) => d,
          );
      memory.merge(data, full: since == null);
      cache.set(_cacheKey(houseId), memory.toJson());
    } catch (e) {
      debugPrint('[ItemMemoryService] Failed to refresh house $houseId: $e');
    }
  }

  /// The category [name] most often lands in, among [usableCategoryIds] — the
  /// house's categories that may go on the target list. Null when nothing
  /// stands out.
  int? guessCategory(
    int houseId,
    String name,
    Iterable<int> usableCategoryIds,
  ) {
    if (!ServerFeature.itemMemory) return null;
    final key = nameKey(name);
    if (key.isEmpty) return null;
    final rows = _memoryOf(houseId).categories[key];
    if (rows == null) return null;
    final usable = usableCategoryIds.toSet();
    _CategoryRow? best;
    for (final row in rows.values) {
      if (!usable.contains(row.categoryId) || row.score <= 0) continue;
      if (best == null ||
          row.score > best.score ||
          (row.score == best.score && row.updatedAt > best.updatedAt)) {
        best = row;
      }
    }
    return best?.categoryId;
  }

  /// The amount [name] was last added in on [listId], or null.
  String? guessQuantity(int houseId, int listId, String name) {
    if (!ServerFeature.itemMemory) return null;
    final key = nameKey(name);
    if (key.isEmpty) return null;
    return _memoryOf(houseId).quantities[listId]?[key];
  }

  Future<void> clear() async {
    _houses.clear();
    await cache.clear();
  }

  /// Fold [response] into [houseId]'s memory as a sync would: a full dump
  /// replaces it, a delta is laid over it.
  @visibleForTesting
  void debugSeed(
    int houseId,
    Map<String, dynamic> response, {
    bool full = true,
  }) => _memoryOf(houseId).merge(response, full: full);
}

class _CategoryRow {
  final int categoryId;
  final int uses;
  final int rejections;
  final int updatedAt;

  const _CategoryRow({
    required this.categoryId,
    required this.uses,
    required this.rejections,
    required this.updatedAt,
  });

  int get score => uses - rejections;
}

class _HouseMemory {
  /// nameKey → categoryId → row.
  final Map<String, Map<int, _CategoryRow>> categories = {};

  /// listId → nameKey → amount.
  final Map<int, Map<String, String>> quantities = {};

  int? serverTime;

  _HouseMemory();

  factory _HouseMemory.fromJson(Map<String, dynamic>? json) {
    final memory = _HouseMemory();
    if (json != null) memory.merge(json, full: true);
    return memory;
  }

  /// Fold a sync response in. A full dump replaces everything; a delta upserts
  /// rows (the server's `since` is inclusive, so a row can come twice) and a
  /// null amount forgets that list's amount for the name.
  void merge(Map<String, dynamic> data, {required bool full}) {
    if (full) {
      categories.clear();
      quantities.clear();
    }
    for (final raw in (data['categories'] as List?) ?? const []) {
      final row = raw as Map<String, dynamic>;
      final key = row['nameKey'] as String?;
      final categoryId = row['categoryId'] as int?;
      if (key == null || key.isEmpty || categoryId == null) continue;
      categories.putIfAbsent(key, () => {})[categoryId] = _CategoryRow(
        categoryId: categoryId,
        uses: row['uses'] as int? ?? 0,
        rejections: row['rejections'] as int? ?? 0,
        updatedAt: row['updatedAt'] as int? ?? 0,
      );
    }
    for (final raw in (data['quantities'] as List?) ?? const []) {
      final row = raw as Map<String, dynamic>;
      final key = row['nameKey'] as String?;
      final listId = row['listId'] as int?;
      if (key == null || key.isEmpty || listId == null) continue;
      final quantity = row['quantity'] as String?;
      if (quantity == null || quantity.isEmpty) {
        quantities[listId]?.remove(key);
      } else {
        quantities.putIfAbsent(listId, () => {})[key] = quantity;
      }
    }
    serverTime = data['serverTime'] as int? ?? serverTime;
  }

  Map<String, dynamic> toJson() => {
    'serverTime': serverTime,
    'categories': [
      for (final MapEntry(key: key, value: rows) in categories.entries)
        for (final row in rows.values)
          {
            'nameKey': key,
            'categoryId': row.categoryId,
            'uses': row.uses,
            'rejections': row.rejections,
            'updatedAt': row.updatedAt,
          },
    ],
    'quantities': [
      for (final MapEntry(key: listId, value: rows) in quantities.entries)
        for (final MapEntry(key: key, value: quantity) in rows.entries)
          {'listId': listId, 'nameKey': key, 'quantity': quantity},
    ],
  };
}
