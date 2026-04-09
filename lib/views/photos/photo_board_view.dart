import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/photo.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/photo_service.dart';
import 'package:provider/provider.dart';
import 'photo_board_controller.dart';

class PhotoBoardView extends StatefulWidget {
  final int houseId;

  const PhotoBoardView({super.key, required this.houseId});

  @override
  State<PhotoBoardView> createState() => _PhotoBoardViewState();
}

class _PhotoBoardViewState extends State<PhotoBoardView> {
  late final _controller = PhotoBoardController(houseId: widget.houseId);

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: const _PhotoBoardBody(),
    );
  }
}

class _PhotoBoardBody extends StatelessWidget {
  const _PhotoBoardBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PhotoBoardController>();

    if (controller.isLoading && controller.photos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null && controller.photos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(controller.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.load,
                child: Text(m.common.retry),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            _TopBar(controller: controller),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                child: _PhotoGrid(controller: controller),
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: _AddButton(controller: controller),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final PhotoBoardController controller;

  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 4),
      child: Row(
        children: [
          if (controller.currentFolderId != null) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: controller.exitFolder,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                controller.currentFolder?.name ?? '',
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),
          if (controller.selectMode)
            _SelectionActions(controller: controller)
          else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: '',
              onPressed: controller.toggleSelectMode,
            ),
            _SortButton(controller: controller),
          ],
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final PhotoBoardController controller;

  const _SortButton({required this.controller});

  static const _sortKeys = [
    'newest',
    'oldest',
    'description_asc',
    'description_desc',
    'custom',
  ];

  static String _label(String key) => switch (key) {
    'newest' => m.photoBoard.sort.newestFirst,
    'oldest' => m.photoBoard.sort.oldestFirst,
    'description_asc' => m.photoBoard.sort.captionAZ,
    'description_desc' => m.photoBoard.sort.captionZA,
    'custom' => m.photoBoard.sort.custom,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      tooltip: '',
      onSelected: (value) {
        if (value == '_folders_first') {
          controller.setFoldersFirst(!controller.foldersFirst);
        } else {
          controller.setSortBy(value);
        }
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem<String>(
          value: '_folders_first',
          checked: controller.foldersFirst,
          child: Text(m.photoBoard.sort.foldersFirst),
        ),
        const PopupMenuDivider(),
        for (final key in _sortKeys)
          PopupMenuItem<String>(
            value: key,
            child: Row(
              children: [
                Icon(
                  key == controller.sortBy
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: key == controller.sortBy
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Text(_label(key)),
              ],
            ),
          ),
      ],
    );
  }
}

class _SelectionActions extends StatelessWidget {
  final PhotoBoardController controller;

  const _SelectionActions({required this.controller});

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

class _PhotoGrid extends StatelessWidget {
  final PhotoBoardController controller;

  const _PhotoGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    final folders = controller.visibleFolders;
    final photos = controller.visiblePhotos;

    if (folders.isEmpty && photos.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(child: Text(m.photoBoard.noPhotos)),
        ],
      );
    }

    // Active uploads (not yet completed or with errors)
    final activeUploads = controller.uploads
        .where((t) => !t.done || t.error != null)
        .toList();

    // Build combined items list
    final items = <_GridItem>[];
    if (controller.foldersFirst) {
      for (final f in folders) {
        items.add(_GridItem.folder(f));
      }
    }
    // Insert upload tiles before photos
    for (final t in activeUploads) {
      items.add(_GridItem.upload(t));
    }
    for (final p in photos) {
      if (p.id == controller.draggingId) {
        // Show a placeholder in the dragged photo's current sorted position
        items.add(_GridItem.placeholder());
      } else {
        items.add(_GridItem.photo(p));
      }
    }
    if (!controller.foldersFirst) {
      for (final f in folders) {
        items.add(_GridItem.folder(f));
      }
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.folder != null) {
          return _FolderTile(
            folder: item.folder!,
            photoCount: controller.folderPhotoCount(item.folder!.id),
            previewPhotos: controller.folderPreviewPhotos(item.folder!.id),
            houseId: controller.houseId,
            controller: controller,
          );
        }
        if (item.isPlaceholder) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
            ),
          );
        }
        if (item.upload != null) {
          return _UploadTile(task: item.upload!, controller: controller);
        }
        return _PhotoTile(
          photo: item.photo!,
          houseId: controller.houseId,
          controller: controller,
        );
      },
    );
  }
}

