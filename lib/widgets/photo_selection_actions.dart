import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/views/photos/photo_board_controller.dart';

class PhotoSelectionActions extends StatelessWidget {
  final PhotoBoardController controller;

  const PhotoSelectionActions({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final count = controller.selected.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$count', style: Theme.of(context).textTheme.titleSmall),
        IconButton(
          icon: const Icon(Icons.drive_file_move_outlined),
          tooltip: '',
          onPressed: count > 0 ? () => _showMoveDialog(context) : null,
        ),
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
          m.photoBoard.deleteSelectedConfirm(controller.selected.length),
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

  void _showMoveDialog(BuildContext context) {
    final folders = controller.folders;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(m.photoBoard.folderName),
        children: [
          // Move to root option
          if (controller.currentFolderId != null)
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                controller.moveSelectedToFolder(null);
              },
              child: const Row(
                children: [
                  Icon(Icons.home_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Root'),
                ],
              ),
            ),
          ...folders.map(
            (f) => SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                controller.moveSelectedToFolder(f.id);
              },
              child: Row(
                children: [
                  const Icon(Icons.folder, size: 20),
                  const SizedBox(width: 12),
                  Text(f.name),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
