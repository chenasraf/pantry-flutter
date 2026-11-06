import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/list_kind.dart';
import 'package:pantry/views/checklists/item_compose_bar.dart';

import '../helpers/test_app.dart';

void main() {
  Future<void> pumpBar(WidgetTester tester, {ListKind? stockKind}) async {
    await tester.pumpWidget(
      wrapForTest(
        ItemComposeBar(
          key: const ValueKey('compose'),
          listName: 'Pantry',
          houseId: 1,
          listId: 1,
          stockKind: stockKind,
          categories: const [],
          initiallyFocused: true,
          onSubmit: (_) async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('switching to an inventory offers Stock instead of Quantity', (
    tester,
  ) async {
    await pumpBar(tester);
    expect(find.text(m.checklists.compose.chipQuantity), findsOneWidget);
    expect(find.text(m.stock.compose.chip), findsNothing);

    await pumpBar(tester, stockKind: ListKind.inventory);
    expect(find.text(m.checklists.compose.chipQuantity), findsNothing);
    expect(find.text(m.stock.compose.chip), findsOneWidget);

    await pumpBar(tester);
    expect(find.text(m.checklists.compose.chipQuantity), findsOneWidget);
    expect(find.text(m.stock.compose.chip), findsNothing);
  });
}
