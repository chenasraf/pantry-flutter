import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/widgets/note_sort_button.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('renders sort icon button', (tester) async {
    final controller = FakeNotesController();
    await tester.pumpWidget(
      wrapForTest(NoteSortButton(controller: controller)),
    );
    expect(find.byIcon(Icons.sort), findsOneWidget);
  });

  testWidgets('opens menu with all sort options', (tester) async {
    final controller = FakeNotesController();
    await tester.pumpWidget(
      wrapForTest(NoteSortButton(controller: controller)),
    );

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();

    expect(find.text('Newest first'), findsOneWidget);
    expect(find.text('Oldest first'), findsOneWidget);
    expect(find.text('Title A–Z'), findsOneWidget);
    expect(find.text('Title Z–A'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
  });

  testWidgets('selecting option calls setSortBy on controller', (tester) async {
    final controller = FakeNotesController();
    await tester.pumpWidget(
      wrapForTest(NoteSortButton(controller: controller)),
    );

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Title Z–A'));
    await tester.pumpAndSettle();

    expect(controller.lastSortBy, 'title_desc');
  });
}
