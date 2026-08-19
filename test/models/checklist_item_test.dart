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

  group('ListItem barcode serialization', () {
    test('round-trips barcode through toJson/fromJson', () {
      final item = ListItem(
        id: 1,
        listId: 2,
        name: 'Coca-Cola Zero',
        done: false,
        repeatFromCompletion: false,
        deleteOnDone: false,
        sortOrder: 0,
        createdAt: 100,
        updatedAt: 200,
        barcode: '4001724819103',
      );

      expect(ListItem.fromJson(item.toJson()).barcode, '4001724819103');
    });

    test('treats a missing barcode key as null', () {
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

      expect(decoded.barcode, isNull);
    });

    test('copyWith preserves an existing barcode', () {
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
        barcode: '4001724819103',
      );

      expect(item.copyWith(name: 'Milk 2').barcode, '4001724819103');
    });
  });

  group('ListItem price serialization', () {
    ListItem base(List<ItemPrice> prices) => ListItem(
      id: 1,
      listId: 2,
      name: 'Milk',
      done: false,
      repeatFromCompletion: false,
      deleteOnDone: false,
      sortOrder: 0,
      createdAt: 100,
      updatedAt: 200,
      prices: prices,
    );

    test('round-trips prices through toJson/fromJson', () {
      final decoded = ListItem.fromJson(
        base([
          const ItemPrice(
            priceType: 'set',
            priceMin: 9.99,
            priceCurrency: 'USD',
          ),
          const ItemPrice(
            storeId: 12,
            priceType: 'range',
            priceMin: 4,
            priceMax: 6,
            priceCurrency: 'USD',
          ),
        ]).toJson(),
      );
      expect(decoded.prices.length, 2);
      final storeless = decoded.prices.first;
      expect(storeless.storeId, isNull);
      expect(storeless.priceType, 'set');
      expect(storeless.priceMin, 9.99);
      expect(storeless.priceMax, isNull);
      expect(storeless.priceCurrency, 'USD');
      expect(decoded.prices[1].storeId, 12);
      expect(decoded.prices[1].priceMax, 6);
    });

    test('coerces integer JSON amounts to double', () {
      final decoded = ListItem.fromJson({
        'id': 1,
        'listId': 2,
        'name': 'Milk',
        'done': false,
        'repeatFromCompletion': false,
        'sortOrder': 0,
        'createdAt': 100,
        'updatedAt': 200,
        'prices': [
          {
            'storeId': null,
            'priceType': 'range',
            'priceMin': 1,
            'priceMax': 10,
            'priceCurrency': 'ILS',
          },
        ],
      });
      expect(decoded.prices.single.priceMin, 1.0);
      expect(decoded.prices.single.priceMax, 10.0);
    });

    test('reads the legacy flat single-price shape as a store-less entry', () {
      final decoded = ListItem.fromJson({
        'id': 1,
        'listId': 2,
        'name': 'Milk',
        'done': false,
        'repeatFromCompletion': false,
        'sortOrder': 0,
        'createdAt': 100,
        'updatedAt': 200,
        'priceType': 'set',
        'priceMin': 9.99,
        'priceCurrency': 'USD',
      });
      expect(decoded.prices.single.storeId, isNull);
      expect(decoded.prices.single.priceType, 'set');
      expect(decoded.prices.single.priceMin, 9.99);
      expect(decoded.prices.single.priceCurrency, 'USD');
    });

    test('prefers the new prices array over legacy flat fields', () {
      final decoded = ListItem.fromJson({
        'id': 1,
        'listId': 2,
        'name': 'Milk',
        'done': false,
        'repeatFromCompletion': false,
        'sortOrder': 0,
        'createdAt': 100,
        'updatedAt': 200,
        'priceType': 'set',
        'priceMin': 1,
        'prices': [
          {'storeId': 12, 'priceType': 'set', 'priceMin': 4, 'priceMax': null},
        ],
      });
      expect(decoded.prices.single.storeId, 12);
      expect(decoded.prices.single.priceMin, 4);
    });

    test('treats a missing prices key as no prices', () {
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
      expect(decoded.prices, isEmpty);
    });

    test('copyWith replaces prices, or leaves them unchanged when null', () {
      final priced = base(const [
        ItemPrice(priceType: 'set', priceMin: 5, priceCurrency: 'USD'),
      ]);
      // An empty list clears all prices.
      expect(priced.copyWith(prices: const []).prices, isEmpty);
      // A plain copyWith preserves the prices.
      expect(priced.copyWith(name: 'Bread').prices.single.priceMin, 5);
    });
  });
}
