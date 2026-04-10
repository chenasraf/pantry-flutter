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
      body: {
        if (name != null) 'name': name,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
      },
      fromJson: (data) => Category.fromJson(data),
    );
  }

  Future<void> deleteCategory(int houseId, int categoryId) async {
    await ApiClient.instance.delete('/houses/$houseId/categories/$categoryId');
  }
}
