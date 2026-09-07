import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/widgets/session_expired_banner.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';

import '../helpers/test_app.dart';

void main() {
  final auth = AuthService.instance;

  tearDown(() => auth.reportAuthorized());

  Widget banner({VoidCallback? onSignIn}) => wrapForTest(
    SessionExpiredBanner(onSignIn: onSignIn ?? () {}, child: const Text('app')),
  );

  testWidgets('draws nothing while the credential is accepted', (tester) async {
    await tester.pumpWidget(banner());

    expect(find.text('app'), findsOneWidget);
    expect(find.text(m.common.sessionExpiredTitle), findsNothing);
  });

  testWidgets('draws above the app once the state is set', (tester) async {
    await tester.pumpWidget(banner());
    auth.isUnauthorized.value = true;
    await tester.pump();

    expect(find.text(m.common.sessionExpiredTitle), findsOneWidget);
    expect(find.text('app'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(m.common.sessionExpiredTitle)).dy,
      lessThan(tester.getTopLeft(find.text('app')).dy),
    );
  });

  testWidgets('the action fires', (tester) async {
    var taps = 0;
    await tester.pumpWidget(banner(onSignIn: () => taps++));
    auth.isUnauthorized.value = true;
    await tester.pump();

    await tester.tap(find.text(m.common.signInAgain));
    expect(taps, 1);
  });

  testWidgets('stays hidden while suppressed', (tester) async {
    auth.isUnauthorized.value = true;
    await tester.pumpWidget(
      wrapForTest(
        SessionExpiredBanner(
          suppressed: true,
          onSignIn: () {},
          child: const Text('app'),
        ),
      ),
    );

    expect(find.text(m.common.sessionExpiredTitle), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });

  testWidgets('clears itself when the credential is accepted again', (
    tester,
  ) async {
    await tester.pumpWidget(banner());
    auth.isUnauthorized.value = true;
    await tester.pump();
    expect(find.text(m.common.sessionExpiredTitle), findsOneWidget);

    auth.reportAuthorized();
    await tester.pump();
    expect(find.text(m.common.sessionExpiredTitle), findsNothing);
  });
}
