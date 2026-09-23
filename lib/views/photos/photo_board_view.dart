import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/models/photo.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/photo_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry/utils/app_toast.dart';
import 'package:pantry/widgets/auto_refresh.dart';
import 'package:pantry_core/widgets/avif_image.dart';
import 'package:pantry/widgets/folder_tile.dart';
import 'package:pantry/widgets/photo_add_actions.dart';
import 'package:pantry/views/home/home_floating_nav.dart';
import 'package:pantry/widgets/photo_selection_actions.dart';
import 'package:pantry/widgets/photo_sort_button.dart';
import 'package:pantry/widgets/photo_tile.dart';
import 'package:pantry/widgets/upload_tile.dart';
import 'package:provider/provider.dart';
import 'photo_board_controller.dart';
import 'photo_detail_view.dart';

class PhotoBoardView extends StatefulWidget {
  final int houseId;
  final ValueNotifier<Future<void> Function()?>? refreshHolder;

  /// Vertical scroll controller for the photo grid. Owned by the host so iOS
  /// status-bar-tap can scroll this tab to the top.
  final ScrollController? scrollController;

  /// Slot for the action this tab contributes to the home floating nav's
  /// trailing button.
  final ValueNotifier<NavPrimaryAction?>? navActionHolder;

  const PhotoBoardView({
    super.key,
    required this.houseId,
    this.refreshHolder,
    this.scrollController,
    this.navActionHolder,
  });

  @override
  State<PhotoBoardView> createState() => _PhotoBoardViewState();
}

class _PhotoBoardViewState extends State<PhotoBoardView> {
  late final _controller = PhotoBoardController(houseId: widget.houseId);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_maybeOpenPendingPhoto);
    _controller.load();
    final holder = widget.refreshHolder;
    if (holder != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        holder.value = _controller.refresh;
      });
    }
  }

  @override
  void dispose() {
    if (widget.refreshHolder?.value == _controller.refresh) {
      widget.refreshHolder?.value = null;
    }
    _controller.removeListener(_maybeOpenPendingPhoto);
    _controller.dispose();
    super.dispose();
  }

  /// Consume a pending photo deep link: once the board is loaded, open that
  /// photo's detail. Cleared whether or not the photo is found, so a stale
  /// request can't reopen on a later load.
  void _maybeOpenPendingPhoto() {
    final id = PhotoService.instance.pendingOpenPhotoId;
    if (id == null || !mounted || _controller.isLoading) return;
    PhotoService.instance.pendingOpenPhotoId = null;
    final photo = _controller.photos.cast<Photo?>().firstWhere(
      (p) => p!.id == id,
      orElse: () => null,
    );
    if (photo == null) return;
    // The viewer pages through the photos the board is currently showing, so
    // the board has to be standing where the photo lives before it opens —
    // otherwise a photo inside a folder opens as whatever is first at the root.
    if (_controller.isTrashMode) unawaited(_controller.setTrashMode(false));
    if (photo.folderId != _controller.currentFolderId) {
      final folderId = photo.folderId;
      folderId == null
          ? _controller.exitFolder()
          : _controller.enterFolder(folderId);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PhotoDetailView(
            photo: photo,
            houseId: widget.houseId,
            headers: AuthService.instance.credentials?.basicAuthHeaders ?? {},
            controller: _controller,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep the controller's view of house capabilities fresh; descendants gate
    // off `controller.permissions`.
    _controller.permissions = context.watch<HousePermissions>();
    return ChangeNotifierProvider.value(
      value: _controller,
      child: _PhotoBoardBody(
        scrollController: widget.scrollController,
        navActionHolder: widget.navActionHolder,
      ),
    );
  }
}

class _PhotoBoardBody extends StatelessWidget {
  final ScrollController? scrollController;
  final ValueNotifier<NavPrimaryAction?>? navActionHolder;

  const _PhotoBoardBody({this.scrollController, this.navActionHolder});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PhotoBoardController>();
    final prefs = context.watch<PrefsService>();

    // A board that couldn't be fetched still has to show what the user just
    // added: offline is exactly when the fetch fails and exactly when an upload
    // is waiting, and a full-screen "failed to load" over it is how a queued
    // photo reads as lost.
    final hasUploads = controller.uploads.isNotEmpty;

    if (controller.isLoading && controller.photos.isEmpty && !hasUploads) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null && controller.photos.isEmpty && !hasUploads) {
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
    final inTrash = controller.isTrashMode;

    return AutoRefresh(
      interval: AutoRefresh.durationFromSeconds(prefs.photosRefreshSeconds),
      onRefresh: () =>
          inTrash ? controller.refreshTrash() : controller.refresh(),
      child: PopScope(
        canPop: !inFolder && !inTrash,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (controller.isTrashMode) {
            controller.setTrashMode(false);
            return;
          }
          if (controller.currentFolderId != null) {
            controller.exitFolder();
          }
        },
        child: Stack(
          children: [
            Column(
              children: [
                if (inTrash)
                  _TrashBanner(controller: controller)
                else
                  _TopBar(controller: controller),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: inTrash
                        ? controller.refreshTrash
                        : controller.refresh,
                    child: inTrash
                        ? _TrashGrid(
                            controller: controller,
                            scrollController: scrollController,
                          )
                        : _PhotoGrid(
                            controller: controller,
                            scrollController: scrollController,
                          ),
                  ),
                ),
              ],
            ),
            PhotoAddActions(
              controller: controller,
              holder: navActionHolder,
              enabled: !inTrash,
            ),
          ],
        ),
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
      padding: const EdgeInsetsDirectional.only(
        start: 16,
        top: 8,
        bottom: 8,
        end: 4,
      ),
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
            // Selection mode only enables bulk move/delete — hide it when the
            // user can do neither.
            if (controller.permissions.canMovePhotos ||
                controller.permissions.canDeletePhotos)
              IconButton(
                icon: const Icon(Icons.checklist),
                tooltip: '',
                onPressed: controller.toggleSelectMode,
              ),
            PhotoSortButton(controller: controller),
            if (hasFeature('photo-trash') &&
                controller.permissions.canDeletePhotos)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: m.photoBoard.viewTrash,
                onPressed: () => controller.setTrashMode(true),
              ),
          ],
        ],
      ),
    );
  }
}

