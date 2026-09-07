import 'package:flutter/material.dart';

/// Parse a `#RRGGBB` / `RRGGBB` (or `#AARRGGBB`) hex string into a [Color],
/// or null when the string is empty or malformed. Mirrors the inline parser
/// used by the checklist item tile.
Color? parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  final value = int.tryParse(h, radix: 16);
  return value != null ? Color(value) : null;
}
