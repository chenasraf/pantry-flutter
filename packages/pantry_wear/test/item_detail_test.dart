import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/checklists/item_detail_page.dart';
import 'package:pantry_wear/src/checklists/item_image.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/image_route.dart';

import 'wear_fixtures.dart';

/// No credentials are installed, so every preview fails to resolve — which is
/// the offline detail page, and the state the photo has to keep its slot in.
void main() {
  setUp(() => WearShape.markFrom(['round']));

  Future<void> pump(WidgetTester tester, ListItem item) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ChecklistsController.seeded(
      houseId: 1,
      list: testList(),
      items: [item],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ItemDetailPage(item: item, controller: controller),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an item with a photo leads with it, and opens it full screen', (
    tester,
  ) async {
    await pump(
      tester,
      testItem(id: 1, name: 'Olive oil', imageFileId: 12, imageUploadedBy: 'a'),
    );

    expect(find.byType(ItemImage), findsOneWidget);
    // Above what the page says about the item, not among it.
    expect(
      tester.getCenter(find.byType(ItemImage)).dy,
      lessThan(tester.getCenter(find.text('Olive oil')).dy),
    );

    await tester.tap(find.byType(ItemImage));
    await tester.pumpAndSettle();

    expect(find.byType(ImageRoute), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an item without one starts at its name', (tester) async {
    await pump(tester, testItem(id: 1, name: 'Olive oil'));

    expect(find.byType(ItemImage), findsNothing);
    expect(find.text('Olive oil'), findsOneWidget);
  });
}
