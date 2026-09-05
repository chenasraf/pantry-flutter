import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../services/rotary_service.dart';
import '../wear_shape.dart';
import '../widgets/focus_list.dart';
import '../widgets/wear_mechanics.dart';
import 'proto_photo_data.dart';
import 'proto_tuning.dart';

/// PROTOTYPE — the photos page.
///
/// View only, and online by nature: the mirror carries neither photo bytes nor
/// photo metadata, so nothing about this page arrives from the phone. What the
/// watch has is the preview endpoint — `photoPreviewUri(house, photo, size:)`,
/// already in core, clamped server-side to 16–2048 — so the watch asks for the
/// size it wants and the server downscales. No cross-repo work is needed.
///
/// The grid is **two tiles to a row and the row is the focus unit**, as card
/// 715 settled: a cell-level focus would need a horizontal notion of "focused"
/// that nothing else on the watch has. What the row can't decide is *which*
/// tile an action lands on, so the two rules split by axis — an off-centre row
/// scrolls to the centre line instead of acting, and within the centred row the
/// tile you touched is the one that opens. Q19's safety is about a mis-aimed
/// scroll, which is vertical; horizontally the two tiles are large targets and
/// there is nothing to protect against.
///
/// **Only the focused row is captioned.** Eight captions at once fight the
/// image the wearer is scanning for, and at tile size most of them ellipsize to
/// nothing — so the caption appears where the wearer is already looking, the
/// same move `expandCentre` makes on the checklist page.
///
/// Folders are tiles in the same grid, ordered ahead of the photos exactly as
/// the phone's board orders them, and they push a route. Depth runs board →
/// folder → photo, and each pushed route carries its own leading-edge back
/// strip, since route (a) removed the system dismiss app-wide.

/// The board at the root of the house: folders first, then the photos that sit
/// outside any of them — the same split the phone's board makes.
class PhotosPage extends StatelessWidget {
  final ProtoTuning tuning;
  final bool active;

  const PhotosPage({super.key, required this.tuning, required this.active});

  @override
  Widget build(BuildContext context) => PhotoBoard(
    tuning: tuning,
    active: active,
    folders: protoPhotoFolders,
    photos: protoPhotosIn(null).toList(),
  );
}

/// A grid of photo rows, with folder rows above it at the root.
///
/// The same list serves the board and a folder, because a folder is the same
/// view over a smaller set — only its route furniture differs.
class PhotoBoard extends StatefulWidget {
  final ProtoTuning tuning;
  final bool active;
  final List<ProtoPhotoFolder> folders;
  final List<ProtoPhoto> photos;

