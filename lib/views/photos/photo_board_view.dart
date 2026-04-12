import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/photo.dart';
import 'package:pantry/widgets/folder_tile.dart';
import 'package:pantry/widgets/photo_add_button.dart';
import 'package:pantry/widgets/photo_selection_actions.dart';
import 'package:pantry/widgets/photo_sort_button.dart';
import 'package:pantry/widgets/photo_tile.dart';
import 'package:pantry/widgets/upload_tile.dart';
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

    final inFolder = controller.currentFolderId != null;

    return PopScope(
      canPop: !inFolder,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (controller.currentFolderId != null) {
          controller.exitFolder();
        }
      },
      child: Stack(
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
          PositionedDirectional(
            end: 16,
            bottom: 16,
            child: PhotoAddButton(controller: controller),
          ),
        ],
      ),
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
            PhotoSelectionActions(controller: controller)
          else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: '',
              onPressed: controller.toggleSelectMode,
            ),
            PhotoSortButton(controller: controller),
          ],
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
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.folder != null) {
          return FolderTile(
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
          return UploadTile(task: item.upload!, controller: controller);
        }
        return PhotoTile(
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
