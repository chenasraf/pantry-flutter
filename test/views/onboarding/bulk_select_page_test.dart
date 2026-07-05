import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/views/onboarding/pages/bulk_select_page.dart';

void main() {
  testWidgets('renders the title and the group-action bar labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BulkSelectOnboardingPage())),
    );
    // Advance one animation frame (the page loops forever, so never settle).
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(m.onboarding.bulkSelectTitle), findsOneWidget);
    // The demo reuses the live group-action labels.
    expect(find.text(m.checklists.batch.move), findsOneWidget);
    expect(find.text(m.checklists.batch.copy), findsOneWidget);
    expect(find.text(m.checklists.batch.category), findsOneWidget);
    expect(find.text(m.checklists.batch.delete), findsOneWidget);
  });
}
