import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/widgets/markdown_description.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('tapping a checkbox flips its own line', (tester) async {
    String? changed;
    await tester.pumpWidget(
      wrapForTest(
        MarkdownDescription(
          description: '- [ ] Milk\n- [ ] Bread',
          onChanged: (value) => changed = value,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.check_box_outline_blank).last);

    expect(changed, '- [ ] Milk\n- [x] Bread');
  });

  testWidgets('a sub-item checkbox flips the sub-item, not its parent', (
    tester,
  ) async {
    String? changed;
    await tester.pumpWidget(
      wrapForTest(
        MarkdownDescription(
          description: '- [ ] Bake\n  - [ ] Flour',
          onChanged: (value) => changed = value,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.check_box_outline_blank).last);

    expect(changed, '- [ ] Bake\n  - [x] Flour');
  });

  testWidgets('checkboxes are inert without onChanged', (tester) async {
    await tester.pumpWidget(
      wrapForTest(const MarkdownDescription(description: '- [ ] Milk')),
    );

    expect(find.byType(InkResponse), findsNothing);
  });
}
