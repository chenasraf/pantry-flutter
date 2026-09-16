import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry/views/onboarding/onboarding_pages.dart';
import 'package:pantry/views/onboarding/pages/join_trip_page.dart';

void main() {
  testWidgets('renders the pitch, the banner mock and what joining costs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: JoinTripOnboardingPage())),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(m.onboarding.joinTripTitle), findsOneWidget);
    expect(find.text(m.onboarding.joinTripBody), findsOneWidget);
    expect(find.text(m.onboarding.joinTripHow), findsOneWidget);

    // The mock says what the real banner says, down to the wording, so the
    // banner is recognised rather than read when it turns up.
    expect(
      find.text(
        m.shopping.bannerHousemateShoppingAt(
          m.onboarding.joinTripMockHousemate,
          m.onboarding.shoppingMockStoreActive,
        ),
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, m.shopping.join), findsOneWidget);
  });

  test('the page is offered to upgraders only, on every platform', () {
    const upgrader = OnboardingAudience(
      isNewUser: false,
      isAndroid: true,
      isDesktop: false,
    );
    const desktopUpgrader = OnboardingAudience(
      isNewUser: false,
      isAndroid: false,
      isDesktop: true,
    );
    // Someone whose house has no trips yet has nothing to weigh the offer
    // against.
    const newUser = OnboardingAudience(
      isNewUser: true,
      isAndroid: true,
      isDesktop: false,
    );
    final entry = kAppOnboardingPages['0.33.0']!.single;

    expect(entry.showWhen!(upgrader), isTrue);
    expect(entry.showWhen!(desktopUpgrader), isTrue);
    expect(entry.showWhen!(newUser), isFalse);
  });
}
