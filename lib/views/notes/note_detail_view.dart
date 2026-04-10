import 'package:flutter/material.dart';

import 'package:pantry/models/note.dart';
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
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        title: Text(note.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => NoteFormView(controller: controller, note: note),
            ),
          );
        },
        child: const Icon(Icons.edit),
      ),
      body: note.content != null && note.content!.isNotEmpty
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                note.content!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textColor.withAlpha(220),
                ),
              ),
            )
          : null,
    );
  }
}
