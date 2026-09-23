import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry/views/settings/settings_view.dart';

import '../helpers/test_app.dart';

void main() {
  Future<void> pumpSettings(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrapForTest(
        ChangeNotifierProvider<PrefsService>.value(
          value: PrefsService.instance,
          child: const SettingsView(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a wide window opens the first section beside the sections', (
    tester,
  ) async {
    await pumpSettings(tester, const Size(1400, 900));

    expect(find.text(m.settings.generalSection), findsOneWidget);
    expect(find.text(m.settings.interfaceSection), findsOneWidget);
    // General is on show without anything being picked first.
    expect(find.text(m.settings.language), findsOneWidget);
  });

  testWidgets('picking a section swaps what is beside them', (tester) async {
    await pumpSettings(tester, const Size(1400, 900));

    await tester.tap(find.text(m.settings.interfaceSection));
    await tester.pumpAndSettle();

    expect(find.text(m.settings.interfaceNavigationSection), findsOneWidget);
    expect(find.text(m.settings.language), findsNothing);
  });

  testWidgets('a narrow window keeps the sections a list of screens', (
    tester,
  ) async {
    await pumpSettings(tester, const Size(400, 800));

    expect(find.text(m.settings.generalSection), findsOneWidget);
    // Nothing is open beside the list; a section is a screen you go to.
    expect(find.text(m.settings.language), findsNothing);
  });
}
