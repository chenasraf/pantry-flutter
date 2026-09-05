import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_wear/src/prototype/checklist_prototype.dart';
import 'package:pantry_wear/src/prototype/proto_checklist_data.dart';
import 'package:pantry_wear/src/wear_shape.dart';

/// The rail is the only thing that names a page, so a page that does not reach
/// it has no title at all — which is how every page came to read as the
/// checklist's name.
void main() {
  setUp(() => WearShape.markFrom(['round']));
  tearDown(() => WearShape.markFrom(['round']));

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ChecklistPrototype()));
    await tester.pumpAndSettle();
  }

  testWidgets('each browse page is named by the rail', (tester) async {
    await pump(tester);

    for (final title in [protoListTitle, 'Photos', 'Notes', 'Account']) {
      expect(
        find.text(title),
        findsWidgets,
        reason: 'the rail should name the page as "$title"',
      );
      await tester.fling(
        find.byType(PageView).first,
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();
    }
  });
}
