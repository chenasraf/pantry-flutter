import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry/views/notes/note_detail_view.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

/// Captures [updateNote] calls without touching services or the sync queue.
class _CapturingNotesController extends FakeNotesController {
  String? lastContent;

  @override
  Future<Note> updateNote(
    Note note, {
    String? title,
    String? content,
    String? color,
    bool? isPinned,
  }) async {
    lastContent = content;
    return note.copyWith(content: content);
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
  testWidgets('tapping a checkbox toggles that line and saves', (tester) async {
    final controller = _CapturingNotesController();
    final note = makeNote(content: '- [ ] Milk\n- [ ] Bread');

    await tester.pumpWidget(_wrap(note, controller));
    await tester.pumpAndSettle();

    // Two rendered checkboxes, both unchecked.
    expect(find.byIcon(Icons.check_box_outline_blank), findsNWidgets(2));

    // Tap the second checkbox.
    await tester.tap(find.byIcon(Icons.check_box_outline_blank).last);
    await tester.pumpAndSettle();

    expect(controller.lastContent, '- [ ] Milk\n- [x] Bread');
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

    expect(controller.lastContent, isNull);
  });
}
