import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/store.dart';
import 'package:pantry/views/checklists/item_stores_chip.dart';

import '../helpers/test_app.dart';

Store _store(int id, String name) => Store(
  id: id,
  houseId: 1,
  name: name,
  icon: 'cart',
  color: '#2196F3',
  createdAt: 0,
  updatedAt: 0,
);

void main() {
  testWidgets('one store shows its name', (tester) async {
    await tester.pumpWidget(
      wrapForTest(ItemStoresChip(stores: [_store(1, 'Supermarket')])),
    );
    expect(find.text('Supermarket'), findsOneWidget);
  });

  testWidgets('several stores show a count that lists them', (tester) async {
    await tester.pumpWidget(
      wrapForTest(
        ItemStoresChip(
          stores: [
            _store(1, 'Supermarket'),
            _store(2, 'Hardware'),
            _store(3, 'Bakery'),
          ],
        ),
      ),
    );
    expect(find.text('3 stores'), findsOneWidget);
    expect(find.text('Hardware'), findsNothing);

    await tester.tap(find.text('3 stores'));
    await tester.pumpAndSettle();

    expect(find.text('Supermarket'), findsOneWidget);
    expect(find.text('Hardware'), findsOneWidget);
    expect(find.text('Bakery'), findsOneWidget);

    await tester.tap(find.text('Hardware'));
    await tester.pumpAndSettle();

    // The list closes and that store's details open in its place.
    expect(find.text('Supermarket'), findsNothing);
    expect(find.text('Hardware'), findsOneWidget);
  });
}
