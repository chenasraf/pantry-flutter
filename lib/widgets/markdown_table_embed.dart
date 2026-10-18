import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown_quill/markdown_quill.dart';

import 'package:pantry/utils/markdown_inline.dart';
import 'package:pantry/utils/markdown_table.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry_core/utils/text_direction.dart';

/// What a [MarkdownEditor] shares with the table embeds inside it.
class TableEmbedHost extends ChangeNotifier {
  /// Focus parent for table cells, sitting outside Quill. Under Quill's own
  /// node, a focused cell would make the editor report focus too: Quill then
  /// shows its caret, takes the text-input connection from the cell, and
  /// handles the cell's keys itself.
  final FocusNode focusParent = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
  );

  final Set<BuildContext> _regions = {};

  /// The cell being edited, which the toolbar formats while it's set.
  TableCellController? get activeCell => _activeCell;
  TableCellController? _activeCell;

  void _register(BuildContext context) => _regions.add(context);
  void _unregister(BuildContext context) => _regions.remove(context);

  void _setActive(TableCellController cell, {required bool active}) {
    if (active) {
      if (_activeCell == cell) return;
      _activeCell = cell;
    } else {
      if (_activeCell != cell) return;
      _activeCell = null;
    }
    notifyListeners();
  }

  /// Whether [globalPosition] falls on a table.
  bool covers(Offset globalPosition) => _regions.any((context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    return (Offset.zero & box.size).contains(box.globalToLocal(globalPosition));
  });

  @override
  void dispose() {
    focusParent.dispose();
    super.dispose();
  }
}

/// Renders a markdown table held as an [EmbeddableTable] as a grid of editable
/// cells. Quill has no table block, so an edit swaps the whole embed for one
/// holding the rewritten markdown.
class TableEmbedBuilder extends EmbedBuilder {
  final TableEmbedHost host;

  const TableEmbedBuilder(this.host);

  @override
  String get key => EmbeddableTable.tableType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final node = embedContext.node;
    final controller = embedContext.controller;
    return Actions(
      actions: _fieldEditingActions,
      child: Focus(
        parentNode: host.focusParent,
        skipTraversal: true,
        canRequestFocus: false,
        child: _EditableTable(
          host: host,
          markdown: node.value.data as String,
          readOnly: embedContext.readOnly,
          onChanged: (markdown) => controller.replaceText(
            node.documentOffset,
            1,
            EmbeddableTable(markdown),
            null,
            ignoreFocus: true,
          ),
          // The embed sits alone on its line; its newline goes with it. Not
          // ignoreFocus like the edits above: Quill skips rebuilding on such
          // changes, which would leave the deleted table on screen.
          onDeleted: () {
            final offset = node.documentOffset;
            controller.replaceText(
              offset,
              2,
              '',
              TextSelection.collapsed(offset: offset),
            );
          },
        ),
      ),
    );
  }
}

/// [EditableText]'s editing actions are overridable by any ancestor [Actions]
/// handling the same intent, and Quill's editor registers its own for all of
/// them — so inside an embed, a text field's Backspace would edit Quill's
/// document instead. Sitting nearer than Quill's, these hand each intent back
/// to the field's own action.
final Map<Type, Action<Intent>> _fieldEditingActions = {
  DeleteCharacterIntent: _DeferToField<DeleteCharacterIntent>(),
  DeleteToNextWordBoundaryIntent:
      _DeferToField<DeleteToNextWordBoundaryIntent>(),
  DeleteToLineBreakIntent: _DeferToField<DeleteToLineBreakIntent>(),
  ExtendSelectionByCharacterIntent:
      _DeferToField<ExtendSelectionByCharacterIntent>(),
  ExtendSelectionToNextWordBoundaryIntent:
      _DeferToField<ExtendSelectionToNextWordBoundaryIntent>(),
  ExtendSelectionToNextWordBoundaryOrCaretLocationIntent:
      _DeferToField<ExtendSelectionToNextWordBoundaryOrCaretLocationIntent>(),
  ExtendSelectionToLineBreakIntent:
      _DeferToField<ExtendSelectionToLineBreakIntent>(),
  ExpandSelectionToLineBreakIntent:
      _DeferToField<ExpandSelectionToLineBreakIntent>(),
  ExtendSelectionToDocumentBoundaryIntent:
      _DeferToField<ExtendSelectionToDocumentBoundaryIntent>(),
  ExpandSelectionToDocumentBoundaryIntent:
      _DeferToField<ExpandSelectionToDocumentBoundaryIntent>(),
  ExtendSelectionVerticallyToAdjacentLineIntent:
      _DeferToField<ExtendSelectionVerticallyToAdjacentLineIntent>(),
  ExtendSelectionVerticallyToAdjacentPageIntent:
      _DeferToField<ExtendSelectionVerticallyToAdjacentPageIntent>(),
  SelectAllTextIntent: _DeferToField<SelectAllTextIntent>(),
  CopySelectionTextIntent: _DeferToField<CopySelectionTextIntent>(),
  PasteTextIntent: _DeferToField<PasteTextIntent>(),
  UndoTextIntent: _DeferToField<UndoTextIntent>(),
  RedoTextIntent: _DeferToField<RedoTextIntent>(),
  ReplaceTextIntent: _DeferToField<ReplaceTextIntent>(),
  UpdateSelectionIntent: _DeferToField<UpdateSelectionIntent>(),
  DoNothingAndStopPropagationTextIntent:
      _DeferToField<DoNothingAndStopPropagationTextIntent>(),
};