  const PhotoBoard({
    super.key,
    required this.tuning,
    required this.active,
    required this.folders,
    required this.photos,
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
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => route));
    if (mounted) setState(() => _covered = false);
  }

  /// The vertical half of the tap rule: a row that is not on the centre line
  /// scrolls there and nothing opens, so a mis-aimed scroll costs a scroll.
  bool _centred(int index) {
    if (index == _geometry.value.centredIndex) return true;
    _listKey.currentState?.centreOn(index);
    return false;
  }

  void _openFolder(int index, ProtoPhotoFolder folder) {
    if (!_centred(index)) return;
    _push(
      PhotoFolderRoute(
        tuning: widget.tuning,
        folder: folder,
        photos: protoPhotosIn(folder.id).toList(),
      ),
    );
  }

  void _openPhoto(int index, ProtoPhoto photo) {
    if (!_centred(index)) return;
    _push(PhotoRoute(photo: photo, available: _available(photo)));
  }

  /// Online everything loads; offline only what the wearer has already opened
  /// is on disk, which is what the load-on-demand policy leaves behind.
  bool _available(ProtoPhoto photo) => photo.cached || !widget.tuning.offline;

  Widget _cell(_Cell cell, int index, bool captioned) {
    final folder = cell.folder;
    if (folder != null) {
      return _FolderTile(
        key: ValueKey('folder-${folder.id}'),
        folder: folder,
        onTap: () => _openFolder(index, folder),
      );
    }
    final photo = cell.photo!;
    return _PhotoTile(
      key: ValueKey('photo-${photo.id}'),
      photo: photo,
      available: _available(photo),
      captioned: captioned,
      onTap: () => _openPhoto(index, photo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final extent = widget.tuning.photoRowExtent;
    // Folders first, then the photos outside them — the phone's own order, in
    // one grid, so a row may hold one of each.
    final cells = [
      for (final folder in widget.folders) _Cell.folder(folder),
      for (final photo in widget.photos) _Cell.photo(photo),
    ];
    final rows = (cells.length / 2).ceil();

    return SnapFocusList(
      key: _listKey,
      controller: _controller,
      itemExtent: extent,
      falloffRows: widget.tuning.falloffRows,
      snapEnabled: widget.tuning.snapEnabled,
      rotaryActive: widget.active && !_covered,
      horizontalInset: widget.tuning.tallSideInset,
      geometry: _geometry,
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
                  final captioned = geometry.centredIndex == row;
                  return Padding(
                    padding: const EdgeInsetsDirectional.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(child: _cell(first, row, captioned)),
                        SizedBox(width: widget.tuning.tileGap),
                        Expanded(
                          child: second == null
                              // The empty half of an odd last row still claims
                              // its width, or the single tile stretches across
                              // the row and reads as a different kind of thing.
                              ? const SizedBox.shrink()
                              : _cell(second, row, captioned),
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

/// One square in the grid.
@immutable
class _Cell {
  final ProtoPhotoFolder? folder;
  final ProtoPhoto? photo;

  const _Cell.folder(this.folder) : photo = null;
  const _Cell.photo(this.photo) : folder = null;
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
  final ProtoPhotoFolder folder;
  final VoidCallback onTap;

  const _FolderTile({super.key, required this.folder, required this.onTap});

  /// Bottom card to top, so the last one sits square and the ones behind it
  /// lean out from under it.
  static const _angles = [-0.08, 0.05, 0.0];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = protoPhotosIn(folder.id).take(3).toList();
    final count = protoFolderCount(folder.id);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WearShape.isRound ? 14 : 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.08),
          ),
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
                                  child: CustomPaint(
                                    painter: SyntheticPhotoPainter(
                                      // Bottom-most first, so the square card
                                      // on top is the folder's newest.
                                      photo: preview[preview.length - 1 - i],
                                    ),
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
                    decoration: BoxDecoration(
                      color: scheme.inverseSurface,
                      borderRadius: BorderRadius.circular(8),
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
///
/// An unavailable tile keeps its place rather than dropping out of the grid:
/// hiding it would move every tile after it between online and offline, so
/// "the paint colour is the third one" would stop being true exactly when the
/// wearer is least able to go looking.
class _PhotoTile extends StatelessWidget {
  final ProtoPhoto photo;
  final bool available;
  final bool captioned;
  final VoidCallback onTap;

  const _PhotoTile({
    super.key,
    required this.photo,
    required this.available,
    required this.captioned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WearShape.isRound ? 14 : 10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (available)
              CustomPaint(painter: SyntheticPhotoPainter(photo: photo))
            else
              _Unavailable(scheme: scheme),
            if (captioned)
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
                    photo.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: detectTextDirection(photo.caption),
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

/// A photo whose bytes are not on disk and cannot be fetched.
class _Unavailable extends StatelessWidget {
  final ColorScheme scheme;

  const _Unavailable({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final ink = scheme.onSurface.withValues(alpha: 0.28);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.07),
      ),
      child: Stack(
        children: [
          Center(child: Icon(Icons.image_outlined, size: 22, color: ink)),
          PositionedDirectional(
            end: 4,
            top: 4,
            child: Icon(Icons.cloud_off_outlined, size: 11, color: ink),
          ),
        ],
      ),
    );
  }
}

/// A folder, pushed over the board.
class PhotoFolderRoute extends StatelessWidget {
  final ProtoTuning tuning;
  final ProtoPhotoFolder folder;
  final List<ProtoPhoto> photos;

  const PhotoFolderRoute({
    super.key,
    required this.tuning,
    required this.folder,
    required this.photos,
  });

  @override
  Widget build(BuildContext context) {
    return EdgeDismissible(
      onDismiss: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: PhotoBoard(
                tuning: tuning,
                active: true,
                folders: const [],
                photos: photos,
              ),
            ),
            _RouteTitle(text: folder.name),
          ],
        ),
      ),
    );
  }
}

/// The name of a pushed route, over a fade so a row scrolling under it does not
/// collide with it. It never takes a pointer: the list runs full height beneath.
class _RouteTitle extends StatelessWidget {
  final String text;

  const _RouteTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      start: 0,
      end: 0,
      top: WearShape.isRound ? 20 : 10,
      child: IgnorePointer(
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 40,
            vertical: 4,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.transparent],
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

/// One photo, full screen.
///
/// Zoom is the feature, not a refinement of it: the photos a household keeps
/// are reference photos — a boiler dial, a lock code, a paint reference — and
/// at fit on a 450 px screen none of them can be read. Three ways in, because
/// not every Wear device has a bezel or a crown: **the crown zooms, pinch
/// zooms, and a double tap toggles** between fit and a working magnification.
///
/// The leading-edge strip is only live at fit. Zoomed, that same strip is where
/// a pan towards the left of the image has to start, so back would fire on
/// every attempt to look at the left of a photo — the double tap is the way
/// back to fit, and fit is the way back out.
class PhotoRoute extends StatefulWidget {
  final ProtoPhoto photo;
  final bool available;

  const PhotoRoute({super.key, required this.photo, required this.available});

  @override
  State<PhotoRoute> createState() => _PhotoRouteState();
}

class _PhotoRouteState extends State<PhotoRoute>
    with SingleTickerProviderStateMixin {
  static const _maxScale = 4.0;

  /// What a double tap lands on: far enough to read a line of small print,
  /// short of the point where the wearer has lost the photo entirely.
  static const _doubleTapScale = 2.5;

  final _view = TransformationController();
  StreamSubscription<double>? _rotary;
  var _zoomed = false;
  Offset? _doubleTapAt;

  /// A double tap travels rather than cuts. The crown does not: its detents
  /// arrive continuously and are already the wearer's own pacing, where a jump
  /// between two magnifications gives the eye nothing to follow.
  late final AnimationController _travel = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Matrix4>? _journey;

  @override
  void initState() {
    super.initState();
    _view.addListener(_onView);
    _rotary = RotaryService.instance.detents.listen(_onDetent);
    _travel.addListener(() {
      final journey = _journey;
      if (journey != null) _view.value = journey.value;
    });
  }

  @override
  void dispose() {
    _rotary?.cancel();
    _travel.dispose();
    _view.removeListener(_onView);
    _view.dispose();
    super.dispose();
  }

  double get _scale => _view.value.getMaxScaleOnAxis();

  void _onView() {
    final zoomed = _scale > 1.01;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  /// The axis reports the opposite of what the wrist means, exactly as it does
  /// for scrolling: clockwise reads negative, and clockwise has to zoom in.
  void _onDetent(double detent) {
    _travel.stop();
    final target = _scaled(
      math.pow(1.08, -detent).toDouble(),
      _viewportCentre(),
    );
    if (target != null) _view.value = target;
  }

  Offset _viewportCentre() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    return box.size.center(Offset.zero);
  }

  /// The transform that scales about [focus], a point in viewport coordinates,
  /// so what was under the wearer's finger — or in the middle of the screen for
  /// the crown — stays where it was. Null when it would not move.
  Matrix4? _scaled(double factor, Offset focus) {
    final current = _scale;
    final target = (current * factor).clamp(1.0, _maxScale);
    final applied = target / current;
    if ((applied - 1).abs() < 0.0001) return null;
    final scene = _view.toScene(focus);
    return _view.value.clone()
      ..translateByDouble(scene.dx, scene.dy, 0, 1)
      ..scaleByDouble(applied, applied, 1, 1)
      ..translateByDouble(-scene.dx, -scene.dy, 0, 1);
  }

  void _animateTo(Matrix4 target) {
    _journey = Matrix4Tween(
      begin: _view.value.clone(),
      end: target,
    ).animate(CurvedAnimation(parent: _travel, curve: Curves.easeOutCubic));
    _travel.forward(from: 0);
  }

  void _onDoubleTap() {
    if (_zoomed) {
      _animateTo(Matrix4.identity());
      return;
    }
    final target = _scaled(_doubleTapScale, _doubleTapAt ?? _viewportCentre());
    if (target != null) _animateTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final body = Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
              onDoubleTap: _onDoubleTap,
              child: InteractiveViewer(
                transformationController: _view,
                minScale: 1,
                maxScale: _maxScale,
                // A finger arriving mid-travel takes over; otherwise the
                // animation keeps writing the transform underneath it.
                onInteractionStart: (_) => _travel.stop(),
                child: widget.available
                    ? CustomPaint(
                        painter: SyntheticPhotoPainter(photo: widget.photo),
                        size: Size.infinite,
                      )
                    : _Unavailable(scheme: Theme.of(context).colorScheme),
              ),
            ),
          ),
          // The caption is what identifies the photo, and it is in the way of
          // the photo the moment the wearer is reading detail off it.
          if (!_zoomed) _Meta(photo: widget.photo),
          if (_zoomed)
            PositionedDirectional(
              end: WearShape.isRound ? 26 : 10,
              top: WearShape.isRound ? 26 : 10,
              child: _ZoomBadge(scale: _scale),
            ),
        ],
      ),
    );

    // Zoomed, the leading edge belongs to panning; at fit it is the way back.
    return _zoomed
        ? body
        : EdgeDismissible(
            onDismiss: () => Navigator.of(context).pop(),
            child: body,
          );
  }
}

