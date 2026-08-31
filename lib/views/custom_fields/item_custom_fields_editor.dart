import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/custom_field.dart';
import 'package:pantry/services/custom_field_service.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/views/checklists/form_components.dart';

/// The per-item "Custom fields" value-filling section. Renders one control per
/// applicable field (house-wide ∪ the item's list), mirroring the web
/// `ItemCustomFieldsEditor`. Owns its own draft state and reports the composed
/// [FieldValue] list through [onChanged]; the parent only stores the result and
/// sends it when the item is saved.
class ItemCustomFieldsEditor extends StatefulWidget {
  final int houseId;

  /// The item's list, so list-scoped fields apply. `null` = no list in context
  /// (only house-wide fields apply).
  final int? listId;
  final List<FieldValue> initial;
  final void Function(List<FieldValue> values) onChanged;

  const ItemCustomFieldsEditor({
    super.key,
    required this.houseId,
    required this.listId,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<ItemCustomFieldsEditor> createState() => _ItemCustomFieldsEditorState();
}

class _ItemCustomFieldsEditorState extends State<ItemCustomFieldsEditor> {
  static const _leadOptions = [0, 1, 2, 3, 7];

  List<FieldDefinition> _fields = [];
  final Map<int, _ValueDraft> _drafts = {};
  final Map<int, TextEditingController> _textCtrls = {};
  final Map<int, TextEditingController> _numberCtrls = {};
  final Map<int, TextEditingController> _offsetCtrls = {};

  @override
  void initState() {
    super.initState();
    final cached = CustomFieldService.instance.getCached(widget.houseId);
    if (cached != null) _applyDefs(cached);
    _load();
  }

  @override
  void dispose() {
    for (final c in _textCtrls.values) {
      c.dispose();
    }
    for (final c in _numberCtrls.values) {
      c.dispose();
    }
    for (final c in _offsetCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final defs = await CustomFieldService.instance.getFields(widget.houseId);
      if (mounted) setState(() => _applyDefs(defs));
    } catch (_) {
      // Offline or transient — keep whatever the cache seeded.
    }
  }

  /// Filter to the applicable fields and ensure a draft + controllers exist for
  /// each. Safe to call again when definitions arrive from the network: drafts
  /// already in hand are preserved (so edits made before the load finishes
  /// aren't clobbered), only newly-applicable fields are seeded from the
  /// initial values, and controllers for fields that dropped out are released.
  void _applyDefs(List<FieldDefinition> defs) {
    _fields = CustomFieldService.sortFields(
      defs.where((f) => f.listId == null || f.listId == widget.listId),
    );
    final byField = {for (final v in widget.initial) v.fieldId: v};
    final applicableIds = {for (final f in _fields) f.id};

    for (final field in _fields) {
      if (_drafts.containsKey(field.id)) continue;
      final existing = byField[field.id];
      final d = existing != null
          ? _ValueDraft.fromValue(existing)
          : _ValueDraft.empty();
      _drafts[field.id] = d;
      _textCtrls[field.id] = TextEditingController(text: d.text);
      _numberCtrls[field.id] = TextEditingController(text: d.number);
      _offsetCtrls[field.id] = TextEditingController(
        text: d.offsetDays?.toString() ?? '',
      );
    }

    // Release state for fields that are no longer applicable.
    for (final id in _drafts.keys.toList()) {
      if (applicableIds.contains(id)) continue;
      _drafts.remove(id);
      _textCtrls.remove(id)?.dispose();
      _numberCtrls.remove(id)?.dispose();
      _offsetCtrls.remove(id)?.dispose();
    }
  }

  _ValueDraft _draftFor(int fieldId) =>
      _drafts.putIfAbsent(fieldId, _ValueDraft.empty);

  /// Compose the filled values and hand them to the parent. A field with no
  /// value produces no row (mirrors the server's upsert semantics).
  void _emit() {
    final out = <FieldValue>[];
    for (final field in _fields) {
      final d = _drafts[field.id];
      if (d == null) continue;
      int? valueDate;
      String? valueText;
      double? valueNumber;
      var valueBool = false;
      int? valueOptionId;
      switch (field.type) {
        case FieldType.text:
          if (d.text.trim().isEmpty) continue;
          valueText = d.text;
        case FieldType.number:
          final n = double.tryParse(d.number.trim());
          if (n == null) continue;
          valueNumber = n;
        case FieldType.checkbox:
          if (!d.boolValue) continue;
          valueBool = true;
        case FieldType.select:
          if (d.optionId == null) continue;
          valueOptionId = d.optionId;
        case FieldType.date:
          if (d.date == null) continue;
          final dt = d.date!;
          valueDate =
              DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch ~/
              1000;
      }
      out.add(
        FieldValue(
          fieldId: field.id,
          valueText: valueText,
          valueNumber: valueNumber,
          valueBool: valueBool,
          valueDate: valueDate,
          valueOptionId: valueOptionId,
          offsetDays: d.offsetDays,
          notifyOverride: d.notifyOverride,
          notifyEnabled: d.notifyEnabled,
          notifyLeadDays: d.notifyLeadDays,
        ),
      );
    }
    widget.onChanged(out);
  }

  /// Local midnight, [offset] days from today.
  DateTime _anchor(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: offset));
  }

