import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/store.dart';
import 'package:pantry/utils/store_icons.dart';
import 'package:pantry/sync/sync_ids.dart';
import 'package:pantry/sync/sync_manager.dart';
import 'package:pantry/sync/sync_op.dart';

const storeColors = [
  '#e11d48',
  '#ea580c',
  '#ca8a04',
  '#16a34a',
  '#0891b2',
  '#2563eb',
  '#7c3aed',
  '#c026d3',
  '#db2777',
  '#57534e',
];

class CreateStoreDialog extends StatefulWidget {
  final int houseId;

  /// If non-null, we're editing this store instead of creating a new one.
  final Store? existing;

  const CreateStoreDialog({super.key, required this.houseId, this.existing});

  @override
  State<CreateStoreDialog> createState() => _CreateStoreDialogState();
}

class _CreateStoreDialogState extends State<CreateStoreDialog> {
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
    _selectedIcon = e?.icon ?? 'store';
    _selectedColor = e?.color ?? storeColors.first;
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
    final Store result;
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
          entity: SyncEntity.store,
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
      result = Store(
        id: tempId,
        houseId: widget.houseId,
        name: name,
        icon: _selectedIcon,
        color: _selectedColor,
        createdAt: now,
        updatedAt: now,
      );
      sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.store,
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

    return AlertDialog(
      title: Text(_isEditing ? m.stores.editTitle : m.stores.addTitle),
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
                labelText: m.stores.name,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(m.stores.icon, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: storeIconMap.entries.map((entry) {
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
            Text(m.stores.color, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: storeColors.map((hex) {
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
