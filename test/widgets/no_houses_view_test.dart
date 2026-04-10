import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/widgets/no_houses_view.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('renders icon, title, body, and create button', (tester) async {
    final controller = FakeHomeController();
    await tester.pumpWidget(wrapForTest(NoHousesView(controller: controller)));

    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.text('No houses yet.'), findsOneWidget);
    expect(find.textContaining('Houses are shared'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create house'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('tapping button opens create house dialog', (tester) async {
    final controller = FakeHomeController();
    await tester.pumpWidget(wrapForTest(NoHousesView(controller: controller)));

    await tester.tap(find.widgetWithText(FilledButton, 'Create house'));
    await tester.pumpAndSettle();

    // Dialog should contain the "House name" field label
    expect(find.text('House name'), findsOneWidget);
  });
}
