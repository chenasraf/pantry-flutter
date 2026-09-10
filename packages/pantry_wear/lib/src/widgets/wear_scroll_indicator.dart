import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../wear_shape.dart';
import 'wear_mechanics.dart';

/// Where the wearer is in a list, drawn against the bezel while they move
/// through it.
///
/// A watch has no scrollbar of its own and no room for one that stays: the
/// screen is the size of a thumbnail and the list is the whole of it. So this
/// arrives with the scroll and leaves a moment after it — long enough to say
/// how much list there is and where in it you are, gone before it is clutter.
///
/// It follows the bezel on a round screen because that is the only edge a
/// round screen has to spare. A square one gets the straight bar the same
/// reasoning produces there.
///
/// Wrapped around a scrollable rather than told about one: what it draws comes
/// from the notifications the scrollable already sends, so any list, sliver or
/// prose page gets one by being put inside it.
class WearScrollIndicator extends StatefulWidget {
  final Widget child;

  const WearScrollIndicator({super.key, required this.child});

  /// The length of the track, and of the thumb at its longest. Fixed rather
  /// than a share of the screen — Wear's own indicator holds this size across
  /// every watch and lets the curve it is bent around change instead.
  static const double trackExtent = 50;

  /// How thick the arc is drawn, and how far its outer edge sits from the
  /// glass.
  static const double thickness = 4;
  static const double margin = 2;

  /// The shortest the thumb is allowed to get. A list of two hundred rows
  /// would otherwise report its position with something too small to see.
  static const double minThumbFraction = 0.12;

  /// How long the indicator stays after the list stops moving.
  static const Duration linger = Duration(milliseconds: 900);

  @override
  State<WearScrollIndicator> createState() => _WearScrollIndicatorState();
}

class _WearScrollIndicatorState extends State<WearScrollIndicator>
    with SingleTickerProviderStateMixin {
  /// Built here rather than lazily at its first use: a page whose list never
  /// moves never draws the indicator, which would leave `dispose` as the first
  /// thing to touch the controller — and a ticker cannot be created against an
  /// element that is already going away.
  late final AnimationController _fade;

  Timer? _idle;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  /// Where the thumb starts and how much of the track it covers, both as a
  /// fraction of the track. Null until a scroll has said.
  ({double start, double extent})? _thumb;

  @override
  void dispose() {
    _idle?.cancel();
    _fade.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (notification.depth > 0 ||
        !metrics.hasContentDimensions ||
        metrics.axis != Axis.vertical) {
      return false;
    }
    // A list that fits has nothing to say about where you are in it, and
    // Wear's own rule is that a view which does not scroll shows no indicator.
    if (metrics.maxScrollExtent <= 0) {
      _publish(null);
      return false;
    }

    final content = metrics.maxScrollExtent + metrics.extentInside;
    final extent = math.max(
      WearScrollIndicator.minThumbFraction,
      metrics.extentInside / content,
    );
    final progress = (metrics.pixels / metrics.maxScrollExtent).clamp(0.0, 1.0);
    _publish((start: progress * (1 - extent), extent: extent));
    return false;
  }

  /// Scroll notifications are dispatched *during* layout when the content's
  /// dimensions change — expanding a section is exactly that — so acting on one
  /// in place asks for a rebuild inside the frame already being built. The work
  /// is the same either way; only when it is allowed to happen differs.
  void _publish(({double start, double extent})? thumb) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _apply(thumb);
      });
      return;
    }
    _apply(thumb);
  }

  void _apply(({double start, double extent})? thumb) {
    if (thumb == null) {
      _idle?.cancel();
      _fade.reverse();
      return;
    }
    setState(() => _thumb = thumb);
    _fade.forward();
    _idle?.cancel();
    _idle = Timer(WearScrollIndicator.linger, () {
      if (mounted) _fade.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final thumb = _thumb;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          if (thumb != null)
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: _fade,
                  child: CustomPaint(
                    painter: _IndicatorPainter(
                      start: thumb.start,
                      extent: thumb.extent,
                      // The bezel's own side, which is the one the system's
                      // dismiss gesture does not live on.
                      onTrailingEdge: systemTextDirection == TextDirection.ltr,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IndicatorPainter extends CustomPainter {
  final double start;
  final double extent;
  final bool onTrailingEdge;

  const _IndicatorPainter({
    required this.start,
    required this.extent,
    required this.onTrailingEdge,
  });

  static const _track = Color(0x2EFFFFFF);
  static const _thumb = Color(0xCCFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..strokeWidth = WearScrollIndicator.thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (WearShape.isRound) {
      final radius =
          size.width / 2 -
          WearScrollIndicator.margin -
          WearScrollIndicator.thickness / 2;
      final box = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: radius,
      );
      // The track's length is what is fixed; the angle it subtends is whatever
      // that length comes to on this watch's radius.
      final sweep = WearScrollIndicator.trackExtent / radius;
      // Zero points at the trailing edge and the angle runs down the screen,
      // so a track centred on the middle of the glass starts half a sweep above
      // it. Mirrored, it is measured from the other side of the circle.
      final centre = onTrailingEdge ? 0.0 : math.pi;
      final from = centre - sweep / 2;
      canvas.drawArc(box, from, sweep, false, stroke..color = _track);
      canvas.drawArc(
        box,
        from + start * sweep,
        extent * sweep,
        false,
        stroke..color = _thumb,
      );
      return;
    }

    final x = onTrailingEdge
        ? size.width -
              WearScrollIndicator.margin -
              WearScrollIndicator.thickness / 2
        : WearScrollIndicator.margin + WearScrollIndicator.thickness / 2;
    final top = (size.height - WearScrollIndicator.trackExtent) / 2;
    canvas.drawLine(
      Offset(x, top),
      Offset(x, top + WearScrollIndicator.trackExtent),
      stroke..color = _track,
    );
    canvas.drawLine(
      Offset(x, top + start * WearScrollIndicator.trackExtent),
      Offset(x, top + (start + extent) * WearScrollIndicator.trackExtent),
      stroke..color = _thumb,
    );
  }

  @override
  bool shouldRepaint(_IndicatorPainter old) =>
      old.start != start ||
      old.extent != extent ||
      old.onTrailingEdge != onTrailingEdge;
}
