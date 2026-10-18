import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry/widgets/markdown_editor.dart';

void main() {
  Widget wrapped(Widget child) => MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );

  Future<void> openTableDialog(WidgetTester tester) async {
    // The table button sits at the far end of the scrolling toolbar.
    final button = find.byIcon(Icons.table_chart_outlined);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('renders seeded markdown as formatted content', (tester) async {
    await tester.pumpWidget(
      wrapped(
        const MarkdownEditor(
          initialValue: '# Groceries\nBuy **milk**\n- [ ] eggs',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Quill renders each line as a RichText; the markdown markers are hidden and
    // only the words show through.
    expect(find.textContaining('Groceries', findRichText: true), findsWidgets);
    expect(find.textContaining('milk', findRichText: true), findsWidgets);
    expect(find.textContaining('eggs', findRichText: true), findsWidgets);
    // No raw markdown syntax leaks into the rendered view.
    expect(find.textContaining('**', findRichText: true), findsNothing);
    expect(
      find.textContaining('# Groceries', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('shows the formatting toolbar', (tester) async {
    await tester.pumpWidget(wrapped(const MarkdownEditor(initialValue: '')));
    await tester.pumpAndSettle();

    // flutter_quill's bold button is present in our trimmed toolbar.
    expect(find.byIcon(Icons.format_bold), findsOneWidget);
    expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
  });

  testWidgets('reseeds when initialValue changes (draft reset)', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapped(const MarkdownEditor(initialValue: 'first value')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('first', findRichText: true), findsWidgets);

    await tester.pumpWidget(
      wrapped(const MarkdownEditor(initialValue: 'second value')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('second', findRichText: true), findsWidgets);
    expect(find.textContaining('first', findRichText: true), findsNothing);
  });

  testWidgets('"Rich text" switch is on by default and toggles source view', (
    tester,
  ) async {
    String? emitted;
    await tester.pumpWidget(
      wrapped(
        MarkdownEditor(
          initialValue: '# Title\nBuy **milk**',
          onChanged: (md) => emitted = md,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The control is a "Rich text" switch, on by default (rich/WYSIWYG).
    expect(find.text(m.markdownEditor.editRich), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    // Rich mode: no editable TextField (Quill renders its own surface).
    expect(find.byType(TextField), findsNothing);

    // Switch off → source: the raw markdown shows in an editable field.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect(
      tester.widget<TextField>(field).controller!.text,
      '# Title\nBuy **milk**',
    );

    // Edit the source; the change is reported as markdown.
    await tester.enterText(field, '# Title\nBuy **oat milk**');
    await tester.pump();
    expect(emitted, '# Title\nBuy **oat milk**');

    // Switch back on → rich: the edit is rendered, field gone.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('oat milk', findRichText: true), findsWidgets);
  });

  testWidgets('a table renders as a table and survives into source mode', (
    tester,
  ) async {
    const source =
        'Groceries\n\n'
        '| Item | Qty |\n'
        '| --- | --- |\n'
        '| Milk | 2 |';
    await tester.pumpWidget(
      wrapped(const MarkdownEditor(initialValue: source)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Table), findsOneWidget);
    expect(find.textContaining('Milk', findRichText: true), findsWidgets);
    expect(find.textContaining('|', findRichText: true), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      source,
    );
  });

  testWidgets('the toolbar inserts a table of the chosen size', (tester) async {
    String? emitted;
    await tester.pumpWidget(
      wrapped(
        MarkdownEditor(
          initialValue: 'Groceries',
          onChanged: (md) => emitted = md,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final line = find.textContaining('Groceries', findRichText: true).first;
    await tester.tapAt(tester.getRect(line).centerRight - const Offset(2, 0));
    await tester.pumpAndSettle();
    await openTableDialog(tester);
    await tester.tap(find.byIcon(Icons.add).first); // 3 columns
    await tester.tap(find.byIcon(Icons.remove).last); // 2 rows
    await tester.pump();
    await tester.tap(find.text(m.markdownEditor.insert));
    await tester.pumpAndSettle();

    expect(
      emitted,
      'Groceries\n\n'
      '| Column 1 | Column 2 | Column 3 |\n'
      '| --- | --- | --- |\n'
      '|  |  |  |\n'
      '|  |  |  |',
    );
    expect(find.byType(Table), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(9));

    // Back from source mode, the markdown still reads as the same table.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(9));
  });

  Future<void> tapTooltip(WidgetTester tester, String tip, [int i = 0]) async {
    await tester.tap(find.byTooltip(tip).at(i));
    await tester.pumpAndSettle();
  }

  group('table row and column controls', () {
    const source =
        '| Item | Qty |\n'
        '| :--- | ---: |\n'
        '| Milk | 2 |\n'
        '| Eggs | 12 |';

    Future<List<String>> pumpTable(WidgetTester tester) async {
      final emitted = <String>[];
      await tester.pumpWidget(
        wrapped(MarkdownEditor(initialValue: source, onChanged: emitted.add)),
      );
      await tester.pumpAndSettle();
      await tapTooltip(tester, m.markdownEditor.editTable);
      return emitted;
    }

    testWidgets('controls stay hidden until the edit button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapped(const MarkdownEditor(initialValue: source)),
      );
      await tester.pumpAndSettle();
      final controls = [
        m.markdownEditor.addTableRow,
        m.markdownEditor.addTableColumn,
        m.markdownEditor.removeTableRow,
        m.markdownEditor.removeTableColumn,
        m.markdownEditor.deleteTable,
      ];
      for (final tip in controls) {
        expect(find.byTooltip(tip), findsNothing, reason: tip);
      }
      final cellTop = tester.getTopLeft(find.byType(TextField).first).dy;

      await tapTooltip(tester, m.markdownEditor.editTable);
      for (final tip in controls) {
        expect(find.byTooltip(tip), findsWidgets, reason: tip);
      }
      expect(find.byTooltip(m.markdownEditor.editTable), findsNothing);
      // Showing the controls doesn't push the cells down.
      expect(tester.getTopLeft(find.byType(TextField).first).dy, cellTop);

      await tapTooltip(tester, m.markdownEditor.doneEditingTable);
      for (final tip in controls) {
        expect(find.byTooltip(tip), findsNothing, reason: tip);
      }
      expect(find.byTooltip(m.markdownEditor.editTable), findsOneWidget);
    });

    testWidgets('adds a blank row at the bottom', (tester) async {
      final emitted = await pumpTable(tester);
      await tapTooltip(tester, m.markdownEditor.addTableRow);
      expect(emitted.last, '$source\n|  |  |');
      expect(find.byType(TextField), findsNWidgets(8));
    });

    testWidgets('adds a numbered column at the end', (tester) async {
      final emitted = await pumpTable(tester);
      await tapTooltip(tester, m.markdownEditor.addTableColumn);
      expect(
        emitted.last,
        '| Item | Qty | Column 3 |\n'
        '| :--- | ---: | --- |\n'
        '| Milk | 2 |  |\n'
        '| Eggs | 12 |  |',
      );
    });

    testWidgets('removes a column along with its alignment', (tester) async {
      final emitted = await pumpTable(tester);
      await tapTooltip(tester, m.markdownEditor.removeTableColumn);
      expect(emitted.last, '| Qty |\n| ---: |\n| 2 |\n| 12 |');

      // The last column stays.
      final count = emitted.length;
      await tapTooltip(tester, m.markdownEditor.removeTableColumn);
      expect(emitted, hasLength(count));
      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('removes a body row; the header has no remove button', (
      tester,
    ) async {
      final emitted = await pumpTable(tester);
      expect(find.byTooltip(m.markdownEditor.removeTableRow), findsNWidgets(2));
      await tapTooltip(tester, m.markdownEditor.removeTableRow);
      expect(
        emitted.last,
        '| Item | Qty |\n'
        '| :--- | ---: |\n'
        '| Eggs | 12 |',
      );
    });

    testWidgets('deletes the whole table, keeping the text around it', (
      tester,
    ) async {
      final emitted = <String>[];
      await tester.pumpWidget(
        wrapped(
          MarkdownEditor(
            initialValue: 'Before\n\n$source\n\nAfter',
            onChanged: emitted.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapTooltip(tester, m.markdownEditor.editTable);
      await tapTooltip(tester, m.markdownEditor.deleteTable);
      expect(emitted.last, 'Before\n\nAfter');
      expect(find.byType(Table), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('deletes a table that is the whole note', (tester) async {
      final emitted = await pumpTable(tester);
      await tapTooltip(tester, m.markdownEditor.deleteTable);
      expect(tester.takeException(), isNull);
      expect(emitted.last.trim(), isEmpty);
      expect(find.byType(Table), findsNothing);
    });

    testWidgets('long cell text wraps, and its whole row grows with it', (
      tester,
    ) async {
      await pumpTable(tester);
      // Header cells first, then the "Milk | 2" row.
      final milk = find.byType(TextField).at(2);
      final qty = find.byType(TextField).at(3);
      final before = tester.getSize(milk).height;

      await tester.tap(milk);
      await tester.pumpAndSettle();
      await tester.enterText(milk, 'Milk ' * 60);
      await tester.pumpAndSettle();

      expect(tester.getSize(milk).height, greaterThan(before * 2));
      expect(tester.getSize(qty).height, tester.getSize(milk).height);
    });

    testWidgets('line breaks in a cell become spaces', (tester) async {
      final emitted = await pumpTable(tester);
      final milk = find.widgetWithText(TextField, 'Milk');
      await tester.tap(milk);
      await tester.pumpAndSettle();
      await tester.enterText(milk, 'Oat\nmilk');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(emitted.last, contains('| Oat milk | 2 |'));
    });

    testWidgets('a table down to its header survives source mode', (
      tester,
    ) async {
      final emitted = await pumpTable(tester);
      await tapTooltip(tester, m.markdownEditor.removeTableRow);
      await tapTooltip(tester, m.markdownEditor.removeTableRow);
      expect(emitted.last, '| Item | Qty |\n| :--- | ---: |');

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('removing the focused cell\'s row keeps the editor working', (
      tester,
    ) async {
      final emitted = await pumpTable(tester);
      await tester.tap(find.widgetWithText(TextField, 'Milk'));
      await tester.pumpAndSettle();
      await tapTooltip(tester, m.markdownEditor.removeTableRow);
      expect(tester.takeException(), isNull);
      expect(emitted.last, contains('| Eggs | 12 |'));
      expect(emitted.last, isNot(contains('Milk')));
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
    });
  });

  testWidgets('cancelling the table dialog leaves the note alone', (
    tester,
  ) async {
    String? emitted;
    await tester.pumpWidget(
      wrapped(
        MarkdownEditor(
          initialValue: 'Groceries',
          onChanged: (md) => emitted = md,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await openTableDialog(tester);
    await tester.tap(find.text(m.common.cancel));
    await tester.pumpAndSettle();

    expect(emitted, isNull);
    expect(find.byType(Table), findsNothing);
  });

  testWidgets('editing a table cell writes the table back as markdown', (
    tester,
  ) async {
    String? emitted;
    await tester.pumpWidget(
      wrapped(
        MarkdownEditor(
          initialValue:
              'Groceries\n\n'
              '| Item | Qty |\n'
              '| :--- | ---: |\n'
              '| Milk | 2 |',
          onChanged: (md) => emitted = md,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final qty = find.widgetWithText(TextField, '2');
    await tester.tap(qty);
    await tester.pumpAndSettle();
    await tester.enterText(qty, '3 | 4');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      emitted,
      'Groceries\n\n'
      '| Item | Qty |\n'
      '| :--- | ---: |\n'
      r'| Milk | 3 \| 4 |',
    );
    expect(find.widgetWithText(TextField, '3 | 4'), findsOneWidget);
  });

  testWidgets('a focused table cell keeps the keyboard away from the editor', (
    tester,
  ) async {
    final editorFocus = FocusNode();
    addTearDown(editorFocus.dispose);
    await tester.pumpWidget(
      wrapped(
        MarkdownEditor(
          focusNode: editorFocus,
          initialValue:
              'Groceries\n\n'
              '| Item | Qty |\n'
              '| --- | --- |\n'
              '| Milk | 25 |',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cell = find.widgetWithText(TextField, '25');
    await tester.tap(cell);
    await tester.pumpAndSettle();
    expect(editorFocus.hasFocus, isFalse);

    final controller = tester.widget<TextField>(cell).controller!;
    controller.selection = const TextSelection.collapsed(offset: 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();
    expect(controller.text, '5');
    expect(editorFocus.hasFocus, isFalse);
  });

  testWidgets('double-tapping a table cell keeps focus in the cell', (
    tester,
  ) async {
    final editorFocus = FocusNode();
    addTearDown(editorFocus.dispose);
    await tester.pumpWidget(
      wrapped(
        MarkdownEditor(
          focusNode: editorFocus,
          initialValue:
              'Groceries\n\n'
              '| Item | Qty |\n'
              '| --- | --- |\n'
              '| Milk | 25 |',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cell = find.widgetWithText(TextField, 'Milk');
    await tester.tap(cell);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(cell);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(editorFocus.hasFocus, isFalse);
    final field = tester.widget<EditableText>(
      find.descendant(of: cell, matching: find.byType(EditableText)),
    );
    expect(field.focusNode.hasFocus, isTrue);
    // The editor's own selection stays off the table.
    final quill = tester.widget<QuillEditor>(find.byType(QuillEditor));
    expect(quill.controller.selection.isCollapsed, isTrue);
  });

  testWidgets('the first drag in a table cell selects its text', (
    tester,
  ) async {
    final editorFocus = FocusNode();
    addTearDown(editorFocus.dispose);
    await tester.pumpWidget(
      wrapped(
        MarkdownEditor(
          focusNode: editorFocus,
          initialValue:
              'Groceries\n\n'
              '| Item | Qty |\n'
              '| --- | --- |\n'
              '| Oat milk | 25 |',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cell = find.widgetWithText(TextField, 'Oat milk');
    final rect = tester.getRect(cell);
    final gesture = await tester.startGesture(
      rect.centerLeft + const Offset(10, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(rect.center + const Offset(20, 0));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(editorFocus.hasFocus, isFalse);
    final selection = tester.widget<TextField>(cell).controller!.selection;
    expect(selection.isCollapsed, isFalse);
  });

  testWidgets('clicking text after a table cell returns focus to the editor', (
    tester,
  ) async {
    final editorFocus = FocusNode();
    addTearDown(editorFocus.dispose);
    await tester.pumpWidget(
      wrapped(
        MarkdownEditor(
          focusNode: editorFocus,
          initialValue:
              'Groceries\n\n'
              '| Item | Qty |\n'
              '| --- | --- |\n'
              '| Milk | 25 |',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextField, 'Milk'));
    await tester.pumpAndSettle();
    expect(editorFocus.hasFocus, isFalse);

    final word = find.textContaining('Groceries', findRichText: true).first;
    await tester.tapAt(tester.getRect(word).centerLeft + const Offset(1, 0));
    await tester.pumpAndSettle();

    expect(editorFocus.hasFocus, isTrue);
    final quill = tester.widget<QuillEditor>(find.byType(QuillEditor));
    expect(
      quill.controller.selection,
      const TextSelection.collapsed(offset: 0),
    );
  });

  group('formatting inside a table cell', () {
    const source =
        'Groceries\n\n'
        '| Item | Qty |\n'
        '| --- | --- |\n'
        '| Oat milk | **2** |';

    TextStyle? styleOf(WidgetTester tester, Finder cell, String text) {
      final controller = tester.widget<TextField>(cell).controller!;
      final span = controller.buildTextSpan(
        context: tester.element(cell),
        withComposing: false,
      );
      TextStyle? found;
      span.visitChildren((child) {
        if (child is TextSpan && child.text == text) {
          found = child.style;
          return false;
        }
        return true;
      });
      return found;
    }

    testWidgets(
      'the toolbar formats the cell and the edit is saved',
      (tester) async {
        String? emitted;
        await tester.pumpWidget(
          wrapped(
            MarkdownEditor(
              initialValue: source,
              onChanged: (md) => emitted = md,
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Quill's block formats are on offer outside the table.
        expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);

        final cell = find.widgetWithText(TextField, 'Oat milk');
        await tester.tap(cell);
        await tester.pumpAndSettle();
        // Inside a cell, only the inline formats are.
        expect(find.byIcon(Icons.format_list_bulleted), findsNothing);
        expect(find.byIcon(Icons.format_bold), findsOneWidget);

        final controller = tester.widget<TextField>(cell).controller!;
        controller.selection = const TextSelection(
          baseOffset: 4,
          extentOffset: 8,
        );
        await tester.tap(
          find.byIcon(Icons.format_bold),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();
        expect(controller.text, 'Oat **milk**');
        // On desktop a click outside a field unfocuses it; the toolbar counts as
        // part of the cell.
        final field = tester.widget<EditableText>(
          find.byWidgetPredicate(
            (w) => w is EditableText && w.controller == controller,
          ),
        );
        expect(field.focusNode.hasFocus, isTrue);

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(emitted, contains('| Oat **milk** | **2** |'));
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets('markers are hidden until the cell is edited', (tester) async {
      await tester.pumpWidget(
        wrapped(const MarkdownEditor(initialValue: source)),
      );
      await tester.pumpAndSettle();

      final cell = find.widgetWithText(TextField, '**2**');
      expect(styleOf(tester, cell, '2')?.fontWeight, FontWeight.bold);
      expect(styleOf(tester, cell, '**')?.color, Colors.transparent);

      await tester.tap(cell);
      await tester.pumpAndSettle();
      expect(styleOf(tester, cell, '**')?.color, isNot(Colors.transparent));
    });
  });

  testWidgets('Enter in a list keeps the new item when the host echoes back', (
    tester,
  ) async {
    await tester.pumpWidget(wrapped(const _EchoingHost('- milk')));
    await tester.pumpAndSettle();

    final controller = tester
        .widget<QuillEditor>(find.byType(QuillEditor))
        .controller;
    final end = controller.document.length - 1;
    controller.replaceText(
      end,
      0,
      '\n',
      TextSelection.collapsed(offset: end + 1),
    );
    await tester.pumpAndSettle();

    // Same controller, empty second item intact, caret sitting in it.
    expect(
      tester.widget<QuillEditor>(find.byType(QuillEditor)).controller,
      same(controller),
    );
    expect(controller.document.toPlainText(), 'milk\n\n');
    expect(controller.selection.baseOffset, end + 1);
    // An item with no text yet isn't markdown the host should store.
    expect(
      tester.state<_EchoingHostState>(find.byType(_EchoingHost)).content,
      '- milk',
    );
  });

  testWidgets('typing after two returns carries on where the caret is', (
    tester,
  ) async {
    await tester.pumpWidget(wrapped(const _EchoingHost('')));
    await tester.pumpAndSettle();

    QuillController controller() =>
        tester.widget<QuillEditor>(find.byType(QuillEditor)).controller;

    Future<void> type(String text) async {
      final at = controller().selection.baseOffset;
      controller().replaceText(
        at,
        0,
        text,
        TextSelection.collapsed(offset: at + text.length),
      );
      await tester.pump();
    }

    for (final character in 'hello\n\nworld'.split('')) {
      await type(character);
    }
    await tester.pumpAndSettle();

    // Blank lines between the two paragraphs collapse when markdown is parsed
    // back, so the caret must not follow a reparse — every character belongs
    // where it was typed.
    expect(controller().document.toPlainText(), 'hello\n\nworld\n');
  });

  group('removing a link', () {
    /// Long-press the text, then pick "Remove" from flutter_quill's link menu.
    Future<void> removeLinkAt(WidgetTester tester, Offset anchor) async {
      await tester.longPressAt(anchor);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
    }

    Offset anchorOn(WidgetTester tester, String word) =>
        tester
            .getRect(find.textContaining(word, findRichText: true).first)
            .centerLeft +
        const Offset(25, 0);

    testWidgets('leaves the text selectable', (tester) async {
      await tester.pumpWidget(
        wrapped(const MarkdownEditor(initialValue: 'https://google.com')),
      );
      await tester.pumpAndSettle();

      final controller = tester
          .widget<QuillEditor>(find.byType(QuillEditor))
          .controller;
      await removeLinkAt(tester, anchorOn(tester, 'google'));

      // The link is gone for good — Quill's auto-format must not put it back.
      expect(
        controller.document.querySegmentLeafNode(1).leaf?.style.attributes,
        isEmpty,
      );

      // The long press the link used to swallow now selects a word again.
      await tester.longPressAt(anchorOn(tester, 'google'));
      await tester.pumpAndSettle();
      expect(controller.selection.isCollapsed, isFalse);
    });

    testWidgets('keeps the other formatting on the text', (tester) async {
      await tester.pumpWidget(
        wrapped(
          const MarkdownEditor(
            initialValue: '[**search**](https://google.com)',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controller = tester
          .widget<QuillEditor>(find.byType(QuillEditor))
          .controller;
      await removeLinkAt(tester, anchorOn(tester, 'search'));

      final attributes = controller.document
          .querySegmentLeafNode(1)
          .leaf
          ?.style
          .attributes;
      expect(attributes, contains(Attribute.bold.key));
      expect(attributes, isNot(contains(Attribute.link.key)));
    });
  });
}

/// Stands in for the note editor, which keeps the markdown the editor reports
/// in its own state and hands it straight back as [MarkdownEditor.initialValue].
class _EchoingHost extends StatefulWidget {
  final String initialValue;

  const _EchoingHost(this.initialValue);

  @override
  State<_EchoingHost> createState() => _EchoingHostState();
}

class _EchoingHostState extends State<_EchoingHost> {
  late String content = widget.initialValue;

  @override
  Widget build(BuildContext context) => MarkdownEditor(
    initialValue: content,
    onChanged: (markdown) => setState(() => content = markdown),
  );
}
