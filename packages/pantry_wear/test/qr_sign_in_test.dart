import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_wear/src/pairing/qr_sign_in_page.dart';
import 'package:pantry_wear/src/pairing/wear_pairing_client.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// The QR sign-in path, as far as a test binding can follow it.
///
/// The code screen itself is a hardware check — whether a decoder reads it off
/// a watch is not a thing a widget test can answer, and the round trip needs a
/// real server and a real phone camera. What is pinned here is everything that
/// fails *silently*: a wakelock that outlives the screen holding it, a screen
/// that leaves the wearer with no way back from a mistyped address, and the
/// geometry of the card, which analyses clean whatever size it draws at.
///
/// A test binding answers every HTTPS request with 400, so the login flow can
/// only ever fail here — which is exactly what makes the failure path the half
/// worth testing off the wrist.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');

  late Directory dir;
  late _FakeWakelock wakelock;
  final storage = <String, String>{};

  setUp(() async {
    WearShape.markFrom(const ['round']);
    storage.clear();
    dir = await Directory.systemTemp.createTemp('wear_qr_test');
    wakelock = _FakeWakelock();
    WakelockPlusPlatformInterface.instance = wakelock;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(pathProvider, (call) async => dir.path);
    messenger.setMockMethodCallHandler(secureStorage, (call) async {
      final key = call.arguments['key'] as String? ?? '';
      return switch (call.method) {
        'read' => storage[key],
        'write' => storage[key] = call.arguments['value'] as String,
        'readAll' => Map<String, String>.from(storage),
        'delete' => storage.remove(key),
        _ => null,
      };
    });
  });

  tearDown(() async {
    await WearPairingClient.instance.debugReset();
    await AuthService.instance.logout(revoke: false);
    await dir.delete(recursive: true);
  });

  /// A watch-sized window, so the card is measured against watch geometry
  /// rather than the 800×600 a test window defaults to.
  void sizeToWatch(WidgetTester tester) {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// The page under a navigator, since leaving it is a route pop and the
  /// wakelock's release rides the page's own disposal.
  Future<void> pump(WidgetTester tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const QrSignInPage()),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('holds the screen awake, and lets go on the way out', (
    tester,
  ) async {
    await pump(tester);
    expect(
      wakelock.held,
      isTrue,
      reason:
          'the wearer has a phone in their other hand while the code is up and '
          'cannot flick their wrist, so a dimmed screen is a dead end',
    );

    Navigator.of(tester.element(find.byType(QrSignInPage))).pop();
    await tester.pumpAndSettle();
    expect(
      wakelock.held,
      isFalse,
      reason: 'a wakelock left on is a flat watch',
    );
  });

  testWidgets('a server it cannot reach leaves a way back to the address', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'cloud.example');
    await tester.tap(find.byKey(const ValueKey('show-qr-code')));
    await tester.pumpAndSettle();

    expect(find.text(m.wear.qrUnreachable), findsOneWidget);
    expect(
      find.byType(QrCodeCard),
      findsNothing,
      reason: 'a code nothing is polling for is a code that cannot be scanned',
    );

    await tester.tap(find.byKey(const ValueKey('qr-start-over')));
    await tester.pumpAndSettle();
    expect(
      find.byType(TextField),
      findsOneWidget,
      reason:
          'every failure this screen can report is one a corrected address '
          'would not produce, so start over is back to the field',
    );
  });

  testWidgets('the card is the inscribed square on round, the width on square', (
    tester,
  ) async {
    for (final (shape, expected) in [
      ('round', 450 / 1.414),
      ('square', 450.0),
    ]) {
      WearShape.markFrom([shape]);
      sizeToWatch(tester);
      await tester.pumpWidget(
        MaterialApp(
          // Keyed per shape: an identical const subtree is canonicalised and
          // returned unbuilt, so the second shape would be measured against
          // the first one's layout.
          home: Scaffold(
            body: QrCodeCard(
              key: ValueKey(shape),
              loginUrl: 'https://cloud.example',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = tester.getSize(find.byType(QrImageView));
      expect(
        card.width,
        closeTo(expected, 0.5),
        reason:
            'a round screen can only show the square inscribed in it, and the '
            'corners of a QR are exactly what a decoder needs',
      );
      expect(card.height, closeTo(expected, 0.5));
    }
  });

  testWidgets('the card names no host beside the code', (tester) async {
    sizeToWatch(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: QrCodeCard(loginUrl: 'https://cloud.example')),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byType(Text),
      findsNothing,
      reason:
          'there is no way here without having typed that address on the '
          'previous screen, so a caption costs width and buys nothing',
    );
  });

  test(
    'a sign-in made on the watch stops the phone from being asked',
    () async {
      final client = WearPairingClient.instance;
      await AuthService.instance.adoptCredentials(
        const NextcloudCredentials(
          serverUrl: 'https://cloud.example',
          loginName: 'ada',
          appPassword: 'secret',
        ),
      );

      await client.adoptLocalSignIn();

      expect(client.state, WearSetupState.ready);
    },
  );
}

/// Stands in for the platform's wakelock, which has no host under a test
/// binding — so the page's acquire and release are observable rather than
/// merely attempted.
class _FakeWakelock extends WakelockPlusPlatformInterface {
  bool held = false;

  @override
  Future<void> toggle({required bool enable}) async => held = enable;

  @override
  Future<bool> get enabled async => held;
}
