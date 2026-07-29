import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/views/checklists/barcode_attribution.dart';

void main() {
  testWidgets('renders the disclaimer with an Open Food Facts link', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BarcodeAttribution())),
    );

    // The link label and the surrounding sentence render as one rich text.
    expect(find.textContaining('Open Food Facts'), findsOneWidget);
    expect(find.textContaining('does not own or control'), findsOneWidget);
    // The private-use split markers must never leak into the rendered text.
    expect(find.textContaining('\u{E000}'), findsNothing);
    expect(find.textContaining('\u{E001}'), findsNothing);
  });
}
