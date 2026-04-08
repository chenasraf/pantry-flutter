import 'package:flutter_test/flutter_test.dart';

import 'package:pantry/main.dart';

void main() {
  testWidgets('App renders login view', (WidgetTester tester) async {
    await tester.pumpWidget(const PantryApp());
    expect(find.text('Pantry'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
  });
}
