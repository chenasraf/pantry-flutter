import 'package:flutter_test/flutter_test.dart';

import 'package:pantry/main.dart';
import 'package:pantry/views/login/login_view.dart';

void main() {
  testWidgets('App renders login view', (WidgetTester tester) async {
    await tester.pumpWidget(const PantryApp());
    // Scoped to the login view: the macOS title bar above the app names it too.
    expect(
      find.descendant(
        of: find.byType(LoginView),
        matching: find.text('Pantry'),
      ),
      findsOneWidget,
    );
    expect(find.text('Connect'), findsOneWidget);
  });
}
