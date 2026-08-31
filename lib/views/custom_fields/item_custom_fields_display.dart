import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/custom_field.dart';
import 'package:pantry/services/custom_field_service.dart';
import 'package:pantry/utils/field_type_icons.dart';
import 'package:pantry/utils/text_direction.dart';

/// Read-only display of an item's custom-field values, one row per filled
/// field, resolved against the field definitions (for names, option labels and
/// per-type formatting). Styled to match the item detail's fact tiles; renders
/// nothing when the item has no resolvable values.
class ItemCustomFieldsDisplay extends StatefulWidget {
  final int houseId;
  final List<FieldValue> values;

  const ItemCustomFieldsDisplay({
    super.key,
    required this.houseId,
    required this.values,
  });

  @override
  State<ItemCustomFieldsDisplay> createState() =>
      _ItemCustomFieldsDisplayState();
}

class _ItemCustomFieldsDisplayState extends State<ItemCustomFieldsDisplay> {
  Map<int, FieldDefinition> _defs = {};

  @override
  void initState() {
    super.initState();
    final cached = CustomFieldService.instance.getCached(widget.houseId);
    if (cached != null) _defs = {for (final f in cached) f.id: f};
    _load();
  }

  Future<void> _load() async {
    try {
      final defs = await CustomFieldService.instance.getFields(widget.houseId);
      if (mounted) setState(() => _defs = {for (final f in defs) f.id: f});
    } catch (_) {
      // Offline or transient — keep whatever the cache seeded.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.values.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    // Only rows we can resolve a definition (and a value) for, in the
    // definitions' display order.
    final rows = <FieldValue>[];
    for (final v in widget.values) {
      final def = _defs[v.fieldId];
      if (def != null && _hasValue(def, v)) rows.add(v);
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    rows.sort((a, b) {
      final da = _defs[a.fieldId]!;
      final db = _defs[b.fieldId]!;
      final c = da.sortOrder.compareTo(db.sortOrder);
      return c != 0 ? c : da.id.compareTo(db.id);
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.customFields.manageTitle.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildRow(cs, _defs[rows[i].fieldId]!, rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(ColorScheme cs, FieldDefinition def, FieldValue v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(fieldTypeIcon(def.type), size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                def.name,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              _buildValue(cs, def, v),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValue(ColorScheme cs, FieldDefinition def, FieldValue v) {
    if (def.type == FieldType.checkbox) {
      return Icon(Icons.check, size: 20, color: cs.primary);
    }
    final text = _format(def, v) ?? '';
    return Text(
      text,
      textDirection: detectTextDirection(text),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  bool _hasValue(FieldDefinition def, FieldValue v) => switch (def.type) {
    FieldType.checkbox => v.valueBool,
    _ => _format(def, v) != null,
  };

  /// Format a non-checkbox value for display, or `null` when it holds nothing.
  String? _format(FieldDefinition def, FieldValue v) {
    switch (def.type) {
      case FieldType.text:
        final t = v.valueText?.trim();
        return (t == null || t.isEmpty) ? null : t;
      case FieldType.number:
        final n = v.valueNumber;
        if (n == null) return null;
        return n == n.roundToDouble() ? n.toInt().toString() : n.toString();
      case FieldType.checkbox:
        return null;
      case FieldType.select:
        final id = v.valueOptionId;
        if (id == null) return null;
        for (final o in def.options) {
          if (o.id == id) return o.label;
        }
        return null;
      case FieldType.date:
        final secs = v.valueDate;
        if (secs == null) return null;
        final date = DateTime.fromMillisecondsSinceEpoch(secs * 1000);
        return MaterialLocalizations.of(context).formatMediumDate(date);
    }
  }
}
