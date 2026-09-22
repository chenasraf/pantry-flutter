import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry/views/notes/note_detail_view.dart';
import 'package:pantry/widgets/note_tile.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

Widget _tile(Note note) => wrapForTest(
  SizedBox(
    width: 180,
    height: 180,
    child: NoteTile(note: note, controller: FakeNotesController()),
  ),
);

Widget _detail(Note note) => wrapForTest(
  NoteDetailView(
    note: note,
    controller: FakeNotesController(),
    bgColor: const Color(0xFFFFFFFF),
    textColor: const Color(0xFF000000),
  ),
);

void main() {
  setUp(
    () => ServerVersionService.instance.debugSeed(
      features: {'note-file-sync': true},
      featuresAuthoritative: true,
    ),
  );
  tearDown(() => ServerVersionService.instance.debugSeed());

  group('note tile', () {
    testWidgets('shows the bound file, without its leading slash', (
      tester,
    ) async {
      await tester.pumpWidget(
        _tile(makeNote(syncFileId: 256, syncPath: '/Templates/Weekly shop.md')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Synced to Templates/Weekly shop.md'), findsOneWidget);
      expect(find.byIcon(Icons.sync_alt), findsOneWidget);
    });

    testWidgets('says the file is missing when the path did not resolve', (
      tester,
    ) async {
      await tester.pumpWidget(_tile(makeNote(syncFileId: 256)));
      await tester.pumpAndSettle();

      expect(find.text('Synced file is missing'), findsOneWidget);
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
    });

    testWidgets('draws nothing for an unsynced note', (tester) async {
      await tester.pumpWidget(_tile(makeNote()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sync_alt), findsNothing);
      expect(find.byIcon(Icons.sync_problem), findsNothing);
    });

    testWidgets('draws nothing on a server without the feature', (
      tester,
    ) async {
      ServerVersionService.instance.debugSeed(featuresAuthoritative: true);
      await tester.pumpWidget(
        _tile(makeNote(syncFileId: 256, syncPath: '/Templates/Weekly shop.md')),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sync_alt), findsNothing);
    });
  });

  group('note detail', () {
    testWidgets('heads the note with its path and when it last agreed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _detail(
          makeNote(
            syncFileId: 256,
            syncPath: '/Templates/Weekly shop.md',
            syncAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Templates/Weekly shop.md'), findsOneWidget);
      expect(find.text('Synced just now'), findsOneWidget);
    });

    testWidgets('draws nothing for an unsynced note', (tester) async {
      await tester.pumpWidget(_detail(makeNote()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sync_alt), findsNothing);
    });
  });
}
