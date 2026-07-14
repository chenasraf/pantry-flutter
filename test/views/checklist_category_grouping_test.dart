import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/views/checklists/checklists_view.dart';

import '../helpers/test_models.dart';

// `groupItemsByCategory` backs the sticky category headers: it slices a
// category-sorted list into consecutive same-category runs, one pinned header
// per run.

void main() {
  group('groupItemsByCategory', () {
    test('splits consecutive runs, preserving order within each', () {
      final items = [
        makeListItem(id: 1, categoryId: 1),
        makeListItem(id: 2, categoryId: 1),
        makeListItem(id: 3, categoryId: 2),
        makeListItem(id: 4, categoryId: null),
      ];

      final groups = groupItemsByCategory(items);

      expect(groups.map((g) => g.categoryId).toList(), [1, 2, null]);
      expect(groups[0].items.map((i) => i.id).toList(), [1, 2]);
      expect(groups[1].items.map((i) => i.id).toList(), [3]);
      expect(groups[2].items.map((i) => i.id).toList(), [4]);
    });

    test('uncategorized items group under a single null run', () {
      final items = [
        makeListItem(id: 1, categoryId: null),
        makeListItem(id: 2, categoryId: null),
      ];

      final groups = groupItemsByCategory(items);

      expect(groups.length, 1);
      expect(groups.single.categoryId, isNull);
      expect(groups.single.items.map((i) => i.id).toList(), [1, 2]);
    });

    test('empty input yields no groups', () {
      expect(groupItemsByCategory(const <ListItem>[]), isEmpty);
    });
  });
}
