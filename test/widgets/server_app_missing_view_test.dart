import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/widgets/server_app_missing_view.dart';

import '../helpers/test_app.dart';

// NOTE: ServerAppMissingView reads AuthService.instance.credentials
// for building the target URL. Since credentials are null by default in a
// fresh test process, serverUrl resolves to '' which is fine for rendering
// assertions. We do NOT test the launch buttons because url_launcher
// requires platform channels.
void main() {
  testWidgets('renders title, body, buttons, and retry', (tester) async {
    await tester.pumpWidget(wrapForTest(ServerAppMissingView(onRetry: () {})));

    expect(find.byIcon(Icons.extension_off_outlined), findsOneWidget);
    expect(find.text('Pantry is not installed'), findsOneWidget);
    expect(find.textContaining('client for the Pantry app'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Open Nextcloud apps'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Learn more'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
  });

  testWidgets('tapping retry calls callback', (tester) async {
    var called = 0;
    await tester.pumpWidget(
      wrapForTest(ServerAppMissingView(onRetry: () => called++)),
    );

    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    await tester.pump();

    expect(called, 1);
  });
}
