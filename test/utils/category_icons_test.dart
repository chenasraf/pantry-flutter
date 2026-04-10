import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/utils/category_icons.dart';

void main() {
  group('categoryIcon', () {
    test('returns mapped icon for known keys', () {
      expect(categoryIcon('food'), Icons.lunch_dining);
      expect(categoryIcon('fruit'), Icons.apple);
      expect(categoryIcon('vegetable'), Icons.grass);
      expect(categoryIcon('bakery'), Icons.bakery_dining);
      expect(categoryIcon('coffee'), Icons.coffee);
      expect(categoryIcon('tag'), Icons.label);
    });

    test('returns default icon for unknown key', () {
      expect(categoryIcon('nope'), defaultCategoryIcon);
      expect(categoryIcon('nope'), Icons.label);
    });

    test('returns default icon for null key', () {
      expect(categoryIcon(null), defaultCategoryIcon);
    });

    test('returns default icon for empty key', () {
      expect(categoryIcon(''), defaultCategoryIcon);
    });

    test('map has at least the expected base keys', () {
      expect(categoryIconMap.keys, containsAll(['tag', 'food', 'coffee']));
    });
  });
}
