import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/custom_field.dart';
import 'package:pantry/services/custom_field_service.dart';
import 'package:pantry/utils/field_type_icons.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/views/checklists/form_components.dart';
import 'package:pantry/views/custom_fields/custom_field_drafts.dart';

/// The inline field-definition editor. Owns its own draft + text controllers,
/// and handles `select`-option removal (remap-or-clear for options in use)
/// itself. The field save/delete are delegated to the parent so they ride the
/// sync queue like every other write.
class CustomFieldEditor extends StatefulWidget {
  final int houseId;
  final List<ChecklistList> lists;

  /// The field being edited, or `null` when creating a new one.
  final FieldDefinition? initial;
  final void Function(FieldDraft draft) onSubmit;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;

  const CustomFieldEditor({
    super.key,
    required this.houseId,
    required this.lists,
    required this.initial,
    required this.onSubmit,
    required this.onCancel,
    this.onDelete,
  });

  @override
  State<CustomFieldEditor> createState() => _CustomFieldEditorState();
}

class _CustomFieldEditorState extends State<CustomFieldEditor> {
  static const _leadOptions = [0, 1, 2, 3, 7];

  late final TextEditingController _name;
  late final TextEditingController _hint;
  late final TextEditingController _defaultText;
  late final TextEditingController _defaultNumber;
  late final TextEditingController _offset;
  final List<TextEditingController> _optionCtrls = [];

  late FieldDraft _d;
  TextDirection _nameDir = TextDirection.ltr;

  /// Drives the submit button's enabled state — a field can't be saved
  /// nameless, and a dead button says so better than a silent no-op.
  bool _nameBlank = true;
  bool _busy = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _d = e == null
        ? FieldDraft(name: '', type: FieldType.text)
        : FieldDraft(
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
                OptionDraft(id: o.id, label: o.label, valueCount: o.valueCount),
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
    _nameBlank = _d.name.trim().isEmpty;
    _name.addListener(() {
      final dir = detectTextDirection(_name.text);
      final blank = _name.text.trim().isEmpty;
      if (dir != _nameDir || blank != _nameBlank) {
        setState(() {
          _nameDir = dir;
          _nameBlank = blank;
        });
      }
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
      _d.options.add(OptionDraft(id: null, label: ''));
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

  Future<RemapChoice?> _promptRemap(OptionDraft removing) {
    final targets = [
      for (final o in _d.options)
        if ((o.id ?? 0) > 0 && o.id != removing.id && o.label.trim().isNotEmpty)
          o,
    ];
    return showDialog<RemapChoice>(
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
              onPressed: () => Navigator.pop(ctx, RemapChoice(remapToId: o.id)),
              child: Text(m.customFields.remapMoveTo(o.label.trim())),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, const RemapChoice(clear: true)),
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
          onPressed: _busy || _nameBlank ? null : _submit,
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
