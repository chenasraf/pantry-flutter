import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/photo.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import '../widgets/focus_list.dart';
import '../widgets/preview_image.dart';
import '../widgets/preview_sizes.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import 'photo_image.dart';
import 'photo_route.dart';
import 'photos_controller.dart';
import '../widgets/wear_surfaces.dart';

/// The photos page: the household's board, at the root of the house.
///
/// View only, and it fetches for itself — the mirror carries neither photo
/// bytes nor photo metadata, so nothing about this page arrives from the phone.
/// What the watch has is the preview endpoint, clamped server-side to 16–2048,
/// so it asks for the size it will draw and the server downscales.
///
/// The grid is **two tiles to a row and the row is the focus unit**. What the
/// row cannot decide is *which* tile an action lands on, so the two rules split
/// by axis: a row the wearer was only aiming at comes within reach instead of
/// acting, and within a row that does act the tile you touched is the one that
/// opens. The safety being bought is about a mis-aimed scroll, which is
/// vertical; horizontally the two tiles are large targets and there is nothing
/// to protect against. Which rows act is the list's to say, and it depends on
/// the screen's shape.
class PhotosPage extends StatefulWidget {
  /// Supplied only by tests, which pump the real tree against a controller
  /// holding a fixed answer. The page starts the one it makes itself.
  final PhotosController? controller;

  /// Only the page being looked at may poll or fetch.
  final bool active;

  /// Whether the crown is this board's to steer: [active], and only while
  /// turning it scrolls rather than turns pages.
  final bool rotary;

  const PhotosPage({
    super.key,
    this.controller,
    required this.active,
    required this.rotary,
  });

  @override
  State<PhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  late final PhotosController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PhotosController();
    _controller.addListener(_onData);
    if (widget.controller == null) {
      unawaited(_controller.start());
      _controller.setActive(widget.active);
    }
  }

  @override
  void didUpdateWidget(PhotosPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && widget.active != oldWidget.active) {
      _controller.setActive(widget.active);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onData);
    // Only the one this page made: an injected controller outlives it.
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onData() {
    if (mounted) setState(() {});
  }

  /// Nothing to draw has two causes, and only one of them is an empty board.
  String get _emptyMessage => AuthService.instance.isLoggedIn
      ? m.photoBoard.noPhotos
      : m.wear.notSignedIn;

  @override
  Widget build(BuildContext context) {
    final house = _controller.houseId;
    final cells = _controller.boardCells;
    if (house == null || cells.isEmpty) {
      return _Empty(message: _emptyMessage);
    }
    return PhotoBoard(
      controller: _controller,
      houseId: house,
      cells: cells,
      rotary: widget.rotary,
      underRail: true,
    );
  }
}

/// A grid of photo rows, with folder rows among them at the root.
///
/// The same board serves the root and a folder, because a folder is the same
/// view over a smaller set — only its route furniture differs.
class PhotoBoard extends StatefulWidget {
  final PhotosController controller;
  final int houseId;
  final List<PhotoCell> cells;

  /// Whether the crown is this board's to steer.
  final bool rotary;

  /// Whether the shell's rail is drawn over this board. The root board sits
  /// under it; a folder is a pushed route with nothing above it.
  final bool underRail;

  const PhotoBoard({
    super.key,
    required this.controller,
    required this.houseId,
    required this.cells,
    required this.rotary,
    this.underRail = false,
  });

  @override
  State<PhotoBoard> createState() => _PhotoBoardState();
}

class _PhotoBoardState extends State<PhotoBoard> {
  final _controller = ScrollController();
  final _listKey = GlobalKey<SnapFocusListState>();
  final _geometry = ValueNotifier(const FocusGeometry());

  /// A route pushed over this board must take the crown with it. The detent
  /// stream is broadcast and a covered list is still mounted, so without this
  /// one turn scrolls both the board underneath and the route on top.
  var _covered = false;

  @override
  void dispose() {
    _controller.dispose();
    _geometry.dispose();
    super.dispose();
  }

  Future<void> _push(Widget route) async {
    setState(() => _covered = true);
    await Navigator.of(context).push(wearRoute<void>(route));
    if (mounted) setState(() => _covered = false);
  }

