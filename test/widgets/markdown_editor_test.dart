import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/i18n.dart';
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
