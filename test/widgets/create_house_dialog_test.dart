import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/widgets/create_house_dialog.dart';

import '../helpers/fakes.dart';

void main() {
  Widget wrapped(CreateHouseDialog dialog) {
    return MaterialApp(
      home: Scaffold(body: Builder(builder: (_) => dialog)),
    );
  }

  testWidgets('renders title, name and description fields, save/cancel', (
    tester,
  ) async {
    final controller = FakeHomeController();
    await tester.pumpWidget(wrapped(CreateHouseDialog(controller: controller)));

    expect(find.text('Create house'), findsWidgets);
    expect(find.text('House name'), findsOneWidget);
    expect(find.text('Description (optional)'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
  });

  testWidgets('empty name prevents save (addHouse not called)', (tester) async {
    final controller = FakeHomeController();
    await tester.pumpWidget(wrapped(CreateHouseDialog(controller: controller)));

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(controller.lastAdded, isNull);
  });

  testWidgets('filled name triggers addHouse via controller', (tester) async {
    final controller = FakeHomeController();
    await tester.pumpWidget(wrapped(CreateHouseDialog(controller: controller)));

    await tester.enterText(
      find.widgetWithText(TextField, 'House name'),
      'Test Home',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(controller.lastAdded, isNotNull);
    expect(controller.lastAdded!.name, 'Test Home');
  });
}