class _DeferToField<T extends Intent> extends ContextAction<T> {
  @override
  bool isEnabled(T intent, [BuildContext? context]) {
    final action = callingAction;
    if (action is ContextAction<T>) return action.isEnabled(intent, context);
    return action?.isEnabled(intent) ?? false;
  }

  @override
  bool consumesKey(T intent) => callingAction?.consumesKey(intent) ?? false;

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    final action = callingAction;
    if (action is ContextAction<T>) return action.invoke(intent, context);
    return action?.invoke(intent);
  }
}

/// A cell's raw markdown, drawn with its inline formatting applied. The
/// markers stay in the text so offsets and selection map one-to-one: they show
/// dimmed while the cell is edited and shrink to nothing otherwise.
class TableCellController extends TextEditingController {
  TableCellController({super.text});

  bool get editing => _editing;
  bool _editing = false;
  set editing(bool value) {
    if (value == _editing) return;
    _editing = value;
    notifyListeners();
  }

  bool isActive(InlineStyle style) => isInlineStyleActive(value, style);

  void toggle(InlineStyle style) => value = toggleInlineStyle(value, style);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // The IME underlines what it's composing; leave that to the default.
    if (withComposing && value.isComposingRangeValid) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final color = style?.color ?? scheme.onSurface;
    return TextSpan(
      style: style,
      children: [
        for (final segment in parseInlineMarkdown(text))
          TextSpan(
            text: segment.text,
            style: segment.marker
                ? _markerStyle(color)
                : _contentStyle(segment.styles, scheme),
          ),
      ],
    );
  }

  TextStyle _markerStyle(Color color) => _editing
      ? TextStyle(color: color.withValues(alpha: 0.4))
      // Not 0: some engines reject a zero font size.
      : const TextStyle(fontSize: 0.01, color: Colors.transparent);

  TextStyle? _contentStyle(Set<InlineStyle> styles, ColorScheme scheme) {
    if (styles.isEmpty) return null;
    final link = styles.contains(InlineStyle.link);
    return TextStyle(
      fontWeight: styles.contains(InlineStyle.bold) ? FontWeight.bold : null,
      fontStyle: styles.contains(InlineStyle.italic) ? FontStyle.italic : null,
      fontFamily: styles.contains(InlineStyle.code) ? 'monospace' : null,
      fontFamilyFallback: styles.contains(InlineStyle.code)
          ? const ['Menlo', 'Roboto Mono', 'Courier']
          : null,
      color: link ? scheme.primary : null,
      decoration: TextDecoration.combine([
        if (styles.contains(InlineStyle.strikethrough))
          TextDecoration.lineThrough,
        if (link) TextDecoration.underline,
      ]),
    );
  }
}

/// The inline formats a cell supports, with their toolbar icons and labels.
List<(InlineStyle, IconData, String)> _cellFormats(BuildContext context) {
  final loc = FlutterQuillLocalizations.of(context);
  return [
    (InlineStyle.bold, Icons.format_bold, loc?.bold ?? 'Bold'),
    (InlineStyle.italic, Icons.format_italic, loc?.italic ?? 'Italic'),
    (
      InlineStyle.strikethrough,
      Icons.format_strikethrough,
      loc?.strikeThrough ?? 'Strikethrough',
    ),
    (InlineStyle.code, Icons.code, loc?.inlineCode ?? 'Code'),
    (InlineStyle.link, Icons.link, loc?.link ?? 'Link'),
  ];
}

