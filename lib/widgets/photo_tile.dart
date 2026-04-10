import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/photo.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/photo_service.dart';
import 'package:pantry/views/photos/photo_board_controller.dart';
import 'package:pantry/views/photos/photo_detail_view.dart';
import 'package:pantry/widgets/tile_menu_button.dart';

class PhotoTile extends StatelessWidget {
  final Photo photo;
  final int houseId;
  final PhotoBoardController controller;

  const PhotoTile({
    super.key,
    required this.photo,
    required this.houseId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uri = PhotoService.instance.photoPreviewUri(houseId, photo.id);
    final headers = AuthService.instance.credentials?.basicAuthHeaders ?? {};

    if (controller.selectMode) {
      final isSelected = controller.selected.contains(photo.id);
      return GestureDetector(
        onTap: () => controller.toggleSelection(photo.id),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: uri.toString(),
                httpHeaders: headers,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_outlined, size: 32),
                ),
              ),
              if (photo.caption != null && photo.caption!.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
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
                      photo.caption!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              Positioned(
                top: 4,
                left: 4,
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? theme.colorScheme.primary : Colors.white,
                  size: 24,
                  shadows: const [Shadow(blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != photo.id,
      onAcceptWithDetails: (_) {},
      onMove: (details) {
        controller.hoverReorder(photo.id);
      },
      builder: (context, candidateData, _) {
        return LongPressDraggable<int>(
          data: photo.id,
          onDragStarted: () => controller.startDrag(photo.id),
          onDragEnd: (_) => controller.endDrag(),
          onDraggableCanceled: (_, _) => controller.cancelDrag(),
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 100,
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: uri.toString(),
                  httpHeaders: headers,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          child: _buildTileContent(context, theme, uri, headers),
        );
      },
    );
  }

  Widget _buildTileContent(
    BuildContext context,
    ThemeData theme,
    Uri uri,
    Map<String, String> headers,
  ) {
    return GestureDetector(
      onTap: () => _showPhotoDetail(context, uri, headers),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: uri.toString(),
              httpHeaders: headers,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined, size: 32),
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: TileMenuButton(
                items: [
                  PopupMenuItem(
                    value: 'caption',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 18),
                        const SizedBox(width: 8),
                        Text(m.photoBoard.caption),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 18),
                        const SizedBox(width: 8),
                        Text(m.common.delete),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'caption':
                      _editCaption(context);
                    case 'delete':
                      _confirmDelete(context);
                  }
                },
              ),
            ),
            if (photo.caption != null && photo.caption!.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withAlpha(180), Colors.transparent],
                    ),
                  ),
                  child: Text(
                    photo.caption!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPhotoDetail(
    BuildContext context,
    Uri previewUri,
    Map<String, String> headers,
  ) {
    final fullUri = PhotoService.instance.photoPreviewUri(
      houseId,
      photo.id,
      size: 1024,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoDetailView(
          photo: photo,
          imageUri: fullUri,
          headers: headers,
          controller: controller,
        ),
      ),
    );
  }

  void _editCaption(BuildContext context) {
    final textController = TextEditingController(text: photo.caption ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.photoBoard.caption),
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: m.photoBoard.caption,
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
              controller.updateCaption(photo, textController.text.trim());
              Navigator.pop(ctx);
            },
            child: Text(m.common.save),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.photoBoard.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deletePhoto(photo);
            },
            child: Text(m.common.delete),
          ),
        ],
      ),
    );
  }
}
