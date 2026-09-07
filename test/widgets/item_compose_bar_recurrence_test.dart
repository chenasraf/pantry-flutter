import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/list_recurrence.dart';
import 'package:pantry_core/utils/rrule.dart';
import 'package:pantry/views/checklists/item_compose_bar.dart';

import '../helpers/test_app.dart';

/// The recurrence a submitted item reported back to its list.
typedef _Remembered = ({
  ListRecurrenceKind kind,
  String? rrule,
  bool repeatFromCompletion,
});

void main() {
  late List<ComposeSubmission> submitted;
  late List<_Remembered> remembered;

  setUp(() {
    submitted = [];
    remembered = [];
  });

  Future<void> pumpBar(
    WidgetTester tester,
    ListRecurrenceDefault recurrenceDefault,
  ) async {
    await tester.pumpWidget(
      wrapForTest(
        ItemComposeBar(
          listName: 'Groceries',
          houseId: 1,
          listId: 1,
          recurrenceDefault: recurrenceDefault,
          onRecurrenceUsed:
              ({required kind, rrule, required repeatFromCompletion}) =>
                  remembered.add((
                    kind: kind,
                    rrule: rrule,
                    repeatFromCompletion: repeatFromCompletion,
                  )),
          categories: const [],
          initiallyFocused: true,
          onSubmit: (s) async {
            submitted.add(s);
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> addItem(WidgetTester tester, String name) async {
    await tester.enterText(find.byType(TextField).first, name);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();
  }

  testWidgets('a pinned one-time default starts items as one-time', (
    tester,
  ) async {
    await pumpBar(
      tester,
      const ListRecurrenceDefault(kind: ListRecurrenceKind.once),
    );

    // The chip names the type rather than staying neutral, so a list that adds
    // one-time items behind the user's back is visible.
    expect(find.text(m.checklists.itemTypes.onceTime), findsOneWidget);
    expect(find.text(m.checklists.compose.chipType), findsNothing);

    await addItem(tester, 'Milk');

    expect(submitted.single.deleteOnDone, isTrue);
    expect(submitted.single.rrule, isNull);
  });

  testWidgets('a pinned recurring default seeds its rule', (tester) async {
    await pumpBar(
      tester,
      const ListRecurrenceDefault(
        kind: ListRecurrenceKind.recurring,
        rrule: 'FREQ=DAILY;INTERVAL=2',
        repeatFromCompletion: true,
      ),
    );

    await addItem(tester, 'Water the plants');

    expect(submitted.single.rrule, 'FREQ=DAILY;INTERVAL=2');
    expect(submitted.single.repeatFromCompletion, isTrue);
    expect(submitted.single.deleteOnDone, isFalse);
    // Nothing is remembered against a list that pins its recurrence.
    expect(remembered, isEmpty);
  });

  testWidgets('a recurring default without a rule falls back to weekly', (
    tester,
  ) async {
    await pumpBar(
      tester,
      const ListRecurrenceDefault(kind: ListRecurrenceKind.recurring),
    );

    await addItem(tester, 'Bins out');

    expect(sameRrule(submitted.single.rrule, kDefaultListRrule), isTrue);
  });

  testWidgets('a remembering list is told the recurrence each item used', (
    tester,
  ) async {
    await pumpBar(
      tester,
      const ListRecurrenceDefault(
        kind: ListRecurrenceKind.once,
        remembers: true,
      ),
    );

    await addItem(tester, 'Milk');

    expect(remembered.single.kind, ListRecurrenceKind.once);
    expect(remembered.single.rrule, isNull);
  });

  testWidgets('and keeps it for the next item, while a pinned list resets', (
    tester,
  ) async {
    await pumpBar(
      tester,
      const ListRecurrenceDefault(
        kind: ListRecurrenceKind.once,
        remembers: true,
      ),
    );

    // Switch the draft to a staple through the type tray.
    await tester.tap(find.text(m.checklists.itemTypes.onceTime));
    await tester.pumpAndSettle();
    await tester.tap(find.text(m.checklists.itemTypes.staple).last);
    await tester.pumpAndSettle();

    await addItem(tester, 'Salt');
    expect(remembered.single.kind, ListRecurrenceKind.none);
    // The choice survives the reset, so a run of staples needs picking once.
    expect(find.text(m.checklists.compose.chipType), findsOneWidget);

    await addItem(tester, 'Pepper');
    expect(submitted.last.deleteOnDone, isFalse);
  });

  testWidgets('a pinned list wins back the next item', (tester) async {
    await pumpBar(
      tester,
      const ListRecurrenceDefault(kind: ListRecurrenceKind.once),
    );

    await tester.tap(find.text(m.checklists.itemTypes.onceTime));
    await tester.pumpAndSettle();
    await tester.tap(find.text(m.checklists.itemTypes.staple).last);
    await tester.pumpAndSettle();

    await addItem(tester, 'Salt');
    expect(submitted.single.deleteOnDone, isFalse);

    await addItem(tester, 'Pepper');
    expect(submitted.last.deleteOnDone, isTrue);
  });
}
