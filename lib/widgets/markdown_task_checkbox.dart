import 'package:flutter/material.dart';

/// A markdown task-list checkbox, centred on the first line of its item.
///
/// The markdown renderer lines a list item's marker up with its text on a
/// shared baseline, and a bare icon's baseline is the foot of its glyph, which
/// lifts the box above the text beside it. Set in a line of the item's own
/// [style], the icon takes that text's baseline and sits in the middle of it.
class MarkdownTaskCheckbox extends StatelessWidget {
  final bool checked;
  final TextStyle? style;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const MarkdownTaskCheckbox({
    super.key,
    required this.checked,
    required this.style,
    this.color,
    this.padding = EdgeInsetsDirectional.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      checked ? Icons.check_box : Icons.check_box_outline_blank,
      size: 20,
      color: color,
    );
    final onTap = this.onTap;
    return Text.rich(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: padding,
          child: onTap == null
              ? icon
              : InkResponse(onTap: onTap, radius: 20, child: icon),
        ),
      ),
      style: style,
    );
  }
}

/// Which task line the [built]-th call of a markdown `checkboxBuilder` renders,
/// given [buildOrder] from `taskLinesInBuildOrder`.
///
/// The markdown widgets re-parse on their own whenever their dependencies
/// change (a route transition does so several times), and each parse builds
/// every checkbox again through the same builder closure, so a count kept
/// across calls runs on past the last line. Every parse builds each checkbox
/// once, in the same order, which makes the count's remainder the position
/// within the current parse.
int? taskLineForBuiltCheckbox(int built, List<int> buildOrder) =>
    buildOrder.isEmpty ? null : buildOrder[built % buildOrder.length];
