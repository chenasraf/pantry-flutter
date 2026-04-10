import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/photo.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/photo_service.dart';
import 'package:pantry/views/photos/photo_board_controller.dart';
import 'package:pantry/widgets/tile_menu_button.dart';

class FolderTile extends StatelessWidget {
  final PhotoFolder folder;
  final int photoCount;
  final List<Photo> previewPhotos;
  final int houseId;
  final PhotoBoardController controller;

  const FolderTile({
    super.key,
    required this.folder,
    required this.photoCount,
    required this.previewPhotos,
    required this.houseId,
    required this.controller,
  });

  // Rotation angles for stacked preview cards (bottom to top)
  static const _angles = [-0.08, 0.05, 0.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headers = AuthService.instance.credentials?.basicAuthHeaders ?? {};

    return DragTarget<int>(
      onAcceptWithDetails: (details) {
        controller.movePhotoToFolder(details.data, folder.id);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: () => controller.enterFolder(folder.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isHovering
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
            child: Stack(
              children: [
                // Photo stack or folder icon — full bleed
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: previewPhotos.isNotEmpty
                        ? _buildPhotoStack(theme, headers)
                        : Center(
                            child: Icon(
                              Icons.folder,
                              size: 56,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                // Count badge
                if (photoCount > 0)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.inverseSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        m.photoBoard.photoCount(photoCount),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onInverseSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Folder name with gradient
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 6,
                      right: 6,
                      bottom: 6,
                      top: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withAlpha(180),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      folder.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // Menu
                Positioned(
                  top: 2,
                  right: 2,
                  child: TileMenuButton(
                    items: [
                      PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 18),
                            const SizedBox(width: 8),
                            Text(m.photoBoard.renameFolder),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 18),
                            const SizedBox(width: 8),
                            Text(m.photoBoard.deleteFolder),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'rename':
                          _renameFolder(context);
                        case 'delete':
                          _deleteFolder(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoStack(ThemeData theme, Map<String, String> headers) {
    // Show up to 3 photos stacked with slight rotations
    final count = previewPhotos.length;
    final cards = <Widget>[];

    for (var i = 0; i < count; i++) {
      final photo = previewPhotos[count - 1 - i]; // bottom-most first
      final angle =
          _angles[(_angles.length - count + i).clamp(0, _angles.length - 1)];
      final uri = PhotoService.instance.photoPreviewUri(
        houseId,
        photo.id,
        size: 128,
      );

      cards.add(
        Transform.rotate(
          angle: angle,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 4,
                  offset: const Offset(1, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: CachedNetworkImage(
                imageUrl: uri.toString(),
                httpHeaders: headers,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(alignment: Alignment.center, children: cards);
  }

  void _renameFolder(BuildContext context) {
    final textController = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.photoBoard.renameFolder),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: m.photoBoard.folderName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                controller.renameFolder(folder, name);
                Navigator.pop(ctx);
              }
            },
            child: Text(m.common.save),
          ),
        ],
      ),
    );
  }

  void _deleteFolder(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.photoBoard.deleteFolderConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(m.common.cancel),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteFolder(folder);
            },
            child: Text(m.photoBoard.deleteFolderKeepPhotos),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteFolder(folder, deleteContents: true);
            },
            child: Text(m.photoBoard.deleteFolderDeleteAll),
          ),
        ],
      ),
    );
  }
}
