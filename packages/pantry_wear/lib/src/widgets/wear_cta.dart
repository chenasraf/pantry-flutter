import 'package:flutter/material.dart';

import '../wear_shape.dart';
import 'wear_ink.dart';
import 'wear_metrics.dart';
import 'wear_surfaces.dart';

/// The one thing a page is for, held where a thumb already is.
///
/// Drawn over the list rather than above it, so the focus falloff keeps
/// measuring from the screen's centre — a column would move that line. The
/// list's own trailing pad is half a viewport, which is what lets the last row
/// scroll clear of it.
///
/// Disabled it says why rather than sitting there dead: a wearer who taps a
/// grey button and gets nothing learns nothing, and offline in a shop is the
/// case these buttons meet most.
class WearCta extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Why the button cannot act, in the quiet ink. Its presence is what
  /// disables it.
  final String? reason;

  /// What went wrong last time it did act, in the notice's ink. Drawn in the
  /// same slot, since a wearer reads one line above a button either way.
  final String? error;

  final bool busy;

  /// An act that cannot be undone wears the notice's colours, so the one
  /// button on the watch that ends something does not look like the ones that
  /// move it along.
  final bool warning;

  final VoidCallback onTap;

  const WearCta({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.reason,
    this.error,
    this.busy = false,
    this.warning = false,
  });

  /// How far the button is held off the bottom of [viewport]. On a round
  /// screen the chord runs out fast down there: at the pill's own width its
  /// lower corners are already outside the glass a tenth of the way up, so it
  /// sits higher than a rectangular screen would ask for.
  static double insetFor(double viewport) =>
      viewport * (WearShape.isRound ? 0.14 : 0.03);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final blocked = reason != null || busy;
    final note = error ?? reason;
    final tint = warning ? wearNoticeInk : scheme.primary;
    return DecoratedBox(
      decoration: const BoxDecoration(
        // Fading out upward, so the rows scrolling under the button are not
        // cut across by a hard edge on a round screen.
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [wearGround, wearGround, Color(0x000B0B0C)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          // A round screen narrows either side of the button as well as under
          // it, so the pill is held back from both.
          horizontal: WearShape.isRound ? 30 : 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            if (note != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 4),
                child: Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.1,
                    color: error != null ? wearNoticeInk : Colors.white38,
                  ),
                ),
              ),
            GestureDetector(
              onTap: blocked ? null : onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                // The same height the rail's own buttons take: one target size
                // for everything on this watch a thumb goes for.
                height: WearMetrics.railButtonExtent,
                alignment: Alignment.center,
                decoration: blocked
                    ? WearSurface.pill(context, quiet: true)
                    : WearSurface.pill(
                        context,
                        fill: tint.withValues(alpha: 0.28),
                      ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 15,
                        color: blocked ? Colors.white38 : tint,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: blocked ? Colors.white38 : tint,
                          ),
                        ),
                      ),
                    ],
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
