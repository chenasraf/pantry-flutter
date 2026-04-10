import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/note.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/views/notes/notes_controller.dart';

const _colorOptions = <String?>[
  null, // default / no color
  '#f44336', // red
  '#e91e63', // pink
  '#9c27b0', // purple
  '#673ab7', // deep purple
  '#3f51b5', // indigo
  '#2196f3', // blue
  '#03a9f4', // light blue
  '#00bcd4', // cyan
  '#009688', // teal
  '#4caf50', // green
  '#8bc34a', // light green
  '#cddc39', // lime
  '#ffeb3b', // yellow
  '#ffc107', // amber
  '#ff9800', // orange
  '#ff5722', // deep orange
];

class NoteFormView extends StatefulWidget {
  final NotesController controller;
  final Note? note;

  const NoteFormView({super.key, required this.controller, this.note});

  @override
  State<NoteFormView> createState() => _NoteFormViewState();
}

class _NoteFormViewState extends State<NoteFormView> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  String? _selectedColor;
  bool _saving = false;
  TextDirection _titleDir = TextDirection.ltr;
  TextDirection _contentDir = TextDirection.ltr;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _selectedColor = widget.note?.color;
    _titleDir = detectTextDirection(widget.note?.title);
    _contentDir = detectTextDirection(widget.note?.content);
    _titleController.addListener(() {
      final dir = detectTextDirection(_titleController.text);
      if (dir != _titleDir) setState(() => _titleDir = dir);
    });
    _contentController.addListener(() {
      final dir = detectTextDirection(_contentController.text);
      if (dir != _contentDir) setState(() => _contentDir = dir);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await widget.controller.updateNote(
          widget.note!,
          title: title,
          content: _contentController.text,
          color: _selectedColor ?? '',
        );
      } else {
        await widget.controller.addNote(
          title: title,
          content: _contentController.text,
          color: _selectedColor,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.notesWall.saveFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? m.notesWall.editNote : m.notesWall.newNote),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: m.notesWall.title,
              border: const OutlineInputBorder(),
            ),
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            textDirection: _titleDir,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            decoration: InputDecoration(
              labelText: m.notesWall.content,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 10,
            minLines: 4,
            textDirection: _contentDir,
          ),
          const SizedBox(height: 16),
          Text(
            m.notesWall.color,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorOptions.map((hex) {
              final color = hex != null
                  ? Color(
                      int.parse('FF${hex.replaceFirst('#', '')}', radix: 16),
                    )
                  : Theme.of(context).colorScheme.surfaceContainerHighest;
              final isSelected = _selectedColor == hex;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = hex),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          )
                        : Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 18,
                          color: _contrastColor(color),
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static Color _contrastColor(Color bg) {
    return bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  }
}
