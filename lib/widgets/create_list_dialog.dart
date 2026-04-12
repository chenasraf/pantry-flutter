import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/utils/checklist_icons.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';

/// Shows a dialog to create a new checklist. Returns the created
/// [ChecklistList] on success, or null if cancelled.
Future<ChecklistList?> showCreateListDialog(
  BuildContext context,
  ChecklistsController controller,
) {
  return showDialog<ChecklistList>(
    context: context,
    builder: (_) => CreateListDialog(controller: controller),
  );
}

class CreateListDialog extends StatefulWidget {
  final ChecklistsController controller;

  const CreateListDialog({super.key, required this.controller});

  @override
  State<CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<CreateListDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedIcon = 'clipboard-check';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      final list = await widget.controller.createList(
        name: name,
        description: _descriptionController.text.trim(),
        icon: _selectedIcon,
      );
      if (mounted) Navigator.of(context).pop(list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.createListFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(m.checklists.createList),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: m.checklists.listName,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: m.checklists.listDescription,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text(m.checklists.listIcon, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: checklistIconMap.entries.map((entry) {
                final isSelected = _selectedIcon == entry.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = entry.key),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Icon(
                      entry.value,
                      size: 20,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(m.common.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(m.common.save),
        ),
      ],
    );
  }
}
