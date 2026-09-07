import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/rotary_service.dart';
import '../wear_shape.dart';
import 'preview_sizes.dart';
import 'wear_mechanics.dart';
import 'wear_surfaces.dart';

/// One image, full screen.
///
/// Zoom is the feature, not a refinement of it: the images a household keeps
/// are reference images — a boiler dial, a lock code, a paint reference, the
/// label on the bottle to buy again — and at fit on a watch none of them can be
/// read. Three ways in, because not every Wear device has a bezel or a crown:
/// **the crown zooms, pinch zooms, and a double tap toggles** between fit and a
/// working magnification.
///
/// The leading-edge strip is only live at fit. Zoomed, that same strip is where
/// a pan towards the left of the image has to start, so back would fire on
/// every attempt to look at the left of an image — the double tap is the way
/// back to fit, and fit is the way back out.
class ImageRoute extends StatefulWidget {
  /// Draws the image at the preview size asked for, called again with a
  /// sharper size once the wearer zooms past reading distance.
  final Widget Function(BuildContext context, int size) image;

  /// The size this image is already on disk at — the tile or thumbnail the
  /// wearer tapped — drawn underneath as this view's own placeholder. Null
  /// where nothing smaller was ever fetched.
  final int Function(BuildContext context)? cached;

  /// What identifies the image, over its foot. It is in the way of the image
  /// the moment the wearer is reading detail off it, so it shows at fit only.
  final Widget? caption;

  const ImageRoute({super.key, required this.image, this.cached, this.caption});

  @override
  State<ImageRoute> createState() => _ImageRouteState();
}

class _ImageRouteState extends State<ImageRoute>
    with SingleTickerProviderStateMixin {
  static const _maxScale = 4.0;

  /// What a double tap lands on: far enough to read a line of small print,
  /// short of the point where the wearer has lost the image entirely.
  static const _doubleTapScale = 2.5;

  /// Past this the fit-size preview is being magnified rather than read, so
  /// the wearer has asked for the detail the endpoint's own clamp can give.
  static const _sharpenAbove = 1.5;

  final _view = TransformationController();
  StreamSubscription<double>? _rotary;
  var _zoomed = false;
  Offset? _doubleTapAt;

  /// The size currently being drawn. It only ever climbs: once the sharper
  /// bytes are on disk, dropping back to fit on zoom-out would cost a redraw
  /// and buy nothing.
  int? _size;

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
    final sharpen = _scale > _sharpenAbove && _size != WearPreviewSize.zoomed;
    if (zoomed == _zoomed && !sharpen) return;
    setState(() {
      _zoomed = zoomed;
      if (sharpen) _size = WearPreviewSize.zoomed;
    });
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
    final size = _size ??= WearPreviewSize.fit(context);
    final cached = widget.cached?.call(context);
    final caption = widget.caption;
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // What the wearer tapped is already on disk, so it is this
                    // view's own placeholder — better than the separate small
                    // fetch the phone makes for the same moment.
                    if (cached != null) widget.image(context, cached),
                    widget.image(context, size),
                  ],
                ),
              ),
            ),
          ),
          if (!_zoomed && caption != null)
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: IgnorePointer(child: caption),
            ),
          if (_zoomed)
            PositionedDirectional(
              end: WearShape.isRound ? 26 : 10,
              top: WearShape.isRound ? 26 : 10,
              // Listening to the transform rather than reading it: this route
              // rebuilds only when the zoom crosses a threshold, so a badge
              // built from `_scale` freezes at whatever the last threshold left
              // it at and then lies for the rest of the gesture.
              child: ListenableBuilder(
                listenable: _view,
                builder: (context, _) => _ZoomBadge(scale: _scale),
              ),
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

/// How far in the wearer is — and, because it only appears off fit, that the
/// leading edge is not currently the way out.
class _ZoomBadge extends StatelessWidget {
  final double scale;

  const _ZoomBadge({required this.scale});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: WearSurface.panel(context, fill: Colors.black54, radius: 9),
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
