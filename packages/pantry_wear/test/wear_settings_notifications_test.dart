import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_wear/src/account/wear_settings_page.dart';
import 'package:pantry_wear/src/wear_shape.dart';

/// The settings row that carries the notification grant.
///
/// An ungranted watch posts nothing and says nothing — the live-trip chip
/// simply never appears, with no error anywhere to find — so this row is the
/// only place a wearer can see why, which makes what it says and when it
/// re-reads it the whole of its job.
import 'wear_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const host = MethodChannel('dev.casraf.pantry/wear_host');
  final calls = <MethodCall>[];
  var enabled = true;

  setUp(() {
    WearShape.markFrom(['round']);
    calls.clear();
    enabled = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(host, (call) async {
          calls.add(call);
          return switch (call.method) {
            'notificationsEnabled' => enabled,
            'hasRotary' => true,
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(host, null);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: WearSettingsPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('a blocked watch says so', (tester) async {
    enabled = false;
    await pump(tester);

    expect(find.text(m.wear.notificationsBlocked), findsOneWidget);
  });

  testWidgets('a grant made on the system screen is read on resume', (
    tester,
  ) async {
    enabled = false;
    await pump(tester);
    expect(find.text(m.wear.notificationsBlocked), findsOneWidget);

    // The wearer left for the system screen and granted it there. Nothing
    // Flutter-shaped was pushed or popped, so the only thing that can tell this
    // page is coming back to the foreground.
    enabled = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text(m.wear.notificationsAllowed), findsOneWidget);
  });

  testWidgets('the row opens the system screen rather than prompting', (
    tester,
  ) async {
    await pump(tester);
    calls.clear();

    await tester.tap(await revealRow(tester, m.wear.notifications));
    await tester.pumpAndSettle();

    // Android suppresses the prompt after a refusal, so a row that prompted
    // would do different things on two identical taps — and a prompt can only
    // ever grant, never take a grant back.
    expect(calls.map((c) => c.method), contains('openNotificationSettings'));
    expect(calls.map((c) => c.method), isNot(contains('requestNotifications')));
  });
}
