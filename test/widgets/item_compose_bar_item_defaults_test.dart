import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/item_defaults.dart';
import 'package:pantry/views/checklists/item_compose_bar.dart';

import '../helpers/test_app.dart';

ItemDefaults _defaults(Map<String, dynamic> json) =>
    ItemDefaults.fromJson(json);

void main() {
  late List<ComposeSubmission> submitted;
  late List<(int, ItemDefaultsPatch)> writeBacks;

  setUp(() {
    submitted = [];
    writeBacks = [];
  });

  /// The bar under a host that, like the checklists controller, applies each
  /// write-back to the list it hands back down.
  Widget bar(ItemDefaults initial) {
    var defaults = initial;
    return wrapForTest(
      StatefulBuilder(
        builder: (context, setState) => ItemComposeBar(
          listName: 'Groceries',
          houseId: 1,
          listId: 7,
          itemDefaults: defaults,
          onItemDefaultsUsed: (listId, patch) {
            writeBacks.add((listId, patch));
            setState(() => defaults = defaults.applyPatch(patch));
          },
          categories: const [],
          initiallyFocused: true,
          onSubmit: (s) async {
            submitted.add(s);
            return true;
          },
        ),
      ),
    );
  }

  Future<void> addItem(WidgetTester tester, String name) async {
    await tester.enterText(find.byType(TextField).first, name);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();
  }

  Future<void> pickStaple(WidgetTester tester) async {
    await tester.tap(find.text(m.checklists.itemTypes.onceTime));
    await tester.pumpAndSettle();
    await tester.tap(find.text(m.checklists.itemTypes.staple).last);
    await tester.pumpAndSettle();
  }

  testWidgets('pinned defaults pre-fill every item', (tester) async {
    await tester.pumpWidget(
      bar(
        _defaults({
          'recurrence': {
            'mode': 'fixed',
            'value': {'kind': 'once'},
          },
          'category': {'mode': 'fixed', 'value': 3},
          'stores': {
            'mode': 'fixed',
            'value': [4],
          },
          'quantity': {'mode': 'fixed', 'value': '2'},
        }),
      ),
    );
    await tester.pumpAndSettle();

    await addItem(tester, 'Milk');
    await addItem(tester, 'Eggs');

    for (final s in submitted) {
      expect(s.categoryId, 3);
      expect(s.storeIds, [4]);
      expect(s.quantity, '2');
      expect(s.deleteOnDone, isTrue);
    }
    // Nothing follows the last item, so nothing is written back.
    expect(writeBacks, isEmpty);
  });

  testWidgets('a remembering key writes back what changed and keeps it', (
    tester,
  ) async {
    await tester.pumpWidget(
      bar(
        _defaults({
          'recurrence': {
            'mode': 'remember',
            'value': {'kind': 'once'},
          },
          'category': {'mode': 'remember', 'value': 3},
        }),
      ),
    );
    await tester.pumpAndSettle();

    await pickStaple(tester);
    await addItem(tester, 'Salt');

    final (listId, patch) = writeBacks.single;
    expect(listId, 7);
    // The category was left as remembered, so only the recurrence goes back.
    expect(patch.toJson(), {
      'recurrence': {
        'value': {'kind': 'none', 'rrule': null, 'repeatFromCompletion': false},
      },
    });

    // The next item starts from what was just remembered, before any write-back
    // reaches the host.
    await addItem(tester, 'Pepper');
    expect(submitted.last.deleteOnDone, isFalse);
    expect(submitted.last.categoryId, 3);
    expect(writeBacks, hasLength(1));
  });

  testWidgets('a remembered value landing does not re-seed the draft', (
    tester,
  ) async {
    final first = _defaults({
      'recurrence': {
        'mode': 'remember',
        'value': {'kind': 'once'},
      },
      'category': {'mode': 'remember', 'value': 3},
    });
    await tester.pumpWidget(bar(first));
    await tester.pumpAndSettle();
    await pickStaple(tester);

    await tester.pumpWidget(
      bar(
        first.applyPatch(
          const ItemDefaultsPatch(
            entries: {'category': ItemDefaultPatchEntry.value(9)},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await addItem(tester, 'Salt');
    expect(submitted.single.deleteOnDone, isFalse);
    expect(submitted.single.categoryId, 3);
  });

  testWidgets('an editor changing the defaults re-seeds the draft', (
    tester,
  ) async {
    final first = _defaults({
      'recurrence': {
        'mode': 'remember',
        'value': {'kind': 'once'},
      },
    });
    await tester.pumpWidget(bar(first));
    await tester.pumpAndSettle();
    await pickStaple(tester);

    await tester.pumpWidget(
      bar(
        first.applyPatch(
          const ItemDefaultsPatch(
            entries: {'quantity': ItemDefaultPatchEntry.mode(.fixed, '3')},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await addItem(tester, 'Salt');
    expect(submitted.single.quantity, '3');
    expect(submitted.single.deleteOnDone, isTrue);
  });
}
