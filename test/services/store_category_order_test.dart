import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/category.dart';
import 'package:pantry_core/services/category_service.dart';

import '../helpers/test_models.dart';

// `orderForStore` composes a store's aisle order: the categories it arranges
// first, in its own order, then everything else in the house-wide one. That
// fallback is what carries the lifecycle — a category created after the
// arrangement lands at the end, a deleted one drops out.

void main() {
  List<int> ids(List<Category> categories) => [
    for (final c in categories) c.id,
  ];

  Category cat(int id, int sortOrder, [String? name]) =>
      makeCategory(id: id, sortOrder: sortOrder, name: name ?? 'c$id');

  group('CategoryService.orderForStore', () {
    test('falls back to the house-wide order when nothing is arranged', () {
      final categories = [cat(1, 2), cat(2, 0), cat(3, 1)];

      expect(ids(CategoryService.orderForStore(categories, const [])), [
        2,
        3,
        1,
      ]);
    });

    test('leads with the arranged categories in the store order', () {
      final categories = [cat(1, 0), cat(2, 1), cat(3, 2)];

      expect(ids(CategoryService.orderForStore(categories, const [3, 1, 2])), [
        3,
        1,
        2,
      ]);
    });

    test('trails a category created after the arrangement', () {
      final categories = [cat(1, 0), cat(2, 1), cat(3, 2)];

      // The store was arranged before category 3 existed, so it lands where the
      // house-wide order appends it — at the end.
      expect(ids(CategoryService.orderForStore(categories, const [2, 1])), [
        2,
        1,
        3,
      ]);
    });

    test('orders the unarranged ones among themselves by the house order', () {
      final categories = [cat(1, 0), cat(2, 5), cat(3, 3), cat(4, 4)];

      expect(ids(CategoryService.orderForStore(categories, const [1])), [
        1,
        3,
        4,
        2,
      ]);
    });

    test('ignores ids of categories that no longer exist', () {
      final categories = [cat(1, 0), cat(2, 1)];

      expect(ids(CategoryService.orderForStore(categories, const [99, 2, 1])), [
        2,
        1,
      ]);
    });

    test('collapses a duplicated id to its first position', () {
      final categories = [cat(1, 0), cat(2, 1), cat(3, 2)];

      expect(
        ids(CategoryService.orderForStore(categories, const [3, 1, 3, 2])),
        [3, 1, 2],
      );
    });

    test('breaks equal house sortOrder ties on name', () {
      final categories = [
        cat(3, 0, 'Cherry'),
        cat(1, 0, 'Apple'),
        cat(2, 0, 'Banana'),
      ];

      expect(ids(CategoryService.orderForStore(categories, const [])), [
        1,
        2,
        3,
      ]);
    });
  });
}
