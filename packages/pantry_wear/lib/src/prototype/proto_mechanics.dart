import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../services/rotary_service.dart';
import '../wear_shape.dart';

/// PROTOTYPE — the shell machinery the three variants share.
///
/// Layout is deliberately *not* shared: each variant is free to throw the
/// whole frame away. What lives here is mechanism the platform forces on us
/// and that every variant must behave identically under — gesture ownership,
/// the hand-rolled exit, rotary, and the geometry of a curved row.

/// Google's rule for a pager on a watch: a drag that starts within this much
/// of the screen width from the leading edge belongs to the system dismiss,
/// not to the pager — and only on the first page, because every deeper page
/// pages back before it could be dismissed.
const kEdgeExclusionFraction = 0.15;

/// The pager is the only widget competing with a vertical list for a drag, and
/// it loses ties too readily at the stock threshold.
const kSlopInflation = 1.10;

/// Google's hard limit on page dots.
const kMaxDots = 6;

/// Page slop wide enough that a vertical scroll doesn't flip pages.
class InflatedSlopPageScrollPhysics extends PageScrollPhysics {
  const InflatedSlopPageScrollPhysics({super.parent});

  @override
  InflatedSlopPageScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      InflatedSlopPageScrollPhysics(parent: buildParent(ancestor));

  @override
  double? get dragStartDistanceMotionThreshold {
    final base = super.dragStartDistanceMotionThreshold ?? 3.5;
    return base * kSlopInflation;
  }
}

/// A pager that reserves the leading edge of its first page for leaving the
/// app.
///
/// `windowSwipeToDismiss=false` is what lets the pager own horizontal drags at
/// all, and it removes the only way out of the app — so the way out is rebuilt
/// here: the excluded strip takes the drag and calls [SystemNavigator.pop],
/// which is framework and needs no Kotlin. The strip sits above the pager so
/// it is hit-tested first and wins the arena; it is translucent, so taps still
/// reach the content underneath.
class EdgeAwarePageView extends StatelessWidget {
  final PageController controller;
  final int page;
  final ValueChanged<int> onPageChanged;
  final List<Widget> children;

