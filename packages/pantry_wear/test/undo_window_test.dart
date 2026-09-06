import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_wear/src/account/wear_settings_page.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/checklists/checklists_page.dart';
import 'package:pantry_wear/src/shell/wear_shell.dart';
import 'package:pantry_wear/src/wear_shape.dart';
import 'package:pantry_wear/src/widgets/undo_window.dart';

import 'wear_fixtures.dart';

/// How long a tap stays reversible, and the rule the length is in service of:
/// every reversible tap on this watch runs the same window in both
/// directions, so a check and the uncheck that takes it back cost the same
/// and cannot be told apart by a thumb.
///
/// The value is the wearer's, *Off* included — that being the behaviour the
/// window replaced, not a broken one.
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
          final args = (call.arguments as Map?) ?? const {};
          switch (call.method) {
            case 'readAll':
              return Map<String, String>.from(storage);
            case 'write':
              storage[args['key'] as String] = args['value'] as String;
              return null;
            case 'delete':
              storage.remove(args['key'] as String);
              return null;
          }
          return null;
        });
    // Offline, so what is asserted is the write's effect on the lists rather
    // than its delivery.
    SyncManager.instance.setOnline(false);
    await PrefsService.instance.setWearUndoSeconds(2);
  });

  tearDown(() async {
    await PrefsService.instance.setWearUndoSeconds(2);
    // Not awaited: a cache store's drain started inside `testWidgets` is never
    // driven to completion by the fake-async zone, so awaiting it hangs the
    // file rather than tidying it.
    unawaited(SyncManager.instance.reset());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
  });

  /// A browse list holding nothing but one item already checked off, so the
  /// only row that can be landed on is the one this file is about.
  ChecklistsController withOneDoneItem() {
    final controller = ChecklistsController.seeded(
      houseId: 1,
      list: testList(),
      lists: [testList()],
      categories: [testCategory(id: 1, name: 'Dairy')],
      done: [testItem(id: 1, name: 'Bread', categoryId: 1, done: true)],
    );
    addTearDown(controller.dispose);
    return controller;
  }

  Future<void> pump(WidgetTester tester, ChecklistsController c) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: WearShell(controller: c)));
    await tester.pumpAndSettle();
  }

  /// Browse keeps its completed items behind a collapsed header, so the row
  /// has to be revealed before it can be tapped.
  Future<void> expandCompleted(WidgetTester tester) async {
    await tester.tap(find.text(m.checklists.completedCount(1)));
    await tester.pumpAndSettle();
  }

  testWidgets('unchecking runs the window checking runs', (tester) async {
    final controller = withOneDoneItem();
    await pump(tester, controller);
    await expandCompleted(tester);

    await tester.tap(find.text('Bread'));
    await tester.pump(const Duration(milliseconds: 100));

    // The row already reads as back on the list; only the write is waiting.
    expect(controller.done.single.name, 'Bread');
    expect(controller.items, isEmpty);

    await tester.pump(undoWindow);
    await tester.pumpAndSettle();

    expect(controller.items.single.name, 'Bread');
    expect(controller.done, isEmpty);
  });

  testWidgets('a second tap inside the window takes the uncheck back', (
    tester,
  ) async {
    final controller = withOneDoneItem();
    await pump(tester, controller);
    await expandCompleted(tester);

    await tester.tap(find.text('Bread'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Bread'));
    await tester.pump(undoWindow);
    await tester.pumpAndSettle();

    expect(controller.done.single.name, 'Bread');
    expect(controller.items, isEmpty);
  });

  testWidgets('with the window off the tap is the write', (tester) async {
    await PrefsService.instance.setWearUndoSeconds(0);
    final controller = withOneDoneItem();
    await pump(tester, controller);
    await expandCompleted(tester);

    await tester.tap(find.text('Bread'));
    await tester.pump();

    expect(controller.items.single.name, 'Bread');
    expect(controller.done, isEmpty);
  });

  // One test per value rather than one test over them: a shell pumped twice
  // keeps the state — and so the controller — it was built with, so a second
  // pass would assert against the first pass's list.
  for (final seconds in PrefsService.validUndoSeconds) {
    testWidgets('the pager swap commits what is open, at $seconds seconds', (
      tester,
    ) async {
      await PrefsService.instance.setWearUndoSeconds(seconds);
      final controller = withOneDoneItem();
      await pump(tester, controller);
      await expandCompleted(tester);

      await tester.tap(find.text('Bread'));
      await tester.pump(const Duration(milliseconds: 100));

      // The seam the mode transition uses, called at the moment it calls it —
      // with the window off there is nothing open to resolve, which is why one
      // rule covers every value rather than zero needing its own.
      tester
          .state<ChecklistsPageState>(find.byType(ChecklistsPage))
          .resolvePending(commit: true);
      await tester.pumpAndSettle();

      expect(controller.items.single.name, 'Bread');
      expect(controller.done, isEmpty);
    });
  }

  testWidgets('an item coming back off the done page runs it too', (
    tester,
  ) async {
    final controller = ChecklistsController.seeded(
      houseId: 1,
      session: testSession(activeStoreId: 1),
      stores: [testStore(id: 1, name: 'Corner shop')],
      categories: [testCategory(id: 1, name: 'Dairy')],
      items: [testItem(id: 1, name: 'Milk', categoryId: 1)],
      done: [testItem(id: 2, name: 'Bread', categoryId: 1)],
    );
    addTearDown(controller.dispose);
    await pump(tester, controller);

    // A session opens on its checklist; the done page is the next one along.
    await tester.fling(
      find.byType(PageView).first,
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bread'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.done.single.name, 'Bread');

    await tester.pump(undoWindow);
    await tester.pumpAndSettle();

    expect(controller.done, isEmpty);
    expect(controller.items.map((i) => i.name), contains('Bread'));
  });

  testWidgets('the settings row says the window, and the picker sets it', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WearSettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text(m.wear.undoWindow), findsOneWidget);
    expect(find.text(m.wear.undoSeconds(2)), findsOneWidget);

    await tester.tap(find.text(m.wear.undoWindow));
    await tester.pumpAndSettle();
    await tester.tap(find.text(m.wear.undoSeconds(5)));
    await tester.pumpAndSettle();

    expect(PrefsService.instance.wearUndoSeconds, 5);
    expect(undoWindow, const Duration(seconds: 5));
    // The page the picker popped back to draws the answer it wrote.
    expect(find.text(m.wear.undoSeconds(5)), findsOneWidget);
  });

  testWidgets('off is a value the picker offers', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WearSettingsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(m.wear.undoWindow));
    await tester.pumpAndSettle();
    await tester.tap(find.text(m.wear.undoOff));
    await tester.pumpAndSettle();

    expect(PrefsService.instance.wearUndoSeconds, 0);
    expect(undoWindow, Duration.zero);
  });
}
