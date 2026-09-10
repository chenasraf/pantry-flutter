import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../services/rotary_service.dart';
import '../wear_shape.dart';
import 'wear_mechanics.dart';
import 'wear_metrics.dart';

/// The list every scrolling page on the watch is built from — centred-focus on
/// a round screen, flat on a square one.
///
/// The focus is a round screen's answer to its own geometry, not a house style:
/// the glass narrows towards the top and bottom, so one row sits where the
/// screen is widest and is worth building around. A square screen narrows
/// nowhere, so it keeps the same rows, the same grouping and the same rail, and
/// drops the snap, the falloff and the aim-then-act tap that all follow from
/// having a row in charge. [hasFocusRow] is the one place that branches.
///
/// Snapping is hand-rolled over row offsets rather than taken from a
/// [ListWheelScrollView]: a wheel has one `itemExtent` and no sliver protocol,
/// so it can express neither a group header shorter than a row nor one that
/// never takes the focus.
///
/// [railFocusCurve] reads a row's distance from the **screen's** centre, which
/// is why the viewport stays full-height with the rail overlaying it rather
/// than sitting in a column below it.

/// One entry in the list: a row you can land on, or a header you cannot.
@immutable
class FocusElement {
  final double extent;

  /// Headers are excluded from the snap table, which is the whole of "it
  /// can't catch the focus" — there is no index to bump past, because a
  /// header was never a candidate.
  final bool snappable;
  final bool isHeader;

  /// Which group this element belongs to, headers included, so the rail can
  /// name the group the focused card is in — and draw it in that group's own
  /// icon and colour rather than as anonymous text.
  final String? groupLabel;
  final IconData? groupIcon;
  final Color? groupColor;

  /// [d] is 0 on the centre line and 1 at the edge of the falloff.
  final Widget Function(BuildContext context, double d) builder;

  const FocusElement({
    required this.extent,
    required this.builder,
    this.snappable = true,
    this.isHeader = false,
    this.groupLabel,
    this.groupIcon,
    this.groupColor,
  });
}

/// What the rail needs to know about where the list currently sits.
@immutable
class FocusGeometry {
  /// Index of the element nearest the centre line, or -1 before first layout.
  final int centredIndex;

  /// How far [centredIndex] actually is from the centre line, in pixels.
  ///
  /// "Nearest snappable" is not the same as "on the line": a header cannot be
  /// landed on, so a tall one at the top of a list leaves the first row a whole
  /// row below the centre while still being the nearest thing to it. A page
  /// that acts on the centred row has to know the difference, or a tap lands on
  /// a row the wearer can plainly see is not the one in charge.
  final double centredDistance;

  /// The group the focused card is in, in that group's own livery.
  final String? stickyGroup;
  final IconData? stickyIcon;
  final Color? stickyColor;

  const FocusGeometry({
    this.centredIndex = -1,
    this.centredDistance = 0,
    this.stickyGroup,
    this.stickyIcon,
    this.stickyColor,
  });
}

class SnapFocusList extends StatefulWidget {
  final ScrollController controller;
  final List<FocusElement> elements;

  /// The extent a snappable row occupies. Headers may be shorter; this is the
  /// figure the leading and trailing pads are built from, so the first and
  /// last rows can both reach the centre line.
  final double itemExtent;

  /// How far the falloff reaches, in rows.
  final double falloffRows;

  final bool snapEnabled;

  /// Only the page being looked at may steer from the crown.
  final bool rotaryActive;

  /// Fraction of the width held back at each side, applied to every row
  /// including the focused one.
  ///
  /// The falloff's width factor is 1.0 on the centre line, so without this the
  /// focused row runs to the glass. A short pill nearly gets away with it — at
  /// the centre line a circle is at its widest — but a tall row's corners sit
  /// well above and below that line, where the circle has already narrowed,
  /// and the bezel shaves them.
  final double horizontalInset;

  /// Updated on every scroll frame. The rail listens to it.
  final ValueNotifier<FocusGeometry>? geometry;

  /// Whether the rail is drawn over this list.
  ///
  /// Only read on a square screen, where the list starts at the top instead of
  /// half a viewport down and would otherwise put its first row behind the
  /// rail. A pushed route leaves this false: it has no rail over it.
  final bool underRail;

