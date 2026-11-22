import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/onboarding/onboarding_pages.dart';
import 'package:pantry/views/onboarding/pages/smart_input_page.dart';

import '../../helpers/test_app.dart';

void main() {
  void seedVersion(String version) => ServerVersionService.instance.debugSeed(
    pantryVersion: Version.parse(version),
  );

  tearDown(() => ServerVersionService.instance.debugSeed());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      wrapForTest(
        const SingleChildScrollView(child: SmartInputOnboardingPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('a server with item memory shows the amount and category', (
    tester,
  ) async {
    seedVersion('0.40.0');
    await pumpPage(tester);

    final ob = m.onboarding;
    expect(find.text(ob.smartInputTitle), findsOneWidget);
    expect(find.text(ob.smartInputMockTyped), findsOneWidget);
    expect(find.text(ob.smartInputMockAmount), findsOneWidget);
    expect(find.text(ob.smartInputMockCategory), findsOneWidget);
    expect(
      find.text(
        ob.smartInputHow(
          m.settings.title,
          m.settings.interfaceSection,
          m.settings.smartItemInput,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(ob.smartInputMemoryNote('0.40.0')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an older server shows the amount only, with a note', (
    tester,
  ) async {
    seedVersion('0.39.0');
    await pumpPage(tester);

    final ob = m.onboarding;
    expect(find.text(ob.smartInputMockAmount), findsOneWidget);
    expect(find.text(ob.smartInputMockCategory), findsNothing);
    expect(find.text(ob.smartInputMemoryNote('0.40.0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('smart input reaches upgraders only', () {
    const upgrader = OnboardingAudience(
      isNewUser: false,
      isAndroid: false,
      isDesktop: true,
    );
    const newUser = OnboardingAudience(
      isNewUser: true,
      isAndroid: true,
      isDesktop: false,
    );
    final [smartInput] = kAppOnboardingPages['0.40.0']!;

    expect(smartInput.showWhen!(upgrader), isTrue);
    expect(smartInput.showWhen!(newUser), isFalse);
  });
}
