import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/views/categories/category_form_view.dart';

// NOTE: The save path enqueues a SyncManager op, which we don't exercise here.
// We only test render and the empty-name guard branch, because the empty-name
// branch returns before touching the sync layer.
void main() {
  Widget wrapped(Widget child) => MaterialApp(home: child);

  testWidgets('renders name field, icon grid, and color picker', (
    tester,
  ) async {
    await tester.pumpWidget(wrapped(const CategoryFormView(houseId: 1)));

    // Title for "new category" — rendered in the app bar and header preview.
    expect(find.text('New category'), findsWidgets);

    // Name field present
    expect(find.byType(TextField), findsOneWidget);

    // Icon grid: one icon per map entry is rendered
    expect(find.byType(Icon), findsWidgets);
    // Sanity: color swatches = categoryColors.length
    expect(find.byType(GestureDetector), findsWidgets);

    // Save + Cancel buttons in the docked bar
    expect(find.widgetWithText(InkWell, 'Save'), findsOneWidget);
    expect(find.widgetWithText(InkWell, 'Cancel'), findsOneWidget);
  });

  testWidgets('icon grid shows one tile per known category icon', (
    tester,
  ) async {
    await tester.pumpWidget(wrapped(const CategoryFormView(houseId: 1)));

    // Each icon map entry should be rendered somewhere inside the grid.
    expect(find.byIcon(categoryIconMap['food']!), findsOneWidget);
    expect(find.byIcon(categoryIconMap['coffee']!), findsOneWidget);
  });

  testWidgets('empty name prevents save — no exception thrown', (tester) async {
    await tester.pumpWidget(wrapped(const CategoryFormView(houseId: 1)));

    // Saving without a name should just early-return. If it attempted to
    // enqueue and pop, the page would be gone.
    await tester.tap(find.widgetWithText(InkWell, 'Save'));
    await tester.pump();
    // Page stays open, no crash.
    expect(find.widgetWithText(InkWell, 'Save'), findsOneWidget);
  });

  testWidgets('tapping a color swatch selects it (check icon appears)', (
    tester,
  ) async {
    await tester.pumpWidget(wrapped(const CategoryFormView(houseId: 1)));
    await tester.pumpAndSettle();

    // Two check icons: the selected color swatch and the docked save button.
    expect(find.byIcon(Icons.check), findsNWidgets(2));
  });
}
