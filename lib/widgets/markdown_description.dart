import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pantry_core/utils/markdown_list.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry/widgets/markdown_task_checkbox.dart';

/// Matches a GitHub-style task-list checkbox at the start of a list item
/// (`- [ ]`, `* [x]`, `1. [ ]`, …). Group 1 is the bullet marker plus spacing,
/// group 2 the check state — used to toggle the Nth checkbox in place.
final _taskCheckboxRegex = RegExp(
  r'^([ \t]*(?:[-*+]|\d+[.)])[ \t]+)\[([ xX])\]',
  multiLine: true,
);

/// Return [source] with the [index]-th task-list checkbox flipped, counting in
/// document order.
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final paragraphStyle =
        (styleSheet ?? MarkdownStyleSheet.fromTheme(theme)).p;
    // The renderer invokes the checkbox builder once per checkbox, a parent
    // after its sub-items; this counter, through the build order, maps each
    // one back to its `- [ ]` line in the source.
    var checkboxIndex = 0;
    final buildOrder = taskLinesInBuildOrder(description);
    return Directionality(
      textDirection: detectTextDirection(description),
      child: MarkdownBody(
        data: description,
        shrinkWrap: true,
        softLineBreak: true,
        onTapLink: (text, href, title) {
          if (href != null) launchUrl(Uri.parse(href));
        },
        checkboxBuilder: (checked) {
          final index = taskLineForBuiltCheckbox(checkboxIndex++, buildOrder);
          final interactive = onChanged != null && index != null;
          return MarkdownTaskCheckbox(
            checked: checked,
            style: paragraphStyle,
            color: interactive && checked ? cs.primary : cs.onSurfaceVariant,
            padding: const EdgeInsetsDirectional.only(end: 6),
            onTap: interactive
                ? () => onChanged(toggleTaskCheckbox(description, index))
                : null,
          );
        },
        styleSheet: styleSheet,
      ),
    );
  }
}
