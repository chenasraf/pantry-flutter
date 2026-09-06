import 'package:flutter/widgets.dart';
import 'package:pantry_core/services/prefs_service.dart';

/// How long a tap stays reversible on this watch.
///
/// Read at the moment a window opens rather than held anywhere, so a value the
/// wearer has just changed is in force on the very next tap.
Duration get undoWindow =>
    Duration(seconds: PrefsService.instance.wearUndoSeconds);

/// The undo windows one surface is holding, keyed by whatever names a row.
///
/// Every reversible tap on the watch runs through this — a check, an uncheck,
/// a note's task line — so the window means one thing wherever the wearer taps
/// and a surface that grows a reversible tap inherits the rhythm rather than
/// restating it.
///
/// What the window delays is the *write*, never the feedback: the row draws
/// [targetOf] from the moment the tap lands, with the stroke on
/// [controllerOf] draining beside it, and a second tap inside the window takes
/// it back without anything having been written.
class UndoWindows<K> {
  final TickerProvider vsync;

  /// Called whenever a window opens, closes or is taken back, so the surface
  /// redraws the rows those windows are holding.
  final VoidCallback onChanged;

  final _open = <K, _Window>{};

  UndoWindows({required this.vsync, required this.onChanged});

  /// The clock behind a row's stroke, counting down from 1 to 0.
  ///
  /// A row with no key of its own — a note's prose between its task lines —
  /// asks with null and is told the same thing as a row with no window open.
  AnimationController? controllerOf(K? key) => _open[key]?.controller;

  /// What the row is on its way to, or null if it is not on its way anywhere.
  bool? targetOf(K? key) => _open[key]?.target;

  /// Hold [key] at [target] for the length of the window, then [commit] it.
  ///
  /// A second call while [key]'s window is open takes it back instead of
  /// queueing the opposite write, which is what makes the first tap reversible
  /// rather than merely slow.
  ///
  /// With the window off, [commit] runs where it would have been queued. Off
  /// is the behaviour that predates the window rather than a zero-length one:
  /// a controller given no duration resolves inside its own constructor, ahead
  /// of the listener that would have carried the write.
  void fire(
    K key, {
    required bool target,
    required void Function(bool target) commit,
  }) {
    final open = _open.remove(key);
    if (open != null) {
      open.controller
        ..stop()
        ..dispose();
      onChanged();
      return;
    }
    final duration = undoWindow;
    if (duration == Duration.zero) {
      commit(target);
      onChanged();
      return;
    }
    final controller = AnimationController(vsync: vsync, duration: duration);
    controller.addStatusListener((status) {
      if (status != AnimationStatus.dismissed) return;
      if (_open.remove(key) == null) return;
      controller.dispose();
      commit(target);
      onChanged();
    });
    _open[key] = _Window(
      controller: controller,
      target: target,
      commit: commit,
    );
    controller.reverse(from: 1);
    onChanged();
  }

  /// Close every open window at once, committing what they were holding or
  /// dropping it.
  ///
  /// The pager calls this before it swaps page sets, so nothing is left
  /// half-committed against pages that no longer exist. With the window off
  /// there is never anything open, so the swap is safe at every value for the
  /// same reason rather than by a second rule.
  void resolveAll({required bool commit}) {
    for (final window in _open.values.toList()) {
      window.controller
        ..stop()
        ..dispose();
      if (commit) window.commit(window.target);
    }
    _open.clear();
    onChanged();
  }

  /// Drop every open window without writing it. A surface going away takes its
  /// undelivered taps with it, exactly as a wearer who taps twice does.
  void dispose() {
    for (final window in _open.values) {
      window.controller
        ..stop()
        ..dispose();
    }
    _open.clear();
  }
}

/// A card with its undo window drawn as a stroke draining off its own border,
/// so the thing running out is the thing you would be undoing.
///
/// Every surface that holds a tap draws it this way — the card already has an
/// edge, and a wearer who learns the stroke on one page has learnt it on all
/// of them.
class UndoStroke extends StatelessWidget {
  /// The window this card is holding, or null when it is holding none.
  final AnimationController? window;
  final Color color;
  final double radius;
  final double strokeWidth;
  final Widget child;

  const UndoStroke({
    super.key,
    required this.window,
    required this.color,
    required this.radius,
    required this.child,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final clock = window;
    if (clock == null) return child;
    return AnimatedBuilder(
      animation: clock,
      builder: (context, child) => CustomPaint(
        foregroundPainter: _UndoStrokePainter(
          remaining: clock.value,
          color: color,
          radius: radius,
          strokeWidth: strokeWidth,
        ),
        child: child,
      ),
      child: child,
    );
  }
}

class _UndoStrokePainter extends CustomPainter {
  final double remaining;
  final Color color;
  final double radius;
  final double strokeWidth;

  const _UndoStrokePainter({
    required this.remaining,
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (remaining <= 0) return;
    // Half the stroke rides either side of the path, so the path is held in by
    // that much to keep the whole width inside the card's own edge.
    final inset = strokeWidth / 2;
    // An oversized RRect radius is not scaled down by `addRRect` the way a
    // `BorderRadius` scales it — a pill radius quoted against the row extent
    // against a card shorter than it draws a malformed path rather than a
    // smaller one.
    final r = radius.clamp(0.0, size.shortestSide / 2);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(r),
        ),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * remaining.clamp(0.0, 1.0)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_UndoStrokePainter old) =>
      old.remaining != remaining ||
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}

class _Window {
  final AnimationController controller;
  final bool target;
  final void Function(bool target) commit;

  const _Window({
    required this.controller,
    required this.target,
    required this.commit,
  });
}
