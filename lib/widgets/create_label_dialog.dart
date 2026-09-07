import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/label.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/label_icons.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry_core/sync/sync_ids.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';

const labelColors = [
  '#ef4444',
  '#f97316',
  '#f59e0b',
  '#eab308',
  '#84cc16',
  '#22c55e',
  '#10b981',
  '#14b8a6',
  '#06b6d4',
  '#0ea5e9',
  '#3b82f6',
  '#6366f1',
  '#8b5cf6',
  '#a855f7',
  '#d946ef',
  '#ec4899',
  '#f43f5e',
  '#78716c',
];

class CreateLabelDialog extends StatefulWidget {
  final int houseId;

  /// If non-null, we're editing this label instead of creating a new one.
  final Label? existing;

  /// Scope to preselect when *creating* — the list currently in context.
  /// `null` defaults to global. Ignored when editing, where the scope is seeded
  /// from [existing].
  final int? defaultListId;

  const CreateLabelDialog({
    super.key,
    required this.houseId,
    this.existing,
    this.defaultListId,
  });

  @override
  State<CreateLabelDialog> createState() => _CreateLabelDialogState();
}

class _CreateLabelDialogState extends State<CreateLabelDialog> {
  late final TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;

  /// Selected scope: `null` = global (all lists), otherwise a list id.
  int? _selectedListId;
  bool _saving = false;

  /// Lists offered in the scope selector. Only populated when the
  /// `label-lists` feature is available.
  List<ChecklistList> _lists = [];

  bool get _isEditing => widget.existing != null;
  bool get _scopingEnabled => hasFeature('label-lists');

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _selectedIcon = e?.icon ?? 'tag';
    _selectedColor = e?.color ?? labelColors.first;
    _selectedListId = e != null ? e.listId : widget.defaultListId;
    if (_scopingEnabled) _loadLists();
  }

  Future<void> _loadLists() async {
    final cached = ChecklistService.instance.getCachedLists(widget.houseId);
    if (cached != null && mounted) {
      setState(() => _lists = ChecklistService.sortLists(cached, 'custom'));
    }
    try {
      final lists = await ChecklistService.instance.getLists(widget.houseId);
      if (mounted) {
        setState(() => _lists = ChecklistService.sortLists(lists, 'custom'));
      }
    } catch (_) {
      // Offline or transient — keep whatever cache gave us (possibly none).
    }
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
    // With the flag off, never send `listId` — every label stays global.
    final listId = _scopingEnabled ? _selectedListId : null;

    final Label result;
    if (_isEditing) {
      final existing = widget.existing!;
      result = existing.copyWith(
        name: name,
        icon: _selectedIcon,
        color: _selectedColor,
        listId: _scopingEnabled ? _selectedListId : existing.listId,
        updatedAt: now,
      );
      sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.label,
          op: SyncOpKind.update,
          houseId: widget.houseId,
          entityId: existing.id < 0 ? null : existing.id,
          tempEntityId: existing.id < 0 ? existing.id : null,
          body: {
            'name': name,
            'icon': _selectedIcon,
            'color': _selectedColor,
            // Present with a value (int or explicit null → global) re-scopes;
            // omitted entirely on servers without the feature so the scope is
            // never touched.
            if (_scopingEnabled) 'listId': _selectedListId,
          },
          createdAt: now,
        ),
      );
    } else {
      final tempId = sync.newTempId();
      result = Label(
        id: tempId,
        houseId: widget.houseId,
        listId: listId,
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
          entity: SyncEntity.label,
          op: SyncOpKind.create,
          houseId: widget.houseId,
          tempEntityId: tempId,
          body: {
            'name': name,
            'icon': _selectedIcon,
            'color': _selectedColor,
            'listId': ?listId,
          },
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

  Widget _buildListSelector() {
    // The current scope must always have a matching item, or the dropdown
    // asserts. When editing a label whose list hasn't loaded yet (cache miss),
    // fall back to the global option until [_loadLists] fills it in.
    final knownIds = _lists.map((l) => l.id).toSet();
    final value = _selectedListId == null || knownIds.contains(_selectedListId)
        ? _selectedListId
        : null;
    return DropdownButtonFormField<int?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: m.labels.list,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<int?>(value: null, child: Text(m.labels.globalList)),
        for (final list in _lists)
          DropdownMenuItem<int?>(
            value: list.id,
            child: Text(
              list.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) => setState(() => _selectedListId = v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEditing ? m.labels.editTitle : m.labels.addTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder(
              valueListenable: _nameController,
              builder: (context, value, _) => TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textDirection: detectTextDirection(value.text),
                decoration: InputDecoration(
                  labelText: m.labels.name,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (_scopingEnabled) ...[
              const SizedBox(height: 16),
              _buildListSelector(),
            ],
            const SizedBox(height: 16),
            Text(m.labels.icon, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: labelIconMap.entries.map((entry) {
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
            Text(m.labels.color, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: labelColors.map((hex) {
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
