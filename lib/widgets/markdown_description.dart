import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pantry_core/utils/text_direction.dart';

/// Matches a GitHub-style task-list checkbox at the start of a list item
/// (`- [ ]`, `* [x]`, `1. [ ]`, …). Group 1 is the bullet marker plus spacing,
/// group 2 the check state — used to toggle the Nth checkbox in place.
final _taskCheckboxRegex = RegExp(
  r'^([ \t]*(?:[-*+]|\d+[.)])[ \t]+)\[([ xX])\]',
  multiLine: true,
);

/// Return [source] with the [index]-th task-list checkbox flipped. Checkboxes
/// are counted in document order, which matches the order the markdown renderer
/// builds them — so the tapped checkbox and the toggled token line up.
String toggleTaskCheckbox(String source, int index) {
  var i = 0;
  return source.replaceAllMapped(_taskCheckboxRegex, (match) {
    if (i++ != index) return match[0]!;
    final checked = match[2]!.toLowerCase() == 'x';
    return '${match[1]}[${checked ? ' ' : 'x'}]';
  });
}

/// Renders [description] as markdown with direction detection and tappable
/// links. When [onChanged] is non-null, task-list checkboxes become
/// interactive; flipping one emits the full updated source so the caller can
/// persist it. With [onChanged] null the checkboxes render but stay inert.
class MarkdownDescription extends StatelessWidget {
  final String description;
  final ValueChanged<String>? onChanged;
  final MarkdownStyleSheet? styleSheet;

  const MarkdownDescription({
    super.key,
    required this.description,
    this.onChanged,
    this.styleSheet,
  });

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return Directionality(
      textDirection: detectTextDirection(description),
      child: Builder(
        builder: (context) {
          // Reset per build: the renderer invokes the checkbox builder once per
          // checkbox in document order, so this counter hands each one its
          // source-order index.
          var checkboxIndex = 0;
          return MarkdownBody(
            data: description,
            shrinkWrap: true,
            softLineBreak: true,
            onTapLink: (text, href, title) {
              if (href != null) launchUrl(Uri.parse(href));
            },
            checkboxBuilder: (checked) {
              final index = checkboxIndex++;
              return _MarkdownCheckbox(
                checked: checked,
                onTap: onChanged == null
                    ? null
                    : () => onChanged(toggleTaskCheckbox(description, index)),
              );
            },
            styleSheet: styleSheet,
          );
        },
      ),
    );
  }
}

/// A checkbox rendered inline in a markdown task list. Tappable when [onTap] is
/// non-null; otherwise inert but with the same footprint so text stays aligned.
class _MarkdownCheckbox extends StatelessWidget {
  final bool checked;
  final VoidCallback? onTap;

  const _MarkdownCheckbox({required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = Icon(
      checked ? Icons.check_box : Icons.check_box_outline_blank,
      size: 20,
      color: onTap == null
          ? cs.onSurfaceVariant
          : (checked ? cs.primary : cs.onSurfaceVariant),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: onTap == null
          ? icon
          : InkResponse(onTap: onTap, radius: 20, child: icon),
    );
  }
}
