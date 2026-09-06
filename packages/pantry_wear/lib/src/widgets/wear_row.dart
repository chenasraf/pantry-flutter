import 'package:flutter/material.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../wear_shape.dart';
import 'wear_metrics.dart';

/// The card every menu and pick-one row on the watch is drawn as.
///
/// One geometry, because the wearer aims at all of them the same way: the
/// account page's rows, the settings page they open, and the household and
/// interval pickers behind that are one target at three depths.
class WearRow extends StatelessWidget {
  final IconData? icon;
  final Color tint;
  final String label;

  /// What this row currently answers, drawn at the end. A menu row that opens
  /// a picker says what it would be opening away from, so the wearer can read
  /// the setting without descending into it.
  final String? value;

  /// Drawn as a check in place of [value], for a row that is one of a set
  /// being chosen from.
  final bool selected;

  /// 0 on the centre line, 1 at the edge of the falloff. A page with no
  /// falloff leaves it at 0 and every row draws at full strength.
  final double distance;

  /// Destructive rows wear the notice's ink rather than the app's, so the one
  /// row on the page that cannot be undone does not look like its neighbours.
  final bool warning;

  final VoidCallback? onTap;

  const WearRow({
    super.key,
    required this.label,
    this.icon,
    this.tint = Colors.white70,
    this.value,
    this.selected = false,
    this.distance = 0,
    this.warning = false,
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
    final ink = warning ? _warningInk : Colors.white;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.lerp(
            warning ? _warningGround : scheme.surfaceContainerHighest,
            const Color(0xFF121215),
            d,
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: WearShape.isRound ? 15 : 11,
            vertical: 4,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: warning ? _warningInk : tint),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: detectTextDirection(label),
                  style: TextStyle(
                    fontSize: 14,
                    // Pinned rather than left to the font's own metrics: the
                    // card has to fit inside a fixed row extent, and an
                    // unpinned line height is the difference between fitting
                    // and the striped overflow banner.
                    height: 1.1,
                    // Weight is the one thing the scale cannot carry: a scaled
                    // regular is still a regular.
                    fontWeight: d < 0.5 ? FontWeight.w600 : FontWeight.w400,
                    color: ink,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check, size: 14, color: scheme.primary)
              else if (value != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: detectTextDirection(value!),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.1,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
