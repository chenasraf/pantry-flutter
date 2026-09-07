import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/category.dart';

void main() {
  Category make({int? listId}) => Category(
    id: 1,
    houseId: 2,
    name: 'Dairy',
    icon: 'food',
    color: '#ef4444',
    sortOrder: 5,
    listId: listId,
    createdAt: 100,
    updatedAt: 200,
  );

  group('Category.listId serialization', () {
    test('round-trips a scoped listId through toJson/fromJson', () {
      final decoded = Category.fromJson(make(listId: 42).toJson());
      expect(decoded.listId, 42);
    });

    test('round-trips a global (null) listId through toJson/fromJson', () {
      final json = make().toJson();
      expect(json.containsKey('listId'), isTrue);
      expect(json['listId'], isNull);
      expect(Category.fromJson(json).listId, isNull);
    });

    test('fromJson tolerates a payload missing listId (global)', () {
      final decoded = Category.fromJson({
        'id': 1,
        'houseId': 2,
        'name': 'Dairy',
        'icon': 'food',
        'color': '#ef4444',
        'sortOrder': 5,
        'createdAt': 100,
        'updatedAt': 200,
      });
      expect(decoded.listId, isNull);
    });
  });

  group('Category.copyWith listId sentinel', () {
    test('omitting listId leaves the current scope unchanged', () {
      expect(make(listId: 42).copyWith(name: 'Cheese').listId, 42);
      expect(make().copyWith(name: 'Cheese').listId, isNull);
    });

    test('explicit null makes a scoped category global', () {
      expect(make(listId: 42).copyWith(listId: null).listId, isNull);
    });

    test('an int re-scopes the category', () {
      expect(make(listId: 42).copyWith(listId: 7).listId, 7);
      expect(make().copyWith(listId: 7).listId, 7);
    });
  });
}
