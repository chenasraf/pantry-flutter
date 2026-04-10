import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/widgets/tile_menu_button.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('renders more_vert icon', (tester) async {
    await tester.pumpWidget(
      wrapForTest(
        TileMenuButton(
          items: const [
            PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
          ],
          onSelected: (_) {},
        ),
      ),
    );
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });

  testWidgets('tapping opens menu and selecting calls onSelected', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      wrapForTest(
        TileMenuButton(
          items: const [
            PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
            PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (v) => picked = v,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(picked, 'delete');
  });
}
