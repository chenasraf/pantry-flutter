import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/markdown_list.dart';
import 'package:pantry/views/checklists/checklist_item_tile.dart'
    show ItemLifecycle;
import 'package:pantry/views/checklists/form_components.dart';
import 'package:pantry/views/checklists/item_compose_bar.dart'
    show ComposeSubmission;

/// What the import dialog hands back to its caller on confirm: one
/// [ComposeSubmission] per selected item (name from the parsed list, every
/// other field from the shared defaults), plus whether the user asked to force
/// reuse of existing items for this import.
class MarkdownImportResult {
  final List<ComposeSubmission> submissions;
  final bool forceReuse;

  const MarkdownImportResult({
    required this.submissions,
    required this.forceReuse,
  });
}

/// Dialog that turns pasted/uploaded Markdown into list items. The found items
/// are shown as a selectable list (all selected by default); a shared set of
/// default fields (category, quantity, description, item type + recurrence) is
/// applied to every imported item — exactly like the multi-item add form.
///
/// Note: OS file drag-and-drop is intentionally not offered — the app has no
/// desktop file-drop plugin (e.g. `desktop_drop`), so import is limited to the
/// upload-file and paste methods. Both feed the same text buffer.
class MarkdownImportDialog extends StatefulWidget {
  final List<models.Category> categories;

  /// Current global "reuse existing items" pref (ask | reuse | never). The
  /// force-reuse checkbox is only offered when this is not already "reuse".
  final String reusePref;

  /// Whether the server advertises the reuse-existing-items capability — the
  /// force-reuse checkbox is hidden entirely when it doesn't.
  final bool reuseFeatureAvailable;

  /// Opens the create-category flow and returns the new category (or null).
  final Future<models.Category?> Function()? onRequestCreateCategory;

  const MarkdownImportDialog({
    super.key,
    required this.categories,
    required this.reusePref,
    required this.reuseFeatureAvailable,
    this.onRequestCreateCategory,
  });

  @override
  State<MarkdownImportDialog> createState() => _MarkdownImportDialogState();
}

class _MarkdownImportDialogState extends State<MarkdownImportDialog> {
  final _textController = TextEditingController();
  final _qtyController = TextEditingController();
  final _descController = TextEditingController();

  List<ParsedMarkdownItem> _parsed = const [];
  List<bool> _selected = const [];

  late List<models.Category> _categories = List.of(widget.categories);
  int? _categoryId;
  ItemLifecycle _lifecycle = ItemLifecycle.staple;
  final RecurrenceState _recurrence = RecurrenceState();
  bool _forceReuse = false;

  // Only offer the override when the global pref would not already reuse on
  // its own — i.e. when it is "ask" or "never" — and the server supports it.
  bool get _canForceReuse =>
      widget.reuseFeatureAvailable && widget.reusePref != 'reuse';

