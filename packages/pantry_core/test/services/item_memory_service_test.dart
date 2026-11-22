import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/item_memory_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/version.dart';

Map<String, dynamic> _category(
  String nameKey,
  int categoryId, {
  int uses = 1,
  int rejections = 0,
  int updatedAt = 1,
}) => {
  'nameKey': nameKey,
  'categoryId': categoryId,
  'uses': uses,
  'rejections': rejections,
  'updatedAt': updatedAt,
};

void main() {
  final memory = ItemMemoryService.instance;

  setUp(() {
    ServerVersionService.instance.debugSeed(
      pantryVersion: Version.parse('0.40.0'),
    );
  });

  tearDown(() => ServerVersionService.instance.debugSeed());

  group('guessCategory', () {
    test('picks the highest uses less rejections', () {
      memory.debugSeed(1, {
        'categories': [
          _category('milk', 1, uses: 5, rejections: 4),
          _category('milk', 2, uses: 3),
        ],
      });
      expect(memory.guessCategory(1, 'Milk', [1, 2]), 2);
    });

    test('breaks a tie on the latest change', () {
      memory.debugSeed(1, {
        'categories': [
          _category('milk', 1, uses: 2, updatedAt: 10),
          _category('milk', 2, uses: 2, updatedAt: 20),
        ],
      });
      expect(memory.guessCategory(1, 'milk', [1, 2]), 2);
    });

    test('offers nothing rejected as often as used', () {
      memory.debugSeed(1, {
        'categories': [_category('milk', 1, uses: 2, rejections: 2)],
      });
      expect(memory.guessCategory(1, 'milk', [1]), isNull);
    });

    test('only offers categories usable on the target list', () {
      memory.debugSeed(1, {
        'categories': [
          _category('milk', 1, uses: 9),
          _category('milk', 2, uses: 1),
        ],
      });
      expect(memory.guessCategory(1, 'milk', [2]), 2);
      expect(memory.guessCategory(1, 'milk', const []), isNull);
    });

    test('looks names up by their folded key', () {
      memory.debugSeed(1, {
        'categories': [_category('creme fraiche', 4)],
      });
      expect(memory.guessCategory(1, '  Crème fraîche (full fat)', [4]), 4);
    });

    test('is silent on servers without item memory', () {
      memory.debugSeed(1, {
        'categories': [_category('milk', 1)],
      });
      ServerVersionService.instance.debugSeed(
        pantryVersion: Version.parse('0.39.0'),
      );
      expect(memory.guessCategory(1, 'milk', [1]), isNull);
    });
  });

  group('sync', () {
    test('a delta upserts rows and keeps the rest', () {
      memory.debugSeed(1, {
        'categories': [_category('milk', 1, uses: 1), _category('eggs', 2)],
        'quantities': [
          {'listId': 3, 'nameKey': 'milk', 'quantity': '1 L'},
        ],
      });
      memory.debugSeed(1, {
        'categories': [_category('milk', 1, uses: 1, rejections: 1)],
        'quantities': [
          {'listId': 3, 'nameKey': 'milk', 'quantity': '2 L'},
        ],
      }, full: false);
      expect(memory.guessCategory(1, 'milk', [1]), isNull);
      expect(memory.guessCategory(1, 'eggs', [2]), 2);
      expect(memory.guessQuantity(1, 3, 'milk'), '2 L');
    });

    test('a forgotten amount in a delta drops the cached one', () {
      memory.debugSeed(1, {
        'quantities': [
          {'listId': 3, 'nameKey': 'milk', 'quantity': '1 L'},
          {'listId': 4, 'nameKey': 'milk', 'quantity': '6'},
        ],
      });
      memory.debugSeed(1, {
        'quantities': [
          {'listId': 3, 'nameKey': 'milk', 'quantity': null},
        ],
      }, full: false);
      expect(memory.guessQuantity(1, 3, 'milk'), isNull);
      expect(memory.guessQuantity(1, 4, 'milk'), '6');
    });

    test('a full dump replaces everything', () {
      memory.debugSeed(1, {
        'categories': [_category('milk', 1)],
      });
      memory.debugSeed(1, {
        'categories': [_category('eggs', 2)],
      });
      expect(memory.guessCategory(1, 'milk', [1]), isNull);
      expect(memory.guessCategory(1, 'eggs', [2]), 2);
    });

    test('houses keep separate memories', () {
      memory.debugSeed(1, {
        'categories': [_category('milk', 1)],
      });
      memory.debugSeed(2, {
        'categories': [_category('milk', 5)],
      });
      expect(memory.guessCategory(1, 'milk', [1, 5]), 1);
      expect(memory.guessCategory(2, 'milk', [1, 5]), 5);
    });
  });
}
