import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/models/checklist.dart';

void main() {
  group('ListItem archivedAt serialization', () {
    test('round-trips archivedAt through toJson/fromJson', () {
      final item = ListItem(
        id: 1,
        listId: 2,
        name: 'Milk',
        done: false,
        repeatFromCompletion: false,
        deleteOnDone: false,
        sortOrder: 0,
        createdAt: 100,
        updatedAt: 200,
        archivedAt: 12345,
      );

      final decoded = ListItem.fromJson(item.toJson());

      expect(decoded.archivedAt, 12345);
      expect(decoded.deletedAt, isNull);
    });

    test('treats a missing archivedAt key as null (active item)', () {
      final decoded = ListItem.fromJson({
        'id': 1,
        'listId': 2,
        'name': 'Milk',
        'done': false,
        'repeatFromCompletion': false,
        'sortOrder': 0,
        'createdAt': 100,
        'updatedAt': 200,
      });

      expect(decoded.archivedAt, isNull);
    });

    test('clearArchivedAt returns the item to the active state', () {
      final archived = ListItem(
        id: 1,
        listId: 2,
        name: 'Milk',
        done: false,
        repeatFromCompletion: false,
        deleteOnDone: false,
        sortOrder: 0,
        createdAt: 100,
        updatedAt: 200,
        archivedAt: 999,
      );

      expect(archived.copyWith(clearArchivedAt: true).archivedAt, isNull);
      // A plain copyWith preserves the existing archivedAt.
      expect(archived.copyWith(name: 'Bread').archivedAt, 999);
    });
  });
}
