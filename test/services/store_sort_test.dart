import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/store.dart';
import 'package:pantry_core/services/store_service.dart';

Store _store(int id, String name, {int sortOrder = 0}) => Store(
  id: id,
  houseId: 1,
  name: name,
  icon: 'store',
  color: '#ef4444',
  sortOrder: sortOrder,
  createdAt: 0,
  updatedAt: 0,
);

void main() {
  group('StoreService.sortStores', () {
    test('name_asc is the default and breaks ties by id', () {
      final input = [_store(9, 'Deli'), _store(4, 'Deli'), _store(6, 'Bakery')];
      final sorted = StoreService.sortStores(input, 'name_asc');
      expect(sorted.map((s) => s.id), [6, 4, 9]);
    });

    test('name_desc reverses, still breaking ties by id', () {
      final input = [_store(6, 'Bakery'), _store(9, 'Deli'), _store(4, 'Deli')];
      final sorted = StoreService.sortStores(input, 'name_desc');
      expect(sorted.map((s) => s.id), [4, 9, 6]);
    });

    test('custom sort breaks sortOrder ties by id (creation order)', () {
      // Every store shares sortOrder 0 — the state fresh stores are in before
      // any reorder. The order must follow id, not input order.
      final input = [
        _store(3, 'Store 3'),
        _store(1, 'Store 1'),
        _store(2, 'Store 2'),
      ];
      final sorted = StoreService.sortStores(input, 'custom');
      expect(sorted.map((s) => s.id), [1, 2, 3]);
    });

    test('explicit sortOrder still wins over id', () {
      final input = [
        _store(1, 'First', sortOrder: 2),
        _store(2, 'Second', sortOrder: 0),
        _store(3, 'Third', sortOrder: 1),
      ];
      final sorted = StoreService.sortStores(input, 'custom');
      expect(sorted.map((s) => s.id), [2, 3, 1]);
    });

    test('does not mutate the input', () {
      final input = [_store(2, 'B'), _store(1, 'A')];
      StoreService.sortStores(input, 'name_asc');
      expect(input.map((s) => s.id), [2, 1]);
    });
  });

  group('Store.sortOrder serialization', () {
    test('round-trips through JSON', () {
      final store = _store(1, 'Corner Shop', sortOrder: 5);
      expect(Store.fromJson(store.toJson()).sortOrder, 5);
    });

    test('defaults to 0 when absent (pre-migration cache)', () {
      final json = {
        'id': 1,
        'houseId': 1,
        'name': 'Old Cache',
        'icon': 'store',
        'color': '#fff',
        'createdAt': 0,
        'updatedAt': 0,
      };
      expect(Store.fromJson(json).sortOrder, 0);
    });
  });
}