  const SnapFocusList({
    super.key,
    required this.controller,
    required this.elements,
    required this.itemExtent,
    this.falloffRows = 2.2,
    this.snapEnabled = true,
    this.rotaryActive = false,
    this.horizontalInset = 0.025,
    this.geometry,
    this.underRail = false,
  });

  /// Whether this list has a row in charge.
  ///
  /// A round screen narrows towards the top and bottom, so one row sits at the
  /// glass's widest point and the list is built around it: rows recede from it,
  /// the scroll settles on it, and it is the row a tap acts on. A square screen
  /// narrows nowhere — every row is as wide and as readable as every other — so
  /// there is no row to elect, and building one anyway costs the wearer a
  /// scroll before every action for nothing.
  static bool get hasFocusRow => WearShape.isRound;

  @override
  SnapFocusListState createState() => SnapFocusListState();
}

class SnapFocusListState extends State<SnapFocusList> {
  /// Absolute top of each element, including the leading pad.
  List<double> _tops = const [];
  List<double> _snapTargets = const [];
  double _viewport = 0;

  /// Where the last detent was heading, so a fast turn accumulates rows
  /// instead of each detent re-measuring from a position still in flight.
  double? _stepTarget;
  StreamSubscription<double>? _rotary;

  @override
  void initState() {
    super.initState();
    _syncRotary();
  }

