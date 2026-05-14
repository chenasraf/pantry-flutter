import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/widgets/photo_add_button.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('renders a single main FAB closed by default', (tester) async {
    final controller = FakePhotoBoardController();
    await tester.pumpWidget(
      wrapForTest(PhotoAddButton(controller: controller)),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);

    // None of the action labels should be visible while closed.
    expect(find.text('Upload photos'), findsNothing);
    expect(find.text('Take photo'), findsNothing);
    expect(find.text('New folder'), findsNothing);
  });

  testWidgets('tapping the FAB opens the menu with all three actions', (
    tester,
  ) async {
    final controller = FakePhotoBoardController();
    await tester.pumpWidget(
      wrapForTest(PhotoAddButton(controller: controller)),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Upload photos'), findsOneWidget);
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('New folder'), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    expect(find.byIcon(Icons.create_new_folder), findsOneWidget);
  });

  testWidgets('tapping the FAB a second time closes the menu', (tester) async {
    final controller = FakePhotoBoardController();
    await tester.pumpWidget(
      wrapForTest(PhotoAddButton(controller: controller)),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Take photo'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Take photo'), findsNothing);
  });

  testWidgets('tapping "New folder" opens the create-folder dialog', (
    tester,
  ) async {
    final controller = FakePhotoBoardController();
    await tester.pumpWidget(
      wrapForTest(PhotoAddButton(controller: controller)),
    );

    await tester.tap(find.byType(FloatingActionButton));
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
      await tester.pumpWidget(
        wrapForTest(PhotoAddButton(controller: controller)),
      );

      await tester.tap(find.byType(FloatingActionButton));
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
    await tester.pumpWidget(
      wrapForTest(PhotoAddButton(controller: controller)),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New folder'));
    await tester.pumpAndSettle();

    // Don't type anything, just submit.
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(controller.lastCreatedFolderName, isNull);
  });
}
