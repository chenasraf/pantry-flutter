import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/services/checklist_service.dart';

ChecklistList _list(int id, int houseId, String name) => ChecklistList(
  id: id,
  houseId: houseId,
  name: name,
  icon: 'list',
  sortOrder: 0,
  createdAt: 0,
  updatedAt: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = ChecklistService.instance;

  group('per-house lists cache', () {
    test('each house keeps its own snapshot across writes', () {
      service.cacheLists(1, [_list(10, 1, 'Groceries')]);
      // Writing a second house must not wipe the first — the core bug.
      service.cacheLists(2, [_list(20, 2, 'Hardware')]);

      final h1 = service.getCachedLists(1);
      final h2 = service.getCachedLists(2);
      expect(h1, isNotNull);
      expect(h1!.map((l) => l.id), [10]);
      expect(h2, isNotNull);
      expect(h2!.map((l) => l.id), [20]);
    });

    test('returns null for a house that was never cached', () {
      expect(service.getCachedLists(999), isNull);
    });

    test('falls back to the legacy global slot for the marked house', () {
      // Simulate a pre-upgrade cache: single global `lists` + `houseId` marker.
      service.cache.set('houseId', 7);
      service.cache.setList('lists', [
        _list(70, 7, 'Legacy'),
      ], (l) => l.toJson());

      final legacy = service.getCachedLists(7);
      expect(legacy, isNotNull);
      expect(legacy!.map((l) => l.id), [70]);

      // A different house doesn't borrow the legacy snapshot.
      expect(service.getCachedLists(8), isNull);
    });

    test('a per-house write supersedes the legacy fallback', () {
      service.cache.set('houseId', 5);
      service.cache.setList('lists', [_list(50, 5, 'Old')], (l) => l.toJson());
      service.cacheLists(5, [_list(51, 5, 'New')]);

      expect(service.getCachedLists(5)!.map((l) => l.id), [51]);
    });
  });
}