  @override
  void didUpdateWidget(SnapFocusList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rotaryActive != widget.rotaryActive) _syncRotary();
  }

  void _syncRotary() {
    _rotary?.cancel();
    _rotary = widget.rotaryActive
        ? RotaryService.instance.detents.listen(_onDetent)
        : null;
    _stepTarget = null;
  }

  /// The axis reports the opposite of what the wrist means: turning the bezel
  /// clockwise reads negative, and clockwise has to move down the list.
  void _onDetent(double detent) => step(detent < 0 ? 1 : -1);

  @override
  void dispose() {
    _rotary?.cancel();
    super.dispose();
  }

  /// Space above the first row. Half a viewport where every row has to be able
  /// to reach the centre line; on a flat list only what the rail covers.
  double _leadPad(double viewportHeight) => SnapFocusList.hasFocusRow
      ? math.max(0.0, viewportHeight / 2 - widget.itemExtent / 2)
      : (widget.underRail
            ? WearMetrics.of(context).railHeight(viewportHeight)
            : 0.0);

  /// Space below the last row. A flat list needs only enough to lift the last
  /// row off the bottom edge.
  double _trailPad(double viewportHeight) => SnapFocusList.hasFocusRow
      ? _leadPad(viewportHeight)
      : WearMetrics.of(context).cardGap;

  void _measure(double viewportHeight) {
    final lead = _leadPad(viewportHeight);
    final tops = <double>[];
    var y = lead;
    for (final e in widget.elements) {
      tops.add(y);
      y += e.extent;
    }
    final targets = <double>[];
    for (var i = 0; i < widget.elements.length; i++) {
      if (!widget.elements[i].snappable) continue;
      targets.add(tops[i] + widget.elements[i].extent / 2 - viewportHeight / 2);
    }
    _tops = tops;
    _snapTargets = targets;
    _viewport = viewportHeight;
  }

  /// Step one row along the **snap table**, not one row's worth of pixels.
  ///
  /// A fixed pixel step is only correct while every element is the same
  /// height. The moment a short header sits between two rows, a uniform step
  /// walks off the grid by exactly the header's extent and every landing after
  /// it falls between two cards — which is why the first row of a group could
  /// not be reached.
  void step(int delta) {
    if (!widget.controller.hasClients) return;
    final position = widget.controller.position;
    final from = _stepTarget ?? position.pixels;

    // A flat list has no landing grid to walk, so a detent is simply a row's
    // worth of scrolling. The snap table's whole purpose was to keep landings
    // on the centre line, and there is no line here to fall off.
    if (!SnapFocusList.hasFocusRow) {
      _animateStep(
        (from + delta * widget.itemExtent).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
        from,
      );
      return;
    }
    if (_snapTargets.isEmpty) return;

    var nearest = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < _snapTargets.length; i++) {
      final d = (_snapTargets[i] - from).abs();
      if (d < bestDistance) {
        bestDistance = d;
        nearest = i;
      }
    }
    // A detent from a resting position moves one row; a detent mid-flight
    // continues from where the last one was heading.
    //
    // Resting somewhere that is not a row is its own case: at the top of a
    // list that opens on a header, the nearest row is already *ahead* of the
    // wearer, so stepping toward it has to land on it rather than step past it
    // — which is how the first row got skipped on the way down.
    final resting = (_snapTargets[nearest] - from).abs() < 1;
    final ahead = delta > 0
        ? _snapTargets[nearest] > from
        : _snapTargets[nearest] < from;
    final next = !resting && ahead
        ? nearest
        : (nearest + delta).clamp(0, _snapTargets.length - 1);
    _animateStep(
      _snapTargets[next].clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
      from,
    );
  }

  /// Carry the crown to [target], remembering where it was heading so a fast
  /// turn accumulates instead of each detent re-measuring from a position
  /// still in flight.
  void _animateStep(double target, double from) {
    if (target == from) return;
    _stepTarget = target;
    widget.controller
        .animateTo(
          target,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
        )
        // Only when nothing newer has been aimed at. A detent arriving
        // mid-flight replaces the target and cancels this animation, and a
        // cancelled animation's future completes just like a finished one —
        // so clearing unconditionally threw away the aim that superseded it,
        // and every later detent in the turn measured from a list still in
        // motion. Ten detents carried one row instead of ten.
        .whenComplete(() {
          if (_stepTarget == target) _stepTarget = null;
        });
  }

  /// Whether a tap on [index] acts, or only brings the row within reach.
  ///
  /// Where there is a row in charge, only that row acts, and only while it is
  /// actually on the line — "nearest snappable" is not the same as "centred",
  /// so a tall header above the first row can leave it a whole row short while
  /// still being the nearest thing to the line.
  ///
  /// Where there is none, a tap acts wherever it lands, so long as the row is
  /// whole: a row running off an edge was not aimed at squarely either, and
  /// tapping one brings it in instead.
  bool canActOn(int index) {
    if (index < 0 || index >= widget.elements.length) return false;
    if (!SnapFocusList.hasFocusRow) return isFullyVisible(index);
    final geometry = widget.geometry?.value;
    if (geometry == null) return false;
    return index == geometry.centredIndex &&
        geometry.centredDistance <= widget.itemExtent / 2;
  }

  /// Whether every pixel of [index] is inside the viewport.
  bool isFullyVisible(int index) {
    if (index < 0 || index >= _tops.length) return false;
    if (!widget.controller.hasClients || _viewport <= 0) return false;
    final offset = widget.controller.offset;
    final top = _tops[index];
    final bottom = top + widget.elements[index].extent;
    // A hair of tolerance: a row flush with an edge is whole, and floating
    // point makes "flush" arrive as either side of exact.
    return top >= offset - 0.5 && bottom <= offset + _viewport + 0.5;
  }

  /// Bring [index] within reach of a tap — to the centre line where the list
  /// has one, and just inside the viewport where it does not. Scrolling a
  /// square list to a centre it does not have would be the very haul that
  /// having no focus row exists to avoid.
  void reveal(int index) {
    if (SnapFocusList.hasFocusRow) return centreOn(index);
    if (index < 0 || index >= _tops.length) return;
    if (!widget.controller.hasClients) return;
    final position = widget.controller.position;
    final offset = widget.controller.offset;
    final top = _tops[index];
    final bottom = top + widget.elements[index].extent;
    var target = offset;
    if (top < offset) {
      target = top;
    } else if (bottom > offset + _viewport) {
      target = bottom - _viewport;
    }
    target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - offset).abs() < 0.5) return;
    widget.controller.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  /// Bring an element to the centre line. Tapping an off-centre card scrolls
  /// it here rather than acting on it, so a mis-aim costs a scroll instead of
  /// a write.
  void centreOn(int index) {
    if (index < 0 || index >= widget.elements.length || _tops.isEmpty) return;
    if (!widget.controller.hasClients) return;
    final position = widget.controller.position;
    final target =
        (_tops[index] + widget.elements[index].extent / 2 - _viewport / 2)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
    widget.controller.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _publish() {
    final notifier = widget.geometry;
    if (notifier == null || _tops.isEmpty) return;
    if (!widget.controller.hasClients) return;
    final offset = widget.controller.offset;
    final centre = offset + _viewport / 2;

    var best = -1;
    var bestDistance = double.infinity;
    for (var i = 0; i < widget.elements.length; i++) {
      if (!widget.elements[i].snappable) continue;
      final d = ((_tops[i] + widget.elements[i].extent / 2) - centre).abs();
      if (d < bestDistance) {
        bestDistance = d;
        best = i;
      }
    }

    // The rail names the group of the **focused** card, not the group the top
    // edge happens to be inside. A group's first row is focused well before
    // its header has climbed to the rail, so measuring at the top left the
    // rail a group behind for the whole of that first row.
    final focused = best >= 0 ? widget.elements[best] : null;

    final next = FocusGeometry(
      centredIndex: best,
      centredDistance: best >= 0 ? bestDistance : 0,
      stickyGroup: focused?.groupLabel,
      stickyIcon: focused?.groupIcon,
      stickyColor: focused?.groupColor,
    );
    final current = notifier.value;
    if (current.centredIndex == next.centredIndex &&
        current.centredDistance == next.centredDistance &&
        current.stickyGroup == next.stickyGroup) {
      return;
    }

    // Scroll notifications are dispatched *during* layout, so publishing
    // straight from one asks a listener to rebuild inside the frame that is
    // already building. The value would still land, but the rebuild is
    // dropped — which is why the rail kept rendering its initial value
    // however correct this computation was.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) notifier.value = next;
      });
      return;
    }
    notifier.value = next;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        _measure(h);
        WidgetsBinding.instance.addPostFrameCallback((_) => _publish());

        final focused = SnapFocusList.hasFocusRow;
        final falloff = widget.falloffRows * widget.itemExtent;
        final lead = _leadPad(h);
        final trail = _trailPad(h);
        final w = constraints.maxWidth;
        final rowWidth = w * (1 - 2 * widget.horizontalInset);

        /// The largest a row of [width] by [height] may be drawn, at [dy] from
        /// the screen's centre line, with its corners still on the glass.
        ///
        /// The falloff alone does not answer this. It reaches two rows and then
        /// holds, where the bezel goes on closing in all the way to the edge —
        /// so past the falloff a row keeps a size the screen has stopped
        /// having, and the wearer reads the middle of it.
        ///
        /// Scale rather than width, because a row is not free to be narrow: its
        /// glyph and its gap are fixed, and squeezing the box they sit in only
        /// moves the overflow inside the card. Scaling leaves the layout alone
        /// and shrinks what is painted, which is what the glass is asking for.
        double glassScale(double dy, double width, double height) {
          if (!WearShape.isRound) return 1;
          final r = w / 2;
          final halfW = width / 2;
          final halfH = height / 2;
          final d = dy.abs();
          // The corner (s·halfW, d + s·halfH) on the circle of radius r, solved
          // for s.
          final a = halfW * halfW + halfH * halfH;
          final root = math.sqrt(
            math.max(0.0, d * d * halfH * halfH - a * (d * d - r * r)),
          );
          return ((root - d * halfH) / a).clamp(0.0, 1.0);
        }

        return Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: constraints.maxWidth * widget.horizontalInset,
          ),
          child: NotificationListener<ScrollNotification>(
            onNotification: (_) {
              _publish();
              return false;
            },
            child: CustomScrollView(
              controller: widget.controller,
              physics: widget.snapEnabled && focused
                  ? _SnapPhysics(
                      targets: () => _snapTargets,
                      reach: widget.itemExtent,
                      parent: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                    )
                  : const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: lead)),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final e = widget.elements[i];
                    // Every row at full strength, none of them receding, and
                    // nothing to rebuild on scroll: a flat list has no row to
                    // measure a distance from.
                    if (!focused) {
                      return SizedBox(
                        height: e.extent,
                        child: e.builder(context, 0),
                      );
                    }
                    return SizedBox(
                      height: e.extent,
                      child: AnimatedBuilder(
                        animation: widget.controller,
                        builder: (context, _) {
                          final centre = widget.controller.hasClients
                              ? widget.controller.offset + h / 2
                              : h / 2;
                          final rowCentre = _tops[i] + e.extent / 2;
                          final dy = rowCentre - centre;
                          final d = (dy.abs() / falloff).clamp(0.0, 1.0);
                          // A header neither grows nor shrinks with the focus:
                          // it is chrome passing through, not a candidate for
                          // it. The glass it still answers to.
                          if (e.isHeader) {
                            return Transform.scale(
                              scale: glassScale(dy, rowWidth, e.extent),
                              child: e.builder(context, d),
                            );
                          }
                          final g = railFocusCurve(d);
                          return FractionallySizedBox(
                            widthFactor: g.widthFactor,
                            child: Transform.scale(
                              scale: math.min(
                                g.scale,
                                glassScale(
                                  dy,
                                  rowWidth * g.widthFactor,
                                  e.extent,
                                ),
                              ),
                              child: e.builder(context, d),
                            ),
                          );
                        },
                      ),
                    );
                  }, childCount: widget.elements.length),
                ),
                SliverToBoxAdapter(child: SizedBox(height: trail)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Settles on row centres only. The snap table is built from snappable
/// elements, so a header is not something the list declines to land on — it
/// was never in the table.
///
/// Which leaves the question of everything that is *not* a row. A note's prose,
/// the account page's identity and its sync line are all content a wearer has
/// to be able to stop and read, and a snap that always hauls them to the
/// nearest row makes exactly that impossible. Two rules keep such content
/// reachable without loosening the grid anywhere it matters:
///
/// - **The ends of the scrollable are always resting places.** On a list whose
///   elements are all landable these already coincide with the first and last
///   row, so this changes nothing there — but where a header sits above the
///   first row, it is the only thing that lets the wearer stay on it.
/// - **The snap only reaches [reach].** A list of landable rows never settles
///   further than half a row from one, so it always snaps; a stretch of
///   unlandable content is longer than that, and in the middle of one the list
///   is left where it came to rest.
class _SnapPhysics extends ScrollPhysics {
  /// Read live rather than captured. A `ScrollPosition` re-runs its ballistic
  /// whenever the content's dimensions change — expanding the Done section is
  /// exactly that — and it does so with the physics attached at that instant.
  /// A snapshot taken at build time is a frame behind the element list there,
  /// so the snap hauls the list back to the *old* last row and the new rows
  /// cannot be reached at all.
  final List<double> Function() targets;

  /// How far the snap pulls from, in pixels — one row.
  final double reach;

  const _SnapPhysics({
    required this.targets,
    required this.reach,
    super.parent,
  });

  @override
  _SnapPhysics applyTo(ScrollPhysics? ancestor) => _SnapPhysics(
    targets: targets,
    reach: reach,
    parent: buildParent(ancestor),
  );

  double _nearest(double value, ScrollMetrics position) {
    var best = double.nan;
    var bestDistance = double.infinity;
    void consider(double candidate) {
      final d = (candidate - value).abs();
      if (d >= bestDistance) return;
      bestDistance = d;
      best = candidate;
    }

    for (final t in targets()) {
      // A row whose centre lies past the end of the scrollable can never be
      // reached, so snapping at it would fight the clamp forever.
      consider(t.clamp(position.minScrollExtent, position.maxScrollExtent));
    }
    consider(position.minScrollExtent);
    consider(position.maxScrollExtent);
    return best;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (targets().isEmpty) {
      return super.createBallisticSimulation(position, velocity);
    }
    // Out of range at either end: let the parent haul it back first.
    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    final natural = super.createBallisticSimulation(position, velocity);
    var settle = natural == null ? position.pixels : natural.x(double.infinity);
    if (!settle.isFinite) settle = position.pixels;
    settle = settle.clamp(position.minScrollExtent, position.maxScrollExtent);

    final target = _nearest(settle, position);
    // Out of reach means the wearer came to rest inside something that is not
    // a row, and is entitled to stay there.
    if (target.isNaN || (target - settle).abs() > reach) return natural;
    if ((target - position.pixels).abs() < toleranceFor(position).distance) {
      return null;
    }
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: toleranceFor(position),
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
