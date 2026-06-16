import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/sync/sync_ids.dart';
import 'package:pantry/sync/sync_manager.dart';
import 'package:pantry/sync/sync_op.dart';

const categoryColors = [
  '#ef4444',
  '#f97316',
  '#eab308',
  '#22c55e',
  '#14b8a6',
  '#0ea5e9',
  '#6366f1',
  '#a855f7',
  '#ec4899',
  '#78716c',
];

class CreateCategoryDialog extends StatefulWidget {
  final int houseId;

  /// If non-null, we're editing this category instead of creating a new one.
  final Category? existing;

  const CreateCategoryDialog({super.key, required this.houseId, this.existing});

  @override
  State<CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<CreateCategoryDialog> {
  late final TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _selectedIcon = e?.icon ?? 'tag';
    _selectedColor = e?.color ?? categoryColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    final sync = SyncManager.instance;
    final now = DateTime.now().millisecondsSinceEpoch;
    final Category result;
    if (_isEditing) {
      final existing = widget.existing!;
      result = existing.copyWith(
        name: name,
        icon: _selectedIcon,
        color: _selectedColor,
        updatedAt: now,
      );
      sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.category,
          op: SyncOpKind.update,
          houseId: widget.houseId,
          entityId: existing.id < 0 ? null : existing.id,
          tempEntityId: existing.id < 0 ? existing.id : null,
          body: {'name': name, 'icon': _selectedIcon, 'color': _selectedColor},
          createdAt: now,
        ),
      );
    } else {
      final tempId = sync.newTempId();
      result = Category(
        id: tempId,
        houseId: widget.houseId,
        name: name,
        icon: _selectedIcon,
        color: _selectedColor,
        sortOrder: 1 << 20,
        createdAt: now,
        updatedAt: now,
      );
      sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.category,
          op: SyncOpKind.create,
          houseId: widget.houseId,
          tempEntityId: tempId,
          body: {'name': name, 'icon': _selectedIcon, 'color': _selectedColor},
          createdAt: now,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop(result);
  }

  Color _parseHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = m.checklists.itemForm;

    return AlertDialog(
      title: Text(_isEditing ? m.categories.editTitle : m.categories.addTitle),
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
                labelText: f.categoryName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(f.categoryIcon, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: categoryIconMap.entries.map((entry) {
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
            const SizedBox(height: 16),
            Text(f.categoryColor, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categoryColors.map((hex) {
                final color = _parseHex(hex);
                final isSelected = _selectedColor == hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 3,
                            )
                          : Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
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
