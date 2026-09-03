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

  List<Category>? getCached(int houseId) =>
      cache.getKeyedList(_prefix, '$houseId', Category.fromJson);

  Future<List<Category>> getCategories(int houseId) async {
    final categories = await ApiClient.instance.get<List, List<Category>>(
      '/houses/$houseId/categories',
      fromJson: (data) => data
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    cache.setKeyedList(_prefix, '$houseId', categories, (c) => c.toJson());
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

  /// Sort categories according to a sort mode (name_asc, name_desc, custom).
  /// Returns a new list; the input is not mutated.
  static List<Category> sortCategories(
    Iterable<Category> categories,
    String sort,
  ) {
    final list = categories.toList();
    // Fall back to id (creation order) as a final tiebreaker: fresh categories
    // share the same sortOrder until reordered, so without it the custom list
    // would reshuffle unpredictably as categories are added.
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
          return c != 0 ? c : a.id.compareTo(b.id);
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
