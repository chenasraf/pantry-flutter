import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/list_recurrence.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/list_kind_strings.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry/theme/app_theme.dart';
import 'package:pantry/utils/app_toast.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';

import 'form_components.dart';
import 'item_defaults_view.dart';
import 'switcher_widgets.dart';
import 'template_attachments_field.dart';

class ListFormStage extends StatefulWidget {
  final ChecklistsController controller;

  /// The kind created, or [existing]'s kind.
  final ListKind kind;
  final ChecklistList? existing;
  final VoidCallback onBack;
  final VoidCallback onSaved;

  const ListFormStage({
    super.key,
    required this.controller,
    this.kind = ListKind.checklist,
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

  /// Whether the attachments section shows: once loaded when editing, right
  /// away when creating. Attaching happens on the server, so offline it stays
  /// hidden.
  bool _attachmentsReady = false;
  List<int> _templateIds = const [];
  List<int> _everyListTemplateIds = const [];
  TemplateLists _templateLists = const TemplateLists();

  /// What was attached when the form opened, to save only a change.
  List<int> _initialTemplateIds = const [];
  TemplateLists _initialTemplateLists = const TemplateLists();

  bool get _isEdit => widget.existing != null;

  // Per-list color only works on servers with the `checklist-color` feature;
  // older servers reject a sent color, so we hide the picker and let the
  // backend assign its default.
  bool get _supportsListColor => ServerFeature.checklistColor;

  // Servers without the per-list recurrence default only ever store the
  // "one-time" flag, which the add-item form owns; there is nothing to pick
  // here, so the whole section is hidden.
  bool get _supportsRecurrenceDefault =>
      ServerFeature.listDefaultRecurrence &&
      !_managesItemDefaults &&
      widget.kind.isChecklist;

  /// The recurrence default is one of the list's item defaults, edited on their
  /// own screen with the rest of them.
  bool get _managesItemDefaults => ServerFeature.listItemDefaults;

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
    if (ServerFeature.templates && SyncManager.instance.isOnline) {
      if (existing == null) {
        _attachmentsReady = true;
      } else if (existing.id > 0) {
        _loadAttachments(existing);
      }
    }
  }

  Future<void> _loadAttachments(ChecklistList list) async {
    try {
      if (list.kind == ListKind.template) {
        final value = await widget.controller.loadTemplateLists(list.id);
        _templateLists = _initialTemplateLists = value;
      } else {
        final attached = await widget.controller.loadAttachedTemplates(list.id);
        _templateIds = _initialTemplateIds = attached.templateIds;
        _everyListTemplateIds = attached.everyListTemplateIds;
      }
      if (mounted) setState(() => _attachmentsReady = true);
    } catch (e) {
      // Left hidden; the rest of the form still saves.
      debugPrint('[ListFormStage] Failed to load attachments: $e');
    }
  }

  /// Saves the attachments onto [list] when they changed. Failing leaves the
  /// list itself saved.
  Future<void> _saveAttachments(ChecklistList list) async {
    if (!_attachmentsReady || list.id <= 0) return;
    try {
      if (list.kind == ListKind.template) {
        final changed =
            _templateLists.everyList != _initialTemplateLists.everyList ||
            !_sameIds(_templateLists.listIds, _initialTemplateLists.listIds);
        if (changed) {
          await widget.controller.setTemplateLists(list.id, _templateLists);
        }
      } else if (!_sameIds(_templateIds, _initialTemplateIds)) {
        await widget.controller.setAttachedTemplates(list.id, _templateIds);
      }
    } catch (e) {
      debugPrint('[ListFormStage] Failed to save attachments: $e');
      showAppToast(message: m.templates.attachFailed, kind: ToastKind.error);
    }
  }

  static bool _sameIds(List<int> a, List<int> b) =>
      a.length == b.length && a.toSet().containsAll(b);

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
        await _saveAttachments(existing);
      } else {
        final fresh = await widget.controller.createList(
          kind: widget.kind,
          name: name,
          icon: _icon,
          color: _supportsListColor ? _color : null,
          defaultRecurrenceMode: mode,
          defaultRrule: rrule,
          defaultRepeatFromCompletion: repeatFromCompletion,
        );
        await _saveAttachments(fresh);
        if (!mounted) return;
        await widget.controller.selectList(fresh);
      }
      if (!mounted) return;
      widget.onSaved();
    } catch (_) {
      if (mounted) {
        showAppToast(
          message: _isEdit
              ? m.checklists.updateListFailed
              : m.checklists.createListFailed,
          kind: ToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surfaces = AppSurfaces.of(context);
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
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 4),
                Text(
                  _isEdit
                      ? (ServerFeature.listKinds
                            ? widget.kind.strings.editTitle
                            : m.checklists.editListTitle)
                      : widget.kind.strings.newList,
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
          // off-screen — and give way further to the keyboard, which takes its
          // height out of the same sheet.
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                // Room above the name field for its floating label, which the
                // scroll view would otherwise clip.
                padding: const EdgeInsetsDirectional.only(top: 8),
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
                    if (_attachmentsReady) ...[
                      const SizedBox(height: 16),
                      if ((widget.existing?.kind ?? widget.kind) ==
                          ListKind.template)
                        TemplateListsField(
                          controller: widget.controller,
                          value: _templateLists,
                          onChanged: (v) => setState(() => _templateLists = v),
                        )
                      else
                        ListTemplatesField(
                          controller: widget.controller,
                          templateIds: _templateIds,
                          everyListTemplateIds: _everyListTemplateIds,
                          onChanged: (ids) =>
                              setState(() => _templateIds = ids),
                        ),
                    ],
                    if (_managesItemDefaults && widget.existing != null) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(SurfaceRadius.card),
                        onTap: () => showItemDefaults(
                          context,
                          widget.controller,
                          widget.existing!,
                        ),
                        child: Ink(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            14,
                            12,
                            10,
                            12,
                          ),
                          decoration: surfaces.card(),
                          child: Row(
                            children: [
                              Icon(Icons.tune, color: cs.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.checklists.itemDefaults.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      m.checklists.itemDefaults.intro,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: cs.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: _saving ? null : _submit,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: surfaces.primaryButton(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_saving)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: surfaces.onAccent,
                      ),
                    )
                  else
                    Icon(
                      _isEdit ? Icons.check : Icons.add,
                      color: surfaces.onAccent,
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _isEdit
                        ? m.checklists.saveListButton
                        : m.checklists.createListButton,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: surfaces.onAccent,
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
