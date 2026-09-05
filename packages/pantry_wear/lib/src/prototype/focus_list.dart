import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../services/rotary_service.dart';
import 'proto_mechanics.dart';

/// PROTOTYPE — the centred-focus list, rebuilt over slivers.
///
/// Card 714 judged the shell on a [ListWheelScrollView], which was buying two
/// things: a uniform `itemExtent` and [FixedExtentScrollPhysics]' snapping.
/// Group headers need neither — they have to be shorter than a row and must
/// never take the focus — and a wheel can express neither, so the list is a
/// [CustomScrollView] whose snapping is hand-rolled over row offsets only.
///
/// The falloff is unchanged: it was never the wheel's. [railFocusCurve] reads
/// a row's distance from the **screen's** centre, which is why the viewport
/// stays full-height with the rail overlaying it rather than sitting in a
/// column below it.

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

  /// The group the focused card is in, in that group's own livery.
  final String? stickyGroup;
  final IconData? stickyIcon;
  final Color? stickyColor;

  const FocusGeometry({
    this.centredIndex = -1,
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

  const SnapFocusList({
    super.key,
    required this.controller,
    required this.elements,
    required this.itemExtent,
    this.falloffRows = 2.2,
    this.snapEnabled = true,
    this.rotaryActive = false,
    this.horizontalInset = 0.04,
    this.geometry,
  });

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

  void _measure(double viewportHeight) {
    final lead = math.max(0.0, viewportHeight / 2 - widget.itemExtent / 2);
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
    if (_snapTargets.isEmpty || !widget.controller.hasClients) return;
    final position = widget.controller.position;
    final from = _stepTarget ?? position.pixels;

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
    final next = (nearest + delta).clamp(0, _snapTargets.length - 1);
    final target = _snapTargets[next].clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target == from) return;
    _stepTarget = target;
    widget.controller
        .animateTo(
          target,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() => _stepTarget = null);
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
      stickyGroup: focused?.groupLabel,
      stickyIcon: focused?.groupIcon,
      stickyColor: focused?.groupColor,
    );
    final current = notifier.value;
    if (current.centredIndex == next.centredIndex &&
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

        final falloff = widget.falloffRows * widget.itemExtent;
        final lead = math.max(0.0, h / 2 - widget.itemExtent / 2);

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
              physics: widget.snapEnabled
                  ? _SnapPhysics(
                      targets: () => _snapTargets,
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
                    return SizedBox(
                      height: e.extent,
                      child: AnimatedBuilder(
                        animation: widget.controller,
                        builder: (context, _) {
                          final centre = widget.controller.hasClients
                              ? widget.controller.offset + h / 2
                              : h / 2;
                          final rowCentre = _tops[i] + e.extent / 2;
                          final d = ((rowCentre - centre).abs() / falloff)
                              .clamp(0.0, 1.0);
                          // A header neither grows nor shrinks: it is chrome
                          // passing through, not a candidate for the focus.
                          if (e.isHeader) return e.builder(context, d);
                          final g = railFocusCurve(d);
                          return FractionallySizedBox(
                            widthFactor: g.widthFactor,
                            child: Transform.scale(
                              scale: g.scale,
                              child: e.builder(context, d),
                            ),
                          );
                        },
                      ),
                    );
                  }, childCount: widget.elements.length),
                ),
                SliverToBoxAdapter(child: SizedBox(height: lead)),
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
class _SnapPhysics extends ScrollPhysics {
  /// Read live rather than captured. A `ScrollPosition` re-runs its ballistic
  /// whenever the content's dimensions change — expanding the Done section is
  /// exactly that — and it does so with the physics attached at that instant.
  /// A snapshot taken at build time is a frame behind the element list there,
  /// so the snap hauls the list back to the *old* last row and the new rows
  /// cannot be reached at all.
  final List<double> Function() targets;

  const _SnapPhysics({required this.targets, super.parent});

  @override
  _SnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapPhysics(targets: targets, parent: buildParent(ancestor));

  double _nearest(double value, ScrollMetrics position) {
    var best = double.nan;
    var bestDistance = double.infinity;
    for (final t in targets()) {
      // A row whose centre lies past the end of the scrollable can never be
      // reached, so snapping at it would fight the clamp forever.
      final reachable = t.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      final d = (reachable - value).abs();
      if (d < bestDistance) {
        bestDistance = d;
        best = reachable;
      }
    }
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
    if (target.isNaN ||
        (target - position.pixels).abs() < toleranceFor(position).distance) {
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