class _TrashBanner extends StatelessWidget {
  final PhotoBoardController controller;

  const _TrashBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
      child: Row(
        children: [
          Icon(Icons.delete_outline, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              m.photoBoard.trashTitle,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          if (controller.trashed.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmEmptyTrash(context, controller),
              icon: const Icon(Icons.delete_forever, size: 16),
              label: Text(m.photoBoard.emptyTrash),
            ),
          TextButton.icon(
            onPressed: () => controller.setTrashMode(false),
            icon: const Icon(Icons.close, size: 16),
            label: Text(m.photoBoard.exitTrash),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmEmptyTrash(
    BuildContext context,
    PhotoBoardController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.photoBoard.emptyTrashConfirm),
        content: Text(m.photoBoard.emptyTrashConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.photoBoard.emptyTrash),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await controller.emptyTrash();
    } catch (_) {
      if (context.mounted) {
        showAppToast(
          message: m.photoBoard.emptyTrashFailed,
          kind: ToastKind.error,
        );
      }
    }
  }
}

class _TrashGrid extends StatelessWidget {
  final PhotoBoardController controller;
  final ScrollController? scrollController;

  const _TrashGrid({required this.controller, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final photos = controller.trashed;
    if (photos.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Center(
            child: Text(
              m.photoBoard.trashEmpty,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }
    return GridView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return _TrashedPhotoTile(photo: photo, controller: controller);
      },
    );
  }
}

class _TrashedPhotoTile extends StatelessWidget {
  final Photo photo;
  final PhotoBoardController controller;

  const _TrashedPhotoTile({required this.photo, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uri = PhotoService.instance.photoPreviewUri(
      controller.houseId,
      photo.id,
    );
    final headers = AuthService.instance.credentials?.basicAuthHeaders ?? {};

    return GestureDetector(
      onTap: () => _showTrashActions(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.7,
              child: AvifNetworkImage(
                imageUrl: uri.toString(),
                headers: headers,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_outlined, size: 32),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 20,
                shadows: const [Shadow(blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTrashActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore_from_trash),
              title: Text(m.photoBoard.restore),
              onTap: () => Navigator.pop(ctx, 'restore'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: Text(m.photoBoard.permanentlyDelete),
              onTap: () => Navigator.pop(ctx, 'permanent'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == 'restore') {
      try {
        await controller.restorePhoto(photo);
      } catch (_) {
        if (context.mounted) {
          showAppToast(
            message: m.photoBoard.restoreFailed,
            kind: ToastKind.error,
          );
        }
      }
    } else if (action == 'permanent') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(m.photoBoard.permanentlyDeleteConfirm),
          content: Text(m.photoBoard.permanentlyDeleteConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(m.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(m.photoBoard.permanentlyDelete),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      try {
        await controller.permanentlyDeletePhoto(photo);
      } catch (_) {
        if (context.mounted) {
          showAppToast(
            message: m.photoBoard.deleteFailed,
            kind: ToastKind.error,
          );
        }
      }
    }
  }
}

class _PhotoGrid extends StatelessWidget {
  final PhotoBoardController controller;
  final ScrollController? scrollController;

  const _PhotoGrid({required this.controller, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final folders = controller.visibleFolders;
    final photos = controller.visiblePhotos;

    // An upload draws in the folder it will land in, so a queued one — which
    // may sit there for days — isn't shown twice or in the wrong place.
    final activeUploads = controller.uploads
        .where(
          (t) =>
              (!t.done || t.error != null) &&
              t.folderId == controller.currentFolderId,
        )
        .toList();

    // An upload in flight, waiting on the queue, or failed is the only thing on
    // an otherwise empty board — telling the user there are no photos while
    // their photo sits right there is how it reads as lost.
    if (folders.isEmpty && photos.isEmpty && activeUploads.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Center(child: Text(m.photoBoard.noPhotos)),
        ],
      );
    }

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
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      // Trailing room for the floating nav the grid scrolls under.
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
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
