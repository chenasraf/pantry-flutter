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
}
