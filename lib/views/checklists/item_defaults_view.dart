import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/custom_field.dart';
import 'package:pantry_core/models/item_defaults.dart';
import 'package:pantry_core/models/item_lifecycle.dart';
import 'package:pantry_core/models/item_start_values.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry_core/utils/quantity.dart';
import 'package:pantry/theme/app_theme.dart';
import 'package:pantry/views/custom_fields/item_custom_fields_editor.dart';

import 'checklists_controller.dart';
import 'item_compose_trays.dart';
import 'item_defaults_draft.dart';
import 'item_draft.dart';

/// Open the item defaults of [list]: a dialog on desktop, a full screen on a
/// phone.
Future<void> showItemDefaults(
  BuildContext context,
  ChecklistsController controller,
  ChecklistList list,
) {
  final view = ItemDefaultsView(controller: controller, list: list);
  if (PlatformInfo.isDesktopHost) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
          child: view,
        ),
      ),
    );
  }
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => view));
}

enum _Section { recurrence, category, stores, labels, quantity, fields }

/// Edits what new items on a list start with. Mirrors the composer: a chip per
/// part of an item, and the open chip shows whether that part is left empty,
/// pinned to a value, or follows the last item added.
class ItemDefaultsView extends StatefulWidget {
  final ChecklistsController controller;
  final ChecklistList list;

  const ItemDefaultsView({
    super.key,
    required this.controller,
    required this.list,
  });

  @override
  State<ItemDefaultsView> createState() => _ItemDefaultsViewState();
}

class _ItemDefaultsViewState extends State<ItemDefaultsView> {
  late final ItemDefaultsDraft _draft = ItemDefaultsDraft.from(
    widget.list.itemDefaults,
  );

  /// Backs the recurrence tray, which edits an [ItemDraft]'s lifecycle and
  /// schedule.
  late final ItemDraft _typeDraft = ItemDraft()
    ..applyRecurrence(_draft.recurrence);
  late final TextEditingController _qtyCtrl = TextEditingController(
    text: _draft.quantity,
  );
  _Section? _open;

  ChecklistsController get _controller => widget.controller;
  ChecklistList get _list => widget.list;

  bool get _canEdit =>
      _list.canEditSettingsWith(_controller.permissions.canEditLists);

  bool get _storesEnabled => hasFeature('stores');
  bool get _labelsEnabled => hasFeature('labels');

  List<FieldDefinition> get _fields => [
    if (hasFeature(kCustomFieldsFeature))
      for (final f in _controller.customFieldDefs)
        if (f.listId == null || f.listId == _list.id) f,
  ];

  List<_Section> get _sections => [
    _Section.recurrence,
    _Section.category,
    if (_storesEnabled) _Section.stores,
    if (_labelsEnabled) _Section.labels,
    _Section.quantity,
    if (_fields.isNotEmpty) _Section.fields,
  ];

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  String? _key(_Section s) => switch (s) {
    _Section.recurrence => ItemDefaults.recurrenceKey,
    _Section.category => ItemDefaults.categoryKey,
    _Section.stores => ItemDefaults.storesKey,
    _Section.labels => ItemDefaults.labelsKey,
    _Section.quantity => ItemDefaults.quantityKey,
    _Section.fields => null,
  };

  String _label(_Section s) {
    final c = m.checklists.compose;
    return switch (s) {
      _Section.recurrence => c.chipType,
      _Section.category => c.chipCategory,
      _Section.stores => c.chipStore,
      _Section.labels => c.chipLabel,
      _Section.quantity => c.chipQuantity,
      _Section.fields => m.customFields.manageTitle,
    };
  }

  /// What the pinned value of [s] reads as on its chip, or `null` when there
  /// is nothing to show.
  String? _summary(_Section s) {
    String? joined(Iterable<String> names) =>
        names.isEmpty ? null : names.join(', ');
    switch (s) {
      case _Section.recurrence:
        final t = m.checklists.itemTypes;
        return switch (_typeDraft.lifecycle) {
          ItemLifecycle.staple => t.staple,
          ItemLifecycle.once => t.onceTime,
          ItemLifecycle.recurring => t.recurring,
        };
      case _Section.category:
        final id = _draft.categoryId;
        return _controller
            .categoriesForList(_list.id)
            .where((c) => c.id == id)
            .firstOrNull
            ?.name;
      case _Section.stores:
        return joined([
          for (final s in _controller.sortedStores)
            if (_draft.storeIds.contains(s.id)) s.name,
        ]);
      case _Section.labels:
        return joined([
          for (final l in _controller.labelsForList(_list.id))
            if (_draft.labelIds.contains(l.id)) l.name,
        ]);
      case _Section.quantity:
        final q = _draft.quantity.trim();
        return q.isEmpty ? null : q;
      case _Section.fields:
        return null;
    }
  }

