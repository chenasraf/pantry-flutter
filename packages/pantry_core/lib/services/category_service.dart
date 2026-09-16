import 'package:pantry_core/models/category.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/cache_store.dart';

/// Sentinel for [CategoryService.updateCategory]'s `listId`: pass it (the
/// default) to omit `listId` from the PATCH entirely, leaving the scope
/// unchanged. `null` is a *meaningful* value ("make global"), so it can't
/// double as "unset".
const Object categoryListIdUnset = Object();

class CategoryService {
  CategoryService._();
  static final CategoryService instance = CategoryService._();

  final cache = CacheStore('category_cache.json');

  static const _prefix = 'categories';
  static const _storeOrderPrefix = 'storeOrder';

  List<Category>? getCached(int houseId) =>
      cache.getKeyedList(_prefix, '$houseId', Category.fromJson);

  static String _storeOrderKey(int houseId, int storeId) =>
      '$_storeOrderPrefix:$houseId:$storeId';

  /// The arrangement [storeId] was last known to have, or null when none has
  /// been read yet. An empty list means the store follows the house-wide order.
  ///
  /// Read as an untyped list and cast: [CacheStore.get] is an unchecked cast,
  /// and a list written with [CacheStore.set] comes back from the JSON reload
  /// as `List<dynamic>`.
  List<int>? getCachedStoreCategoryOrder(int houseId, int storeId) =>
      cache.get<List>(_storeOrderKey(houseId, storeId))?.cast<int>();

  void cacheStoreCategoryOrder(
    int houseId,
    int storeId,
    List<int> categoryIds,
  ) {
    cache.set(_storeOrderKey(houseId, storeId), categoryIds);
  }

  void cacheCategories(int houseId, List<Category> categories) {
    cache.setKeyedList(_prefix, '$houseId', categories, (c) => c.toJson());
  }

