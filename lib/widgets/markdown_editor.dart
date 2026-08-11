import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/utils/markdown_delta.dart';
import 'package:pantry/utils/text_direction.dart';

/// A markdown editor with two synced views:
///
///  * **Rich** (default) — a WYSIWYG surface (flutter_quill) where text renders
///    formatted as you type, markers hidden, with a formatting toolbar.
///  * **Source** — the raw markdown in a plain multiline field, for when you
///    want to see or hand-edit the syntax.
///
/// A toggle in the toolbar row flips between them and carries the content across
/// (rich → source serializes the document; source → rich reparses it), mirroring
/// the Nextcloud web app's "Rich text" switch.
///
/// The widget speaks plain markdown throughout: it seeds from [initialValue] and
/// reports edits through [onChanged] as a markdown string, so storage stays raw
/// markdown regardless of which view is active. It is uncontrolled — passing a
/// *different* [initialValue] later (a draft reset) reseeds it, but its own
/// output echoed back does not. Direction is detected from the content.
class MarkdownEditor extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String>? onChanged;
  final String? placeholder;

  /// Fill the parent's height (the editor is wrapped in an [Expanded], so the
  /// widget must sit in a [Column]/flex parent). Used by the full-screen note
  /// editor. When false the editor sizes between [minHeight] and [maxHeight],
  /// scrolling internally past the max.
  final bool expands;
  final double minHeight;
  final double maxHeight;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Overrides text + icon color for the toolbar and rendered content. The
  /// notes editor sets it so content stays legible on colored note backgrounds.
  final Color? foregroundColor;
  final EdgeInsetsGeometry contentPadding;

  /// When non-null the rich ⇄ source mode is controlled by the parent (which
  /// renders its own toggle — e.g. the note editor puts it in the app bar) and
  /// the built-in toggle button is hidden. When null the editor owns the mode
  /// and shows its own toggle in the toolbar row.
  final bool? sourceMode;

  const MarkdownEditor({
    super.key,
    required this.initialValue,
    this.onChanged,
    this.placeholder,
    this.expands = false,
    this.minHeight = 72,
    this.maxHeight = 220,
    this.autofocus = false,
    this.focusNode,
    this.foregroundColor,
    this.contentPadding = EdgeInsets.zero,
    this.sourceMode,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late QuillController _controller;
  late final ScrollController _scrollController = ScrollController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool get _ownsFocusNode => widget.focusNode == null;

  /// Raw-markdown view. Populated from the rich document each time source mode
  /// is entered.
  final TextEditingController _sourceController = TextEditingController();
  final FocusNode _sourceFocus = FocusNode();

  /// Internal mode, used only when the parent doesn't control it via
  /// [MarkdownEditor.sourceMode].
  bool _ownSourceMode = false;
  bool get _sourceMode => widget.sourceMode ?? _ownSourceMode;

  /// The last markdown we surfaced to [onChanged]. Also the yardstick for
  /// deciding whether an incoming [initialValue] is a genuine external reset
  /// versus our own value echoed back.
  String _lastEmitted = '';
  TextDirection _dir = TextDirection.ltr;

  @override
  void initState() {
    super.initState();
    _controller = _makeController(widget.initialValue);
    if (_sourceMode) _sourceController.text = _lastEmitted;
  }

  QuillController _makeController(String markdown) {
    final controller = QuillController(
      document: markdownToDocument(markdown),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _lastEmitted = documentToMarkdown(controller.document);
    _dir = detectTextDirection(controller.document.toPlainText());
    controller.addListener(_onRichChanged);
    return controller;
  }

  void _emit(String markdown) {
    final dir = detectTextDirection(markdown);
    if (dir != _dir) setState(() => _dir = dir);
    if (markdown == _lastEmitted) return;
    _lastEmitted = markdown;
    widget.onChanged?.call(markdown);
  }

  void _onRichChanged() => _emit(documentToMarkdown(_controller.document));

  void _onSourceChanged(String text) => _emit(text);

  /// Rich → source: fill the source field with the document's markdown.
  void _enterSourceMode() {
    _sourceController.text = documentToMarkdown(_controller.document);
    _sourceFocus.requestFocus();
  }

  /// Source → rich: reparse the (possibly hand-edited) markdown into a fresh
  /// document.
  void _enterRichMode() {
    _controller.removeListener(_onRichChanged);
    _controller.dispose();
    _controller = _makeController(_sourceController.text);
    _focusNode.requestFocus();
  }

  /// Sets the editor's own mode (only used when the parent isn't controlling it
  /// via [MarkdownEditor.sourceMode]).
  void _setOwnMode({required bool source}) {
    if (source == _ownSourceMode) return;
    if (source) {
      _enterSourceMode();
    } else {
      _enterRichMode();
    }
    setState(() => _ownSourceMode = source);
  }

  @override
  void didUpdateWidget(covariant MarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reseed only when the caller hands us a genuinely different starting value
    // (a reset), not when it feeds our own last output back as initialValue.
    if (widget.initialValue != oldWidget.initialValue &&
        normalizeMarkdown(widget.initialValue) != _lastEmitted) {
      _controller.removeListener(_onRichChanged);
      _controller.dispose();
      _controller = _makeController(widget.initialValue);
      if (_sourceMode) _sourceController.text = _lastEmitted;
    }
    // Parent-driven mode change (toggle lives in their app bar).
    if (widget.sourceMode != null &&
        widget.sourceMode != oldWidget.sourceMode) {
      if (widget.sourceMode!) {
        _enterSourceMode();
      } else {
        _enterRichMode();
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onRichChanged);
    _controller.dispose();
    _sourceController.dispose();
    _sourceFocus.dispose();
    _scrollController.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _sourceMode ? _sourceField() : _richEditor();

    Widget column = Column(
      mainAxisSize: widget.expands ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        const SizedBox(height: 4),
        widget.expands ? Expanded(child: body) : _bounded(body),
      ],
    );

    final fg = widget.foregroundColor;
    if (fg != null) {
      final base = Theme.of(context);
      column = Theme(
        data: base.copyWith(
          iconTheme: base.iconTheme.copyWith(color: fg),
          textTheme: base.textTheme.apply(bodyColor: fg, displayColor: fg),
        ),
        child: column,
      );
    }
    return column;
  }

  Widget _bounded(Widget child) => ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: widget.minHeight,
      maxHeight: widget.maxHeight,
    ),
    child: child,
  );

  Widget _richEditor() => Directionality(
    textDirection: _dir,
    child: QuillEditor(
      controller: _controller,
      focusNode: _focusNode,
      scrollController: _scrollController,
      config: QuillEditorConfig(
        placeholder: widget.placeholder,
        padding: widget.contentPadding,
        autoFocus: widget.autofocus,
        expands: widget.expands,
        scrollable: true,
      ),
    ),
  );

  Widget _sourceField() {
    final base = DefaultTextStyle.of(context).style;
    return TextField(
      controller: _sourceController,
      focusNode: _sourceFocus,
      onChanged: _onSourceChanged,
      textDirection: _dir,
      expands: widget.expands,
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      keyboardType: TextInputType.multiline,
      style: base.copyWith(
        fontFamily: 'monospace',
        fontFamilyFallback: const ['Menlo', 'Roboto Mono', 'Courier'],
        fontSize: 14,
      ),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        contentPadding: widget.contentPadding,
        hintText: widget.placeholder,
      ),
    );
  }

  /// The toolbar (rich mode) or an empty spacer (source mode), plus the built-in
  /// rich ⇄ source toggle — unless the parent owns the toggle.
  Widget _header() {
    final ownsToggle = widget.sourceMode == null;
    if (_sourceMode) {
      // Nothing to show in source mode except our own toggle, if we own it.
      return ownsToggle
          ? Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _modeToggle(),
            )
          : const SizedBox.shrink();
    }
    return Row(
      children: [
        Expanded(child: _toolbar()),
        if (ownsToggle) ...[const SizedBox(width: 4), _modeToggle()],
      ],
    );
  }

  Widget _modeToggle() => MarkdownModeSwitch(
    richMode: !_sourceMode,
    foregroundColor: widget.foregroundColor,
    onChanged: (rich) => _setOwnMode(source: !rich),
  );

  Widget _toolbar() {
    return QuillSimpleToolbar(
      controller: _controller,
      config: const QuillSimpleToolbarConfig(
        multiRowsDisplay: false,
        showDividers: false,
        // Blend into whatever sits behind the editor — the note's color, or the
        // surface card on the item form — instead of flutter_quill's default
        // dark canvas strip.
        color: Colors.transparent,
        // Formatting we support (maps cleanly to markdown).
        showBoldButton: true,
        showItalicButton: true,
        showStrikeThrough: true,
        showInlineCode: true,
        showHeaderStyle: true,
        showListBullets: true,
        showListNumbers: true,
        showListCheck: true,
        showCodeBlock: true,
        showQuote: true,
        showLink: true,
        showDirection: true,
        // Everything else has no markdown representation — keep it out.
        showFontFamily: false,
        showFontSize: false,
        showSmallButton: false,
        showUnderLineButton: false,
        showLineHeightButton: false,
        showColorButton: false,
        showBackgroundColorButton: false,
        showClearFormat: false,
        showAlignmentButtons: false,
        showIndent: false,
        showSearchButton: false,
        showSubscript: false,
        showSuperscript: false,
        showUndo: false,
        showRedo: false,
      ),
    );
  }
}

/// The "Rich text" switch that flips a [MarkdownEditor] between its rich and
/// source views — on (default) is rich, off is raw markdown. Mirrors the
/// Nextcloud web app's control. Exposed so a parent that hosts the editor (the
/// note editor, which puts it in the app bar) can render the toggle itself and
/// drive [MarkdownEditor.sourceMode].
class MarkdownModeSwitch extends StatelessWidget {
  /// True when the rich (WYSIWYG) view is active — the switch is on.
  final bool richMode;
  final ValueChanged<bool> onChanged;
  final Color? foregroundColor;

  const MarkdownModeSwitch({
    super.key,
    required this.richMode,
    required this.onChanged,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          m.markdownEditor.editRich,
          style: TextStyle(
            color: fg,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Switch(
          value: richMode,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          // Tint the "on" (rich) state with the surrounding foreground so it
          // reads on colored note backgrounds.
          activeTrackColor: foregroundColor?.withValues(alpha: 0.5),
          activeThumbColor: foregroundColor,
        ),
      ],
    );
  }
}