class _GridItem {
  final Photo? photo;
  final PhotoFolder? folder;
  final UploadTask? upload;
  final bool isPlaceholder;

  _GridItem.photo(this.photo)
    : folder = null,
      upload = null,
      isPlaceholder = false;
  _GridItem.folder(this.folder)
    : photo = null,
      upload = null,
      isPlaceholder = false;
  _GridItem.upload(this.upload)
    : photo = null,
      folder = null,
      isPlaceholder = false;
  _GridItem.placeholder()
    : photo = null,
      folder = null,
      upload = null,
      isPlaceholder = true;
}

class _FolderTile extends StatelessWidget {
  final PhotoFolder folder;
  final int photoCount;
  final List<Photo> previewPhotos;
  final int houseId;
  final PhotoBoardController controller;

  const _FolderTile({
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
                  child: _TileMenuButton(
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

class _PhotoTile extends StatelessWidget {
  final Photo photo;
  final int houseId;
  final PhotoBoardController controller;

  const _PhotoTile({
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
              child: _TileMenuButton(
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
        builder: (_) => _PhotoDetailPage(
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

class _PhotoDetailPage extends StatelessWidget {
  final Photo photo;
  final Uri imageUri;
  final Map<String, String> headers;
  final PhotoBoardController controller;

  const _PhotoDetailPage({
    required this.photo,
    required this.imageUri,
    required this.headers,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(photo.caption ?? '')),
      body: InteractiveViewer(
        child: Center(
          child: CachedNetworkImage(
            imageUrl: imageUri.toString(),
            httpHeaders: headers,
            fit: BoxFit.contain,
            errorWidget: (_, _, _) =>
                const Icon(Icons.broken_image_outlined, size: 64),
          ),
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final UploadTask task;
  final PhotoBoardController controller;

  const _UploadTile({required this.task, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = task.error != null;

    return GestureDetector(
      onTap: hasError ? () => controller.retryUpload(task) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (task.thumbnailBytes != null)
              Image.memory(
                task.thumbnailBytes!,
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.4),
              )
            else
              Container(color: theme.colorScheme.surfaceContainerHighest),
            Center(
              child: hasError
                  ? Icon(
                      Icons.refresh,
                      color: theme.colorScheme.error,
                      size: 32,
                    )
                  : SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        value: task.progress > 0 ? task.progress : null,
                        strokeWidth: 3,
                      ),
                    ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => controller.dismissUpload(task),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final PhotoBoardController controller;

  const _AddButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'photo_folder',
          onPressed: () => _createFolder(context),
          child: const Icon(Icons.create_new_folder),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'photo_upload',
          onPressed: () => _pickPhotos(context),
          child: const Icon(Icons.add_photo_alternate),
        ),
      ],
    );
  }

  Future<void> _pickPhotos(BuildContext context) async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isNotEmpty) {
      controller.uploadPhotos(files);
    }
  }

  void _createFolder(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.photoBoard.newFolder),
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
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
                controller.createFolder(name);
                Navigator.pop(ctx);
              }
            },
            child: Text(m.common.save),
          ),
        ],
      ),
    );
  }
}

class _TileMenuButton extends StatelessWidget {
  final List<PopupMenuEntry<String>> items;
  final ValueChanged<String> onSelected;

  const _TileMenuButton({required this.items, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: Colors.white,
        shadows: const [Shadow(blurRadius: 4)],
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: onSelected,
      itemBuilder: (_) => items,
    );
  }
}
