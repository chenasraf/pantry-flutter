import 'dart:math' as math;
import 'dart:ui';

/// How much of a restored window has to land on a display for the frame to be
/// worth keeping. A sliver is not enough: the user has to be able to grab the
/// title bar, or the window is back but unreachable.
const _minReachableWidth = 120.0;
const _minReachableHeight = 40.0;

/// Fit a remembered window frame to the displays actually attached now.
///
/// [saved], [primary] and [displays] are all visible frames in the same
/// logical-pixel coordinate space — the desktop area a window may occupy, so
/// excluding the menu bar or taskbar.
///
/// A frame that still reaches a display is returned untouched, spill included:
/// a window hanging off the edge is a position the user chose. Only when the
/// display it lived on is gone does the size survive and the position get
/// recomputed, centred on [primary].
Rect resolveWindowBounds({
  required Rect saved,
  required Rect primary,
  required List<Rect> displays,
}) {
  final reachable = displays.any((display) {
    final overlap = display.intersect(saved);
    return overlap.width >= _minReachableWidth &&
        overlap.height >= _minReachableHeight;
  });
  if (reachable) return saved;

  final size = Size(
    math.min(saved.width, primary.width),
    math.min(saved.height, primary.height),
  );
  return Rect.fromLTWH(
    primary.left + (primary.width - size.width) / 2,
    primary.top + (primary.height - size.height) / 2,
    size.width,
    size.height,
  );
}