  String _chipText(_Section s) {
    if (s == _Section.fields) {
      final set = _draft.fields.values
          .where((f) => f.mode != ItemDefaultMode.none)
          .length;
      return set > 0 ? m.checklists.itemDefaults.fieldsSet(set) : _label(s);
    }
    return switch (_draft.modeOf(_key(s)!)) {
      ItemDefaultMode.none => _label(s),
      ItemDefaultMode.remember => m.checklists.itemDefaults.lastUsed(_label(s)),
      ItemDefaultMode.fixed => _summary(s) ?? _label(s),
    };
  }

  bool _isSet(_Section s) => s == _Section.fields
      ? _draft.fields.values.any((f) => f.mode != ItemDefaultMode.none)
      : _draft.modeOf(_key(s)!) != ItemDefaultMode.none;

  void _save() {
    final patch = _draft.patchAgainst(_list.itemDefaults);
    if (patch.isNotEmpty) _controller.updateItemDefaults(_list.id, patch);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = m.checklists.itemDefaults;
    final open = _open;
    return Scaffold(
      appBar: AppBar(
        title: Text(d.title),
        actions: [
          if (_canEdit)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: TextButton(onPressed: _save, child: Text(m.common.save)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 24),
        children: [
          Text(d.intro, style: TextStyle(color: cs.onSurfaceVariant)),
          if (!_canEdit) ...[
            const SizedBox(height: 8),
            Text(
              d.readOnly,
              style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _sections)
                _DefaultChip(
                  label: _chipText(s),
                  set: _isSet(s),
                  open: _open == s,
                  onTap: () => setState(() => _open = _open == s ? null : s),
                ),
            ],
          ),
          if (open != null) ...[
            const SizedBox(height: 14),
            AbsorbPointer(absorbing: !_canEdit, child: _sectionBody(open)),
          ],
        ],
      ),
    );
  }

