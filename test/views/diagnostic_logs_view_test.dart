import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/diagnostic_log.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry/views/settings/diagnostic_logs_view.dart';
import 'package:pantry/views/settings/settings_view.dart';

import '../helpers/test_app.dart';

void main() {
  final log = DiagnosticLog.instance;

  setUp(() async => log.debugReset());
  tearDown(() async => log.debugReset());

  testWidgets('settings offers the logs', (tester) async {
    await tester.pumpWidget(
      wrapForTest(
        ChangeNotifierProvider<PrefsService>.value(
          value: PrefsService.instance,
          child: const SettingsView(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(m.settings.diagnostics.title), findsOneWidget);
  });

  testWidgets('a wide window opens the logs beside the sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
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

    await tester.tap(find.text(m.settings.diagnostics.title));
    await tester.pumpAndSettle();

    expect(find.text(m.settings.diagnostics.body), findsOneWidget);
    // The sidebar row names it; the pane carries the actions itself.
    expect(find.text(m.settings.diagnostics.title), findsOneWidget);
    expect(find.byTooltip(m.common.copy), findsOneWidget);
  });

  testWidgets('entries show newest first, and can be cut to problems', (
    tester,
  ) async {
    log.info('http', 'GET /houses 200 (12 ms)');
    log.warning('sync', 'Holding checklistItem.toggle 1234abcd');

    await tester.pumpWidget(wrapForTest(const DiagnosticLogsView()));
    await tester.pumpAndSettle();

    final info = find.text('GET /houses 200 (12 ms)');
    final warning = find.text('Holding checklistItem.toggle 1234abcd');
    expect(info, findsOneWidget);
    expect(tester.getTopLeft(warning).dy, lessThan(tester.getTopLeft(info).dy));

    await tester.tap(find.text(m.settings.diagnostics.problemsOnly));
    await tester.pumpAndSettle();
    expect(info, findsNothing);
    expect(warning, findsOneWidget);
  });

  testWidgets('an empty log says so', (tester) async {
    await tester.pumpWidget(wrapForTest(const DiagnosticLogsView()));
    await tester.pumpAndSettle();

    expect(find.text(m.settings.diagnostics.empty), findsOneWidget);
  });
}
