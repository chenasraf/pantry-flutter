import 'package:flutter/material.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import 'wear_metrics.dart';
import 'wear_surfaces.dart';

/// The card every menu and pick-one row on the watch is drawn as.
///
/// One geometry, because the wearer aims at all of them the same way: the
/// account page's rows, the settings page they open, and the household and
/// interval pickers behind that are one target at three depths.
class WearRow extends StatelessWidget {
  final IconData? icon;
  final Color tint;
  final String label;

  /// What this row currently answers, drawn under the label. A menu row that
  /// opens a picker says what it would be opening away from, so the wearer can
  /// read the setting without descending into it.
  ///
  /// It sits under the label rather than beside it because the two were
  /// competing for one line: on a small screen a long setting name and its
  /// value both elided, leaving a row that named neither. Stacked, each gets
  /// the whole width, and the card's fixed extent has room for the second line.
  final String? value;

  /// Drawn as a check in place of [value], for a row that is one of a set
  /// being chosen from.
  final bool selected;

  /// Draws an empty box on an unselected row rather than nothing. A row in a
  /// set being checked on and off has to say that it is *off*, where a row in
  /// a pick-one list only has to say which one is on.
  final bool checkbox;

  /// A row that answers in place instead of opening a page. The switch shows
  /// the value and the outcome of a tap at once, which is what earns it the
  /// exception — a cycling control on a wrist does not.
  final bool? toggled;

  /// 0 on the centre line, 1 at the edge of the falloff. A page with no
  /// falloff leaves it at 0 and every row draws at full strength.
  final double distance;

  /// Destructive rows wear the notice's ink rather than the app's, so the one
  /// row on the page that cannot be undone does not look like its neighbours.
  final bool warning;

  /// A row whose moment has passed — a store leg already walked. It keeps its
  /// place in the sequence and its full target size, because tapping it is
  /// still how you go back to it; only the ink recedes.
  final bool spent;

  final VoidCallback? onTap;

  const WearRow({
    super.key,
    required this.label,
    this.icon,
    this.tint = Colors.white70,
    this.value,
    this.selected = false,
    this.checkbox = false,
    this.toggled,
    this.distance = 0,
    this.warning = false,
    this.spent = false,
    this.onTap,
  });

  static const _warningInk = Color(0xFFE0A0A0);
  static const _warningGround = Color(0xFF2A1D1D);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = distance;

    // A round screen wants a round row: at a card's corners the glass is
    // already curving away, so a pill follows the bezel instead of fighting
    // it.
    final radius = WearShape.isRound ? WearMetrics.cardHeight / 2 : 14.0;
    final ink = warning
        ? _warningInk
        : spent
        ? Colors.white54
        : Colors.white;

    // A row answering with a check or a switch has already said what it is.
    // The value line belongs to the rows that answer by opening a page.
    final subtitle = toggled == null && !checkbox && !selected ? value : null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: WearSurface.card(
          context,
          fill: Color.lerp(
            warning ? _warningGround : scheme.surfaceContainerHighest,
            const Color(0xFF121215),
            d,
          ),
          radius: radius,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: WearShape.isRound ? 15 : 11,
            vertical: 4,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: warning
                      ? _warningInk
                      : tint.withValues(alpha: spent ? 0.45 : 1),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: detectTextDirection(label),
                      style: TextStyle(
                        fontSize: 14,
                        // Pinned rather than left to the font's own metrics:
                        // the card has to fit inside a fixed row extent, and an
                        // unpinned line height is the difference between
                        // fitting and the striped overflow banner.
                        height: 1.1,
                        // Weight is the one thing the scale cannot carry: a
                        // scaled regular is still a regular.
                        fontWeight: d < 0.5 ? FontWeight.w600 : FontWeight.w400,
                        color: ink,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: 2),
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: detectTextDirection(subtitle),
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.1,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (toggled != null)
                _Toggle(on: toggled!, tint: scheme.primary)
              else if (checkbox)
                Icon(
                  selected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 15,
                  color: selected ? scheme.primary : Colors.white38,
                )
              else if (selected)
                Icon(Icons.check, size: 14, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// The switch a row answers with.
///
/// Drawn rather than taken from Material: a `Switch` brings a tap target of its
/// own, and two targets on one row is exactly the ambiguity a wrist cannot
/// afford — the whole row is the control, and this only reports it.
class _Toggle extends StatelessWidget {
  final bool on;
  final Color tint;

  const _Toggle({required this.on, required this.tint});

  static const _width = 26.0;
  static const _height = 15.0;
  static const _knob = 11.0;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    curve: Curves.easeOutCubic,
    width: _width,
    height: _height,
    decoration: WearSurface.track(context, on: on, tint: tint, height: _height),
    child: AnimatedAlign(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      alignment: on
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 2),
        child: Container(
          width: _knob,
          height: _knob,
          decoration: WearSurface.indicator(on ? tint : Colors.white54),
        ),
      ),
    ),
  );
}
