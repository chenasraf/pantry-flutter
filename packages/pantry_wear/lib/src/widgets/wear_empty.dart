import 'package:flutter/material.dart';
import 'package:pantry_core/utils/text_direction.dart';

import 'wear_metrics.dart';

/// What a page says where its content would have been.
///
/// Held to the band rather than the full width: prose following the bezel is
/// shaved on every line but the widest.
class WearEmpty extends StatelessWidget {
  final String message;

  /// The ink a note's own hue asks for. Pages on the ground plane take the
  /// default.
  final Color? color;

  final double fontSize;

  const WearEmpty({
    super.key,
    required this.message,
    this.color,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: WearMetrics.bandInsets(context),
      child: Text(
        message,
        textAlign: TextAlign.center,
        textDirection: detectTextDirection(message),
        style: TextStyle(
          fontSize: fontSize,
          height: 1.3,
          color: color ?? Colors.white38,
        ),
      ),
    ),
  );
}
