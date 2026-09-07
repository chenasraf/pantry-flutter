import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/list_recurrence.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';
import 'package:pantry/views/checklists/switcher_form_stage.dart';

import '../helpers/test_app.dart';

void main() {
  late ChecklistsController controller;

  setUp(() => controller = ChecklistsController(houseId: 1));
  tearDown(() {
    controller.dispose();
    ServerVersionService.instance.debugSeed();
  });

  void seedRecurrenceDefault(bool enabled) {
    ServerVersionService.instance.debugSeed(
      features: {
        'checklist-color': true,
        if (enabled) kListDefaultRecurrenceFeature: true,
      },
      featuresAuthoritative: true,
    );
  }

  ChecklistList listWith({
    required ListRecurrenceMode mode,
    String? rrule,
    bool repeatFromCompletion = false,
  }) => ChecklistList(
    id: 3,
    houseId: 1,
    name: 'Chores',
    icon: 'cart',
    sortOrder: 0,
    defaultRecurrenceMode: mode,
    defaultRecurrenceKind: mode.pinned ?? ListRecurrenceKind.none,
    defaultRrule: rrule,
    defaultRepeatFromCompletion: repeatFromCompletion,
    createdAt: 0,
    updatedAt: 0,
  );

  Future<void> pumpForm(WidgetTester tester, {ChecklistList? existing}) async {
    await tester.pumpWidget(
      wrapForTest(
        ListFormStage(
          controller: controller,
          existing: existing,
          onBack: () {},
          onSaved: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // The fields scroll inside the sheet, so a mode row can sit below the fold.
  Future<void> tapMode(WidgetTester tester, String label) async {
    final row = find.text(label);
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
  }

  testWidgets('a new list offers the four recurrence defaults', (tester) async {
    seedRecurrenceDefault(true);
    await pumpForm(tester);

    final r = m.checklists.listRecurrence;
    expect(find.text(r.label.toUpperCase()), findsOneWidget);
    expect(find.text(r.remember), findsOneWidget);
    expect(find.text(r.none), findsOneWidget);
    expect(find.text(r.once), findsOneWidget);
    expect(find.text(r.recurring), findsOneWidget);
    // The rule editor only belongs under a recurring default.
    expect(find.text(m.recurrence.everyLabel), findsNothing);
  });

  testWidgets('picking Recurring reveals the rule editor', (tester) async {
    seedRecurrenceDefault(true);
    await pumpForm(tester);

    await tapMode(tester, m.checklists.listRecurrence.recurring);

    expect(find.text(m.recurrence.everyLabel), findsOneWidget);
  });

  testWidgets('editing a list opens on the default it already has', (
    tester,
  ) async {
    seedRecurrenceDefault(true);
    await pumpForm(
      tester,
      existing: listWith(
        mode: ListRecurrenceMode.recurring,
        rrule: 'FREQ=DAILY;INTERVAL=3',
      ),
    );

    // The rule editor is open on the stored rule, not a blank weekly one.
    expect(find.text(m.recurrence.everyLabel), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('a server without the capability hides the section', (
    tester,
  ) async {
    seedRecurrenceDefault(false);
    await pumpForm(tester);

    expect(
      find.text(m.checklists.listRecurrence.label.toUpperCase()),
      findsNothing,
    );
    expect(find.text(m.checklists.listRecurrence.remember), findsNothing);
  });

  testWidgets('the save button stays on screen on a short viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    seedRecurrenceDefault(true);
    await pumpForm(tester);
    await tapMode(tester, m.checklists.listRecurrence.recurring);

    expect(tester.takeException(), isNull);
    final button = find.text(m.checklists.createListButton);
    expect(button, findsOneWidget);
    expect(tester.getBottomLeft(button).dy, lessThanOrEqualTo(700));
  });
}
