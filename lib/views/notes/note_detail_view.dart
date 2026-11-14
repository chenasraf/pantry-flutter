import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/utils/markdown_list.dart';
import 'package:pantry/views/checklists/import_to_list.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry/views/notes/note_form_view.dart';
import 'package:pantry/views/notes/notes_controller.dart';
import 'package:pantry/widgets/note_sync.dart';

class NoteDetailView extends StatefulWidget {
  final Note note;
  final NotesController controller;
  final Color bgColor;
  final Color textColor;

  const NoteDetailView({
    super.key,
    required this.note,
    required this.controller,
    required this.bgColor,
    required this.textColor,
  });

  @override
  State<NoteDetailView> createState() => _NoteDetailViewState();
}

class _NoteDetailViewState extends State<NoteDetailView> {
  late Note _note = widget.note;

  void _importToList(BuildContext context) {
    final content = _note.content;
    if (content == null || content.trim().isEmpty) return;
    showImportToListDialog(context, houseId: _note.houseId, markdown: content);
  }

  Future<void> _onToggleCheckbox(int ordinal) async {
    final content = _note.content;
    if (content == null) return;
    final lines = taskLines(content);
    if (ordinal >= lines.length) return;
    final line = lines[ordinal];
    final updated = await widget.controller.setTaskLine(
      _note,
      ordinal: ordinal,
      text: line.text,
      checked: !line.checked,
      sink: context.read<PrefsService>().notesCheckedToBottom,
    );
    if (!mounted) return;
    setState(() => _note = updated);
  }

  /// Each rendered checkbox's context, by task-line ordinal, so a tap anywhere
  /// on its row can be traced back to it.
  final Map<int, BuildContext> _checkboxes = {};
  PointerDownEvent? _down;
  Timer? _tapWindow;
  bool _linkTapped = false;

  void _onPointerDown(PointerDownEvent event) {
    _down = event;
    _linkTapped = false;
    _tapWindow?.cancel();
    _tapWindow = Timer(kLongPressTimeout, () => _down = null);
  }

  @override
  void dispose() {
    _tapWindow?.cancel();
    super.dispose();
  }

  /// Toggles the checkbox whose row a tap landed on.
  ///
  /// The text is selectable, and its own tap recognizers win the gesture arena
  /// against any detector wrapped around a row, so the tap is read from raw
  /// pointer events instead. Anything slower or further than a tap — a long
  /// press to select, a scroll — is left alone.
  void _onPointerUp(PointerUpEvent event) {
    final down = _down;
    _down = null;
    _tapWindow?.cancel();
    if (down == null || down.pointer != event.pointer) return;
    if ((event.position - down.position).distance > kTouchSlop) return;
    final ordinal = _checkboxRowAt(event.position);
    if (ordinal == null) return;
    // A link's recognizer fires after this pointer-up, in the same event
    // dispatch; waiting a microtask lets a link tap claim the gesture.
    scheduleMicrotask(() {
      if (_linkTapped || !mounted) return;
      _onToggleCheckbox(ordinal);
    });
  }

  /// The ordinal of the innermost task-list row containing [position]. The
  /// checkbox sits directly in the row flex the markdown builder lays out for
  /// a list item; a parent item's row also spans its sub-items, so the
  /// smallest row wins.
  int? _checkboxRowAt(Offset position) {
    int? hit;
    var hitArea = double.infinity;
    for (final MapEntry(key: ordinal, value: context) in _checkboxes.entries) {
      if (!context.mounted) continue;
      final row = context.findAncestorRenderObjectOfType<RenderFlex>();
      if (row == null || !row.attached || !row.hasSize) continue;
      final rect = MatrixUtils.transformRect(
        row.getTransformTo(null),
        Offset.zero & row.size,
      );
      final area = rect.width * rect.height;
      if (rect.contains(position) && area < hitArea) {
        hit = ordinal;
        hitArea = area;
      }
    }
    return hit;
  }

