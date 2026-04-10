import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/views/notes/notes_controller.dart';

class NoteSelectionActions extends StatelessWidget {
  final NotesController controller;

  const NoteSelectionActions({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final count = controller.selected.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$count', style: Theme.of(context).textTheme.titleSmall),
        IconButton(
          icon: const Icon(Icons.delete_outlined),
          tooltip: '',
          onPressed: count > 0 ? () => _confirmDelete(context) : null,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: '',
          onPressed: controller.clearSelection,
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          m.notesWall.deleteSelectedConfirm(controller.selected.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteSelected();
            },
            child: Text(m.common.delete),
          ),
        ],
      ),
    );
  }
}
