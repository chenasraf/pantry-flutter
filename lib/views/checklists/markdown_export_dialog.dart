import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/utils/markdown_list.dart';

/// Dialog that turns a list into an editable Markdown document the user can
/// copy to the clipboard or share/download as a `.md` file.
///
/// Completed items are excluded by default; the "Include completed items"
/// checkbox opts them back in. The text field is pre-seeded with the generated
/// document and stays editable — copy/share use whatever is currently in the
/// field. Toggling the include checkbox regenerates the text (discarding manual
/// edits), and re-opening the dialog re-seeds fresh from the list.
class MarkdownExportDialog extends StatefulWidget {
  final String listName;
  final List<ListItem> items;
  final Category? Function(int? id) categoryFor;

  const MarkdownExportDialog({
    super.key,
    required this.listName,
    required this.items,
    required this.categoryFor,
  });

  @override
  State<MarkdownExportDialog> createState() => _MarkdownExportDialogState();
}

class _MarkdownExportDialogState extends State<MarkdownExportDialog> {
  // Completed items are excluded by default.
  bool _includeCompleted = false;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reseed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _generate() {
    final items = _includeCompleted
        ? widget.items
        : widget.items.where((i) => !i.done).toList();
    return buildListMarkdown(widget.listName, items, widget.categoryFor);
  }

  void _reseed() {
    _controller.text = _generate();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _controller.text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(m.checklists.markdown.copied)));
  }

  /// Sanitize the list name into a filesystem-safe `.md` filename, falling
  /// back to "list" when nothing usable is left.
  String _safeFileName(String name) {
    final base = name.trim().replaceAll(RegExp(r'[\\/:*?"<>|]+'), '-');
    return '${base.isEmpty ? 'list' : base}.md';
  }

  Future<void> _download() async {
    final fileName = _safeFileName(widget.listName);
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(_controller.text);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'text/markdown')]),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m.checklists.markdown.shareFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(m.checklists.markdown.exportTitle),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _includeCompleted,
              onChanged: (v) {
                setState(() {
                  _includeCompleted = v ?? false;
                  // A content-changing toggle regenerates the document,
                  // discarding any manual edits.
                  _reseed();
                });
              },
              title: Text(m.checklists.markdown.includeCompleted),
            ),
            const SizedBox(height: 4),
            Text(
              m.checklists.markdown.editHint,
              style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: TextField(
                controller: _controller,
                maxLines: null,
                minLines: 10,
                expands: false,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(m.checklists.markdown.close),
        ),
        TextButton.icon(
          onPressed: _copy,
          icon: const Icon(Icons.copy, size: 18),
          label: Text(m.checklists.markdown.copy),
        ),
        FilledButton.icon(
          onPressed: _download,
          icon: const Icon(Icons.download, size: 18),
          label: Text(m.checklists.markdown.download),
        ),
      ],
    );
  }
}
