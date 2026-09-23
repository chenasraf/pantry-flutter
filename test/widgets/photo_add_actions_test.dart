import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/views/home/home_floating_nav.dart';
import 'package:pantry/widgets/photo_add_actions.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

void main() {
  // On desktop the camera action is suppressed, so the "Take photo" label is
  // never rendered. The label we reach for to confirm the menu is open varies
  // by platform.
  final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  final menuOpenLabel = isDesktop ? 'Upload photos' : 'Take photo';

  /// The board's actions and the nav that renders them, wired the way the home
  /// shell wires them: the board publishes into a holder, the bar reads it.
  Widget harness(FakePhotoBoardController controller) {
    final holder = ValueNotifier<NavPrimaryAction?>(null);
    return wrapForTest(
      Stack(
        children: [
          PhotoAddActions(controller: controller, holder: holder),
          ValueListenableBuilder<NavPrimaryAction?>(
            valueListenable: holder,
            builder: (context, action, _) => HomeFloatingNav(
              pageController: PageController(),
              currentIndex: 0,
              onTap: (_) {},
              destinations: const [
                (icon: Icons.checklist, label: 'Checklists'),
                (icon: Icons.photo, label: 'Photo Board'),
              ],
              action: action,
            ),
          ),
        ],
      ),
    );
  }

  testWidgets('offers a single closed button by default', (tester) async {
    final controller = FakePhotoBoardController();
    await tester.pumpWidget(harness(controller));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add), findsOneWidget);

    // None of the action labels should be visible while closed.
    expect(find.text('Upload photos'), findsNothing);
    expect(find.text('Take photo'), findsNothing);
    expect(find.text('New folder'), findsNothing);
  });

  testWidgets('tapping the button opens the menu with all available actions', (
    tester,
  ) async {
    final controller = FakePhotoBoardController();
    await tester.pumpWidget(harness(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Upload photos'), findsOneWidget);
    expect(find.text('New folder'), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
    expect(find.byIcon(Icons.create_new_folder), findsOneWidget);
    if (!isDesktop) {
      expect(find.text('Take photo'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    }
  });

  testWidgets('tapping the button a second time closes the menu', (
    tester,
  ) async {
    final controller = FakePhotoBoardController();
    await tester.pumpWidget(harness(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text(menuOpenLabel), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text(menuOpenLabel), findsNothing);
  });

  testWidgets('the trash view offers no add button at all', (tester) async {
    final controller = FakePhotoBoardController();
    final holder = ValueNotifier<NavPrimaryAction?>(null);
    await tester.pumpWidget(
      wrapForTest(
        PhotoAddActions(controller: controller, holder: holder, enabled: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(holder.value, isNull);
  });

  testWidgets('tapping "New folder" opens the create-folder dialog', (
    tester,
  ) async {
    final controller = FakePhotoBoardController();
    await tester.pumpWidget(harness(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New folder'));
    await tester.pumpAndSettle();

    // Dialog field label + the action buttons confirm the dialog opened.
    expect(find.text('Folder name'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
  });

  testWidgets(
    'submitting the create-folder dialog calls controller.createFolder',
    (tester) async {
      final controller = FakePhotoBoardController();
      await tester.pumpWidget(harness(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New folder'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Folder name'),
        'Vacation',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(controller.lastCreatedFolderName, 'Vacation');
    },
  );

  testWidgets('empty folder name does not invoke createFolder', (tester) async {
    final controller = FakePhotoBoardController();
    await tester.pumpWidget(harness(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New folder'));
    await tester.pumpAndSettle();

    // Don't type anything, just submit.
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(controller.lastCreatedFolderName, isNull);
  });
}
