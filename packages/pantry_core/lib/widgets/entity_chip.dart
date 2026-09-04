import 'package:flutter/material.dart';

/// Vertical and typographic scale of a chip. Each level carries its concrete
/// metrics so callers stay declarative instead of branching on a form factor,
/// mirroring how `ChecklistDensity` carries the row metrics.
enum ChipDensity {
  /// Phone and tablet.
  comfortable(
    radius: 7,
    padH: 9,
    padHIconOnly: 6,
    padV: 3,
    fontSize: 12,
    gap: 6,
    tintAlpha: 0.13,
  ),

  /// A watch row, where a chip shares one line with an item name. The tint is
  /// stronger because it sits on an OLED black rather than a light surface.
  dense(
    radius: 6,
    padH: 5,
    padHIconOnly: 4,
    padV: 2,
    fontSize: 9,
    gap: 4,
    tintAlpha: 0.16,
  );

  const ChipDensity({
    required this.radius,
    required this.padH,
    required this.padHIconOnly,
    required this.padV,
    required this.fontSize,
    required this.gap,
    required this.tintAlpha,
  });

  final double radius;
  final double padH;
  final double padHIconOnly;
  final double padV;
  final double fontSize;
  final double gap;

  /// Opacity of a background derived from the entity's own colour.
  final double tintAlpha;
}

/// A labelled swatch for one entity — a category, store, label, list — drawn
/// in that entity's colour.
///
/// Shared because the phone and the watch have to agree about what a category
/// looks like: two implementations of this drift, and a category that reads
/// differently on the wrist than in your hand is a category you have to
/// recognise twice.
class EntityChip extends StatelessWidget {
  final Widget? leading;

  /// When null the chip renders as an icon-only badge, so the leading glyph
  /// carries the whole meaning.
  final String? label;

  final Color textColor;

  /// Defaults to [textColor] at the density's tint alpha. Pass one explicitly
  /// for a chip whose fill is not derived from its text, such as a neutral
  /// count.
  final Color? background;

  /// When set the chip becomes tappable. Inert otherwise.
  final VoidCallback? onTap;

  final ChipDensity density;

  const EntityChip({
    super.key,
    this.leading,
    this.label,
    required this.textColor,
    this.background,
    this.onTap,
    this.density = ChipDensity.comfortable,
  });

  @override
  Widget build(BuildContext context) {
    final hasLabel = label != null;
    final radius = BorderRadius.circular(density.radius);
    final fill = background ?? textColor.withValues(alpha: density.tintAlpha);

    final content = Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: hasLabel ? density.padH : density.padHIconOnly,
        vertical: density.padV,
      ),
      decoration: BoxDecoration(color: fill, borderRadius: radius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            if (hasLabel) SizedBox(width: density.gap),
          ],
          if (hasLabel)
            Text(
              label!,
              style: TextStyle(
                color: textColor,
                fontSize: density.fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
  }
}