/// Formatting toolbar shown in place of Quill's while a cell is edited. Cells
/// hold inline markdown only, so block formats (headings, lists, quotes) are
/// left out.
class TableCellToolbar extends StatelessWidget {
  final TableCellController cell;

  const TableCellToolbar({super.key, required this.cell});

  @override
  Widget build(BuildContext context) {
    // Counts as part of the cell's field, so a click here doesn't unfocus it.
    return TextFieldTapRegion(
      child: ListenableBuilder(
        listenable: cell,
        builder: (context, _) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (style, icon, label) in _cellFormats(context))
                QuillToolbarIconButton(
                  tooltip: label,
                  icon: Icon(icon, size: kDefaultIconSize * 1.2),
                  isSelected: cell.isActive(style),
                  iconTheme: null,
                  onPressed: () => cell.toggle(style),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks for a table size and returns a blank table of that size, with numbered
/// column headers: GFM has no table without a header row.
Future<MarkdownTable?> showInsertTableDialog(BuildContext context) async {
  final size = await showDialog<(int, int)>(
    context: context,
    builder: (_) => const _InsertTableDialog(),
  );
  if (size == null) return null;
  final (columns, rows) = size;
  return MarkdownTable(
    header: [
      for (var c = 1; c <= columns; c++) m.markdownEditor.tableColumnHeader(c),
    ],
    alignments: List.filled(columns, '---'),
    rows: List.generate(rows, (_) => List.filled(columns, '')),
  );
}

class _InsertTableDialog extends StatefulWidget {
  const _InsertTableDialog();

  @override
  State<_InsertTableDialog> createState() => _InsertTableDialogState();
}

class _InsertTableDialogState extends State<_InsertTableDialog> {
  static const _maxColumns = 8;
  static const _maxRows = 30;

  int _columns = 2;
  int _rows = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(m.markdownEditor.insertTable),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Counter(
            label: m.markdownEditor.tableColumns,
            value: _columns,
            max: _maxColumns,
            onChanged: (v) => setState(() => _columns = v),
          ),
          _Counter(
            label: m.markdownEditor.tableRows,
            value: _rows,
            max: _maxRows,
            onChanged: (v) => setState(() => _rows = v),
          ),
          const SizedBox(height: 12),
          _TablePreview(columns: _columns, rows: _rows),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(m.common.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_columns, _rows)),
          child: Text(m.markdownEditor.insert),
        ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _Counter({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove),
          tooltip: '$label −',
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: '$label +',
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

/// A miniature of the table being created, header row shaded.
class _TablePreview extends StatelessWidget {
  final int columns;
  final int rows;

  const _TablePreview({required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Tall tables are cut off rather than growing the dialog.
    const shownRows = 8;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Table(
        border: TableBorder.all(color: scheme.outline),
        children: [
          for (var r = 0; r <= rows && r <= shownRows; r++)
            TableRow(
              decoration: r == 0
                  ? BoxDecoration(color: scheme.surfaceContainerHighest)
                  : null,
              children: [
                for (var c = 0; c < columns; c++) const SizedBox(height: 14),
              ],
            ),
        ],
      ),
    );
  }
}

class _EditableTable extends StatefulWidget {
  final TableEmbedHost host;
  final String markdown;
  final bool readOnly;
  final ValueChanged<String> onChanged;
  final VoidCallback onDeleted;

  const _EditableTable({
    required this.host,
    required this.markdown,
    required this.readOnly,
    required this.onChanged,
    required this.onDeleted,
  });

  @override
  State<_EditableTable> createState() => _EditableTableState();
}

class _EditableTableState extends State<_EditableTable> {
  late MarkdownTable _table;
  late List<String> _alignments;

  /// Whether the row, column and delete controls are showing.
  bool _editingLayout = false;

  /// Row 0 is the header; the rest follow the table's body rows.
  late List<List<TableCellController>> _cells;

  @override
  void initState() {
    super.initState();
    widget.host._register(context);
    _load();
  }

  @override
  void didUpdateWidget(covariant _EditableTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.markdown != oldWidget.markdown &&
        widget.markdown != _table.toMarkdown()) {
      _disposeCells();
      _load();
    }
  }

  void _load() {
    _table = MarkdownTable.parse(widget.markdown);
    _alignments = [..._table.alignments];
    _cells = [
      for (final row in [_table.header, ..._table.rows])
        [for (final cell in row) TableCellController(text: cell)],
    ];
  }

  void _disposeCells() => _release([for (final row in _cells) ...row]);

  /// Disposed after the frame: a removed cell's field may still hold focus,
  /// and its focus-loss callback fires as the field unmounts.
  void _release(List<TableCellController> cells) {
    for (final cell in cells) {
      widget.host._setActive(cell, active: false);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final cell in cells) {
        cell.dispose();
      }
    });
  }

  int get _columnCount => _alignments.length;

  void _addRow() {
    setState(() {
      _cells.add([
        for (var c = 0; c < _columnCount; c++) TableCellController(),
      ]);
    });
    _commit();
  }

  void _addColumn() {
    setState(() {
      _alignments.add('---');
      _cells.first.add(
        TableCellController(
          text: m.markdownEditor.tableColumnHeader(_columnCount),
        ),
      );
      for (final row in _cells.skip(1)) {
        row.add(TableCellController());
      }
    });
    _commit();
  }

  /// [index] counts the header as row 0, which can't be removed: GFM has no
  /// table without one.
  void _removeRow(int index) {
    setState(() => _release(_cells.removeAt(index)));
    _commit();
  }

  void _removeColumn(int index) {
    setState(() {
      _alignments.removeAt(index);
      _release([for (final row in _cells) row.removeAt(index)]);
    });
    _commit();
  }

  @override
  void dispose() {
    widget.host._unregister(context);
    _disposeCells();
    super.dispose();
  }

  /// Writes back on leaving a cell rather than per keystroke: each write swaps
  /// the embed, and doing that mid-typing would rebuild the cell under the
  /// caret.
  void _commit() {
    final values = [
      for (final row in _cells) [for (final cell in row) cell.text],
    ];
    final next = MarkdownTable(
      header: values.first,
      alignments: [..._alignments],
      rows: values.skip(1).toList(),
    );
    final markdown = next.toMarkdown();
    if (markdown == _table.toMarkdown()) return;
    _table = next;
    widget.onChanged(markdown);
  }

  void _onCellFocusChange(TableCellController cell, bool focused) {
    if (!_cells.any((row) => row.contains(cell))) return;
    cell.editing = focused;
    widget.host._setActive(cell, active: focused);
    if (!focused) _commit();
  }

  /// The platform's selection menu, plus the cell's formats for a ranged
  /// selection — matching the editor's own menu.
  Widget _contextMenu(
    BuildContext context,
    EditableTextState state,
    TableCellController cell,
  ) {
    final items = [...state.contextMenuButtonItems];
    if (!cell.selection.isCollapsed) {
      for (final (style, _, label) in _cellFormats(context)) {
        items.add(
          ContextMenuButtonItem(
            label: label,
            onPressed: () {
              cell.toggle(style);
              state.hideToolbar();
            },
          ),
        );
      }
    }
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: items,
    );
  }

  /// Touch screens get finger-sized controls (and rows tall enough to hold
  /// them); a mouse pointer gets compact ones.
  static final bool _touch = PlatformInfo.isMobile;
  static double get _controlSize => _touch ? 44 : 28;
  static double get _removeBarHeight => _touch ? 40 : 22;
  static const _gap = 4.0;

  /// A tinted bar filling the space it's given: red to remove, the theme's
  /// primary to add.
  Widget _control({
    required String tooltip,
    required VoidCallback? onPressed,
    required bool remove,
    IconData? icon,
    EdgeInsetsGeometry margin = EdgeInsets.zero,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final (background, foreground) = !enabled
        ? (
            scheme.onSurface.withValues(alpha: 0.06),
            scheme.onSurface.withValues(alpha: 0.3),
          )
        : remove
        ? (scheme.errorContainer, scheme.onErrorContainer)
        : (scheme.primaryContainer, scheme.onPrimaryContainer);
    return Padding(
      padding: margin,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(4),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Icon(
                icon ?? (remove ? Icons.close : Icons.add),
                size: 16,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The edit / done toggle in the table's top trailing corner.
  Widget _modeToggle() => SizedBox(
    width: _controlSize + _gap,
    height: _removeBarHeight + _gap,
    child: _control(
      tooltip: _editingLayout
          ? m.markdownEditor.doneEditingTable
          : m.markdownEditor.editTable,
      onPressed: () => setState(() => _editingLayout = !_editingLayout),
      remove: false,
      icon: _editingLayout ? Icons.check : Icons.edit_outlined,
      margin: const EdgeInsetsDirectional.only(start: _gap, bottom: _gap),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final table = _grid(context);
    if (widget.readOnly) return table;
    if (!_editingLayout) {
      // The toggle sits in the strip the column controls take when shown, so
      // the cells don't shift down on entering layout editing.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _modeToggle(),
          ),
          table,
        ],
      );
    }
    // Controls: an X above each column and after each body row, bars to add a
    // column (trailing side) and a row (below), and the table's delete and
    // done buttons in the top trailing corner.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: table),
              SizedBox(
                width: _controlSize + _gap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _modeToggle(),
                    Expanded(
                      child: _control(
                        tooltip: m.markdownEditor.addTableColumn,
                        onPressed: _addColumn,
                        remove: false,
                        margin: const EdgeInsetsDirectional.only(start: _gap),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: _controlSize + _gap * 2,
          child: _control(
            tooltip: m.markdownEditor.addTableRow,
            onPressed: _addRow,
            remove: false,
            margin: EdgeInsetsDirectional.only(
              top: _gap,
              bottom: _gap,
              end: (_controlSize + _gap) * 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _grid(BuildContext context) {
    final side = BorderSide(color: Theme.of(context).dividerColor);
    final base = DefaultTextStyle.of(context).style;
    final editable = !widget.readOnly && _editingLayout;
    // Borders are drawn per cell rather than by the table, so the control
    // row and column stay unframed.
    BoxDecoration frame(int r, int c) => BoxDecoration(
      border: BorderDirectional(
        top: r == 0 ? side : BorderSide.none,
        start: c == 0 ? side : BorderSide.none,
        end: side,
        bottom: side,
      ),
    );
    return Table(
      // Every cell takes its row's full height, so the borders join up.
      defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
      columnWidths: {
        if (editable) _columnCount: FixedColumnWidth(_controlSize + _gap),
      },
      children: [
        if (editable)
          TableRow(
            children: [
              for (var c = 0; c < _columnCount; c++)
                SizedBox(
                  height: _removeBarHeight + _gap,
                  child: _control(
                    tooltip: m.markdownEditor.removeTableColumn,
                    onPressed: _columnCount > 1 ? () => _removeColumn(c) : null,
                    remove: true,
                    margin: const EdgeInsetsDirectional.only(
                      start: 2,
                      end: 2,
                      bottom: _gap,
                    ),
                  ),
                ),
              SizedBox(
                height: _removeBarHeight + _gap,
                child: _control(
                  tooltip: m.markdownEditor.deleteTable,
                  onPressed: widget.onDeleted,
                  remove: true,
                  icon: Icons.delete_outline,
                  margin: const EdgeInsetsDirectional.only(
                    start: _gap,
                    bottom: _gap,
                  ),
                ),
              ),
            ],
          ),
        for (var r = 0; r < _cells.length; r++)
          TableRow(
            children: [
              for (var c = 0; c < _columnCount; c++)
                DecoratedBox(
                  decoration: frame(r, c),
                  child: _cell(_cells[r][c], header: r == 0, base: base),
                ),
              if (editable)
                r == 0
                    ? const SizedBox.shrink()
                    : _control(
                        tooltip: m.markdownEditor.removeTableRow,
                        onPressed: () => _removeRow(r),
                        remove: true,
                        margin: const EdgeInsetsDirectional.only(
                          start: _gap,
                          top: 2,
                          bottom: 2,
                        ),
                      ),
            ],
          ),
      ],
    );
  }

  Widget _cell(
    TableCellController cell, {
    required bool header,
    required TextStyle base,
  }) {
    return Focus(
      skipTraversal: true,
      onFocusChange: (focused) => _onCellFocusChange(cell, focused),
      child: TextField(
        controller: cell,
        readOnly: widget.readOnly,
        // Long text wraps, but a GFM cell is a single line of markdown:
        // Enter finishes the cell and pasted line breaks become spaces.
        maxLines: null,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.deny(
            RegExp(r'\r?\n'),
            replacementString: ' ',
          ),
        ],
        textDirection: detectTextDirection(cell.text),
        style: header ? base.copyWith(fontWeight: FontWeight.bold) : base,
        onSubmitted: (_) => _commit(),
        contextMenuBuilder: (context, state) =>
            _contextMenu(context, state, cell),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsetsDirectional.symmetric(
            horizontal: 8,
            vertical: _touch ? 12 : 6,
          ),
        ),
      ),
    );
  }
}
