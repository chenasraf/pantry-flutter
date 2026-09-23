import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/checklists/checklists_page.dart';
import 'package:pantry_wear/src/notes/note_route.dart';
import 'package:pantry_wear/src/notes/notes_controller.dart';
import 'package:pantry_wear/src/photos/photos_controller.dart';
import 'package:pantry_wear/src/photos/photos_page.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/focus_list.dart';

import 'note_fixtures.dart';
import 'wear_fixtures.dart';

/// What a page says when it has nothing to draw.
///
/// A watch page with an empty list is a black screen, and a black screen is
/// indistinguishable from one that failed to load — which is why every page
/// here owes the wearer a line, and why the line has to name the right one of
/// the several reasons a page can be empty.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final storage = <String, String>{};

  setUp(() async {
    WearShape.markFrom(['round']);
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async {
          final key = call.arguments['key'] as String? ?? '';
          return switch (call.method) {
            'read' => storage[key],
            'write' => storage[key] = call.arguments['value'] as String,
            'readAll' => Map<String, String>.from(storage),
            _ => null,
          };
        });
    // Signed in, because a signed-out watch has its own line and would answer
    // every case here with that one.
    await AuthService.instance.adoptCredentials(
      const NextcloudCredentials(
        serverUrl: 'https://cloud.example',
        loginName: 'ada',
        appPassword: 'secret',
      ),
    );
    // Offline, so a write made by a test goes to the queue rather than arming
    // a retry the widget tree outlives.
    SyncManager.instance.setOnline(false);
  });

  tearDown(() async {
    // Not awaited: a cache store's drain started inside `testWidgets` is never
    // driven to completion by the fake-async zone, so awaiting it hangs the
    // file rather than tidying it.
    unawaited(SyncManager.instance.reset());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
  });

  void sizeToWatch(WidgetTester tester) {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget checklists(ChecklistsController controller) => MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: ChecklistsPage(
        controller: controller,
        geometry: ValueNotifier(const FocusGeometry()),
        rotary: true,
      ),
    ),
  );

  group('a browse list with everything ticked off', () {
    ChecklistsController allDone() {
      final controller = ChecklistsController.seeded(
        houseId: 1,
        list: testList(),
        lists: [testList()],
        categories: [testCategory(id: 1, name: 'Dairy')],
        done: [
          testItem(id: 1, name: 'Bread', categoryId: 1, done: true),
          testItem(id: 2, name: 'Milk', categoryId: 1, done: true),
        ],
      );
      addTearDown(controller.dispose);
      return controller;
    }

    testWidgets('says so above the completed section', (tester) async {
      sizeToWatch(tester);
      final controller = allDone();
      await tester.pumpWidget(checklists(controller));
      await tester.pumpAndSettle();

      expect(find.text(m.checklists.allDone), findsOneWidget);
      expect(find.text(m.checklists.completedCount(2)), findsOneWidget);
      // Above it, not instead of it: the section is still the way to reach
      // what was ticked off.
      expect(
        tester.getCenter(find.text(m.checklists.allDone)).dy,
        lessThan(
          tester.getCenter(find.text(m.checklists.completedCount(2))).dy,
        ),
      );
    });

    testWidgets('and says nothing while anything is still on the list', (
      tester,
    ) async {
      sizeToWatch(tester);
      final controller = ChecklistsController.seeded(
        houseId: 1,
        list: testList(),
        lists: [testList()],
        categories: [testCategory(id: 1, name: 'Dairy')],
        items: [testItem(id: 1, name: 'Bread', categoryId: 1)],
        done: [testItem(id: 2, name: 'Milk', categoryId: 1, done: true)],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(checklists(controller));
      await tester.pumpAndSettle();

      expect(find.text(m.checklists.allDone), findsNothing);
      expect(find.text(m.checklists.completedCount(1)), findsOneWidget);
    });

    testWidgets('an empty list with nothing done says nothing was there', (
      tester,
    ) async {
      sizeToWatch(tester);
      final controller = ChecklistsController.seeded(
        houseId: 1,
        list: testList(),
        lists: [testList()],
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(checklists(controller));
      await tester.pumpAndSettle();

      expect(find.text(m.checklists.noItems), findsOneWidget);
      expect(find.text(m.checklists.allDone), findsNothing);
    });
  });

  group('a trip standing in a shop', () {
    ChecklistsController trip({
      List<int> itemIds = const [],
      List<int> doneIds = const [],
    }) {
      final controller = ChecklistsController.seeded(
        houseId: 1,
        session: testSession(activeStoreId: 1),
        stores: [testStore(id: 1, name: 'Corner shop')],
        categories: [testCategory(id: 1, name: 'Dairy')],
        items: [
          for (final id in itemIds)
            testItem(id: id, name: 'Item $id', categoryId: 1),
        ],
        done: [
          for (final id in doneIds)
            testItem(id: id, name: 'Item $id', categoryId: 1),
        ],
      );
      addTearDown(controller.dispose);
      return controller;
    }

    testWidgets('with nothing on its list says there is nothing to buy', (
      tester,
    ) async {
      sizeToWatch(tester);
      await tester.pumpWidget(checklists(trip()));
      await tester.pumpAndSettle();

      expect(find.text(m.shopping.nothingToBuyHere), findsOneWidget);
    });

    // A cleared shop and one that had nothing in it are the same empty list
    // and opposite facts about the trip.
    testWidgets('that cleared its list says it cleared it', (tester) async {
      sizeToWatch(tester);
      await tester.pumpWidget(checklists(trip(doneIds: const [1, 2])));
      await tester.pumpAndSettle();

      expect(find.text(m.shopping.allCheckedHere), findsOneWidget);
      expect(find.text(m.shopping.nothingToBuyHere), findsNothing);
    });
  });

  testWidgets('a note with no body says the note is empty', (tester) async {
    sizeToWatch(tester);
    final empty = sampleNotes.firstWhere((n) => n.body.isEmpty);
    final controller = NotesController.seeded(
      houseId: 1,
      notes: [noteOf(empty)],
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: NoteRoute(controller: controller, note: noteOf(empty)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(m.wear.emptyNote), findsOneWidget);
  });

  testWidgets('a folder holding no photos says so', (tester) async {
    sizeToWatch(tester);
    final folder = testPhotoFolder(id: 7, name: 'Receipts');
    final controller = PhotosController.seeded(
      houseId: 1,
      folders: [folder],
      photos: [testPhoto(id: 1, caption: 'Fridge shelf')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PhotoFolderRoute(
          controller: controller,
          houseId: 1,
          folder: folder,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(m.photoBoard.noPhotos), findsOneWidget);
    // The route still names itself, so the wearer knows which folder is empty.
    expect(find.text('Receipts'), findsOneWidget);
  });
}
