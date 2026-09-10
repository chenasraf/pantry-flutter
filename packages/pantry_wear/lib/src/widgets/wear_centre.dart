import 'package:flutter/material.dart';

import 'wear_mechanics.dart';
import 'wear_metrics.dart';
import 'wear_scroll_indicator.dart';

/// A page held in the middle of the glass, and scrolled instead the moment it
/// stops fitting between the edges.
///
/// Every page built this way is a short stack of prose over a button, and the
/// centred version is the one the design is for: on a round screen the middle
/// is where the chord is longest and the wearer's eye already is. What it
/// cannot be is the *only* version. The wearer's own font size decides how tall
/// the prose is, and a column pinned to the centre answers a size it cannot fit
/// by pushing its button off the bottom of the screen — the one control the
/// page exists to offer, gone precisely for the wearer who asked to be able to
/// read it.
///
/// So the height is a floor rather than a fixture: content that fits is centred
/// exactly as before, and content that does not gets the crown and a finger to
/// reach the rest of itself with.
class WearCentre extends StatefulWidget {
  final Widget child;

  /// What the page is held back by, defaulting to the band a round screen can
  /// hold a line in whatever height it comes to rest at. Pass one only where
  /// the page has something else to clear — a button standing over its own
  /// content, say.
  final EdgeInsetsGeometry? padding;

  const WearCentre({super.key, required this.child, this.padding});

  @override
  State<WearCentre> createState() => _WearCentreState();
}

class _WearCentreState extends State<WearCentre> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => WearScrollIndicator(
      child: RotaryScrollable(
        controller: _scroll,
        active: true,
        child: SingleChildScrollView(
          controller: _scroll,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: widget.padding ?? WearMetrics.bandInsets(context),
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    ),
  );
}
