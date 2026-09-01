import 'package:flutter/material.dart';

/// A rounded-rectangle dashed outline around [child]. When [background] or
/// [padding] is given, the child is wrapped in a filled, rounded container so
/// the dashed edge frames a card.
class DashedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;
  final Color? background;
  final EdgeInsetsGeometry? padding;

  const DashedBorder({
    super.key,
    required this.child,
    required this.color,
    this.radius = 14,
    this.strokeWidth = 1.5,
    this.background,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (background != null || padding != null) {
      content = Container(
        decoration: background != null
            ? BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(radius),
              )
            : null,
        padding: padding,
        child: child,
      );
    }
    return CustomPaint(
      painter: DashedBorderPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
      ),
      child: content,
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;

  DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}
