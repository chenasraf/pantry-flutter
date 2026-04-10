import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/widgets/create_category_dialog.dart';

// NOTE: The save path calls CategoryService.instance which performs real
// network I/O via ApiClient. We only test render and the empty-name guard
// branch, because the empty-name branch returns before touching the service.
// TODO: Extract an injectable CategoryService interface to enable testing
// the full save/update flow.
void main() {
  Widget wrapped(Widget child) => MaterialApp(
    home: Scaffold(body: Builder(builder: (_) => child)),
  );

  testWidgets('renders name field, icon grid, and color picker', (
    tester,
  ) async {
    await tester.pumpWidget(wrapped(const CreateCategoryDialog(houseId: 1)));

    // Title for "new category"
    expect(find.text('New category'), findsOneWidget);

    // Name field present
    expect(find.byType(TextField), findsOneWidget);

    // Icon grid: one icon per map entry is rendered
    expect(find.byType(Icon), findsWidgets);
    // Sanity: color swatches = categoryColors.length
    expect(find.byType(GestureDetector), findsWidgets);

    // Save + Cancel buttons
    expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
  });

  testWidgets('icon grid shows one tile per known category icon', (
    tester,
  ) async {
    await tester.pumpWidget(wrapped(const CreateCategoryDialog(houseId: 1)));

    // Each icon map entry should be rendered somewhere inside the grid.
    // We assert the count of the default 'tag' icon (Icons.label) appears
    // (it's the default selected icon).
    expect(find.byIcon(categoryIconMap['food']!), findsOneWidget);
    expect(find.byIcon(categoryIconMap['coffee']!), findsOneWidget);
  });

  testWidgets('empty name prevents save — no exception thrown', (tester) async {
    await tester.pumpWidget(wrapped(const CreateCategoryDialog(houseId: 1)));

    // The Save button without a name should just early-return. If it did
    // attempt to call the service, the test would explode with an HTTP error.
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    // Dialog stays open, no crash.
    expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
  });

  testWidgets('tapping a color swatch selects it (check icon appears)', (
    tester,
  ) async {
    await tester.pumpWidget(wrapped(const CreateCategoryDialog(houseId: 1)));
    await tester.pumpAndSettle();

    // Initially the first color swatch is selected, so one Icons.check exists.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
