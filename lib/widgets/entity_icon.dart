import 'package:flutter/material.dart';

/// An [Icon] that can be struck through to read as the "none/off" state of the
/// entity it represents — e.g. the "No label" filter row shows the label glyph
/// with a diagonal line rather than a separate off-glyph. The slash is drawn in
/// the icon's own colour, corner to corner (top-start to bottom-end).
class EntityIcon extends StatelessWidget {
  final IconData icon;
  final bool off;
  final double? size;
  final Color? color;

  const EntityIcon(
    this.icon, {
    super.key,
    this.off = false,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, size: size, color: color);
    if (!off) return glyph;

    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 24.0;
    final resolvedColor =
        color ?? iconTheme.color ?? Theme.of(context).colorScheme.onSurface;

    return SizedBox.square(
      dimension: resolvedSize,
      child: CustomPaint(
        foregroundPainter: _StrikePainter(resolvedColor),
        child: glyph,
      ),
    );
  }
}

class _StrikePainter extends CustomPainter {
  final Color color;

  const _StrikePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.width * 0.12;
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(inset, inset),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter oldDelegate) => oldDelegate.color != color;
}
