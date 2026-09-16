import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/views/shopping/shopping_item_picker_view.dart';

import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

// The picker decides which items a trip covers. Everything it does not hand
// back is shopped, so the two things that matter are that a fresh open picks
// everything and that backing out cannot change the plan.

void main() {
  final dairy = makeCategory(id: 1, name: 'Dairy', sortOrder: 0);
  final fruits = makeCategory(id: 2, name: 'Fruits', sortOrder: 1);
  final categories = {dairy.id: dairy, fruits.id: fruits};

  final items = [
    makeListItem(id: 1, name: 'Milk', categoryId: dairy.id),
    makeListItem(id: 2, name: 'Butter', categoryId: dairy.id),
    makeListItem(id: 3, name: 'Apples', categoryId: fruits.id),
  ];

  /// Collects what the picker hands back: [excluded] once it closes, still
  /// [open] until then.
  final outcome = <String, Object?>{};

  Future<void> openPicker(
    WidgetTester tester, {
    Set<int> excluded = const {},
  }) async {
    outcome['result'] = 'open';
    await tester.pumpWidget(
      wrapForTest(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              outcome['result'] = await pickShoppingItems(
                context,
                items: items,
                categories: categories,
                excludedItemIds: excluded,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Object? result() => outcome['result'];

  bool isPicked(WidgetTester tester, String label) {
    final tile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, label),
    );
    return tile.value ?? false;
  }

  Future<void> tapItem(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(CheckboxListTile, label));
    await tester.pump();
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('everything is picked when the picker first opens', (
    tester,
  ) async {
    await openPicker(tester);

    expect(isPicked(tester, 'Milk'), isTrue);
    expect(isPicked(tester, 'Butter'), isTrue);
    expect(isPicked(tester, 'Apples'), isTrue);
    expect(find.text('3 of 3 items'), findsOneWidget);
  });

  testWidgets('the bulk actions fit a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await openPicker(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Invert'), findsOneWidget);
  });

  testWidgets('items already off the plan come back unpicked', (tester) async {
    await openPicker(tester, excluded: {2});

    expect(isPicked(tester, 'Milk'), isTrue);
    expect(isPicked(tester, 'Butter'), isFalse);
    expect(find.text('2 of 3 items'), findsOneWidget);
  });

  testWidgets('groups items under their category, in category order', (
    tester,
  ) async {
    await openPicker(tester);

    final labels = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .where((d) => d == 'Dairy' || d == 'Fruits')
        .toList();
    expect(labels, ['Dairy', 'Fruits']);
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets('Done hands back the items left unpicked', (tester) async {
    await openPicker(tester);

    await tapItem(tester, 'Apples');
    await tapButton(tester, 'Done');

    expect(result(), {3});
  });

  testWidgets('backing out leaves the plan untouched', (tester) async {
    await openPicker(tester);

    await tapItem(tester, 'Milk');
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(result(), isNull);
  });

  testWidgets('tapping anywhere on a category takes its whole block off', (
    tester,
  ) async {
    await openPicker(tester);

    await tester.tap(find.text('Dairy'));
    await tester.pump();

    expect(isPicked(tester, 'Milk'), isFalse);
    expect(isPicked(tester, 'Butter'), isFalse);
    expect(isPicked(tester, 'Apples'), isTrue);

    await tapButton(tester, 'Done');
    expect(result(), {1, 2});
  });

  testWidgets('None then Invert picks everything again', (tester) async {
    await openPicker(tester);

    await tapButton(tester, 'Select none');
    expect(find.text('Pick at least one item to shop.'), findsOneWidget);

    await tapButton(tester, 'Invert');
    expect(find.text('3 of 3 items'), findsOneWidget);
  });

  testWidgets('Done is refused while nothing is picked', (tester) async {
    await openPicker(tester);

    await tapButton(tester, 'Select none');
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Done'))
          .enabled,
      isFalse,
    );

    await tapButton(tester, 'Done');
    expect(result(), 'open');

    await tapItem(tester, 'Milk');
    await tapButton(tester, 'Done');
    expect(result(), {2, 3});
  });

  testWidgets('Invert swaps which items the trip covers', (tester) async {
    await openPicker(tester, excluded: {1});

    await tapButton(tester, 'Invert');

    expect(isPicked(tester, 'Milk'), isTrue);
    expect(isPicked(tester, 'Butter'), isFalse);
    expect(isPicked(tester, 'Apples'), isFalse);
  });

  testWidgets('an exclusion from an unchecked list survives the picker', (
    tester,
  ) async {
    // 99 is on a list the shopper unchecked, so it is not offered here — and
    // re-checking that list has to restore the choice already made about it.
    await openPicker(tester, excluded: {1, 99});

    await tapButton(tester, 'Invert');
    await tapButton(tester, 'Done');

    expect(result(), {2, 3, 99});
  });
}
