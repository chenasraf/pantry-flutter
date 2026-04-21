import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:pantry/models/note.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/views/notes/note_form_view.dart';
import 'package:pantry/views/notes/notes_controller.dart';

class NoteDetailView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleDir = detectTextDirection(note.title);
    final contentDir = detectTextDirection(note.content);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        title: Align(
          alignment: titleDir == TextDirection.rtl
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Directionality(
            textDirection: titleDir,
            child: Text(note.title),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => NoteFormView(controller: controller, note: note),
            ),
          );
        },
        child: const Icon(Icons.edit),
      ),
      body: Hero(
        tag: 'note-${note.id}',
        child: Material(
          color: bgColor,
          child: note.content != null && note.content!.isNotEmpty
              ? Directionality(
                  textDirection: contentDir,
                  child: Markdown(
                    data: note.content!,
                    padding: const EdgeInsets.all(16),
                    selectable: true,
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
