import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/list_recurrence.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';

import 'form_components.dart';
import 'switcher_widgets.dart';

class ListFormStage extends StatefulWidget {
  final ChecklistsController controller;
  final ChecklistList? existing;
  final VoidCallback onBack;
  final VoidCallback onSaved;

  const ListFormStage({
    super.key,
    required this.controller,
    this.existing,
    required this.onBack,
    required this.onSaved,
  });

  @override
  State<ListFormStage> createState() => _ListFormStageState();
}

class _ListFormStageState extends State<ListFormStage> {
  late final TextEditingController _nameCtrl;
  late String _color;
  late String _icon;
  late ListRecurrenceMode _recurrenceMode;
  late RecurrenceState _recurrence;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  // Per-list color only works on servers with the `checklist-color` feature;
  // older servers reject a sent color, so we hide the picker and let the
  // backend assign its default.
  bool get _supportsListColor => hasFeature('checklist-color');

  // Servers without the per-list recurrence default only ever store the
  // "one-time" flag, which the add-item form owns; there is nothing to pick
  // here, so the whole section is hidden.
  bool get _supportsRecurrenceDefault =>
      hasFeature(kListDefaultRecurrenceFeature);

  bool get _recurringDefault => _recurrenceMode == ListRecurrenceMode.recurring;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _icon = existing?.icon ?? 'cart';
    final fromExisting = existing?.color;
    _color = (fromExisting != null && kListColorSwatches.contains(fromExisting))
        ? fromExisting
        : kListColorSwatches.first;
    _recurrenceMode =
        existing?.defaultRecurrenceMode ?? ListRecurrenceMode.remember;
    _recurrence = RecurrenceState.fromRrule(
      existing?.defaultRrule,
      repeatFromCompletion: existing?.defaultRepeatFromCompletion ?? false,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _modeLabel(ListRecurrenceMode mode) => switch (mode) {
    ListRecurrenceMode.remember => m.checklists.listRecurrence.remember,
    ListRecurrenceMode.none => m.checklists.listRecurrence.none,
    ListRecurrenceMode.once => m.checklists.listRecurrence.once,
    ListRecurrenceMode.recurring => m.checklists.listRecurrence.recurring,
  };

  String _modeHint(ListRecurrenceMode mode) => switch (mode) {
    ListRecurrenceMode.remember => m.checklists.listRecurrence.rememberHint,
    ListRecurrenceMode.none => m.checklists.listRecurrence.noneHint,
    ListRecurrenceMode.once => m.checklists.listRecurrence.onceHint,
    ListRecurrenceMode.recurring => m.checklists.listRecurrence.recurringHint,
  };

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final existing = widget.existing;
      final mode = _supportsRecurrenceDefault ? _recurrenceMode : null;
      final rrule = _recurringDefault ? _recurrence.toRrule() : null;
      final repeatFromCompletion =
          _recurringDefault && _recurrence.repeatFromCompletion;
      if (existing != null) {
        await widget.controller.updateList(
          existing,
          name: name,
          icon: _icon,
          color: _supportsListColor ? _color : existing.color,
          defaultRecurrenceMode: mode,
          defaultRrule: rrule,
          defaultRepeatFromCompletion: repeatFromCompletion,
        );
      } else {
        await widget.controller.createList(
          name: name,
          icon: _icon,
          color: _supportsListColor ? _color : null,
          defaultRecurrenceMode: mode,
          defaultRrule: rrule,
          defaultRepeatFromCompletion: repeatFromCompletion,
        );
        if (!mounted) return;
        final fresh = widget.controller.lists.firstWhere((l) => l.name == name);
        await widget.controller.selectList(fresh);
      }
      if (!mounted) return;
      widget.onSaved();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? m.checklists.updateListFailed
                  : m.checklists.createListFailed,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedColor = parseHexColor(_color) ?? cs.primary;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 4),
                Text(
                  _isEdit
                      ? m.checklists.editListTitle
                      : m.checklists.newChecklist,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          // The stage lives in a bottom sheet sized to its content, so the
          // fields scroll among themselves rather than pushing the save button
          // off-screen.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: m.checklists.listName,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide(color: cs.primary, width: 1.5),
                      ),
                    ),
                  ),
                  if (_supportsListColor) ...[
                    const SizedBox(height: 16),
                    Text(
                      m.checklists.listColor.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final hex in kListColorSwatches)
                          SwitcherColorSwatch(
                            color: parseHexColor(hex)!,
                            selected: hex == _color,
                            onTap: () => setState(() => _color = hex),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    m.checklists.listIcon.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (PlatformInfo.isDesktopHost)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in checklistIconMap.entries)
                          IconChip(
                            icon: entry.value,
                            selected: entry.key == _icon,
                            color: selectedColor,
                            onTap: () => setState(() => _icon = entry.key),
                          ),
                      ],
                    )
                  else
                    SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final entry in checklistIconMap.entries) ...[
                            IconChip(
                              icon: entry.value,
                              selected: entry.key == _icon,
                              color: selectedColor,
                              onTap: () => setState(() => _icon = entry.key),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  if (_supportsRecurrenceDefault) ...[
                    const SizedBox(height: 16),
                    Text(
                      m.checklists.listRecurrence.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final (index, mode)
                        in ListRecurrenceMode.values.indexed) ...[
                      if (index > 0) const SizedBox(height: 8),
                      LifecycleRow(
                        label: _modeLabel(mode),
                        body: _modeHint(mode),
                        selected: mode == _recurrenceMode,
                        onTap: () => setState(() => _recurrenceMode = mode),
                      ),
                    ],
                    if (_recurringDefault) ...[
                      const SizedBox(height: 10),
                      RecurrenceInline(
                        state: _recurrence,
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: _saving ? null : _submit,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_saving)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(
                      _isEdit ? Icons.check : Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _isEdit
                        ? m.checklists.saveListButton
                        : m.checklists.createListButton,
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
        ],
      ),
    );
  }
}
