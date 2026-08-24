import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/note.dart';
import 'package:pantry/utils/markdown_list.dart';
import 'package:pantry/views/checklists/import_to_list.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/views/notes/note_form_view.dart';
import 'package:pantry/views/notes/notes_controller.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';

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

  void _onToggleCheckbox(int ordinal) {
    final content = _note.content;
    if (content == null) return;
    final updated = toggleChecklistItem(content, ordinal);
    if (updated == content) return;
    setState(() => _note = _note.copyWith(content: updated));
    widget.controller.updateNote(_note, content: updated);
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
    // The Markdown builder invokes checkboxBuilder once per task-list item in
    // document order; this counter maps each rendered checkbox back to the Nth
    // `- [ ]` line in the source. Reset every build.
    var checkboxIndex = 0;

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
        leading: appBarBackLeading(context),
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
          child: note.content != null && note.content!.isNotEmpty
              ? Directionality(
                  textDirection: contentDir,
                  child: Markdown(
                    data: note.content!,
                    padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
                    selectable: true,
                    softLineBreak: true,
                    checkboxBuilder: (checked) {
                      final ordinal = checkboxIndex++;
                      final icon = Icon(
                        checked
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 20,
                        color: textColor.withAlpha(230),
                      );
                      if (!hasEditButton) return icon;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _onToggleCheckbox(ordinal),
                        child: icon,
                      );
                    },
                    onTapLink: (text, href, title) {
                      if (href != null) {
                        launchUrl(Uri.parse(href));
                      }
                    },
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
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
                )
              : null,
        ),
      ),
    );
  }
}
