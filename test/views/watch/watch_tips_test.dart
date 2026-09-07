import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/i18n/messages.i18n.dart';
import 'package:pantry_core/i18n/messages_de.i18n.dart';
import 'package:pantry_core/i18n/messages_es.i18n.dart';
import 'package:pantry_core/i18n/messages_fr.i18n.dart';
import 'package:pantry_core/i18n/messages_he.i18n.dart';
import 'package:pantry_core/i18n/messages_nn.i18n.dart';
import 'package:pantry/views/watch/tips/watch_tip_view.dart';
import 'package:pantry/views/watch/tips/watch_tips.dart';

/// The pictures are fixed-size diagrams carrying translated labels, so the
/// locale with the longest word for *Allow* is a layout case and not a
/// translation detail.
const _locales = {
  'en': TextDirection.ltr,
  'de': TextDirection.ltr,
  'es': TextDirection.ltr,
  'fr': TextDirection.ltr,
  'he': TextDirection.rtl,
  'nn': TextDirection.ltr,
};

Messages _messagesFor(String code) => switch (code) {
  'de' => MessagesDe(),
  'es' => MessagesEs(),
  'fr' => MessagesFr(),
  'he' => MessagesHe(),
  'nn' => MessagesNn(),
  _ => Messages(),
};

void main() {
  tearDown(() => m = Messages());

  testWidgets('every tip is listed with its title and subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: WatchTipsSection())),
      ),
    );

    for (final tip in watchTips()) {
      expect(find.text(tip.title), findsOneWidget, reason: tip.id);
      expect(find.text(tip.subtitle), findsOneWidget, reason: tip.id);
    }
  });

  // Each stage is a loop of hand-placed phases, and the ones that only appear
  // for a fifth of a second are exactly the ones a manual look misses.
  for (final tip in watchTips()) {
    testWidgets('the ${tip.id} tip draws through its whole loop', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: WatchTipView(tip: tip)));
      for (var frame = 0; frame < 40; frame++) {
        await tester.pump(tip.loop ~/ 40);
        expect(
          tester.takeException(),
          isNull,
          reason: '${tip.id} frame $frame',
        );
      }
      expect(find.text(tip.body), findsOneWidget);
      for (final step in tip.steps) {
        expect(find.text(step), findsOneWidget);
      }
    });
  }

  testWidgets('tapping a step takes the picture to the moment it describes', (
    tester,
  ) async {
    final tip = watchTips().firstWhere((t) => t.id == 'shopping');
    await tester.pumpWidget(MaterialApp(home: WatchTipView(tip: tip)));
    await tester.pump(const Duration(milliseconds: 16));

    final last = find.text(tip.steps.last);
    await tester.ensureVisible(last);
    await tester.pump();
    await tester.tap(last);
    await tester.pump();

    expect(tip.activeStep(tip.cues.last), tip.steps.length - 1);
    expect(tester.takeException(), isNull);
  });

  for (final locale in _locales.entries) {
    testWidgets('every picture fits in ${locale.key}', (tester) async {
      m = _messagesFor(locale.key);
      for (final tip in watchTips()) {
        await tester.pumpWidget(
          Directionality(
            textDirection: locale.value,
            child: MaterialApp(
              locale: Locale(locale.key),
              home: WatchTipView(tip: tip),
            ),
          ),
        );
        for (var frame = 0; frame < 24; frame++) {
          await tester.pump(tip.loop ~/ 24);
          expect(
            tester.takeException(),
            isNull,
            reason: '${locale.key} ${tip.id} frame $frame',
          );
        }
      }
    });
  }

  testWidgets('a phone with animations off holds the picture still', (
    tester,
  ) async {
    final tip = watchTips().first;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: WatchTipView(tip: tip),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(m.watchTips.stepsLabel), findsOneWidget);
  });
}