/// Caption, who added it and when.
///
/// The phone shows none of this — its detail view carries the caption alone —
/// but on a shared household board "Dana, Tuesday" is often the thing that
/// tells two similar photos apart, and a pushed route has the room.
class _Meta extends StatelessWidget {
  final ProtoPhoto photo;

  const _Meta({required this.photo});

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      start: 0,
      end: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          padding: EdgeInsetsDirectional.only(
            start: 22,
            end: 22,
            top: 16,
            bottom: WearShape.isRound ? 24 : 12,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                photo.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                textDirection: detectTextDirection(photo.caption),
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${photo.uploadedBy} · ${photo.when}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  height: 1.2,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How far in the wearer is — and, because it only appears off fit, that the
/// leading edge is not currently the way out.
class _ZoomBadge extends StatelessWidget {
  final double scale;

  const _ZoomBadge({required this.scale});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      child: Text(
        '${scale.toStringAsFixed(1)}×',
        style: const TextStyle(
          fontSize: 9,
          height: 1.2,
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

/// Stands in for a photo.
///
/// It draws small print deliberately: at tile size and at fit it is a texture,
/// and it only resolves into something readable a long way into the zoom. A
/// flat gradient would make every zoom decision look equally good.
class SyntheticPhotoPainter extends CustomPainter {
  final ProtoPhoto photo;

  const SyntheticPhotoPainter({required this.photo});

  /// The design space the content is laid out in, scaled to whatever box it
  /// lands in, so a tile and the full view show the same photo.
  static const _design = 300.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / _design, size.height / _design);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _design, _design),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [photo.a, photo.b],
        ).createShader(const Rect.fromLTWH(0, 0, _design, _design)),
    );

    // Deterministic per photo, so a tile does not reshuffle between rebuilds.
    final random = math.Random(photo.id);
    final ink = Paint()..color = Colors.white.withValues(alpha: 0.82);

    canvas.drawRect(
      const Rect.fromLTWH(28, 34, 150, 9),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    for (var i = 0; i < 14; i++) {
      final y = 62.0 + i * 15;
      canvas.drawRect(
        Rect.fromLTWH(28, y, 60 + random.nextDouble() * 70, 4),
        ink,
      );
      canvas.drawRect(
        Rect.fromLTWH(212, y, 20 + random.nextDouble() * 40, 4),
        ink,
      );
    }

    // One line of genuinely small print: the thing a wearer opens the photo to
    // read, and the thing fit-to-screen cannot show them.
    final painter = TextPainter(
      text: TextSpan(
        text: '${photo.uploadedBy} · ${1000 + photo.id * 137}',
        style: const TextStyle(
          fontSize: 7,
          height: 1,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, const Offset(28, 276));

    canvas.restore();
  }

  @override
  bool shouldRepaint(SyntheticPhotoPainter old) => old.photo.id != photo.id;
}
