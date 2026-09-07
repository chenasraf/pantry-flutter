import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pantry/views/checklists/item_compose_bar.dart';
import 'package:pantry/views/checklists/item_compose_chips.dart';

import '../helpers/test_app.dart';

void main() {
  Future<void> pumpBar(WidgetTester tester, {required bool onTop}) async {
    await tester.pumpWidget(
      wrapForTest(
        ItemComposeBar(
          listName: 'Groceries',
          houseId: 1,
          listId: 1,
          categories: const [],
          initiallyFocused: true,
          onTop: onTop,
          onSubmit: (_) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double chipRowTop(WidgetTester tester) =>
      tester.getTopLeft(find.byType(ChipRow)).dy;

  double inputTop(WidgetTester tester) =>
      tester.getTopLeft(find.byType(TextField)).dy;

  testWidgets('a bottom-anchored bar keeps its chips above the input', (
    tester,
  ) async {
    await pumpBar(tester, onTop: false);

    expect(chipRowTop(tester), lessThan(inputTop(tester)));
  });

  testWidgets('a top-anchored bar moves its chips below the input', (
    tester,
  ) async {
    await pumpBar(tester, onTop: true);

    expect(chipRowTop(tester), greaterThan(inputTop(tester)));
  });
}