  @override
  Widget build(BuildContext context) {
    if (_fields.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final field in _fields) ...[
          _buildField(field),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildField(FieldDefinition field) {
    return switch (field.type) {
      FieldType.text => _buildText(field),
      FieldType.number => _buildNumber(field),
      FieldType.checkbox => _buildCheckbox(field),
      FieldType.select => _buildSelect(field),
      FieldType.date => _buildDate(field),
    };
  }

  Widget _buildText(FieldDefinition field) {
    return LabeledFieldCard(
      label: field.name,
      child: TextField(
        controller: _textCtrls[field.id],
        minLines: field.multiline ? 2 : 1,
        maxLines: field.multiline ? 5 : 1,
        textDirection: detectTextDirection(_textCtrls[field.id]?.text),
        style: _valueStyle,
        decoration: _bare(hint: field.hint),
        onChanged: (v) {
          _draftFor(field.id).text = v;
          _emit();
        },
      ),
    );
  }

  Widget _buildNumber(FieldDefinition field) {
    return LabeledFieldCard(
      label: field.name,
      child: TextField(
        controller: _numberCtrls[field.id],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: _valueStyle,
        decoration: _bare(hint: field.hint),
        onChanged: (v) {
          _draftFor(field.id).number = v;
          _emit();
        },
      ),
    );
  }

  Widget _buildCheckbox(FieldDefinition field) {
    final d = _draftFor(field.id);
    return LabeledFieldCard(
      label: field.name,
      trailing: Switch(
        value: d.boolValue,
        onChanged: (v) {
          setState(() => d.boolValue = v);
          _emit();
        },
      ),
    );
  }

  Widget _buildSelect(FieldDefinition field) {
    final d = _draftFor(field.id);
    final cs = Theme.of(context).colorScheme;
    final value = field.options.any((o) => o.id == d.optionId)
        ? d.optionId
        : null;
    return LabeledFieldCard(
      label: field.name,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          isExpanded: true,
          isDense: true,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(12),
          style: _valueStyle,
          hint: Text(
            field.hint ?? m.customFields.noValue,
            style: _valueStyle?.copyWith(color: cs.onSurfaceVariant),
          ),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(
                m.customFields.noValue,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
            for (final o in field.options)
              DropdownMenuItem<int?>(
                value: o.id,
                child: Text(
                  o.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (v) {
            setState(() => d.optionId = v);
            _emit();
          },
        ),
      ),
    );
  }

  Widget _buildDate(FieldDefinition field) {
    final d = _draftFor(field.id);
    final cs = Theme.of(context).colorScheme;
    if (field.dateMode == FieldDateMode.relative) {
      return LabeledFieldCard(
        label: field.name,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _offsetCtrls[field.id],
              keyboardType: TextInputType.number,
              style: _valueStyle,
              decoration: _bare(hint: m.customFields.daysFromToday),
              onChanged: (v) {
                final s = v.trim();
                setState(() {
                  if (s.isEmpty) {
                    d.offsetDays = null;
                    d.date = null;
                  } else {
                    final n = int.tryParse(s);
                    if (n != null) {
                      d.offsetDays = n;
                      d.date = _anchor(n);
                    }
                  }
                });
                _emit();
              },
            ),
            if (d.date != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.customFields.due(
                          MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(d.date!),
                        ),
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        if (d.offsetDays == null) return;
                        setState(() => d.date = _anchor(d.offsetDays!));
                        _emit();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(m.customFields.reanchor),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            ..._reminderSection(field),
          ],
        ),
      );
    }
    // Absolute date: a tappable row opening the platform date picker, with the
    // reminder controls tucked into the same card below.
    return LabeledFieldCard(
      label: field.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _pickDate(field),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    d.date != null
                        ? MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(d.date!)
                        : m.customFields.noValue,
                    style: d.date == null
                        ? _valueStyle?.copyWith(color: cs.onSurfaceVariant)
                        : _valueStyle,
                  ),
                ),
                if (d.date != null)
                  InkResponse(
                    onTap: () {
                      setState(() => d.date = null);
                      _emit();
                    },
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  )
                else
                  Icon(Icons.event, size: 18, color: cs.onSurfaceVariant),
              ],
            ),
          ),
          ..._reminderSection(field),
        ],
      ),
    );
  }

  Future<void> _pickDate(FieldDefinition field) async {
    final d = _draftFor(field.id);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: d.date ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    setState(() => d.date = DateTime(picked.year, picked.month, picked.day));
    _emit();
  }

  bool _showReminderOverride(FieldDefinition field) =>
      field.type == FieldType.date &&
      field.overridePolicy == FieldOverridePolicy.itemOverride &&
      _draftFor(field.id).date != null;

  /// The per-item reminder controls, embedded *inside* the date field's card
  /// (below the date) so they read as part of that field rather than a separate
  /// one. Empty when the field doesn't allow an item override or no date is set.
  List<Widget> _reminderSection(FieldDefinition field) {
    if (!_showReminderOverride(field)) return const [];
    final d = _draftFor(field.id);
    final on = d.notifyOverride ? d.notifyEnabled : field.notifyDefault;
    final lead = d.notifyOverride
        ? (d.notifyLeadDays ?? field.leadDays)
        : field.leadDays;
    final differs =
        d.notifyOverride &&
        (d.notifyEnabled != field.notifyDefault ||
            (d.notifyEnabled &&
                (d.notifyLeadDays ?? field.leadDays) != field.leadDays));
    final cs = Theme.of(context).colorScheme;
    return [
      Padding(
        padding: const EdgeInsetsDirectional.only(top: 10, bottom: 2),
        child: Divider(height: 1, color: cs.outlineVariant),
      ),
      Row(
        children: [
          Icon(Icons.notifications_none, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              m.customFields.remindMe,
              style: _valueStyle?.copyWith(color: cs.onSurface),
            ),
          ),
          Switch(
            value: on,
            onChanged: (v) {
              setState(() {
                d.notifyOverride = true;
                d.notifyEnabled = v;
                if (v && d.notifyLeadDays == null) {
                  d.notifyLeadDays = field.leadDays;
                }
              });
              _emit();
            },
          ),
        ],
      ),
      if (on)
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _leadOptions.contains(lead) ? lead : 0,
            isExpanded: true,
            isDense: true,
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(12),
            style: _valueStyle,
            items: [
              for (final days in _leadOptions)
                DropdownMenuItem(value: days, child: Text(_leadLabel(days))),
            ],
            onChanged: (v) {
              setState(() {
                d.notifyOverride = true;
                d.notifyEnabled = true;
                d.notifyLeadDays = v ?? 0;
              });
              _emit();
            },
          ),
        ),
      if (on && differs)
        Row(
          children: [
            Expanded(
              child: Text(
                m.customFields.customReminder,
                style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  d.notifyOverride = false;
                  d.notifyEnabled = false;
                  d.notifyLeadDays = null;
                });
                _emit();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(m.customFields.useFieldDefault),
            ),
          ],
        ),
    ];
  }

  String _leadLabel(int days) => switch (days) {
    0 => m.customFields.leadOnDay,
    1 => m.customFields.leadDay1,
    2 => m.customFields.leadDay2,
    3 => m.customFields.leadDay3,
    _ => m.customFields.leadWeek1,
  };

  TextStyle? get _valueStyle =>
      const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500);

  /// Borderless input styling — the [LabeledFieldCard] provides the frame.
  InputDecoration _bare({String? hint}) => const InputDecoration(
    isCollapsed: true,
    border: InputBorder.none,
    contentPadding: EdgeInsets.zero,
  ).copyWith(hintText: hint);
}

