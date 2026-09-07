import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/utils/price.dart';
import 'package:pantry/views/checklists/checklists_filter_bar.dart';

import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

/// Opening a filter dropdown must not throw the "PrimaryScrollController is
/// attached to more than one ScrollPosition" Scrollbar assertion: the menu's
/// scroll view must use its own controller, not the primary one the MenuAnchor
/// panel already claims.
void main() {
  testWidgets('opening a category filter dropdown does not double-attach the '
      'primary scroll controller', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final categories = [
      for (var i = 1; i <= 30; i++) makeCategory(id: i, name: 'Cat $i'),
    ];

    await tester.pumpWidget(
      wrapForTest(
        ChecklistsFiltersSection(
          categories: categories,
          selectedCategoryIds: const {},
          onToggleCategory: (_) {},
          onClearCategories: () {},
          showNoCategory: false,
          noCategorySelected: false,
          onToggleNoCategory: () {},
          showListFilter: false,
          lists: const [],
          selectedListIds: const {},
          onToggleList: (_) {},
          onClearLists: () {},
          showStoreFilter: false,
          stores: const [],
          selectedStoreIds: const {},
          onToggleStore: (_) {},
          onClearStores: () {},
          showNoStore: false,
          noStoreSelected: false,
          onToggleNoStore: () {},
          showLabelFilter: false,
          labels: const [],
          selectedLabelIds: const {},
          onToggleLabel: (_) {},
          onClearLabels: () {},
          showNoLabel: false,
          noLabelSelected: false,
          onToggleNoLabel: () {},
          showPriceFilter: false,
          priceFilter: PriceFilter.empty,
          onPriceFilterChanged: (_) {},
          view: 'list',
          onViewChanged: (_) {},
        ),
      ),
    );

    // Open the category filter dropdown (its MenuAnchor button).
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    debugDefaultTargetPlatformOverride = null;
  });
}
