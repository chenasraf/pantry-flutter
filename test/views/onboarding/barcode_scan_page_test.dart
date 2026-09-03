import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry/views/onboarding/pages/barcode_scan_page.dart';

void main() {
  testWidgets('renders the title, scan affordance, and mock result', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BarcodeScanOnboardingPage())),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(m.onboarding.barcodeScanTitle), findsOneWidget);
    // The mocked input bar calls out the scan button…
    expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    // …and the result card shows what a scan fills in.
    expect(find.text(m.onboarding.barcodeScanMockName), findsOneWidget);
    expect(find.text(m.onboarding.barcodeScanMockCategory), findsOneWidget);
  });
}
