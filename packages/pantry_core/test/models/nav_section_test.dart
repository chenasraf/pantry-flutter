import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/nav_section.dart';

void main() {
  group('decodeNavOrder', () {
    test('keeps an order that names every section', () {
      expect(decodeNavOrder('notesWall,inventories,checklists,photoBoard'), [
        NavSection.notesWall,
        NavSection.inventories,
        NavSection.checklists,
        NavSection.photoBoard,
      ]);
    });

    test('places a missing section after its default neighbour', () {
      expect(decodeNavOrder('photoBoard,checklists,notesWall'), [
        NavSection.photoBoard,
        NavSection.checklists,
        NavSection.inventories,
        NavSection.notesWall,
      ]);
    });

    test('puts a missing first section first', () {
      expect(decodeNavOrder('notesWall,photoBoard,inventories'), [
        NavSection.checklists,
        NavSection.notesWall,
        NavSection.photoBoard,
        NavSection.inventories,
      ]);
    });

    test('drops unknown and repeated ids', () {
      expect(decodeNavOrder('photoBoard,bogus,photoBoard'), [
        NavSection.checklists,
        NavSection.inventories,
        NavSection.photoBoard,
        NavSection.notesWall,
      ]);
    });

    test('falls back to the default order', () {
      expect(decodeNavOrder(null), kDefaultNavOrder);
      expect(decodeNavOrder(''), kDefaultNavOrder);
    });
  });
}
