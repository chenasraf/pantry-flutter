import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/shopping_put_away.dart';

/// Finishing a trip puts what was bought away. The review starts each item
/// where its tick restocked it, and sends only what the shopper changed.
void main() {
  const fridge = 20;
  const freezer = 21;

  RestockEntry entry(int listId, {String? added, String? previousLevel}) =>
      RestockEntry(
        itemId: 100 + listId,
        listId: listId,
        itemName: 'Milk',
        listName: 'Storage $listId',
        added: added,
        previousLevel: previousLevel,
      );

  ListItem item({int id = 1, String? quantity, List<RestockEntry>? restock}) =>
      ListItem(
        id: id,
        listId: 4,
        name: 'Milk',
        quantity: quantity,
        storeIds: const [],
        done: true,
        repeatFromCompletion: false,
        deleteOnDone: false,
        sortOrder: 0,
        createdAt: 0,
        updatedAt: 0,
        restock: restock,
      );

  group('putAwayFromRecord', () {
    test('an amount per inventory the tick restocked', () {
      final storages = putAwayFromRecord(
        item(
          restock: [
            entry(fridge, added: '2 L'),
            entry(freezer, added: '1'),
          ],
        ),
      );
      expect(storages, const [
        PutAwayStorage(listId: fridge, amount: 2),
        PutAwayStorage(listId: freezer, amount: 1),
      ]);
    });

    test('a level item taken to Full has no amount', () {
      expect(
        putAwayFromRecord(item(restock: [entry(fridge, previousLevel: 'low')])),
        const [PutAwayStorage(listId: fridge)],
      );
    });

    test('a renewed date alone put nothing away', () {
      expect(putAwayFromRecord(item(restock: [entry(fridge)])), isEmpty);
    });

    test('two entries on one inventory add up', () {
      expect(
        putAwayFromRecord(
          item(
            restock: [
              entry(fridge, added: '2'),
              entry(fridge, added: '3'),
            ],
          ),
        ),
        const [PutAwayStorage(listId: fridge, amount: 5)],
      );
    });

    test('an item no tick restocked starts nowhere', () {
      expect(putAwayFromRecord(item()), isEmpty);
    });
  });

  test('amountLeft is what was bought less what is placed', () {
    final milk = item(quantity: '6 bottles');
    expect(amountLeft(milk, const []), 6);
    expect(
      amountLeft(milk, const [PutAwayStorage(listId: fridge, amount: 4)]),
      2,
    );
    expect(
      amountLeft(milk, const [PutAwayStorage(listId: fridge, amount: 9)]),
      0,
    );
    expect(amountLeft(item(), const []), 1, reason: 'no quantity is one');
  });

  group('changedPutAway', () {
    final milk = item(id: 1, restock: [entry(fridge, added: '2')]);
    final eggs = item(id: 2, restock: [entry(freezer, added: '6')]);

    test('an untouched draft sends nothing', () {
      expect(changedPutAway([milk, eggs], putAwayDraft([milk, eggs])), isEmpty);
    });

    test('sends only the items whose storages changed', () {
      final draft = putAwayDraft([milk, eggs]);
      draft[milk.id] = const [
        PutAwayStorage(listId: fridge, amount: 1),
        PutAwayStorage(listId: freezer, amount: 1),
      ];
      final changed = changedPutAway([milk, eggs], draft);
      expect(changed.map((e) => e.itemId), [milk.id]);
      expect(changed.single.toJson(), {
        'itemId': milk.id,
        'storages': [
          {'listId': fridge, 'amount': 1.0},
          {'listId': freezer, 'amount': 1.0},
        ],
      });
    });

    test('the storages order does not count as a change', () {
      final split = item(
        restock: [
          entry(fridge, added: '1'),
          entry(freezer, added: '1'),
        ],
      );
      final draft = {
        split.id: const [
          PutAwayStorage(listId: freezer, amount: 1),
          PutAwayStorage(listId: fridge, amount: 1),
        ],
      };
      expect(changedPutAway([split], draft), isEmpty);
    });

    test('emptying an item sends it with no storages', () {
      final changed = changedPutAway([milk], {milk.id: const []});
      expect(changed.single.storages, isEmpty);
    });
  });
}
