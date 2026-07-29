import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/utils/text_direction.dart';

/// Attribution line for the barcode product data, with a tappable link to
/// Open Food Facts. Shown wherever a scan can pull in product info (the scan
/// view, the manual-entry dialog).
///
/// The localized string wraps the link label in `linkStart`/`linkEnd` markers;
/// we pass private-use sentinels for those and split on them, so the link
/// position survives translation without depending on the label text.
class BarcodeAttribution extends StatefulWidget {
  /// Base text color. When null, falls back to the theme's muted body color
  /// (and the link uses the primary color). Pass an explicit color on dark
  /// surfaces like the camera view.
  final Color? color;

  const BarcodeAttribution({super.key, this.color});

  @override
  State<BarcodeAttribution> createState() => _BarcodeAttributionState();
}

class _BarcodeAttributionState extends State<BarcodeAttribution> {
  static const _url = 'https://world.openfoodfacts.org/';
  // Private-use sentinels injected as the link markers, then split on. They
  // never occur in real copy and are bidi-neutral, so they don't disturb
  // direction detection.
  static const _startMarker = '\u{E000}';
  static const _endMarker = '\u{E001}';

  late final TapGestureRecognizer _tap = TapGestureRecognizer()..onTap = _open;

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    await launchUrl(Uri.parse(_url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final baseColor = widget.color ?? cs.onSurfaceVariant;
    final linkColor = widget.color ?? cs.primary;

    final raw = m.checklists.barcode.disclaimer(_startMarker, _endMarker);
    final start = raw.indexOf(_startMarker);
    final end = raw.indexOf(_endMarker);

    final baseStyle = theme.textTheme.bodySmall?.copyWith(
      color: baseColor,
      height: 1.3,
    );

    // Defensive: if the markers went missing (bad translation), render the
    // sentence as plain text so we never show control characters.
    if (start < 0 || end < 0 || end < start) {
      final plain = raw.replaceAll(_startMarker, '').replaceAll(_endMarker, '');
      return Text(
        plain,
        style: baseStyle,
        textAlign: TextAlign.center,
        textDirection: detectTextDirection(plain),
      );
    }

    final before = raw.substring(0, start);
    final linkText = raw.substring(start + _startMarker.length, end);
    final after = raw.substring(end + _endMarker.length);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: before),
          TextSpan(
            text: linkText,
            recognizer: _tap,
            style: TextStyle(
              color: linkColor,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
          TextSpan(text: after),
        ],
        style: baseStyle,
      ),
      textAlign: TextAlign.center,
      // Direction from the sentence start (the leading strong char), so RTL
      // locales lay the whole line out correctly.
      textDirection: detectTextDirection(before.isNotEmpty ? before : raw),
    );
  }
}