  Future<List<Category>> getCategories(int houseId) async {
    final categories = await ApiClient.instance.get<List, List<Category>>(
      '/houses/$houseId/categories',
      fromJson: (data) => data
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    cacheCategories(houseId, categories);
    return categories;
  }

  Future<void> setCategorySortPref(int houseId, String sort) async {
    await ApiClient.instance.put<Map<String, dynamic>, void>(
      '/houses/$houseId/prefs',
      body: {'categorySort': sort},
      fromJson: (_) {},
    );
  }

  Future<void> reorderCategories(
    int houseId,
    List<({int id, int sortOrder})> order,
  ) async {
    await ApiClient.instance.post<Map<String, dynamic>, void>(
      '/houses/$houseId/categories/reorder',
      body: {
        'items': order
            .map((e) => {'id': e.id, 'sortOrder': e.sortOrder})
            .toList(),
      },
      fromJson: (_) {},
    );
  }

  /// The categories [storeId] arranges, in the order its aisles are walked.
  /// Empty when the store follows the house-wide order throughout.
  Future<List<int>> getStoreCategoryOrder(int houseId, int storeId) async {
    final ids = await ApiClient.instance.get<Map<String, dynamic>, List<int>>(
      '/houses/$houseId/stores/$storeId/category-order',
      fromJson: (data) =>
          (data['categoryIds'] as List?)?.cast<int>() ?? const <int>[],
    );
    cacheStoreCategoryOrder(houseId, storeId, ids);
    return ids;
  }

  /// Replace [storeId]'s whole arrangement. Ids outside the house are dropped
  /// and duplicates collapse to their first position, so the echo back — not
  /// what was sent — is what the store now holds.
  Future<List<int>> setStoreCategoryOrder(
    int houseId,
    int storeId,
    List<int> categoryIds,
  ) async {
    final stored = await ApiClient.instance
        .put<Map<String, dynamic>, List<int>>(
          '/houses/$houseId/stores/$storeId/category-order',
          body: {'categoryIds': categoryIds},
          fromJson: (data) =>
              (data['categoryIds'] as List?)?.cast<int>() ?? const <int>[],
        );
    cacheStoreCategoryOrder(houseId, storeId, stored);
    return stored;
  }

  /// Drop [storeId]'s arrangement, returning it to the house-wide order.
  Future<void> clearStoreCategoryOrder(int houseId, int storeId) async {
    await ApiClient.instance.delete(
      '/houses/$houseId/stores/$storeId/category-order',
    );
    cacheStoreCategoryOrder(houseId, storeId, const []);
  }

  /// Categories in the order a store is walked: the ones it arranges first, in
  /// its own order, then everything else in the house-wide order.
  ///
  /// [arrangedIds] names only the categories the store arranges, so that
  /// fallback is what carries the lifecycle — a category created after the
  /// arrangement has no entry and lands at the end, exactly where the
  /// house-wide order appends it, and a deleted one simply drops out. Ids that
  /// no longer name a category are ignored, and a repeated id keeps its first
  /// position.
  static List<Category> orderForStore(
    Iterable<Category> categories,
    List<int> arrangedIds,
  ) {
    final byId = {for (final c in categories) c.id: c};
    final seen = <int>{};
    final arranged = <Category>[];
    for (final id in arrangedIds) {
      final category = byId[id];
      if (category != null && seen.add(id)) arranged.add(category);
    }
    final rest = [
      for (final c in categories)
        if (!seen.contains(c.id)) c,
    ];
    return [...arranged, ...sortCategories(rest, 'custom')];
  }

  /// Sort categories according to a sort mode (name_asc, name_desc, custom).
  /// Returns a new list; the input is not mutated.
  static List<Category> sortCategories(
    Iterable<Category> categories,
    String sort,
  ) {
    final list = categories.toList();
    // Categories waiting on their first sync carry a placeholder sortOrder, so
    // custom order settles ties on name and then id (creation order) — the way
    // the server and the shopping screen settle them — instead of reshuffling
    // as categories are added.
    switch (sort) {
      case 'name_asc':
        list.sort((a, b) {
          final c = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          return c != 0 ? c : a.id.compareTo(b.id);
        });
      case 'name_desc':
        list.sort((a, b) {
          final c = b.name.toLowerCase().compareTo(a.name.toLowerCase());
          return c != 0 ? c : a.id.compareTo(b.id);
        });
      case 'custom':
      default:
        list.sort((a, b) {
          final c = a.sortOrder.compareTo(b.sortOrder);
          if (c != 0) return c;
          final n = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          return n != 0 ? n : a.id.compareTo(b.id);
        });
    }
    return list;
  }

  Future<Category> createCategory(
    int houseId, {
    required String name,
    required String icon,
    required String color,
    int? listId,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, Category>(
      '/houses/$houseId/categories',
      // A null `listId` means global — the server default — so it's only sent
      // when scoping to a real list.
      body: {'name': name, 'icon': icon, 'color': color, 'listId': ?listId},
      fromJson: (data) => Category.fromJson(data),
    );
  }

  /// Pass [listId] as an int to scope the category, `null` to make it global,
  /// or leave it as [categoryListIdUnset] to keep the current scope. The `?`
  /// map-spread would silently drop an explicit `null`, so `listId` is added
  /// separately.
  Future<Category> updateCategory(
    int houseId,
    int categoryId, {
    String? name,
    String? icon,
    String? color,
    Object? listId = categoryListIdUnset,
  }) async {
    final body = <String, dynamic>{
      'name': ?name,
      'icon': ?icon,
      'color': ?color,
    };
    if (!identical(listId, categoryListIdUnset)) body['listId'] = listId;
    return ApiClient.instance.patch<Map<String, dynamic>, Category>(
      '/houses/$houseId/categories/$categoryId',
      body: body,
      fromJson: (data) => Category.fromJson(data),
    );
  }

  Future<void> deleteCategory(int houseId, int categoryId) async {
    await ApiClient.instance.delete('/houses/$houseId/categories/$categoryId');
  }
}
