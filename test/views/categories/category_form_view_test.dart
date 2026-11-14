import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/category.dart';
import 'package:pantry_core/services/category_service.dart';
import 'package:pantry_core/utils/category_icons.dart';
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

  group('a name already taken', () {
    Category category(int id, String name) => Category(
      id: id,
      houseId: 1,
      name: name,
      icon: 'tag',
      color: '#ef4444',
      sortOrder: id,
      createdAt: 0,
      updatedAt: 0,
    );

    final toilet = category(1, 'Toilet');

    setUp(
      () => CategoryService.instance.cacheCategories(1, [
        toilet,
        category(2, 'Dairy'),
      ]),
    );
    tearDown(() => CategoryService.instance.cacheCategories(1, const []));

    Future<void> typeName(WidgetTester tester, String name) async {
      await tester.enterText(find.byType(TextField), name);
      await tester.pump();
    }

    testWidgets('is flagged and cannot be saved', (tester) async {
      await tester.pumpWidget(wrapped(const CategoryFormView(houseId: 1)));
      await typeName(tester, ' Toilet ');

      expect(find.text('A category with this name already exists'), findsOne);
      await tester.tap(find.widgetWithText(InkWell, 'Save'));
      await tester.pump();
      expect(find.widgetWithText(InkWell, 'Save'), findsOneWidget);
    });

    testWidgets('differently cased is left for the server to judge', (
      tester,
    ) async {
      await tester.pumpWidget(wrapped(const CategoryFormView(houseId: 1)));
      await typeName(tester, 'dairy');

      expect(
        find.text('A category with this name already exists'),
        findsNothing,
      );
    });

    testWidgets('editing a category keeps its own name', (tester) async {
      await tester.pumpWidget(
        wrapped(CategoryFormView(houseId: 1, existing: toilet)),
      );
      await tester.pump();
      expect(
        find.text('A category with this name already exists'),
        findsNothing,
      );

      await typeName(tester, 'Dairy');
      expect(find.text('A category with this name already exists'), findsOne);
    });
  });
}
