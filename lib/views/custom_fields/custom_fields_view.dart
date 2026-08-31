import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/custom_field.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/custom_field_service.dart';
import 'package:pantry/sync/sync_ids.dart';
import 'package:pantry/sync/sync_manager.dart';
import 'package:pantry/sync/sync_op.dart';
import 'package:pantry/utils/field_type_icons.dart';
import 'package:pantry/views/checklists/form_components.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/utils/text_direction.dart';
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
  List<_FieldGroup> _buildGroups() {
    final globals = [
      for (final f in _fields)
        if (f.listId == null) f,
    ];
    final byList = <int, List<FieldDefinition>>{};
    for (final f in _fields) {
      final lid = f.listId;
      if (lid != null) byList.putIfAbsent(lid, () => []).add(f);
    }

    final groups = <_FieldGroup>[];
    if (globals.isNotEmpty) {
      groups.add(
        _FieldGroup(
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
          _FieldGroup(listId: list.id, title: list.name, fields: fields),
        );
      }
    }
    for (final entry in byList.entries) {
      groups.add(
        _FieldGroup(
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
  void _reorderGroup(_FieldGroup group, int oldIndex, int newIndex) {
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

  void _submitCreate(_FieldDraft draft) {
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

  void _submitEdit(FieldDefinition existing, _FieldDraft draft) {
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
    _FieldDraft d, {
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

  Map<String, dynamic> _createBody(_FieldDraft d) {
    final b = <String, dynamic>{'name': d.name, 'type': d.type.name};
    if (d.listId != null) b['listId'] = d.listId;
    _fillTypeConfig(b, d, forCreate: true);
    return b;
  }

  Map<String, dynamic> _patchBody(_FieldDraft d) {
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
    _FieldDraft d, {
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
                child: _FieldEditor(
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
            _FieldEditor(
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

/// A display group of fields sharing a scope: `listId == null` for the
/// house-wide ("All lists") section, or a list id for a per-list section.
class _FieldGroup {
  final int? listId;
  final String title;
  final List<FieldDefinition> fields;

  const _FieldGroup({
    required this.listId,
    required this.title,
    required this.fields,
  });
}

/// Mutable editing state for one field definition.
class _FieldDraft {
  String name;
  FieldType type;
  int? listId;
  String? hint;
  bool multiline;
  String? defaultText;
  double? defaultNumber;
  bool defaultBool;
  int? defaultOptionId;
  FieldDateMode dateMode;
  int? defaultOffsetDays;
  bool notifyDefault;
  int leadDays;
  FieldOverridePolicy overridePolicy;
  bool stopWhenDone;
  List<_OptionDraft> options;

  _FieldDraft({
    required this.name,
    required this.type,
    this.listId,
    this.hint,
    this.multiline = false,
    this.defaultText,
    this.defaultNumber,
    this.defaultBool = false,
    this.defaultOptionId,
    this.dateMode = FieldDateMode.absolute,
    this.defaultOffsetDays,
    this.notifyDefault = false,
    this.leadDays = 0,
    this.overridePolicy = FieldOverridePolicy.fieldOnly,
    this.stopWhenDone = false,
    this.options = const [],
  });
}

class _OptionDraft {
  final int? id;
  String label;
  int valueCount;

  _OptionDraft({this.id, required this.label, this.valueCount = 0});
}

/// The inline field-definition editor. Owns its own draft + text controllers,
/// and handles `select`-option removal (remap-or-clear for options in use)
/// itself. The field save/delete are delegated to the parent so they ride the
/// sync queue like every other write.
class _FieldEditor extends StatefulWidget {
  final int houseId;
  final List<ChecklistList> lists;

  /// The field being edited, or `null` when creating a new one.
  final FieldDefinition? initial;
  final void Function(_FieldDraft draft) onSubmit;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;

  const _FieldEditor({
    super.key,
    required this.houseId,
    required this.lists,
    required this.initial,
    required this.onSubmit,
    required this.onCancel,
    this.onDelete,
  });

  @override
  State<_FieldEditor> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<_FieldEditor> {
  static const _leadOptions = [0, 1, 2, 3, 7];

  late final TextEditingController _name;
  late final TextEditingController _hint;
  late final TextEditingController _defaultText;
  late final TextEditingController _defaultNumber;
  late final TextEditingController _offset;
  final List<TextEditingController> _optionCtrls = [];

  late _FieldDraft _d;
  TextDirection _nameDir = TextDirection.ltr;
  bool _busy = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _d = e == null
        ? _FieldDraft(name: '', type: FieldType.text)
        : _FieldDraft(
            name: e.name,
            type: e.type,
            listId: e.listId,
            hint: e.hint,
            multiline: e.multiline,
            defaultText: e.defaultText,
            defaultNumber: e.defaultNumber,
            defaultBool: e.defaultBool,
            defaultOptionId: e.defaultOptionId,
            dateMode: e.dateMode ?? FieldDateMode.absolute,
            defaultOffsetDays: e.defaultOffsetDays,
            notifyDefault: e.notifyDefault,
            leadDays: e.leadDays,
            overridePolicy: e.overridePolicy ?? FieldOverridePolicy.fieldOnly,
            stopWhenDone: e.stopWhenDone,
            options: [
              for (final o in e.options)
                _OptionDraft(
                  id: o.id,
                  label: o.label,
                  valueCount: o.valueCount,
                ),
            ],
          );
    _name = TextEditingController(text: _d.name);
    _hint = TextEditingController(text: _d.hint ?? '');
    _defaultText = TextEditingController(text: _d.defaultText ?? '');
    _defaultNumber = TextEditingController(
      text: _d.defaultNumber?.toString() ?? '',
    );
    _offset = TextEditingController(
      text: _d.defaultOffsetDays?.toString() ?? '',
    );
    for (final o in _d.options) {
      _optionCtrls.add(TextEditingController(text: o.label));
    }
    _nameDir = detectTextDirection(_d.name);
    _name.addListener(() {
      final dir = detectTextDirection(_name.text);
      if (dir != _nameDir) setState(() => _nameDir = dir);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _hint.dispose();
    _defaultText.dispose();
    _defaultNumber.dispose();
    _offset.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _d.options.add(_OptionDraft(id: null, label: ''));
      _optionCtrls.add(TextEditingController());
    });
  }

  Future<void> _removeOption(int index) async {
    final opt = _d.options[index];
    final inUse = _isEditing && (opt.id ?? 0) > 0 && opt.valueCount > 0;
    if (!inUse) {
      setState(() {
        _d.options.removeAt(index);
        _optionCtrls.removeAt(index).dispose();
        if (opt.id != null && _d.defaultOptionId == opt.id) {
          _d.defaultOptionId = null;
        }
      });
      return;
    }

    // Reading the labels back keeps the remap dialog's option names current.
    _syncOptionLabels();
    final choice = await _promptRemap(opt);
    if (choice == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated = await CustomFieldService.instance.deleteFieldOption(
        widget.houseId,
        widget.initial!.id,
        opt.id!,
        action: choice.clear
            ? OptionDeleteAction.clear
            : OptionDeleteAction.remap,
        remapToId: choice.clear ? null : choice.remapToId,
      );
      if (!mounted) return;
      setState(() {
        _d.options.removeAt(index);
        _optionCtrls.removeAt(index).dispose();
        if (_d.defaultOptionId == opt.id) {
          _d.defaultOptionId = choice.clear ? null : choice.remapToId;
        }
        // Refresh surviving counts from the server (a remap bumps the target).
        for (final o in _d.options) {
          for (final u in updated.options) {
            if (u.id == o.id) o.valueCount = u.valueCount;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(m.customFields.optionDeleteFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<_RemapChoice?> _promptRemap(_OptionDraft removing) {
    final targets = [
      for (final o in _d.options)
        if ((o.id ?? 0) > 0 && o.id != removing.id && o.label.trim().isNotEmpty)
          o,
    ];
    return showDialog<_RemapChoice>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(m.customFields.remapTitle),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              m.customFields.remapPrompt(
                removing.valueCount,
                removing.label.trim(),
              ),
            ),
          ),
          for (final o in targets)
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.pop(ctx, _RemapChoice(remapToId: o.id)),
              child: Text(m.customFields.remapMoveTo(o.label.trim())),
            ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(ctx, const _RemapChoice(clear: true)),
            child: Text(m.customFields.remapClear),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx),
            child: Text(m.common.cancel),
          ),
        ],
      ),
    );
  }

  void _syncOptionLabels() {
    for (var i = 0; i < _d.options.length; i++) {
      _d.options[i].label = _optionCtrls[i].text.trim();
    }
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    _syncOptionLabels();
    _d
      ..name = name
      ..hint = _hint.text.trim().isEmpty ? null : _hint.text.trim()
      ..defaultText = _defaultText.text.trim().isEmpty
          ? null
          : _defaultText.text.trim()
      ..defaultNumber = double.tryParse(_defaultNumber.text.trim())
      ..defaultOffsetDays = int.tryParse(_offset.text.trim());
    // Drop blank options so they don't reach the server as empty rows.
    _d.options.removeWhere((o) => o.label.trim().isEmpty && o.id == null);
    widget.onSubmit(_d);
  }

  @override
  Widget build(BuildContext context) {
    final f = m.customFields;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(f.name),
        TextField(
          controller: _name,
          autofocus: !_isEditing,
          textCapitalization: TextCapitalization.sentences,
          textDirection: _nameDir,
          decoration: _dec(hint: f.namePlaceholder),
        ),
        const SizedBox(height: 14),
        _label(f.type),
        const SizedBox(height: 4),
        _buildTypeSelector(),
        if (_isEditing)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 4),
            child: Text(
              f.typeLocked,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 14),
        _label(f.scope),
        const SizedBox(height: 4),
        _buildScopeSelector(),
        if (_hasHint) ...[
          const SizedBox(height: 14),
          _label(f.hint),
          TextField(
            controller: _hint,
            decoration: _dec(hint: f.hintPlaceholder),
          ),
        ],
        ..._buildTypeConfig(),
        ..._buildDefaultValue(),
        const SizedBox(height: 16),
        _buildActions(),
      ],
    );
  }

  bool get _hasHint =>
      _d.type == FieldType.text ||
      _d.type == FieldType.number ||
      _d.type == FieldType.select;

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final type in kFieldTypesInOrder)
          ChoiceChip(
            avatar: Icon(fieldTypeIcon(type), size: 18),
            label: Text(fieldTypeLabel(type)),
            selected: _d.type == type,
            // The type is immutable after creation.
            onSelected: _isEditing
                ? null
                : (_) => setState(() => _d.type = type),
          ),
      ],
    );
  }

  Widget _buildScopeSelector() {
    final knownIds = widget.lists.map((l) => l.id).toSet();
    final value = _d.listId == null || knownIds.contains(_d.listId)
        ? _d.listId
        : null;
    return DropdownButtonFormField<int?>(
      initialValue: value,
      isExpanded: true,
      decoration: _dec(),
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Text(m.customFields.allLists),
        ),
        for (final list in widget.lists)
          DropdownMenuItem<int?>(
            value: list.id,
            child: Text(
              list.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) => setState(() => _d.listId = v),
    );
  }

  List<Widget> _buildTypeConfig() {
    final f = m.customFields;
    switch (_d.type) {
      case FieldType.text:
        return [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(f.multiline),
            value: _d.multiline,
            onChanged: (v) => setState(() => _d.multiline = v),
          ),
        ];
      case FieldType.number:
      case FieldType.checkbox:
        return const [];
      case FieldType.select:
        return _buildOptionsEditor();
      case FieldType.date:
        return _buildDateConfig();
    }
  }

  List<Widget> _buildOptionsEditor() {
    final f = m.customFields;
    return [
      const SizedBox(height: 14),
      _label(f.options),
      for (var i = 0; i < _d.options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _optionCtrls[i],
                  decoration: _dec(hint: f.optionPlaceholder),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: f.removeOption,
                onPressed: _busy ? null : () => _removeOption(i),
              ),
            ],
          ),
        ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: _busy ? null : _addOption,
          icon: const Icon(Icons.add, size: 18),
          label: Text(f.addOption),
        ),
      ),
    ];
  }

  List<Widget> _buildDateConfig() {
    final f = m.customFields;
    return [
      const SizedBox(height: 14),
      _label(f.entryMode),
      const SizedBox(height: 4),
      SegmentedButton<FieldDateMode>(
        segments: [
          ButtonSegment(
            value: FieldDateMode.absolute,
            label: Text(f.dateAbsolute),
          ),
          ButtonSegment(
            value: FieldDateMode.relative,
            label: Text(f.dateRelative),
          ),
        ],
        selected: {_d.dateMode},
        onSelectionChanged: (s) => setState(() => _d.dateMode = s.first),
      ),
      if (_d.dateMode == FieldDateMode.relative) ...[
        const SizedBox(height: 14),
        _label(f.defaultOffset),
        TextField(
          controller: _offset,
          keyboardType: TextInputType.number,
          decoration: _dec(hint: f.defaultOffsetPlaceholder),
        ),
      ],
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(f.notifyDefault),
        value: _d.notifyDefault,
        onChanged: (v) => setState(() => _d.notifyDefault = v),
      ),
      if (_d.notifyDefault) ...[
        _label(f.leadTime),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          initialValue: _leadOptions.contains(_d.leadDays) ? _d.leadDays : 0,
          isExpanded: true,
          decoration: _dec(),
          items: [
            for (final days in _leadOptions)
              DropdownMenuItem(value: days, child: Text(_leadLabel(days))),
          ],
          onChanged: (v) => setState(() => _d.leadDays = v ?? 0),
        ),
        const SizedBox(height: 14),
      ],
      _label(f.overridePolicy),
      const SizedBox(height: 4),
      DropdownButtonFormField<FieldOverridePolicy>(
        initialValue: _d.overridePolicy,
        isExpanded: true,
        decoration: _dec(),
        items: [
          DropdownMenuItem(
            value: FieldOverridePolicy.fieldOnly,
            child: Text(f.overrideFieldOnly),
          ),
          DropdownMenuItem(
            value: FieldOverridePolicy.itemOverride,
            child: Text(f.overrideItem),
          ),
        ],
        onChanged: (v) => setState(
          () => _d.overridePolicy = v ?? FieldOverridePolicy.fieldOnly,
        ),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(f.stopWhenDone),
        value: _d.stopWhenDone,
        onChanged: (v) => setState(() => _d.stopWhenDone = v),
      ),
    ];
  }

  List<Widget> _buildDefaultValue() {
    final f = m.customFields;
    switch (_d.type) {
      case FieldType.text:
        return [
          const SizedBox(height: 14),
          _label(f.defaultValue),
          TextField(
            controller: _defaultText,
            decoration: _dec(hint: f.noDefault),
          ),
        ];
      case FieldType.number:
        return [
          const SizedBox(height: 14),
          _label(f.defaultValue),
          TextField(
            controller: _defaultNumber,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec(hint: f.noDefault),
          ),
        ];
      case FieldType.checkbox:
        return [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(f.defaultChecked),
            value: _d.defaultBool,
            onChanged: (v) => setState(() => _d.defaultBool = v),
          ),
        ];
      case FieldType.select:
        final saved = [
          for (final o in _d.options)
            if ((o.id ?? 0) > 0 && o.label.trim().isNotEmpty) o,
        ];
        if (saved.isEmpty) return const [];
        final value = saved.any((o) => o.id == _d.defaultOptionId)
            ? _d.defaultOptionId
            : null;
        return [
          const SizedBox(height: 14),
          _label(f.defaultValue),
          const SizedBox(height: 4),
          DropdownButtonFormField<int?>(
            initialValue: value,
            isExpanded: true,
            decoration: _dec(),
            items: [
              DropdownMenuItem<int?>(value: null, child: Text(f.noDefault)),
              for (final o in saved)
                DropdownMenuItem<int?>(
                  value: o.id,
                  child: Text(
                    o.label.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _d.defaultOptionId = v),
          ),
        ];
      case FieldType.date:
        return const [];
    }
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (_isEditing && widget.onDelete != null)
          TextButton.icon(
            onPressed: _busy ? null : widget.onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(m.common.delete),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          )
        else
          TextButton(
            onPressed: _busy ? null : widget.onCancel,
            child: Text(m.common.cancel),
          ),
        const Spacer(),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(m.customFields.done),
        ),
      ],
    );
  }

  String _leadLabel(int days) => switch (days) {
    0 => m.customFields.leadOnDay,
    1 => m.customFields.leadDay1,
    2 => m.customFields.leadDay2,
    3 => m.customFields.leadDay3,
    _ => m.customFields.leadWeek1,
  };

  Widget _label(String text) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: 6, top: 2),
    child: Text(
      text.toUpperCase(),
      style: fieldCardLabelStyle(Theme.of(context).colorScheme),
    ),
  );

  /// Filled, rounded input matching the app's field cards (surfaceContainer
  /// fill, radius-14 outlineVariant border, accent on focus).
  InputDecoration _dec({String? hint}) {
    final cs = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
    return InputDecoration(
      isDense: true,
      hintText: hint,
      filled: true,
      fillColor: cs.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: border(cs.outlineVariant, 1),
      enabledBorder: border(cs.outlineVariant, 1),
      focusedBorder: border(cs.primary, 1.5),
    );
  }
}

/// The user's answer to the remap-or-clear prompt: [clear] empties the values,
/// otherwise they move to [remapToId].
class _RemapChoice {
  final bool clear;
  final int? remapToId;

  const _RemapChoice({this.clear = false, this.remapToId});
}
