import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/utils/text_direction.dart';

/// Opens a read-only dialog showing an item's full description, rendered as
/// markdown. Mirrors [showStoreDetails] — tapping the item's description chip
/// surfaces the whole text without leaving the list.
Future<void> showItemDescription(BuildContext context, String description) {
  return showDialog<void>(
    context: context,
    builder: (_) => DescriptionDetailDialog(description: description),
  );
}

class DescriptionDetailDialog extends StatelessWidget {
  final String description;

  const DescriptionDetailDialog({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.primary.withValues(alpha: 0.16),
            child: Icon(Icons.notes, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(m.checklists.viewItem.descriptionLabel)),
        ],
      ),
      content: SingleChildScrollView(
        child: Directionality(
          textDirection: detectTextDirection(description),
          child: MarkdownBody(
            data: description,
            shrinkWrap: true,
            softLineBreak: true,
            onTapLink: (text, href, title) {
              if (href != null) launchUrl(Uri.parse(href));
            },
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.5,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(m.common.closeDialog),
        ),
      ],
    );
  }
}
