import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/utils/undo_snackbar.dart';
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
    final count = controller.selected.length;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.photoBoard.deleteSelectedConfirm(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              hasFeature('photo-trash') ? m.common.remove : m.common.delete,
            ),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      try {
        final snapshot = controller.photos
            .where((p) => controller.selected.contains(p.id))
            .toList();
        final deletedIds = await controller.deleteSelected();
        final deleted = snapshot
            .where((p) => deletedIds.contains(p.id))
            .toList();
        if (!context.mounted) return;
        if (hasFeature('photo-trash') && deleted.isNotEmpty) {
          showUndoSnackBar(
            context,
            message: m.photoBoard.photoRemoved(deleted.length),
            undoLabel: m.checklists.undo,
            onUndo: () async {
              for (final p in deleted) {
                await controller.restorePhoto(p);
              }
            },
            undoFailedMessage: m.photoBoard.restoreFailed,
          );
        } else {
          final messenger = ScaffoldMessenger.of(context);
          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(content: Text(m.photoBoard.photoRemoved(count))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(m.photoBoard.deleteFailed)));
        }
      }
    });
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
