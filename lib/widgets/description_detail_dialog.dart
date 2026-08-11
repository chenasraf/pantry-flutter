import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/widgets/markdown_description.dart';

/// Opens a read-only dialog showing an item's full [description], rendered as
/// markdown. When [onChanged] is supplied, task-list checkboxes become
/// tappable and each toggle emits the full updated source so the caller can
/// persist it; pass null to keep the dialog read-only. Mirrors
/// [showStoreDetails] — tapping the item's description chip surfaces the whole
/// text without leaving the list.
Future<void> showItemDescription(
  BuildContext context,
  String description, {
  ValueChanged<String>? onChanged,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) =>
        DescriptionDetailDialog(description: description, onChanged: onChanged),
  );
}

class DescriptionDetailDialog extends StatefulWidget {
  final String description;
  final ValueChanged<String>? onChanged;

  const DescriptionDetailDialog({
    super.key,
    required this.description,
    this.onChanged,
  });

  @override
  State<DescriptionDetailDialog> createState() =>
      _DescriptionDetailDialogState();
}

class _DescriptionDetailDialogState extends State<DescriptionDetailDialog> {
  late String _description = widget.description;

  void _onChanged(String updated) {
    setState(() => _description = updated);
    widget.onChanged?.call(updated);
  }

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
        child: MarkdownDescription(
          description: _description,
          onChanged: widget.onChanged == null ? null : _onChanged,
          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
            p: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              height: 1.5,
              color: cs.onSurface,
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
