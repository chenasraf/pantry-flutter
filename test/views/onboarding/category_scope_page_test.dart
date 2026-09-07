import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry/views/onboarding/pages/category_scope_page.dart';

void main() {
  testWidgets('renders the title, scope field, and both scope options', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CategoryScopeOnboardingPage())),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(m.onboarding.categoryScopeTitle), findsOneWidget);
    // The mock "List" selector is scoped to a sample list.
    expect(find.text(m.categories.list.toUpperCase()), findsOneWidget);
    // Both scope options are illustrated: global and single-list.
    expect(find.text(m.categories.globalList), findsOneWidget);
    expect(find.text(m.onboarding.categoryScopeGlobalCaption), findsOneWidget);
    expect(find.text(m.onboarding.categoryScopeScopedCaption), findsOneWidget);
  });
}
