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
    final count = controller.selected.length;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.notesWall.deleteSelectedConfirm(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.common.delete),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      try {
        await controller.deleteSelected();
        if (context.mounted) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(content: Text(m.notesWall.noteRemoved(count))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(m.notesWall.deleteFailed)));
        }
      }
    });
  }
}
