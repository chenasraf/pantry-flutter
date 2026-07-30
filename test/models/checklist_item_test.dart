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
    ListItem base({
      String? priceType,
      double? priceMin,
      double? priceMax,
      String? priceCurrency,
    }) => ListItem(
      id: 1,
      listId: 2,
      name: 'Milk',
      done: false,
      repeatFromCompletion: false,
      deleteOnDone: false,
      sortOrder: 0,
      createdAt: 100,
      updatedAt: 200,
      priceType: priceType,
      priceMin: priceMin,
      priceMax: priceMax,
      priceCurrency: priceCurrency,
    );

    test('round-trips a set price through toJson/fromJson', () {
      final decoded = ListItem.fromJson(
        base(priceType: 'set', priceMin: 9.99, priceCurrency: 'USD').toJson(),
      );
      expect(decoded.priceType, 'set');
      expect(decoded.priceMin, 9.99);
      expect(decoded.priceMax, isNull);
      expect(decoded.priceCurrency, 'USD');
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
        'priceType': 'range',
        'priceMin': 1,
        'priceMax': 10,
        'priceCurrency': 'ILS',
      });
      expect(decoded.priceMin, 1.0);
      expect(decoded.priceMax, 10.0);
    });

    test('treats missing price keys as no price', () {
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
      expect(decoded.priceType, isNull);
      expect(decoded.priceMin, isNull);
    });

    test('clearPrice nulls the whole group', () {
      final priced = base(priceType: 'set', priceMin: 5, priceCurrency: 'USD');
      final cleared = priced.copyWith(clearPrice: true);
      expect(cleared.priceType, isNull);
      expect(cleared.priceMin, isNull);
      expect(cleared.priceCurrency, isNull);
      // A plain copyWith preserves the price.
      expect(priced.copyWith(name: 'Bread').priceMin, 5);
    });
  });
}