/// Mutable per-field editing state, keyed by field id.
class _ValueDraft {
  String text;
  String number;
  bool boolValue;
  int? optionId;
  DateTime? date;
  int? offsetDays;
  bool notifyOverride;
  bool notifyEnabled;
  int? notifyLeadDays;

  _ValueDraft({
    this.text = '',
    this.number = '',
    this.boolValue = false,
    this.optionId,
    this.date,
    this.offsetDays,
    this.notifyOverride = false,
    this.notifyEnabled = false,
    this.notifyLeadDays,
  });

  factory _ValueDraft.empty() => _ValueDraft();

  factory _ValueDraft.fromValue(FieldValue v) => _ValueDraft(
    text: v.valueText ?? '',
    number: v.valueNumber != null ? _trimNumber(v.valueNumber!) : '',
    boolValue: v.valueBool,
    optionId: v.valueOptionId,
    date: v.valueDate != null
        ? DateTime.fromMillisecondsSinceEpoch(v.valueDate! * 1000)
        : null,
    offsetDays: v.offsetDays,
    notifyOverride: v.notifyOverride,
    notifyEnabled: v.notifyEnabled,
    notifyLeadDays: v.notifyLeadDays,
  );

  /// Render a stored number without a trailing `.0` for whole values.
  static String _trimNumber(double n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toString();
}
