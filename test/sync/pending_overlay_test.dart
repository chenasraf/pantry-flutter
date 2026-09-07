import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/sync/pending_overlay.dart';

/// The queue wins over any snapshot, from any source.
///
/// The rule exists because the paths that write a cache key are not all
/// controller paths: a mirrored snapshot lands straight on the file. A watch
/// that checked three rows off in a dead zone and then drifted back into range
/// used to watch them flip back, which on a wrist mid-shop reads as the watch
/// forgetting.
void main() {
  ListItem item(int id, {required bool done, String name = 'Milk'}) => ListItem(
    id: id,
    listId: 7,
    name: name,
    done: done,
    repeatFromCompletion: false,
    deleteOnDone: false,
    sortOrder: id,
    createdAt: 0,
    updatedAt: 0,
  );

  test('a snapshot cannot revert a row with a queued write', () {
    final merged = overlayPendingItems(
      server: [item(1, done: false), item(2, done: false)],
      local: [item(1, done: true), item(2, done: false)],
      pending: {1},
    );

    expect(merged.map((i) => (i.id, i.done)), [(1, true), (2, false)]);
  });

  test('a row the server still has but the queue deleted stays gone', () {
    final merged = overlayPendingItems(
      server: [item(1, done: false), item(2, done: false)],
      local: [item(2, done: false)],
      pending: {1},
    );

    expect(merged.map((i) => i.id), [2]);
  });

  test('an unqueued row takes the server value', () {
    final merged = overlayPendingItems(
      server: [item(1, done: true, name: 'Bread')],
      local: [item(1, done: false, name: 'Milk')],
      pending: {2},
    );

    expect(merged.single.name, 'Bread');
  });

  test('an empty queue hands the snapshot back untouched', () {
    final server = [item(1, done: false)];
    expect(
      identical(
        overlayPendingItems(server: server, local: const [], pending: const {}),
        server,
      ),
      isTrue,
    );
  });

  group('a create the server has never returned', () {
    test('is appended when nothing says where it goes', () {
      final merged = overlayPendingItems(
        server: [item(1, done: false)],
        local: [
          item(1, done: false),
          item(-1, done: false, name: 'Eggs'),
        ],
        pending: {-1},
      );

      expect(merged.map((i) => i.id), [1, -1]);
    });

    test('lands where the caller\'s sort puts it', () {
      // Slotting matters because a refresh arriving before the create acks
      // would otherwise yank the new row to whichever end the merge happened
      // to leave it on, regardless of the sort the user is looking at.
      final merged = overlayPendingItems(
        server: [item(1, done: false), item(3, done: false)],
        local: [item(2, done: false, name: 'Eggs')],
        pending: {2},
        insertIndex: (item, into) =>
            into.indexWhere((i) => i.sortOrder > item.sortOrder),
      );

      expect(merged.map((i) => i.id), [1, 2, 3]);
    });
  });
}
