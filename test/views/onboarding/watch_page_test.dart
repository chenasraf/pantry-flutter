import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry/views/onboarding/onboarding_pages.dart';
import 'package:pantry/views/onboarding/pages/watch_page.dart';

void main() {
  testWidgets('renders the pitch, the demo and where to go next', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WatchOnboardingPage())),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(m.onboarding.watchTitle), findsOneWidget);
    expect(find.text(m.onboarding.watchBody), findsOneWidget);
    // The pointer names the real path, not a paraphrase of it.
    expect(
      find.text(
        m.onboarding.watchHowTo(m.settings.title, m.settings.watchSection),
      ),
      findsOneWidget,
    );
    // The list the demo works through.
    expect(find.text(m.onboarding.mockItemName), findsOneWidget);
    expect(find.text(m.onboarding.mockBulkItemThird), findsOneWidget);
    expect(find.text(m.onboarding.mockBulkItemFourth), findsOneWidget);
  });

  testWidgets('the demo ticks its way down the list without faulting', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WatchOnboardingPage())),
    );
    for (var frame = 0; frame < 60; frame++) {
      await tester.pump(const Duration(milliseconds: 110));
      expect(tester.takeException(), isNull, reason: 'frame $frame');
    }
  });

  test('the page is offered to Android only', () {
    const android = OnboardingAudience(
      isNewUser: false,
      isAndroid: true,
      isDesktop: false,
    );
    const iphone = OnboardingAudience(
      isNewUser: false,
      isAndroid: false,
      isDesktop: false,
    );
    final entry = kAppOnboardingPages['0.31.0']!.single;

    expect(entry.showWhen!(android), isTrue);
    expect(entry.showWhen!(iphone), isFalse);
  });
}
