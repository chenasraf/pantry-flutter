import 'package:flutter/material.dart';

import '../wear_ambient_skin.dart';
import 'wear_ink.dart';
import 'wear_metrics.dart';

/// The shapes the watch draws, named once.
///
/// `wear_ink.dart` holds what the watch is coloured with and `wear_metrics.dart`
/// what it is measured by; this is the third of the same kind — the shapes those
/// two combine into. A call site names the role it wants and passes nothing
/// else, so the surface can change everywhere from here.
///
/// **Pass an argument only where the thing genuinely differs from the usual
/// design.** A tint that carries meaning is a difference; the radius a card
/// happens to have is not, and a site that restates it has quietly forked the
/// design.
///
/// Every filled role answers the dimmed screen by giving up its fill for its own
/// outline. That is why the fill has to be asked for rather than written down at
/// the call site: a shape that describes itself in place cannot be told the
/// screen has changed underneath it.
abstract final class WearSurface {
  /// A row in a list — a checklist item, a note, a settings line.
  ///
  /// Round glass wants the ends round: a rectangle's corners are the first
  /// thing a bezel shaves.
  static BoxDecoration card(
    BuildContext context, {
    Color? fill,
    double? radius,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return wearAmbientFill(
      context,
      color: fill ?? scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(
        radius ?? WearMetrics.of(context).cardRadius,
      ),
    );
  }

  /// Something to press: the page's one action, a rail button, the setup
  /// button.
  ///
  /// [warning] is the livery of an act that cannot be undone, so the one button
  /// that ends something does not look like the ones that move it along.
  /// [quiet] is the same shape with no claim on the accent, for the second
  /// button beside a first.
  static BoxDecoration pill(
    BuildContext context, {
    bool warning = false,
    bool quiet = false,
    Color? fill,
    double? radius,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final ground = warning
        ? wearNoticeGround
        : quiet
        ? Colors.white.withValues(alpha: 0.10)
        : scheme.primary.withValues(alpha: 0.26);
    return wearAmbientFill(
      context,
      color: fill ?? ground,
      borderRadius: BorderRadius.circular(
        radius ?? WearMetrics.of(context).railButtonRadius,
      ),
    );
  }

  /// The corner a panel turns, for the odd surface that has to clip its own
  /// content to the same shape rather than draw the decoration.
  static const double panelRadius = 16;

  /// A panel that holds other things — a detail block, a sheet, a caption over
  /// a photo. Squarer than a card, because it is a region rather than a target.
  static BoxDecoration panel(
    BuildContext context, {
    Color? fill,
    double? radius,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return wearAmbientFill(
      context,
      color: fill ?? scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(radius ?? panelRadius),
    );
  }

  /// The transient line the shell drops over whatever is showing.
  static BoxDecoration notice(BuildContext context) => wearAmbientFill(
    context,
    color: wearNoticeGround,
    borderRadius: BorderRadius.circular(12),
  );

  /// Where an image will be once it has loaded, and where it stays if it never
  /// does.
  static BoxDecoration placeholder(
    BuildContext context, {
    double? radius,
    double alpha = 0.07,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return wearAmbientFill(
      context,
      color: scheme.onSurface.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(radius ?? 8),
    );
  }

  /// The bed a switch's knob travels along.
  static BoxDecoration track(
    BuildContext context, {
    required bool on,
    required Color tint,
    required double height,
  }) => wearAmbientFill(
    context,
    color: on ? tint.withValues(alpha: 0.45) : Colors.white24,
    borderRadius: BorderRadius.circular(height / 2),
  );

  /// A dot: a page marker, the sync state, a switch's knob, a bullet.
  ///
  /// **Filled in ambient too, unlike every other role here.** These are a few
  /// pixels across, and an outline at that size reads as a smudge rather than a
  /// shape — the one place where dropping the fill would cost the wearer the
  /// thing itself rather than its decoration.
  static BoxDecoration indicator(Color color, {double? radius}) =>
      BoxDecoration(
        color: color,
        shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: radius == null ? null : BorderRadius.circular(radius),
      );
}
