import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry/views/onboarding/onboarding_pages.dart';
import 'package:pantry/views/onboarding/pages/inventory_page.dart';
import 'package:pantry/views/onboarding/pages/templates_page.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('the inventory page shows low, expiring and full stock', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapForTest(
        const SingleChildScrollView(child: InventoryOnboardingPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final ob = m.onboarding;
    expect(find.text(ob.inventoryTitle), findsOneWidget);
    expect(find.text(ob.inventoryHow), findsOneWidget);
    expect(find.text(ob.inventoryMockEggs), findsOneWidget);
    // The mock reads its chips from the same rules a real row does.
    expect(find.text(m.stock.lowBuy('9')), findsOneWidget);
    expect(find.text(m.stock.expiresTomorrowBuy('2')), findsOneWidget);
    expect(find.text(m.stock.full), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the templates page shows suggestions from a template', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapForTest(
        const SingleChildScrollView(child: TemplatesOnboardingPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final ob = m.onboarding;
    expect(find.text(ob.templateTitle), findsOneWidget);
    expect(find.text(ob.templateMockFirst), findsOneWidget);
    expect(
      find.text(m.templates.fromTemplates(ob.templateMockName)),
      findsNWidgets(2),
    );
    expect(find.text(ob.templateHow(m.templates.applyToList)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('inventories reach everyone, templates upgraders only', () {
    const upgrader = OnboardingAudience(
      isNewUser: false,
      isAndroid: true,
      isDesktop: false,
    );
    const newUser = OnboardingAudience(
      isNewUser: true,
      isAndroid: true,
      isDesktop: false,
    );
    final entries = kAppOnboardingPages['0.38.0']!;

    expect(entries, hasLength(2));
    final [inventory, templates] = entries;
    expect(inventory.showWhen, isNull);
    expect(templates.showWhen!(upgrader), isTrue);
    expect(templates.showWhen!(newUser), isFalse);
  });
}
