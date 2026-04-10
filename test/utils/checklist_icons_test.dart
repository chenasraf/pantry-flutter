import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/utils/checklist_icons.dart';

void main() {
  group('checklistIcon', () {
    test('returns mapped icon for known keys', () {
      expect(checklistIcon('cart'), Icons.shopping_cart);
      expect(checklistIcon('basket'), Icons.shopping_basket);
      expect(checklistIcon('star'), Icons.star);
      expect(checklistIcon('heart'), Icons.favorite);
      expect(checklistIcon('home'), Icons.home);
      expect(checklistIcon('calendar'), Icons.calendar_today);
      expect(checklistIcon('clipboard-check'), Icons.assignment_turned_in);
    });

    test('returns default icon for unknown key', () {
      expect(checklistIcon('unknown-key'), defaultChecklistIcon);
      expect(checklistIcon('unknown-key'), Icons.assignment_turned_in);
    });

    test('returns default icon for null key', () {
      expect(checklistIcon(null), defaultChecklistIcon);
    });

    test('returns default icon for empty string', () {
      expect(checklistIcon(''), defaultChecklistIcon);
    });
  });
}