  @override
  Widget build(BuildContext context) {
    final note = _note;
    final controller = widget.controller;
    final bgColor = widget.bgColor;
    final textColor = widget.textColor;
    final theme = Theme.of(context);
    final titleDir = detectTextDirection(note.title);
    final contentDir = detectTextDirection(note.content);
    final hasEditButton = note.canEditWith(
      controller.permissions.canUpdateNotes,
    );
    final canImportToList =
        controller.permissions.canViewLists &&
        controller.permissions.canAddItems &&
        (note.content?.trim().isNotEmpty ?? false);
    // The Markdown builder invokes checkboxBuilder once per task-list item, a
    // parent after its sub-items; this counter, through the build order, maps
    // each rendered checkbox back to its `- [ ]` line in the source. Reset
    // every build.
    var checkboxIndex = 0;
    final buildOrder = taskLinesInBuildOrder(note.content ?? '');
    _checkboxes.clear();

    // The scaffold renders edge-to-edge, so the content scrolls behind the
    // system navigation bar and the floating edit button. Pad the bottom of the
    // markdown by the safe-area inset plus clearance for the FAB so the last
    // lines stay readable.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final bottomPadding = 16 + bottomInset + (hasEditButton ? 72.0 : 0.0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        title: Directionality(textDirection: titleDir, child: Text(note.title)),
        actions: [
          if (canImportToList)
            IconButton(
              icon: const Icon(Icons.playlist_add),
              tooltip: m.notesWall.importToList,
              onPressed: () => _importToList(context),
            ),
        ],
      ),
      floatingActionButton: hasEditButton
          ? FloatingActionButton(
              heroTag: null,
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        NoteFormView(controller: controller, note: note),
                  ),
                );
              },
              child: const Icon(Icons.edit),
            )
          : null,
      body: Hero(
        tag: 'note-${note.id}',
        child: Material(
          color: bgColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.isSynced)
                NoteSyncHeader(note: note, textColor: textColor),
              if (note.content != null && note.content!.isNotEmpty)
                Expanded(
                  child: Listener(
                    onPointerDown: hasEditButton ? _onPointerDown : null,
                    onPointerUp: hasEditButton ? _onPointerUp : null,
                    child: Directionality(
                      textDirection: contentDir,
                      child: Markdown(
                        data: note.content!,
                        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
                        selectable: true,
                        softLineBreak: true,
                        checkboxBuilder: (checked) {
                          final built = checkboxIndex++;
                          final ordinal = built < buildOrder.length
                              ? buildOrder[built]
                              : built;
                          final icon = Icon(
                            checked
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 20,
                            color: textColor.withAlpha(230),
                          );
                          if (!hasEditButton) return icon;
                          return Builder(
                            builder: (context) {
                              _checkboxes[ordinal] = context;
                              return icon;
                            },
                          );
                        },
                        onTapLink: (text, href, title) {
                          _linkTapped = true;
                          if (href != null) {
                            launchUrl(Uri.parse(href));
                          }
                        },
                        styleSheet: MarkdownStyleSheet.fromTheme(theme)
                            .copyWith(
                              p: theme.textTheme.bodyLarge?.copyWith(
                                color: textColor.withAlpha(230),
                              ),
                              h1: theme.textTheme.headlineMedium?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              h2: theme.textTheme.headlineSmall?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              h3: theme.textTheme.titleLarge?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              h4: theme.textTheme.titleMedium?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              listBullet: theme.textTheme.bodyLarge?.copyWith(
                                color: textColor.withAlpha(230),
                              ),
                              code: TextStyle(
                                color: textColor,
                                backgroundColor: textColor.withAlpha(30),
                                fontFamily: 'monospace',
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: textColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              blockquote: theme.textTheme.bodyLarge?.copyWith(
                                color: textColor.withAlpha(180),
                                fontStyle: FontStyle.italic,
                              ),
                              blockquoteDecoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: textColor.withAlpha(100),
                                    width: 4,
                                  ),
                                ),
                              ),
                              a: TextStyle(
                                color: textColor,
                                decoration: TextDecoration.underline,
                              ),
                              strong: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              em: TextStyle(
                                color: textColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
