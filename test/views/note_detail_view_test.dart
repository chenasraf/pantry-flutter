import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/utils/markdown_list.dart';
import 'package:pantry/views/notes/note_detail_view.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

/// Captures [setTaskLine] calls without touching services or the sync queue.
class _CapturingNotesController extends FakeNotesController {
  ({int ordinal, String text, bool checked})? lastTick;
  bool? lastSink;

  @override
  Future<Note> setTaskLine(
    Note note, {
    required int ordinal,
    required String text,
    required bool checked,
    bool sink = false,
  }) async {
    lastTick = (ordinal: ordinal, text: text, checked: checked);
    lastSink = sink;
    final content = note.content;
    if (content == null) return note;
    return note.copyWith(content: setChecklistItem(content, ordinal, checked));
  }
}

Widget _wrap(Note note, _CapturingNotesController controller) => wrapForTest(
  NoteDetailView(
    note: note,
    controller: controller,
    bgColor: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF000000),
  ),
);

void main() {
  testWidgets('tapping a checkbox writes that line, not the document', (
    tester,
  ) async {
    final controller = _CapturingNotesController();
    final note = makeNote(content: '- [ ] Milk\n- [ ] Bread');

    await tester.pumpWidget(_wrap(note, controller));
    await tester.pumpAndSettle();

    // Two rendered checkboxes, both unchecked.
    expect(find.byIcon(Icons.check_box_outline_blank), findsNWidgets(2));

    // Tap the second checkbox.
    await tester.tap(find.byIcon(Icons.check_box_outline_blank).last);
    await tester.pumpAndSettle();

    expect(controller.lastTick, (ordinal: 1, text: 'Bread', checked: true));
    expect(find.byIcon(Icons.check_box), findsOneWidget);
  });

  group('tapping a checklist row', () {
    testWidgets('anywhere on its text ticks it', (tester) async {
      final controller = _CapturingNotesController();
      final note = makeNote(content: '- [ ] Milk\n- [ ] Bread');

      await tester.pumpWidget(_wrap(note, controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bread'));
      await tester.pumpAndSettle();

      expect(controller.lastTick, (ordinal: 1, text: 'Bread', checked: true));
    });

    testWidgets('a sub-item row ticks the sub-item, not its parent', (
      tester,
    ) async {
      final controller = _CapturingNotesController();
      final note = makeNote(content: '- [ ] Bake\n  - [ ] Flour');

      await tester.pumpWidget(_wrap(note, controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Flour'));
      await tester.pumpAndSettle();

      expect(controller.lastTick, (ordinal: 1, text: 'Flour', checked: true));
    });

    testWidgets('a sub-item checkbox ticks the sub-item', (tester) async {
      final controller = _CapturingNotesController();
      final note = makeNote(content: '- [ ] Bake\n  - [ ] Flour');

      await tester.pumpWidget(_wrap(note, controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check_box_outline_blank).last);
      await tester.pumpAndSettle();

      expect(controller.lastTick, (ordinal: 1, text: 'Flour', checked: true));
    });

    testWidgets('prose outside the checklist ticks nothing', (tester) async {
      final controller = _CapturingNotesController();
      final note = makeNote(content: 'Shopping run\n\n- [ ] Milk');

      await tester.pumpWidget(_wrap(note, controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shopping run'));
      await tester.pumpAndSettle();

      expect(controller.lastTick, isNull);
    });

    testWidgets('a long press to select ticks nothing', (tester) async {
      final controller = _CapturingNotesController();
      final note = makeNote(content: '- [ ] Milk');

      await tester.pumpWidget(_wrap(note, controller));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Milk'));
      await tester.pumpAndSettle();

      expect(controller.lastTick, isNull);
    });
  });

  group('with checked items moved to the bottom', () {
    const secureStorage = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );

    setUp(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorage, (_) async => null);
      await PrefsService.instance.setNotesCheckedToBottom(true);
    });

    tearDown(() async {
      await PrefsService.instance.setNotesCheckedToBottom(false);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorage, null);
    });

    testWidgets('a tap asks for the line to move', (tester) async {
      final controller = _CapturingNotesController();
      final note = makeNote(content: '- [ ] Milk\n- [ ] Bread');

      await tester.pumpWidget(_wrap(note, controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check_box_outline_blank).first);
      await tester.pumpAndSettle();

      expect(controller.lastTick, (ordinal: 0, text: 'Milk', checked: true));
      expect(controller.lastSink, isTrue);
    });
  });

  testWidgets('read-only note renders non-interactive checkboxes', (
    tester,
  ) async {
    final controller = _CapturingNotesController()
      ..permissions = const HousePermissions(canUpdateNotes: false);
    final note = makeNote(content: '- [ ] Milk');

    await tester.pumpWidget(_wrap(note, controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_box_outline_blank));
    await tester.pumpAndSettle();

    expect(controller.lastTick, isNull);
  });
}
