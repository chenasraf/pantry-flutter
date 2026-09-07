import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/custom_field.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/custom_field_service.dart';
import 'package:pantry_core/sync/sync_ids.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/utils/field_type_icons.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry/views/custom_fields/custom_field_drafts.dart';
import 'package:pantry/views/custom_fields/custom_field_editor.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';

/// The unified custom-fields manager: field definitions grouped by scope,
/// each editable inline (accordion). Reachable from a list's manage menu,
/// gated by `hasFeature('custom-fields')` and the `canEditFields` capability.
class CustomFieldsView extends StatefulWidget {
  final int houseId;

  const CustomFieldsView({super.key, required this.houseId});

  @override
  State<CustomFieldsView> createState() => _CustomFieldsViewState();
}

class _CustomFieldsViewState extends State<CustomFieldsView> {
  List<FieldDefinition> _fields = [];

  /// Lists in display order, backing the scope grouping and the scope selector.
  List<ChecklistList> _lists = [];
  bool _isLoading = true;
  String? _error;

  /// The id of the field whose editor is expanded, or `null` when none is.
  int? _expandedId;

  /// Whether the new-field editor is open at the bottom of the list.
  bool _creating = false;

  /// One [ExpansibleController] per field, so opening one row can collapse
  /// the previously open one (single-open accordion).
  final Map<int, ExpansibleController> _controllers = {};

  StreamSubscription<SyncOpApplied>? _appliedSub;

  /// Fields can be dragged to reorder only while nothing is being edited — the
  /// row header doubles as the expand toggle, and an expanded editor is tall.
  bool get _canReorder => _expandedId == null && !_creating;

  @override
  void initState() {
    super.initState();
    _appliedSub = SyncManager.instance.onApplied.listen(_onApplied);
    _load();
  }

  @override
  void dispose() {
    _appliedSub?.cancel();
    super.dispose();
  }

  /// Replace an optimistic field with the server's canonical record (real id,
  /// real option ids) once its create/update flushes.
  void _onApplied(SyncOpApplied e) {
    if (!mounted) return;
    if (e.op.entity != SyncEntity.customField) return;
    final entity = e.entity;
    if (entity is! FieldDefinition) return;
    setState(() {
      final tempId = e.op.tempEntityId;
      final idx = _fields.indexWhere(
        (f) => f.id == entity.id || (tempId != null && f.id == tempId),
      );
      if (idx != -1) {
        _fields[idx] = entity;
      } else {
        _fields.add(entity);
      }
      _fields = CustomFieldService.sortFields(_fields);
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    // Show cached fields immediately so the screen is usable offline.
    final cached = CustomFieldService.instance.getCached(widget.houseId);
    if (cached != null && mounted) {
      setState(() => _fields = CustomFieldService.sortFields(cached));
    }
    try {
      final results = await Future.wait([
        CustomFieldService.instance.getFields(widget.houseId),
        ChecklistService.instance.getLists(widget.houseId),
      ]);
      if (!mounted) return;
      setState(() {
        _fields = CustomFieldService.sortFields(
          results[0] as List<FieldDefinition>,
        );
        _lists = ChecklistService.sortLists(
          results[1] as List<ChecklistList>,
          'custom',
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Keep any cached fields on screen; only surface the error when we have
        // nothing to show.
        _error = _fields.isEmpty ? e.toString() : null;
        _isLoading = false;
      });
    }
  }

  /// Partition [_fields] into scope groups: the house-wide ("All lists")
  /// section first, then one section per list that has fields, in the lists'
  /// display order. Fields scoped to a list that isn't loaded still get a
  /// best-effort section so they stay reachable.
  List<FieldGroup> _buildGroups() {
    final globals = [
      for (final f in _fields)
        if (f.listId == null) f,
    ];
    final byList = <int, List<FieldDefinition>>{};
    for (final f in _fields) {
      final lid = f.listId;
      if (lid != null) byList.putIfAbsent(lid, () => []).add(f);
    }

    final groups = <FieldGroup>[];
    if (globals.isNotEmpty) {
      groups.add(
        FieldGroup(
          listId: null,
          title: m.customFields.allLists,
          fields: globals,
        ),
      );
    }
    for (final list in _lists) {
      final fields = byList.remove(list.id);
      if (fields != null && fields.isNotEmpty) {
        groups.add(
          FieldGroup(listId: list.id, title: list.name, fields: fields),
        );
      }
    }
    for (final entry in byList.entries) {
      groups.add(
        FieldGroup(
          listId: entry.key,
          title: '#${entry.key}',
          fields: entry.value,
        ),
      );
    }
    return groups;
  }

  ExpansibleController _controllerFor(int id) =>
      _controllers.putIfAbsent(id, ExpansibleController.new);

  /// Close whatever editor is open — the expanded row (collapsing its tile) or
  /// the new-field editor.
  void _closeEditor() {
    final open = _expandedId;
    setState(() {
      _expandedId = null;
      _creating = false;
    });
    if (open != null) _controllers[open]?.collapse();
  }

  /// Enforce single-open: expanding a row collapses the previously open one.
  void _onExpansionChanged(FieldDefinition field, bool expanded) {
    if (expanded) {
      final previous = _expandedId;
      setState(() {
        _expandedId = field.id;
        _creating = false;
      });
      if (previous != null && previous != field.id) {
        _controllers[previous]?.collapse();
      }
    } else if (_expandedId == field.id) {
      setState(() => _expandedId = null);
    }
  }

  void _startCreate() {
    setState(() {
      _expandedId = null;
      _creating = true;
    });
  }

  /// Reorder within one scope group. The drag can't move a field across scopes
  /// (each group is its own reorderable), so the group's reordered slice is
  /// spliced back into the full house-wide sequence, which is then renumbered.
  void _reorderGroup(FieldGroup group, int oldIndex, int newIndex) {
    if (!_canReorder || oldIndex == newIndex) return;
    final reordered = [...group.fields];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final flat = <FieldDefinition>[];
    for (final g in _buildGroups()) {
      flat.addAll(g.listId == group.listId ? reordered : g.fields);
    }
    setState(() => _fields = flat);
    _persistOrder(flat);
  }

  void _persistOrder(List<FieldDefinition> ordered) {
    final order = <Map<String, int>>[
      for (var i = 0; i < ordered.length; i++)
        {'id': ordered[i].id, 'sortOrder': i},
    ];
    SyncManager.instance.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.customField,
        op: SyncOpKind.reorder,
        houseId: widget.houseId,
        body: {'order': order},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void _submitCreate(FieldDraft draft) {
    final sync = SyncManager.instance;
    final now = DateTime.now().millisecondsSinceEpoch;
    final tempId = sync.newTempId();
    final field = _optimisticField(draft, id: tempId, now: now);
    sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.customField,
        op: SyncOpKind.create,
        houseId: widget.houseId,
        tempEntityId: tempId,
        body: _createBody(draft),
        createdAt: now,
      ),
    );
    setState(() {
      _fields = CustomFieldService.sortFields([..._fields, field]);
      _creating = false;
    });
  }

  void _submitEdit(FieldDefinition existing, FieldDraft draft) {
    final sync = SyncManager.instance;
    final now = DateTime.now().millisecondsSinceEpoch;
    final field = _optimisticField(
      draft,
      id: existing.id,
      now: now,
      createdAt: existing.createdAt,
    );
    sync.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.customField,
        op: SyncOpKind.update,
        houseId: widget.houseId,
        entityId: existing.id < 0 ? null : existing.id,
        tempEntityId: existing.id < 0 ? existing.id : null,
        body: _patchBody(draft),
        createdAt: now,
      ),
    );
    setState(() {
      final idx = _fields.indexWhere((f) => f.id == existing.id);
      if (idx != -1) _fields[idx] = field;
      _fields = CustomFieldService.sortFields(_fields);
      _expandedId = null;
    });
    _controllers[existing.id]?.collapse();
  }

