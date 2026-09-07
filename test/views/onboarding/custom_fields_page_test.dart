import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/custom_field.dart';
import 'package:pantry_core/utils/field_type_icons.dart';
import 'package:pantry/views/onboarding/pages/custom_fields_page.dart';

void main() {
  testWidgets('renders the title, the mock tile, and every field type', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CustomFieldsOnboardingPage())),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(m.onboarding.customFieldsTitle), findsOneWidget);
    // The mock tile carries the same header as the real one on an item.
    expect(find.text(m.customFields.manageTitle.toUpperCase()), findsOneWidget);
    // Both sample fields show a name and a value.
    expect(find.text(m.onboarding.customFieldsMockExpiry), findsOneWidget);
    expect(find.text(m.onboarding.customFieldsMockExpiryValue), findsOneWidget);
    expect(find.text(m.onboarding.customFieldsMockAisle), findsOneWidget);
    expect(find.text(m.onboarding.customFieldsMockAisleValue), findsOneWidget);
    // All five types are pitched.
    for (final type in kFieldTypesInOrder) {
      expect(find.text(fieldTypeLabel(type)), findsOneWidget);
    }
    expect(find.byType(Icon), findsNWidgets(kFieldTypesInOrder.length + 2));
  });

  testWidgets('the select type is illustrated by a filled sample row', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CustomFieldsOnboardingPage())),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // The date row and the type chip share the date icon; the aisle row adds
    // the select one, so each sample row is drawn with its own type's icon.
    expect(find.byIcon(fieldTypeIcon(FieldType.date)), findsNWidgets(2));
    expect(find.byIcon(fieldTypeIcon(FieldType.select)), findsNWidgets(2));
  });
}
