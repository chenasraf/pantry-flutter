import 'package:pantry/models/category.dart';
import 'package:pantry/services/api_client.dart';
import 'package:pantry/services/cache_store.dart';

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
    switch (sort) {
      case 'name_asc':
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case 'name_desc':
        list.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
      case 'custom':
      default:
        list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return list;
  }

  Future<Category> createCategory(
    int houseId, {
    required String name,
    required String icon,
    required String color,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, Category>(
      '/houses/$houseId/categories',
      body: {'name': name, 'icon': icon, 'color': color},
      fromJson: (data) => Category.fromJson(data),
    );
  }

  Future<Category> updateCategory(
    int houseId,
    int categoryId, {
    String? name,
    String? icon,
    String? color,
  }) async {
    return ApiClient.instance.patch<Map<String, dynamic>, Category>(
      '/houses/$houseId/categories/$categoryId',
      body: {'name': ?name, 'icon': ?icon, 'color': ?color},
      fromJson: (data) => Category.fromJson(data),
    );
  }

  Future<void> deleteCategory(int houseId, int categoryId) async {
    await ApiClient.instance.delete('/houses/$houseId/categories/$categoryId');
  }
}