  @override
  void dispose() {
    _textController.dispose();
    _qtyController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _recompute() {
    setState(() {
      _parsed = parseMarkdownItems(_textController.text);
      // Everything is selected by default whenever the parsed set changes.
      _selected = List.filled(_parsed.length, true);
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    String? text;
    if (file.bytes != null) {
      text = utf8.decode(file.bytes!, allowMalformed: true);
    } else if (file.path != null) {
      text = await File(file.path!).readAsString();
    }
    if (text == null || !mounted) return;
    _textController.text = text;
    _recompute();
  }

  int get _selectedCount => _selected.where((s) => s).length;

  bool get _allSelected => _parsed.isNotEmpty && _selected.every((s) => s);

  void _toggleAll() {
    final target = !_allSelected;
    setState(() => _selected = List.filled(_parsed.length, target));
  }

  Future<void> _createCategory() async {
    final created = await widget.onRequestCreateCategory?.call();
    if (created == null || !mounted) return;
    setState(() {
      if (!_categories.any((c) => c.id == created.id)) {
        _categories = [..._categories, created];
      }
      _categoryId = created.id;
    });
  }

  void _submit() {
    final desc = _descController.text.trim();
    final qty = _qtyController.text.trim();
    final recurring = _lifecycle == ItemLifecycle.recurring;
    final once = _lifecycle == ItemLifecycle.once;
    final submissions = <ComposeSubmission>[];
    for (var i = 0; i < _parsed.length; i++) {
      if (!_selected[i]) continue;
      submissions.add(
        ComposeSubmission(
          name: _parsed[i].name,
          description: desc.isEmpty ? null : desc,
          quantity: qty.isEmpty ? null : qty,
          categoryId: _categoryId,
          rrule: recurring ? _recurrence.toRrule() : null,
          deleteOnDone: once,
          repeatFromCompletion: recurring && _recurrence.repeatFromCompletion,
        ),
      );
    }
    if (submissions.isEmpty) return;
    Navigator.of(context).pop(
      MarkdownImportResult(
        submissions: submissions,
        forceReuse: _canForceReuse && _forceReuse,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasText = _textController.text.trim().isNotEmpty;
    final hasItems = _parsed.isNotEmpty;

    return AlertDialog(
      title: Text(m.checklists.markdown.importTitle),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: Text(m.checklists.markdown.uploadFile),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _textController,
                onChanged: (_) => _recompute(),
                minLines: 4,
                maxLines: 8,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: m.checklists.markdown.pasteLabel,
                  hintText: m.checklists.markdown.pastePlaceholder,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              if (hasItems) ...[
                _foundHeader(cs),
                const SizedBox(height: 6),
                _foundList(cs),
                const SizedBox(height: 16),
                _defaultsSection(cs),
                if (_canForceReuse) ...[
                  const SizedBox(height: 4),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _forceReuse,
                    onChanged: (v) => setState(() => _forceReuse = v ?? false),
                    title: Text(m.checklists.markdown.reuseExisting),
                  ),
                ],
              ] else if (hasText) ...[
                Text(
                  m.checklists.markdown.noneFound,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(m.common.cancel),
        ),
        FilledButton(
          onPressed: _selectedCount == 0 ? null : _submit,
          child: Text(m.checklists.markdown.addItems(_selectedCount)),
        ),
      ],
    );
  }

  Widget _foundHeader(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: Text(
            m.checklists.markdown.itemsFound(_parsed.length),
            style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
          ),
        ),
        TextButton(
          onPressed: _toggleAll,
          child: Text(
            _allSelected
                ? m.checklists.markdown.deselectAll
                : m.checklists.markdown.selectAll,
          ),
        ),
      ],
    );
  }

  Widget _foundList(ColorScheme cs) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _parsed.length,
        itemBuilder: (context, i) {
          return CheckboxListTile(
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: _selected[i],
            onChanged: (v) => setState(() => _selected[i] = v ?? false),
            title: Text(_parsed[i].name),
          );
        },
      ),
    );
  }

  Widget _defaultsSection(ColorScheme cs) {
    final t = m.checklists.itemTypes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          m.checklists.markdown.defaultFields.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        // Category
        Text(
          m.checklists.compose.chipCategory,
          style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CategorySwatch(
              label: m.checklists.compose.none,
              color: cs.onSurfaceVariant,
              selected: _categoryId == null,
              onTap: () => setState(() => _categoryId = null),
            ),
            for (final c in _categories)
              CategorySwatch(
                icon: categoryIcon(c.icon),
                label: c.name,
                color: _parseColor(c.color) ?? cs.primary,
                selected: _categoryId == c.id,
                onTap: () => setState(() => _categoryId = c.id),
              ),
            if (widget.onRequestCreateCategory != null)
              NewCategoryChipButton(
                color: cs.primary,
                label: m.checklists.itemForm.createCategory,
                onTap: _createCategory,
              ),
          ],
        ),
        const SizedBox(height: 14),
        // Quantity
        TextField(
          controller: _qtyController,
          decoration: InputDecoration(
            labelText: m.checklists.compose.chipQuantity,
            hintText: m.checklists.compose.qtyHint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        // Description
        TextField(
          controller: _descController,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: m.checklists.compose.chipDescription,
            hintText: m.checklists.compose.descHint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 14),
        // Item type
        Text(
          t.label,
          style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        LifecycleRow(
          label: t.staple,
          body: t.stapleBody,
          selected: _lifecycle == ItemLifecycle.staple,
          onTap: () => setState(() => _lifecycle = ItemLifecycle.staple),
        ),
        const SizedBox(height: 7),
        LifecycleRow(
          label: t.onceTime,
          body: t.onceTimeBody,
          selected: _lifecycle == ItemLifecycle.once,
          onTap: () => setState(() => _lifecycle = ItemLifecycle.once),
        ),
        const SizedBox(height: 7),
        LifecycleRow(
          label: t.recurring,
          body: t.recurringBody,
          selected: _lifecycle == ItemLifecycle.recurring,
          onTap: () => setState(() => _lifecycle = ItemLifecycle.recurring),
        ),
        if (_lifecycle == ItemLifecycle.recurring) ...[
          const SizedBox(height: 12),
          RecurrenceInline(
            state: _recurrence,
            onChanged: () => setState(() {}),
          ),
        ],
      ],
    );
  }

  static Color? _parseColor(String hex) {
    if (hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : null;
  }
}
