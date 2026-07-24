import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/models/category.dart';
import 'package:pantry/services/category_service.dart';

Category _cat(int id, String name, {int sortOrder = 0}) => Category(
  id: id,
  houseId: 1,
  name: name,
  icon: 'tag',
  color: '#ef4444',
  sortOrder: sortOrder,
  createdAt: 0,
  updatedAt: 0,
);

void main() {
  group('CategoryService.sortCategories', () {
    test('custom sort breaks sortOrder ties by id (creation order)', () {
      // Every category shares sortOrder 0 — the state fresh categories are in
      // before any reorder. The order must follow id, not input order.
      final input = [
        _cat(3, 'Aisle 3'),
        _cat(1, 'Aisle 1'),
        _cat(2, 'Aisle 2'),
      ];
      final sorted = CategoryService.sortCategories(input, 'custom');
      expect(sorted.map((c) => c.id), [1, 2, 3]);
    });

    test(
      'custom sort is stable across repeated calls with equal sortOrder',
      () {
        final a = [_cat(10, 'B'), _cat(5, 'A'), _cat(7, 'C')];
        final first = CategoryService.sortCategories(a, 'custom');
        final second = CategoryService.sortCategories(first, 'custom');
        expect(first.map((c) => c.id), second.map((c) => c.id));
        expect(first.map((c) => c.id), [5, 7, 10]);
      },
    );

    test('explicit sortOrder still wins over id', () {
      final input = [
        _cat(1, 'First', sortOrder: 2),
        _cat(2, 'Second', sortOrder: 0),
        _cat(3, 'Third', sortOrder: 1),
      ];
      final sorted = CategoryService.sortCategories(input, 'custom');
      expect(sorted.map((c) => c.id), [2, 3, 1]);
    });

    test('name_asc breaks ties by id', () {
      final input = [_cat(9, 'Dairy'), _cat(4, 'Dairy'), _cat(6, 'Apples')];
      final sorted = CategoryService.sortCategories(input, 'name_asc');
      expect(sorted.map((c) => c.id), [6, 4, 9]);
    });
  });
}