  const EdgeAwarePageView({
    super.key,
    required this.controller,
    required this.page,
    required this.onPageChanged,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final ltr = Directionality.of(context) == TextDirection.ltr;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          children: [
            PageView(
              controller: controller,
              physics: const InflatedSlopPageScrollPhysics(),
              onPageChanged: onPageChanged,
              children: children,
            ),
            if (page == 0)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: width * kEdgeExclusionFraction,
                child: _DismissStrip(
                  width: width,
                  towardsEnd: ltr ? 1 : -1,
                  onDismiss: () => SystemNavigator.pop(),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DismissStrip extends StatefulWidget {
  final double width;
  final double towardsEnd;
  final VoidCallback onDismiss;

  const _DismissStrip({
    required this.width,
    required this.towardsEnd,
    required this.onDismiss,
  });

  @override
  State<_DismissStrip> createState() => _DismissStripState();
}

class _DismissStripState extends State<_DismissStrip> {
  var _travelled = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _travelled = 0,
      onHorizontalDragUpdate: (d) => _travelled += d.delta.dx,
      onHorizontalDragEnd: (d) {
        final travelled = _travelled * widget.towardsEnd;
        final velocity = (d.primaryVelocity ?? 0) * widget.towardsEnd;
        if (travelled > widget.width * 0.25 || velocity > 400) {
          widget.onDismiss();
        }
        _travelled = 0;
      },
    );
  }
}

/// Steers [controller] from the bezel and the crown.
///
/// Only the page the wearer is looking at may listen: the detent stream is
/// broadcast, and two pages scrolling on one turn is the failure this guards.
class RotaryScrollable extends StatefulWidget {
  final ScrollController controller;
  final bool active;
  final double pixelsPerDetent;
  final Widget child;

  const RotaryScrollable({
    super.key,
    required this.controller,
    required this.active,
    required this.child,
    this.pixelsPerDetent = 48,
  });

  @override
  State<RotaryScrollable> createState() => _RotaryScrollableState();
}

class _RotaryScrollableState extends State<RotaryScrollable> {
  StreamSubscription<double>? _sub;
  double? _target;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(RotaryScrollable old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  void _sync() {
    _sub?.cancel();
    _sub = widget.active
        ? RotaryService.instance.detents.listen(_onDetent)
        : null;
    _target = null;
  }

  void _onDetent(double detent) {
    final controller = widget.controller;
    if (!controller.hasClients) return;
    final position = controller.position;
    final from = _target ?? position.pixels;
    // The axis reports the opposite of what the wrist means: turning the bezel
    // clockwise reads negative, and clockwise has to scroll down.
    _target = (from - detent * widget.pixelsPerDetent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    controller
        .animateTo(
          _target!,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() => _target = null);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// How far a row sits from the vertical centre, expressed as the three things
/// a curved list can spend: width, scale and opacity.
typedef RowGeometry = ({double widthFactor, double scale, double opacity});

/// [normalized] is 0 at the vertical centre and ±1 at the top and bottom of
/// the viewport.
typedef RowCurve = RowGeometry Function(double normalized);

const RowGeometry _uniform = (widthFactor: 1, scale: 1, opacity: 1);

/// A row that is as wide as the circle is at its height. The chord of a circle
/// is `sqrt(1 - n²)` of the diameter, so this is the shape of the screen
/// itself rather than an approximation of it, floored so the extremes stay
/// readable rather than collapsing to a sliver.
RowGeometry circleChordCurve(double n) => (
  widthFactor: math.max(0.60, math.sqrt(1 - n * n)),
  scale: 1,
  opacity: 1 - 0.45 * n * n,
);

/// Size, width and weight as a ratio of distance up the y axis from the
/// centred row, where [d] is 0 at the centre and 1 at the edge of the falloff.
///
/// A row's distance from the centre is the only thing that varies, so it is
/// the only thing allowed to drive its treatment — an index-based "focused or
/// not" step reads as a jump halfway through a scroll.
/// Nothing dims: a watch list is read at a glance and in sunlight, and a row
/// two places down is still a row you are reading.
RowGeometry railFocusCurve(double d) =>
    (widthFactor: 1 - 0.14 * d, scale: 1 - 0.24 * d, opacity: 1);

/// A list with one row in charge: the centred row is full size and everything
/// else recedes, so the thing under your thumb is the thing you meant.
RowGeometry focusCurve(double n) {
  final d = n.abs();
  return (
    // Even the centred row stops short of the glass: a round screen is only
    // as wide as its diameter on one line, and a row that used all of it
    // would have its ends shaved off by the bezel.
    widthFactor: math.max(0.52, 0.86 - 0.34 * d),
    scale: 1 - 0.30 * d,
    opacity: math.max(0.25, 1 - 0.75 * d),
  );
}

/// A fixed-extent list whose rows narrow towards the top and bottom of a round
/// screen.
///
/// The shape comes from [WearShape], which is filled from a Dart entrypoint
/// argument before `runApp` — a channel round trip lands 311 ms after the
/// first frame, and a list that reflows a third of a second in is worse than
/// one that never curved.
class CurvedRowList extends StatelessWidget {
  final ScrollController controller;
  final double itemExtent;
  final int itemCount;
  final RowCurve curve;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  const CurvedRowList({
    super.key,
    required this.controller,
    required this.itemExtent,
    required this.itemCount,
    required this.curve,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = padding.resolve(Directionality.of(context));
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = constraints.maxHeight / 2;
        return ListView.builder(
          controller: controller,
          padding: padding,
          itemExtent: itemExtent,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final child = itemBuilder(context, index);
            if (WearShape.isSquare) return child;
            return AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final offset = controller.hasClients ? controller.offset : 0.0;
                final rowCentre =
                    resolved.top + index * itemExtent + itemExtent / 2 - offset;
                final n = ((rowCentre - half) / half).clamp(-1.0, 1.0);
                final g = curve(n);
                return _shaped(child, g);
              },
            );
          },
        );
      },
    );
  }

  static Widget _shaped(Widget child, RowGeometry g) {
    if (g == _uniform) return child;
    return Opacity(
      opacity: g.opacity,
      child: FractionallySizedBox(
        widthFactor: g.widthFactor,
        child: g.scale == 1
            ? child
            : Transform.scale(scale: g.scale, child: child),
      ),
    );
  }
}

/// Draws [text] along the arc of the bezel.
///
/// Round screens have their most useless pixels at the very top: a rectangle
/// that reaches them wastes the width of the whole row. Text bent along the
/// arc costs almost none of the rectangle the content wants.
class ArcText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double inset;

  const ArcText({
    super.key,
    required this.text,
    required this.style,
    this.inset = 8,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ArcTextPainter(
      text: text,
      style: style,
      inset: inset,
      rtl: detectTextDirection(text) == TextDirection.rtl,
    ),
    size: Size.infinite,
  );
}

class _ArcTextPainter extends CustomPainter {
  final String text;
  final TextStyle style;
  final double inset;
  final bool rtl;

  _ArcTextPainter({
    required this.text,
    required this.style,
    required this.inset,
    required this.rtl,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2 - inset;
    if (radius <= 0) return;
    final centre = Offset(size.width / 2, size.height / 2);

    final glyphs = text.split('');
    final painters = [
      for (final glyph in rtl ? glyphs.reversed : glyphs)
        TextPainter(
          text: TextSpan(text: glyph, style: style),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];

    final sweep = painters.fold<double>(0, (sum, p) => sum + p.width) / radius;
    var angle = -math.pi / 2 - sweep / 2;

    for (final painter in painters) {
      final half = painter.width / 2 / radius;
      angle += half;
      canvas.save();
      canvas.translate(
        centre.dx + radius * math.cos(angle),
        centre.dy + radius * math.sin(angle),
      );
      canvas.rotate(angle + math.pi / 2);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height));
      canvas.restore();
      angle += half;
    }
  }

  @override
  bool shouldRepaint(_ArcTextPainter old) =>
      old.text != text || old.style != style || old.inset != inset;
}

/// The window of dots to draw, since the indicator caps at [kMaxDots] and the
/// pages may one day outnumber it.
({int count, int selected}) dotWindow(int pages, int page) {
  if (pages <= kMaxDots) return (count: pages, selected: page);
  final start = (page - kMaxDots ~/ 2).clamp(0, pages - kMaxDots);
  return (count: kMaxDots, selected: page - start);
}