  /// The vertical half of the tap rule: a row the wearer was only aiming at
  /// comes within reach and nothing opens, so a mis-aim costs a scroll. The
  /// horizontal half never applies — both tiles in a row are large targets.
  bool _actionable(int index) {
    final list = _listKey.currentState;
    if (list != null && list.canActOn(index)) return true;
    list?.reveal(index);
    return false;
  }

  void _openFolder(int index, PhotoFolder folder) {
    if (!_actionable(index)) return;
    unawaited(
      _push(
        PhotoFolderRoute(
          controller: widget.controller,
          houseId: widget.houseId,
          folder: folder,
        ),
      ),
    );
  }

  void _openPhoto(int index, Photo photo) {
    if (!_actionable(index)) return;
    unawaited(_push(PhotoRoute(photo: photo, houseId: widget.houseId)));
  }

  Widget _cell(PhotoCell cell, int index, bool captioned, int size) {
    final folder = cell.folder;
    if (folder != null) {
      return _FolderTile(
        key: ValueKey('folder-${folder.id}'),
        folder: folder,
        houseId: widget.houseId,
        preview: widget.controller.previewPhotos(folder.id),
        count: widget.controller.photoCount(folder.id),
        size: size,
        onTap: () => _openFolder(index, folder),
      );
    }
    final photo = cell.photo!;
    return _PhotoTile(
      key: ValueKey('photo-${photo.id}'),
      photo: photo,
      houseId: widget.houseId,
      captioned: captioned,
      size: size,
      onTap: () => _openPhoto(index, photo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final extent = WearMetrics.of(context).photoRowExtent;
    final cells = widget.cells;
    final rows = (cells.length / 2).ceil();
    final size = WearPreviewSize.tile(context);

    return SnapFocusList(
      key: _listKey,
      controller: _controller,
      itemExtent: extent,
      falloffRows: WearMetrics.falloffRows,
      rotaryActive: widget.rotary && !_covered,
      horizontalInset: WearMetrics.tallSideInset,
      geometry: _geometry,
      underRail: widget.underRail,
      elements: [
        for (var row = 0; row < rows; row++)
          FocusElement(
            extent: extent,
            builder: (context, d) {
              final first = cells[row * 2];
              final second = row * 2 + 1 < cells.length
                  ? cells[row * 2 + 1]
                  : null;
              return ValueListenableBuilder<FocusGeometry>(
                valueListenable: _geometry,
                builder: (context, geometry, _) {
                  // Only the row in charge is captioned, so the board reads as
                  // photos rather than as a page of labels. Where no row is in
                  // charge there is nothing to single out, and every row keeps
                  // its caption.
                  final captioned =
                      !SnapFocusList.hasFocusRow ||
                      geometry.centredIndex == row;
                  return Padding(
                    padding: const EdgeInsetsDirectional.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(child: _cell(first, row, captioned, size)),
                        const SizedBox(width: WearMetrics.photoTileGap),
                        Expanded(
                          child: second == null
                              // The empty half of an odd last row still claims
                              // its width, or the single tile stretches across
                              // the row and reads as a different kind of thing.
                              ? const SizedBox.shrink()
                              : _cell(second, row, captioned, size),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

/// A folder, as a tile in the same grid its photos live in.
///
/// It is the phone's folder tile at watch size: a fanned stack of the photos it
/// holds, a count, and the name over a gradient. The fan is what tells a folder
/// from a photo before a word is read — at this size a single thumbnail with a
/// label would just look like a photo whose caption is always on.
///
/// The name is drawn at every distance, where a photo's caption is drawn only
/// on the focused row. The asymmetry is the point: a photo without its caption
/// is still the photo, but a folder without its name is three thumbnails of
/// things that are not in it.
class _FolderTile extends StatelessWidget {
  final PhotoFolder folder;
  final int houseId;
  final List<Photo> preview;
  final int count;

  /// Tile size, though a fanned card is a third of one: the preview and the
  /// photo's own tile are then the same file, and the fan costs no fetch of
  /// its own.
  final int size;

  final VoidCallback onTap;

  const _FolderTile({
    super.key,
    required this.folder,
    required this.houseId,
    required this.preview,
    required this.count,
    required this.size,
    required this.onTap,
  });

  /// Bottom card to top, so the last one sits square and the ones behind it
  /// lean out from under it.
  static const _angles = [-0.08, 0.05, 0.0];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WearShape.isRound ? 14 : 10),
        child: DecoratedBox(
          decoration: WearSurface.placeholder(context, alpha: 0.08, radius: 0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 14),
                child: preview.isEmpty
                    ? Icon(
                        Icons.folder,
                        size: 26,
                        color: scheme.onSurface.withValues(alpha: 0.4),
                      )
                    // The fan states its own size: left to shrink-wrap, the
                    // stack takes the size of its largest child and collapses.
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          for (var i = 0; i < preview.length; i++)
                            Transform.rotate(
                              angle:
                                  _angles[_angles.length - preview.length + i],
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: scheme.outlineVariant,
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: PhotoImage(
                                    // Bottom-most first, so the square card on
                                    // top is the folder's newest.
                                    photo: preview[preview.length - 1 - i],
                                    houseId: houseId,
                                    size: size,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              if (count > 0)
                PositionedDirectional(
                  top: 3,
                  start: 3,
                  child: DecoratedBox(
                    decoration: WearSurface.panel(
                      context,
                      fill: scheme.inverseSurface,
                      radius: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 8.5,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: scheme.onInverseSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsetsDirectional.only(
                    start: 5,
                    end: 5,
                    bottom: 3,
                    top: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    textDirection: detectTextDirection(folder.name),
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1.1,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tile on the grid.
class _PhotoTile extends StatelessWidget {
  final Photo photo;
  final int houseId;
  final bool captioned;
  final int size;
  final VoidCallback onTap;

  const _PhotoTile({
    super.key,
    required this.photo,
    required this.houseId,
    required this.captioned,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final caption = photo.caption;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WearShape.isRound ? 14 : 10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PhotoImage(
              photo: photo,
              houseId: houseId,
              size: size,
              unavailable: const ImageUnavailable(),
            ),
            if (captioned && caption != null && caption.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: detectTextDirection(caption),
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1.1,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A folder, pushed over the board. Depth runs board → folder → photo, and
/// each level carries its own leading-edge back strip: route (a) removed the
/// system dismiss app-wide, so a pushed route inherits no way out.
class PhotoFolderRoute extends StatelessWidget {
  final PhotosController controller;
  final int houseId;
  final PhotoFolder folder;

  const PhotoFolderRoute({
    super.key,
    required this.controller,
    required this.houseId,
    required this.folder,
  });

  @override
  Widget build(BuildContext context) {
    return EdgeDismissible(
      onDismiss: () => Navigator.of(context).pop(),
      child: Scaffold(
        // The board's own ground, not black: the title above it is that plane,
        // and a route a shade darker than the page it came from reads as a
        // different app rather than a level down.
        body: Stack(
          children: [
            Positioned.fill(
              child: PhotoBoard(
                controller: controller,
                houseId: houseId,
                cells: controller.cellsInFolder(folder.id),
                // A pushed route has no pager to turn, so the crown scrolls its
                // list whichever way the setting is pointing.
                rotary: true,
              ),
            ),
            RouteTitle(text: folder.name),
          ],
        ),
      ),
    );
  }
}

/// The name of a pushed route, standing where the rail stands on the pager.
///
/// It never takes a pointer: the list runs full height beneath it, the same way
/// it runs under the rail. Solid down past the title and only then fading —
/// a gradient that is transparent at the top of the screen lets a row scrolling
/// under the title reappear *above* it, which reads as the page leaking rather
/// than as one plane over another.
class RouteTitle extends StatelessWidget {
  final String text;

  const RouteTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final ground = Theme.of(context).scaffoldBackgroundColor;
    return PositionedDirectional(
      start: 0,
      end: 0,
      top: 0,
      child: IgnorePointer(
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsetsDirectional.only(
            start: 40,
            end: 40,
            top: WearShape.isRound ? 22 : 12,
            bottom: 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ground, ground, ground.withValues(alpha: 0)],
              stops: const [0, 0.78, 1],
            ),
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: detectTextDirection(text),
            style: const TextStyle(
              fontSize: 12,
              height: 1.0,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;

  const _Empty({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: WearMetrics.bandInsets(context),
      child: Text(
        message,
        textAlign: TextAlign.center,
        textDirection: detectTextDirection(message),
        style: const TextStyle(fontSize: 12, color: Colors.white38),
      ),
    ),
  );
}
