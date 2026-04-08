import 'package:pantry/models/category.dart';
import 'package:pantry/services/api_client.dart';

class CategoryService {
  CategoryService._();
  static final CategoryService instance = CategoryService._();

  Future<List<Category>> getCategories(int houseId) async {
    return ApiClient.instance.get<List, List<Category>>(
      '/houses/$houseId/categories',
      fromJson: (data) => data
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
