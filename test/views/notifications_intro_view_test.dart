import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry/views/notifications_intro/notifications_intro_view.dart';
import 'package:pantry/views/onboarding/onboarding_view.dart';

void main() {
  testWidgets('caps its content at the onboarding reading width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: NotificationsIntroView(onDone: () {})),
    );

    final button = tester.getSize(find.byType(FilledButton));
    expect(button.width, lessThanOrEqualTo(kOnboardingPageMaxWidth));
    expect(find.text(m.notificationsIntro.title), findsOneWidget);
  });

  testWidgets('fills a phone-width window', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: NotificationsIntroView(onDone: () {})),
    );

    expect(tester.takeException(), isNull);
    // The window is narrower than the cap, so the page spends all of it bar
    // its own padding.
    expect(tester.getSize(find.byType(FilledButton)).width, 360 - 64);
  });
}