  Future<void> _confirmDelete(FieldDefinition field) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.customFields.deleteTitle),
        content: Text(m.customFields.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.common.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    SyncManager.instance.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.customField,
        op: SyncOpKind.delete,
        houseId: widget.houseId,
        entityId: field.id < 0 ? null : field.id,
        tempEntityId: field.id < 0 ? field.id : null,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    setState(() {
      _fields = _fields.where((f) => f.id != field.id).toList();
      if (_expandedId == field.id) _expandedId = null;
    });
  }

  /// Build the optimistic [FieldDefinition] shown until the server's canonical
  /// record arrives via [_onApplied]. New `select` options carry no id yet.
  FieldDefinition _optimisticField(
    FieldDraft d, {
    required int id,
    required int now,
    int? createdAt,
  }) {
    return FieldDefinition(
      id: id,
      houseId: widget.houseId,
      listId: d.listId,
      name: d.name,
      type: d.type,
      sortOrder: 1 << 20,
      hint: d.hint,
      multiline: d.multiline,
      defaultText: d.defaultText,
      defaultNumber: d.defaultNumber,
      defaultBool: d.defaultBool,
      defaultOptionId: d.defaultOptionId,
      dateMode: d.type == FieldType.date ? d.dateMode : null,
      defaultOffsetDays: d.defaultOffsetDays,
      notifyDefault: d.notifyDefault,
      leadDays: d.leadDays,
      overridePolicy: d.type == FieldType.date ? d.overridePolicy : null,
      stopWhenDone: d.stopWhenDone,
      options: [
        for (var i = 0; i < d.options.length; i++)
          FieldOption(
            id: d.options[i].id ?? 0,
            label: d.options[i].label,
            sortOrder: i,
            valueCount: d.options[i].valueCount,
          ),
      ],
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> _createBody(FieldDraft d) {
    final b = <String, dynamic>{'name': d.name, 'type': d.type.name};
    if (d.listId != null) b['listId'] = d.listId;
    _fillTypeConfig(b, d, forCreate: true);
    return b;
  }

  Map<String, dynamic> _patchBody(FieldDraft d) {
    // `listId` is always present so a scope change persists; a null value moves
    // the field house-wide.
    final b = <String, dynamic>{'name': d.name, 'listId': d.listId};
    _fillTypeConfig(b, d, forCreate: false);
    return b;
  }

  /// Add the type-specific config to a create/update body. Only the fields that
  /// apply to [d]'s type are sent.
  void _fillTypeConfig(
    Map<String, dynamic> b,
    FieldDraft d, {
    required bool forCreate,
  }) {
    switch (d.type) {
      case FieldType.text:
        if (d.hint != null) b['hint'] = d.hint;
        b['multiline'] = d.multiline;
        b['defaultText'] = d.defaultText;
      case FieldType.number:
        if (d.hint != null) b['hint'] = d.hint;
        b['defaultNumber'] = d.defaultNumber;
      case FieldType.checkbox:
        b['defaultBool'] = d.defaultBool;
      case FieldType.date:
        b['dateMode'] = d.dateMode.name;
        b['defaultOffsetDays'] = d.dateMode == FieldDateMode.relative
            ? d.defaultOffsetDays
            : null;
        b['notifyDefault'] = d.notifyDefault;
        b['leadDays'] = d.leadDays;
        b['overridePolicy'] = d.overridePolicy.wire;
        b['stopWhenDone'] = d.stopWhenDone;
      case FieldType.select:
        if (d.hint != null) b['hint'] = d.hint;
        b['options'] = [
          for (var i = 0; i < d.options.length; i++)
            {
              // A real id targets an existing row; a new option omits it.
              if ((d.options[i].id ?? 0) > 0) 'id': d.options[i].id,
              'label': d.options[i].label,
              'sortOrder': i,
            },
        ];
        // The default option can only reference a saved option id.
        if (!forCreate) b['defaultOptionId'] = d.defaultOptionId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(m.customFields.manageTitle),
        actions: [
          if (PlatformInfo.isDesktop)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: m.common.refresh,
              onPressed: _load,
            ),
        ],
      ),
      body: _isLoading && _fields.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: Text(m.common.retry)),
                  ],
                ),
              ),
            )
          : RefreshIndicator(onRefresh: _load, child: _buildList(theme)),
    );
  }

  Widget _buildList(ThemeData theme) {
    final groups = _buildGroups();
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (groups.isEmpty && !_creating)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              m.customFields.empty,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        for (final group in groups) ...[
          _buildSectionHeader(theme, group.title),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: group.fields.length,
            onReorderItem: (oldIndex, newIndex) =>
                _reorderGroup(group, oldIndex, newIndex),
            itemBuilder: (context, index) => _buildFieldTile(
              theme,
              group.fields[index],
              dragIndex: _canReorder ? index : null,
            ),
          ),
        ],
        if (_creating)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.colorScheme.primary),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CustomFieldEditor(
                  key: const ValueKey('cf-new'),
                  houseId: widget.houseId,
                  lists: _lists,
                  initial: null,
                  onSubmit: (draft) => _submitCreate(draft),
                  onCancel: _closeEditor,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
          child: OutlinedButton.icon(
            onPressed: (_creating || _expandedId != null) ? null : _startCreate,
            icon: const Icon(Icons.add),
            label: Text(m.customFields.addField),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
    child: Text(
      title.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    ),
  );

  /// A single field as a Material [ExpansionTile] wrapped in a bordered card.
  /// [dragIndex] is the field's position within its scope group; the drag
  /// handle shows only when it's provided (i.e. reordering is enabled).
  Widget _buildFieldTile(
    ThemeData theme,
    FieldDefinition field, {
    int? dragIndex,
  }) {
    final cs = theme.colorScheme;
    final expanded = _expandedId == field.id;
    final showBell = field.type == FieldType.date && field.notifyDefault;
    return Padding(
      key: ValueKey(field.id),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 4),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: expanded ? cs.primary : cs.outlineVariant),
        ),
        child: ExpansionTile(
          controller: _controllerFor(field.id),
          initiallyExpanded: expanded,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: EdgeInsetsDirectional.only(
            start: dragIndex != null ? 6 : 14,
            end: 10,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          onExpansionChanged: (e) => _onExpansionChanged(field, e),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dragIndex != null) ...[
                ReorderableDragStartListener(
                  index: dragIndex,
                  child: Icon(Icons.drag_handle, color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 6),
              ],
              Icon(fieldTypeIcon(field.type), color: cs.primary),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  field.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: detectTextDirection(field.name),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                fieldTypeLabel(field.type),
                style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
              ),
              if (showBell) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.notifications_active_outlined,
                  size: 16,
                  color: cs.primary,
                ),
              ],
            ],
          ),
          children: [
            CustomFieldEditor(
              key: ValueKey('cf-edit-${field.id}'),
              houseId: widget.houseId,
              lists: _lists,
              initial: field,
              onSubmit: (draft) => _submitEdit(field, draft),
              onCancel: _closeEditor,
              onDelete: () => _confirmDelete(field),
            ),
          ],
        ),
      ),
    );
  }
}
