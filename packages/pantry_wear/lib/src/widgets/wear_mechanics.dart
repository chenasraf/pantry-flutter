import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pantry_core/services/locale_service.dart';

import '../services/rotary_service.dart';

/// The machinery every page and pushed route shares.
///
/// Layout is deliberately *not* here: a page owns its own frame. What lives
/// here is mechanism the platform forces on us and that every surface must
/// behave identically under — gesture ownership, the hand-rolled exit,
/// rotary, and the geometry of a focused row.

/// Google's rule for a pager on a watch: a drag that starts within this much
/// of the screen width from the leading edge belongs to the system dismiss,
/// not to the pager — and only on the first page, because every deeper page
/// pages back before it could be dismissed.
const kEdgeExclusionFraction = 0.15;

/// How much of the stock drag threshold the pager needs before it claims a
/// horizontal drag, as a fraction.
///
/// Every page is a scrolling list, so the pager and that list race: whichever
/// recognizer passes its own slop first takes the gesture. Above 1 the list
/// wins ties, which stops a vertical scroll flipping pages — and costs a
/// deliberate sideways swipe, which on a wrist is short, arced and thumb-shaped
/// and so carries vertical movement of its own. Below 1 the pager claims
/// sooner. Judged on the watch: the list's own slop is enough to protect a
/// scroll, and a page that will not turn is the worse failure.
const kPagerSlopFactor = 0.75;

/// Google's hard limit on page dots.
const kMaxDots = 6;

/// The direction the **device** reads in, for the navigation the wearer learnt
/// outside this app.
///
/// Which way you swipe to go back, and which way pages advance, are spatial
/// habits built by the watch and every other app on it — so an app running in
/// Hebrew on an English watch keeps them rather than mirroring them. What is
/// *inside* a page is content and follows the app's own `Directionality`; only
/// the frame around it answers to this.
TextDirection get systemTextDirection =>
    LocaleService.instance.systemIsRtl ? TextDirection.rtl : TextDirection.ltr;

/// A route over the pager, drawn in whatever language is current.
///
/// The page rides inside a subtree keyed on the locale, and that key is the
/// whole point. A rebuild reaches a child only when the child *widget* differs
/// from the one already mounted, and a route builder hands back the instance it
/// closed over — identical every time, and identical again for a `const` page.
/// So a language landing from the phone repaints the frame and leaves every
/// pushed route beneath it in the language it was pushed in.
///
/// Keying is what forces that open, and it is the narrowest thing that does:
/// the route itself is untouched, so the wearer keeps their place in a stack
/// each level of which costs a deliberate edge-strip drag to climb back. The
/// page's own state is discarded, which is the price, and a language change is
/// rare and deliberate enough to pay it. The accent needs none of this — a
/// theme is inherited, so a colour reaches through a `const` widget on its own.
Route<T> wearRoute<T>(Widget page) => MaterialPageRoute<T>(
  builder: (_) => KeyedSubtree(
    key: ValueKey(LocaleService.instance.effectiveLocale.languageCode),
    child: page,
  ),
);

/// Page physics tuned by [kPagerSlopFactor], so the pager and the list under
/// it race on terms chosen for a wrist rather than a phone.
class PagerScrollPhysics extends PageScrollPhysics {
  const PagerScrollPhysics({super.parent});

  @override
  PagerScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      PagerScrollPhysics(parent: buildParent(ancestor));

  @override
  double? get dragStartDistanceMotionThreshold {
    final base = super.dragStartDistanceMotionThreshold ?? 3.5;
    return base * kPagerSlopFactor;
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
    final appDirection = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          children: [
            // Pages advance the way the device reads, so that forward and back
            // are one spatial rule with the edge strip rather than two facing
            // each other. Each page is handed the app's own direction straight
            // back: which way you page is navigation, what a page says is
            // content, and only the first of those belongs to the watch.
            Directionality(
              textDirection: systemTextDirection,
              child: PageView(
                controller: controller,
                physics: const PagerScrollPhysics(),
                onPageChanged: onPageChanged,
                children: [
                  for (final child in children)
                    Directionality(textDirection: appDirection, child: child),
                ],
              ),
            ),
            if (page == 0)
              systemEdgeStrip(
                width: width,
                onDismiss: () => SystemNavigator.pop(),
              ),
          ],
        );
      },
    );
  }
}

/// The dismiss strip, on the edge the **device** starts its reading from.
///
/// Every other gesture in the watch tree follows the app's `Directionality`,
/// and this one deliberately does not. Going back is muscle memory built by the
/// system and every other app on the watch, so it belongs to the device's
/// language rather than to the one the wearer chose in here: someone reading
/// Pantry in Hebrew on an English watch still swipes in from the left, the way
/// they do everywhere else on it.
///
/// Positioned against the physical edge rather than with `PositionedDirectional`
/// for the same reason — `start` resolves against the app's direction, which is
/// exactly the thing that must not move it.
Widget systemEdgeStrip({
  required double width,
  required VoidCallback onDismiss,
}) {
  final rtl = LocaleService.instance.systemIsRtl;
  final strip = _DismissStrip(
    width: width,
    towardsEnd: rtl ? -1 : 1,
    onDismiss: onDismiss,
  );
  return Positioned(
    left: rtl ? null : 0,
    right: rtl ? 0 : null,
    top: 0,
    bottom: 0,
    width: width * kEdgeExclusionFraction,
    child: strip,
  );
}

/// The leading-edge back gesture, for a route pushed *over* the pager.
///
/// Route (a) turns off `windowSwipeToDismiss` for the whole app, so a pushed
/// route inherits no way back at all — it has to rebuild one. This is the same
/// strip the pager spends on leaving the app, spent here on leaving the route,
/// so the wearer learns one gesture rather than two.
class EdgeDismissible extends StatelessWidget {
  final VoidCallback onDismiss;
  final Widget child;

  const EdgeDismissible({
    super.key,
    required this.onDismiss,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          children: [
            Positioned.fill(child: child),
            systemEdgeStrip(width: width, onDismiss: onDismiss),
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
    final target = (from - detent * widget.pixelsPerDetent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _target = target;
    controller
        .animateTo(
          target,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
        )
        // Only when nothing newer has been aimed at — a cancelled animation's
        // future completes too, so clearing unconditionally discarded the
        // detent that interrupted this one and stalled a fast turn.
        .whenComplete(() {
          if (_target == target) _target = null;
        });
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

/// The window of dots to draw, since the indicator caps at [kMaxDots] and the
/// pages may one day outnumber it.
({int count, int selected}) dotWindow(int pages, int page) {
  if (pages <= kMaxDots) return (count: pages, selected: page);
  final start = (page - kMaxDots ~/ 2).clamp(0, pages - kMaxDots);
  return (count: kMaxDots, selected: page - start);
}
