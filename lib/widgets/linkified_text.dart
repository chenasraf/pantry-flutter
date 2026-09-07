import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pantry_core/utils/link_detection.dart';
import 'package:pantry_core/utils/text_direction.dart';

/// Renders [text] as plain text with any web or email addresses in it turned
/// into tappable links.
class LinkifiedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  const LinkifiedText(
    this.text, {
    super.key,
    this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow,
  });

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  var _segments = const <LinkSegment>[];
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void didUpdateWidget(LinkifiedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _parse();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _parse() {
    _disposeRecognizers();
    _segments = detectLinks(widget.text);
    for (final segment in _segments) {
      final url = segment.url;
      if (url == null) continue;
      _recognizers.add(TapGestureRecognizer()..onTap = () => _launch(url));
    }
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle =
        widget.linkStyle ??
        TextStyle(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
          decorationColor: Theme.of(context).colorScheme.primary,
        );

    var recognizer = 0;
    return Text.rich(
      TextSpan(
        children: [
          for (final segment in _segments)
            TextSpan(
              text: segment.text,
              style: segment.isLink ? linkStyle : null,
              recognizer: segment.isLink ? _recognizers[recognizer++] : null,
            ),
        ],
      ),
      style: widget.style,
      textDirection: detectTextDirection(widget.text),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
