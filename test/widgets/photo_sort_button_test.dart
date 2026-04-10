import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/widgets/photo_sort_button.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('renders sort icon button', (tester) async {
    final controller = FakePhotoBoardController();
    await tester.pumpWidget(
      wrapForTest(PhotoSortButton(controller: controller)),
    );
    expect(find.byIcon(Icons.sort), findsOneWidget);
  });

  testWidgets('opens menu with folders-first toggle and sort options', (
    tester,
  ) async {
    final controller = FakePhotoBoardController();
    await tester.pumpWidget(
      wrapForTest(PhotoSortButton(controller: controller)),
    );

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();

    expect(find.text('Folders first'), findsOneWidget);
    expect(find.text('Newest first'), findsOneWidget);
    expect(find.text('Oldest first'), findsOneWidget);
    expect(find.text('Caption A–Z'), findsOneWidget);
    expect(find.text('Caption Z–A'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
  });

  testWidgets('selecting a sort option calls setSortBy', (tester) async {
    final controller = FakePhotoBoardController();
    await tester.pumpWidget(
      wrapForTest(PhotoSortButton(controller: controller)),
    );

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Newest first'));
    await tester.pumpAndSettle();

    expect(controller.lastSortBy, 'newest');
  });

  testWidgets('toggling folders first calls setFoldersFirst', (tester) async {
    final controller = FakePhotoBoardController(foldersFirst: true);
    await tester.pumpWidget(
      wrapForTest(PhotoSortButton(controller: controller)),
    );

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Folders first'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(controller.lastFoldersFirst, false);
  });
}
