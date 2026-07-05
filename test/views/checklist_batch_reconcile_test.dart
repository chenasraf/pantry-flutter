import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';

import '../helpers/test_models.dart';

// The group (batch) actions reconcile local state from the server's
// PantryBatchResult without a full reload. These cover the two pure rules the
// controller applies: replace-by-id (move in the aggregate view, set-category)
// and remove-by-id (delete, and the per-list move where items leave the view).

List<int> _ids(List<ListItem> items) => [for (final i in items) i.id];

void main() {
  group('reconcileReplaceById', () {
    test('overlays same-id items and leaves order + others untouched', () {
      final current = [
        makeListItem(id: 1, name: 'a', categoryId: null),
        makeListItem(id: 2, name: 'b', categoryId: null),
        makeListItem(id: 3, name: 'c', categoryId: null),
      ];
      // Server returns items 1 and 3 with a new category assigned.
      final updated = [
        makeListItem(id: 1, name: 'a', categoryId: 7),
        makeListItem(id: 3, name: 'c', categoryId: 7),
      ];

      final result = reconcileReplaceById(current, updated);

      expect(_ids(result), [1, 2, 3]);
      expect(result[0].categoryId, 7);
      expect(result[1].categoryId, isNull); // untouched
      expect(result[2].categoryId, 7);
    });

    test('a move in the aggregate view adopts the new listId', () {
      final current = [
        makeListItem(id: 1, listId: 10),
        makeListItem(id: 2, listId: 10),
      ];
      // Item 1 moved to list 20; item 2 was a no-op (not returned).
      final moved = [makeListItem(id: 1, listId: 20)];

      final result = reconcileReplaceById(current, moved);

      expect(result[0].listId, 20);
      expect(result[1].listId, 10);
    });
  });

  group('reconcileRemoveIds', () {
    test('delete drops sent minus skipped, keeping skipped in place', () {
      final current = [
        makeListItem(id: 1),
        makeListItem(id: 2),
        makeListItem(id: 3),
      ];
      // Sent [1, 2, 3]; server skipped [2]. Done ids = {1, 3}.
      const skipped = {2};
      final sent = {1, 2, 3};
      final removed = sent.difference(skipped);

      final result = reconcileRemoveIds(current, removed);

      expect(_ids(result), [2]);
    });

    test('per-list move removes only the ids the server returned', () {
      final current = [
        makeListItem(id: 1),
        makeListItem(id: 2), // no-op: already on target, not returned
        makeListItem(id: 3), // skipped: no access, not returned
      ];
      // Only item 1 was actually moved and returned.
      final movedAway = {1};

      final result = reconcileRemoveIds(current, movedAway);

      // No-op and skipped items stay put; only the moved item leaves.
      expect(_ids(result), [2, 3]);
    });

    test('empty removal set is a no-op', () {
      final current = [makeListItem(id: 1), makeListItem(id: 2)];
      expect(_ids(reconcileRemoveIds(current, {})), [1, 2]);
    });
  });
}
