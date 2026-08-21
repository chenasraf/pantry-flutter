import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';
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

class CategoryFormView extends StatefulWidget {
  final int houseId;

  /// If non-null, we're editing this category instead of creating a new one.
  final Category? existing;

  /// Scope to preselect when *creating* — the list currently in context (e.g.
  /// the list an item form belongs to). `null` defaults to global. Ignored when
  /// editing, where the scope is seeded from [existing].
  final int? defaultListId;

  const CategoryFormView({
    super.key,
    required this.houseId,
    this.existing,
    this.defaultListId,
  });

  @override
  State<CategoryFormView> createState() => _CategoryFormViewState();
}

class _CategoryFormViewState extends State<CategoryFormView> {
  late final TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;
  TextDirection _nameDir = TextDirection.ltr;

  /// Selected scope: `null` = global (all lists), otherwise a list id.
  int? _selectedListId;
  bool _saving = false;

  /// Lists offered in the scope selector. Only populated when the
  /// `category-lists` feature is available.
  List<ChecklistList> _lists = [];

  bool get _isEditing => widget.existing != null;
  bool get _scopingEnabled => hasFeature('category-lists');

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _selectedIcon = e?.icon ?? 'tag';
    _selectedColor = e?.color ?? categoryColors.first;
    _selectedListId = e != null ? e.listId : widget.defaultListId;
    _nameDir = detectTextDirection(e?.name);
    _nameController.addListener(() {
      final dir = detectTextDirection(_nameController.text);
      if (dir != _nameDir) setState(() => _nameDir = dir);
    });
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
    // With the flag off, never send `listId` — every category stays global.
    final listId = _scopingEnabled ? _selectedListId : null;
    final Category result;
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
          entity: SyncEntity.category,
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
      result = Category(
        id: tempId,
        houseId: widget.houseId,
        name: name,
        icon: _selectedIcon,
        color: _selectedColor,
        listId: listId,
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
    // asserts. When editing a category whose list hasn't loaded yet (cache
    // miss), fall back to the global option until [_loadLists] fills it in.
    final knownIds = _lists.map((l) => l.id).toSet();
    final value = _selectedListId == null || knownIds.contains(_selectedListId)
        ? _selectedListId
        : null;
    return DropdownButtonFormField<int?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: m.categories.list,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Text(m.categories.globalList),
        ),
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
    final cs = theme.colorScheme;
    final f = m.checklists.itemForm;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        // Desktop opens the form as a modal — give it a close affordance
        // instead of the platform-default Back chevron, which would read as
        // navigating away from a page that doesn't exist on the stack.
        leading: PlatformInfo.isDesktop
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: m.common.cancel,
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : appBarBackLeading(context),
        title: Text(
          _isEditing ? m.categories.editTitle : m.categories.addTitle,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _CategoryHeaderPreview(
                  name: _nameController.text.trim().isEmpty
                      ? (_isEditing
                            ? m.categories.editTitle
                            : m.categories.addTitle)
                      : _nameController.text.trim(),
                  icon: _selectedIcon,
                  color: _parseHex(_selectedColor),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  autofocus: !_isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  textDirection: _nameDir,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: f.categoryName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (_scopingEnabled) ...[
                  const SizedBox(height: 16),
                  _buildListSelector(),
                ],
                const SizedBox(height: 20),
                _SectionLabel(text: f.categoryIcon),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: categoryIconMap.entries.map((entry) {
                    final isSelected = _selectedIcon == entry.key;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = entry.key),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isSelected ? cs.primaryContainer : null,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(color: cs.primary, width: 2)
                              : Border.all(color: cs.outlineVariant),
                        ),
                        child: Icon(
                          entry.value,
                          size: 22,
                          color: isSelected ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                _SectionLabel(text: f.categoryColor),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: categoryColors.map((hex) {
                    final color = _parseHex(hex);
                    final isSelected = _selectedColor == hex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = hex),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: cs.primary, width: 3)
                              : Border.all(color: cs.outlineVariant),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 20,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          _DockedSaveBar(
            onCancel: _saving ? null : () => Navigator.of(context).maybePop(),
            onSave: _saving ? null : _save,
            saving: _saving,
            label: m.common.save,
          ),
        ],
      ),
    );
  }
}

/// Live preview of the category's icon, color and name as edits are made.
class _CategoryHeaderPreview extends StatelessWidget {
  final String name;
  final String icon;
  final Color color;

  const _CategoryHeaderPreview({
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(categoryIcon(icon), color: color, size: 26),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DockedSaveBar extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final bool saving;
  final String label;

  const _DockedSaveBar({
    required this.onCancel,
    required this.onSave,
    required this.saving,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        child: Row(
          children: [
            InkWell(
              onTap: onCancel,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  m.common.cancel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: InkWell(
                onTap: onSave,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cs.primary, cs.primary.withValues(alpha: 0.78)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (saving)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.check, color: Colors.white, size: 20),
                      const SizedBox(width: 9),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