  Widget _sectionBody(_Section s) {
    if (s == _Section.fields) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, field) in _fields.indexed) ...[
            if (i > 0) const SizedBox(height: 14),
            _fieldBody(field),
          ],
        ],
      );
    }
    final key = _key(s)!;
    final mode = _draft.modeOf(key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModeControl(
          mode: mode,
          allowRemember: s != _Section.quantity,
          enabled: _canEdit,
          onChanged: (next) => setState(() => _draft.modes[key] = next),
        ),
        const SizedBox(height: 8),
        _ModeHint(mode: mode),
        if (mode == ItemDefaultMode.fixed) ...[
          const SizedBox(height: 12),
          _editor(s),
        ],
      ],
    );
  }

  Widget _editor(_Section s) {
    switch (s) {
      case _Section.recurrence:
        return TypeTray(
          draft: _typeDraft,
          onChanged: () =>
              setState(() => _draft.recurrence = _typeDraft.usedRecurrence),
        );
      case _Section.category:
        return CategoryTray(
          categories: _controller.categoriesForList(_list.id),
          selectedId: _draft.categoryId,
          onSelected: (id) => setState(() => _draft.categoryId = id),
        );
      case _Section.stores:
        return StoreTray(
          stores: _controller.sortedStores,
          selectedIds: _draft.storeIds.toSet(),
          onToggle: (id) => setState(() {
            _draft.storeIds = _draft.storeIds.contains(id)
                ? [..._draft.storeIds.where((s) => s != id)]
                : [..._draft.storeIds, id];
          }),
        );
      case _Section.labels:
        return LabelTray(
          labels: _controller.labelsForList(_list.id),
          selectedIds: _draft.labelIds.toSet(),
          onToggle: (id) => setState(() {
            _draft.labelIds = _draft.labelIds.contains(id)
                ? [..._draft.labelIds.where((l) => l != id)]
                : [..._draft.labelIds, id];
          }),
        );
      case _Section.quantity:
        void step(int dir) {
          final next = stepQuantity(_qtyCtrl.text, dir);
          _qtyCtrl.text = next;
          setState(() => _draft.quantity = next);
        }
        return QuantityTray(
          controller: _qtyCtrl,
          onChanged: (v) => setState(() => _draft.quantity = v),
          onMinus: () => step(-1),
          onPlus: () => step(1),
        );
      case _Section.fields:
        return const SizedBox.shrink();
    }
  }

  Widget _fieldBody(FieldDefinition field) {
    final cs = Theme.of(context).colorScheme;
    final d = m.checklists.itemDefaults;
    final entry = _draft.fields[field.id];
    final mode = entry?.mode ?? ItemDefaultMode.none;
    final own = _ownDefault(field);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 13),
      decoration: AppSurfaces.of(context).card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            field.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _ModeControl(
            mode: mode,
            allowRemember: true,
            fieldDefault: true,
            enabled: _canEdit,
            onChanged: (next) => setState(
              () => _draft.fields[field.id] = (mode: next, value: entry?.value),
            ),
          ),
          const SizedBox(height: 8),
          if (mode == ItemDefaultMode.none)
            Text(
              own == null ? d.inheritEmpty : d.inheritValue(own),
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            )
          else
            _ModeHint(mode: mode),
          if (mode == ItemDefaultMode.fixed) ...[
            const SizedBox(height: 10),
            ItemCustomFieldsEditor(
              key: ValueKey('item-default-field-${field.id}'),
              houseId: _list.houseId,
              listId: _list.id,
              initial: [
                if (entry?.value != null)
                  fieldValueFromDefault(field.id, entry!.value!),
              ],
              onlyFieldIds: {field.id},
              valuesOnly: true,
              onChanged: (values) => setState(
                () => _draft.fields[field.id] = (
                  mode: ItemDefaultMode.fixed,
                  value: fieldDefaultFromValue(field, values.firstOrNull),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The field definition's own default as text, or `null` when it has none.
  String? _ownDefault(FieldDefinition field) {
    final offset = field.defaultOffsetDays;
    if (field.type == FieldType.date &&
        field.dateMode == FieldDateMode.relative &&
        offset != null) {
      return m.checklists.itemDefaults.inDays(offset);
    }
    final seed = field.seedValue();
    if (seed == null) return null;
    return switch (field.type) {
      FieldType.text => seed.valueText,
      FieldType.number => seed.valueNumber?.toString(),
      FieldType.checkbox => m.checklists.itemDefaults.checked,
      FieldType.select =>
        field.options
            .where((o) => o.id == seed.valueOptionId)
            .firstOrNull
            ?.label,
      FieldType.date => null,
    };
  }
}

class _DefaultChip extends StatelessWidget {
  final String label;
  final bool set;
  final bool open;
  final VoidCallback onTap;

  const _DefaultChip({
    required this.label,
    required this.set,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surfaces = AppSurfaces.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SurfaceRadius.chip),
      child: Ink(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: set || open
            ? surfaces.chip(tint: cs.primary, selected: open)
            : surfaces.chip(),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: set ? cs.primary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Not set / Fixed / Remember last. A custom field calls "not set" its own
/// default, because that is what a new item then starts with.
class _ModeControl extends StatelessWidget {
  final ItemDefaultMode mode;
  final bool allowRemember;
  final bool fieldDefault;
  final bool enabled;
  final ValueChanged<ItemDefaultMode> onChanged;

  const _ModeControl({
    required this.mode,
    required this.allowRemember,
    required this.enabled,
    required this.onChanged,
    this.fieldDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    final d = m.checklists.itemDefaults;
    return SegmentedButton<ItemDefaultMode>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: ItemDefaultMode.none,
          label: Text(fieldDefault ? d.modeFieldDefault : d.modeNone),
        ),
        ButtonSegment(value: ItemDefaultMode.fixed, label: Text(d.modeFixed)),
        if (allowRemember)
          ButtonSegment(
            value: ItemDefaultMode.remember,
            label: Text(d.modeRemember),
          ),
      ],
      selected: {mode},
      onSelectionChanged: enabled ? (s) => onChanged(s.single) : null,
    );
  }
}

class _ModeHint extends StatelessWidget {
  final ItemDefaultMode mode;

  const _ModeHint({required this.mode});

  @override
  Widget build(BuildContext context) {
    final d = m.checklists.itemDefaults;
    return Text(
      switch (mode) {
        ItemDefaultMode.none => d.noneHint,
        ItemDefaultMode.fixed => d.fixedHint,
        ItemDefaultMode.remember => d.rememberHint,
      },
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
