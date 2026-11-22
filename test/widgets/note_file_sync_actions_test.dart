import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/home/home_floating_nav.dart';
import 'package:pantry/views/notes/note_detail_view.dart';
import 'package:pantry/widgets/nav_action_offer.dart';
import 'package:pantry/widgets/note_tile.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

class _RecordingNotesController extends FakeNotesController {
  final stopped = <int>[];

  @override
  Future<Note> stopFileSync(Note note) async {
    stopped.add(note.id);
    return makeNote(id: note.id);
  }
}

Widget _tile(Note note, [FakeNotesController? controller]) => wrapForTest(
  SizedBox(
    width: 180,
    height: 180,
    child: NoteTile(
      note: note,
      controller: controller ?? FakeNotesController(),
    ),
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

void _serverAt(String version) => ServerVersionService.instance.debugSeed(
  pantryVersion: Version.parse(version),
);

Future<void> _openTileMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => ServerVersionService.instance.debugSeed());

  group('note tile menu', () {
    testWidgets('offers to sync a note that is not synced', (tester) async {
      _serverAt('0.34.0');
      await tester.pumpWidget(_tile(makeNote()));
      await _openTileMenu(tester);

      expect(find.text('Sync with a file'), findsOneWidget);
      expect(find.text('Stop syncing with file'), findsNothing);
    });

    testWidgets('offers to stop syncing a synced note', (tester) async {
      _serverAt('0.34.0');
      await tester.pumpWidget(
        _tile(makeNote(syncFileId: 7, syncPath: '/Notes/Plants.md')),
      );
      await _openTileMenu(tester);

      expect(find.text('Stop syncing with file'), findsOneWidget);
      expect(find.text('Sync with a file'), findsNothing);
    });

    testWidgets('stopping asks first, then unbinds the note', (tester) async {
      _serverAt('0.34.0');
      final controller = _RecordingNotesController();
      await tester.pumpWidget(
        _tile(makeNote(id: 5, syncFileId: 7), controller),
      );
      await _openTileMenu(tester);
      await tester.tap(find.text('Stop syncing with file'));
      await tester.pumpAndSettle();

      expect(find.text('Stop syncing with the file?'), findsOneWidget);
      expect(controller.stopped, isEmpty);

      await tester.tap(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.text('Stop syncing with file'),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.stopped, [5]);
    });

    testWidgets('has no sync actions on a server before 0.34.0', (
      tester,
    ) async {
      _serverAt('0.33.0');
      await tester.pumpWidget(_tile(makeNote()));
      await _openTileMenu(tester);

      expect(find.text('Sync with a file'), findsNothing);
      expect(find.text('Stop syncing with file'), findsNothing);
    });
  });

  group('note detail', () {
    testWidgets('has a sync button', (tester) async {
      _serverAt('0.34.0');
      await tester.pumpWidget(_detail(makeNote()));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Sync with a file'), findsOneWidget);
    });

    testWidgets('has no sync button on a server before 0.34.0', (tester) async {
      _serverAt('0.33.0');
      await tester.pumpWidget(_detail(makeNote()));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Sync with a file'), findsNothing);
    });
  });

  group('NavActionOffer', () {
    Future<NavPrimaryAction?> offerFor(
      WidgetTester tester,
      List<NavMenuAction> actions,
    ) async {
      final holder = ValueNotifier<NavPrimaryAction?>(null);
      await tester.pumpWidget(
        wrapForTest(NavActionOffer(holder: holder, actions: actions)),
      );
      await tester.pump();
      return holder.value;
    }

    void noop() {}

    testWidgets('makes a single action the button\'s own tap', (tester) async {
      var tapped = false;
      final offer = await offerFor(tester, [
        (icon: Icons.note_add, label: 'New note', onTap: () => tapped = true),
      ]);

      expect(offer?.label, 'New note');
      expect(offer?.icon, Icons.add);
      expect(offer?.menu, isEmpty);
      offer!.onTap!();
      expect(tapped, isTrue);
    });

    testWidgets('fans several actions out', (tester) async {
      final offer = await offerFor(tester, [
        (icon: Icons.note_add, label: 'New note', onTap: noop),
        (icon: Icons.file_open, label: 'Import from Nextcloud', onTap: noop),
      ]);

      expect(offer?.onTap, isNull);
      expect(offer?.menu.map((a) => a.label), [
        'New note',
        'Import from Nextcloud',
      ]);
    });

    testWidgets('takes the button away when there is nothing to do', (
      tester,
    ) async {
      expect(await offerFor(tester, const []), isNull);
    });
  });
}
