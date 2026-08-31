/// Sentinel for [FieldDefinition.copyWith]'s `listId`, where `null` is a
/// meaningful value ("All lists" / house-wide) and must be distinguishable
/// from "leave unchanged".
const Object _unset = Object();

/// The five custom-field types, in their locked presentation order (per the
/// UI contract). The wire form is the lowercase [name].
enum FieldType {
  text,
  number,
  checkbox,
  date,
  select;

  static FieldType fromWire(String wire) =>
      FieldType.values.firstWhere((t) => t.name == wire, orElse: () => text);
}

/// Entry mode for a `date` field: a picked calendar date, or an offset
/// materialized to an absolute date at entry.
enum FieldDateMode {
  absolute,
  relative;

  static FieldDateMode? fromWire(String? wire) => wire == null
      ? null
      : FieldDateMode.values.firstWhere(
          (m) => m.name == wire,
          orElse: () => absolute,
        );
}

/// Per-item reminder policy for a `date` field.
enum FieldOverridePolicy {
  fieldOnly('field-only'),
  itemOverride('item-override');

  const FieldOverridePolicy(this.wire);

  final String wire;

  static FieldOverridePolicy? fromWire(String? wire) => wire == null
      ? null
      : FieldOverridePolicy.values.firstWhere(
          (p) => p.wire == wire,
          orElse: () => fieldOnly,
        );
}

/// One choice of a `select` field. Stored item values reference an option by
/// [id], so rename/reorder are safe.
class FieldOption {
  final int id;
  final String label;
  final int sortOrder;

  /// How many stored item values currently reference this option. Drives the
  /// remap-or-clear prompt when deleting an option that's in use.
  final int valueCount;

  const FieldOption({
    required this.id,
    required this.label,
    required this.sortOrder,
    this.valueCount = 0,
  });

  factory FieldOption.fromJson(Map<String, dynamic> json) => FieldOption(
    id: json['id'] as int,
    label: json['label'] as String,
    sortOrder: json['sortOrder'] as int? ?? 0,
    valueCount: json['valueCount'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'sortOrder': sortOrder,
    'valueCount': valueCount,
  };

  FieldOption copyWith({int? id, String? label, int? sortOrder}) => FieldOption(
    id: id ?? this.id,
    label: label ?? this.label,
    sortOrder: sortOrder ?? this.sortOrder,
    valueCount: valueCount,
  );
}

/// A custom-field definition, scoped to a house and optionally to a single
/// list ([listId] `null` = house-wide, offered on every list). Type-specific
/// config lives in the matching fields; [options] is populated for `select`.
/// Mirrors [Category]'s house/list scoping and gated behind the
/// `custom-fields` capability.
class FieldDefinition {
  final int id;
  final int houseId;

  /// The list this field is scoped to, or `null` when it's house-wide.
  final int? listId;
  final String name;
  final FieldType type;
  final int sortOrder;
  final String? hint;
  final bool multiline;
  final String? defaultText;
  final double? defaultNumber;
  final bool defaultBool;
  final int? defaultOptionId;
  final FieldDateMode? dateMode;
  final int? defaultOffsetDays;
  final bool notifyDefault;
  final int leadDays;
  final FieldOverridePolicy? overridePolicy;
  final bool stopWhenDone;
  final List<FieldOption> options;
  final int createdAt;
  final int updatedAt;

  const FieldDefinition({
    required this.id,
    required this.houseId,
    this.listId,
    required this.name,
    required this.type,
    required this.sortOrder,
    this.hint,
    this.multiline = false,
    this.defaultText,
    this.defaultNumber,
    this.defaultBool = false,
    this.defaultOptionId,
    this.dateMode,
    this.defaultOffsetDays,
    this.notifyDefault = false,
    this.leadDays = 0,
    this.overridePolicy,
    this.stopWhenDone = false,
    this.options = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory FieldDefinition.fromJson(Map<String, dynamic> json) =>
      FieldDefinition(
        id: json['id'] as int,
        houseId: json['houseId'] as int,
        listId: json['listId'] as int?,
        name: json['name'] as String,
        type: FieldType.fromWire(json['type'] as String),
        sortOrder: json['sortOrder'] as int? ?? 0,
        hint: json['hint'] as String?,
        multiline: json['multiline'] as bool? ?? false,
        defaultText: json['defaultText'] as String?,
        defaultNumber: (json['defaultNumber'] as num?)?.toDouble(),
        defaultBool: json['defaultBool'] as bool? ?? false,
        defaultOptionId: json['defaultOptionId'] as int?,
        dateMode: FieldDateMode.fromWire(json['dateMode'] as String?),
        defaultOffsetDays: json['defaultOffsetDays'] as int?,
        notifyDefault: json['notifyDefault'] as bool? ?? false,
        leadDays: json['leadDays'] as int? ?? 0,
        overridePolicy: FieldOverridePolicy.fromWire(
          json['overridePolicy'] as String?,
        ),
        stopWhenDone: json['stopWhenDone'] as bool? ?? false,
        options:
            (json['options'] as List?)
                ?.map((e) => FieldOption.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        createdAt: json['createdAt'] as int? ?? 0,
        updatedAt: json['updatedAt'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'houseId': houseId,
    'listId': listId,
    'name': name,
    'type': type.name,
    'sortOrder': sortOrder,
    'hint': hint,
    'multiline': multiline,
    'defaultText': defaultText,
    'defaultNumber': defaultNumber,
    'defaultBool': defaultBool,
    'defaultOptionId': defaultOptionId,
    'dateMode': dateMode?.name,
    'defaultOffsetDays': defaultOffsetDays,
    'notifyDefault': notifyDefault,
    'leadDays': leadDays,
    'overridePolicy': overridePolicy?.wire,
    'stopWhenDone': stopWhenDone,
    'options': options.map((o) => o.toJson()).toList(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  /// The value to seed on a newly-created item, or `null` when the field
  /// defines no default. `date` fields have no default value (a fixed default
  /// date isn't meaningful), and an unset default yields nothing.
  FieldValue? seedValue() {
    switch (type) {
      case FieldType.text:
        final t = defaultText?.trim();
        return (t == null || t.isEmpty)
            ? null
            : FieldValue(fieldId: id, valueText: defaultText);
      case FieldType.number:
        return defaultNumber == null
            ? null
            : FieldValue(fieldId: id, valueNumber: defaultNumber);
      case FieldType.checkbox:
        return defaultBool ? FieldValue(fieldId: id, valueBool: true) : null;
      case FieldType.select:
        return defaultOptionId == null
            ? null
            : FieldValue(fieldId: id, valueOptionId: defaultOptionId);
      case FieldType.date:
        return null;
    }
  }

  /// Pass `listId: null` to make the field house-wide, an int to scope it, or
  /// omit it to leave the current scope unchanged.
  FieldDefinition copyWith({
    int? id,
    Object? listId = _unset,
    String? name,
    int? sortOrder,
    String? hint,
    bool? multiline,
    String? defaultText,
    double? defaultNumber,
    bool? defaultBool,
    int? defaultOptionId,
    FieldDateMode? dateMode,
    int? defaultOffsetDays,
    bool? notifyDefault,
    int? leadDays,
    FieldOverridePolicy? overridePolicy,
    bool? stopWhenDone,
    List<FieldOption>? options,
    int? updatedAt,
  }) => FieldDefinition(
    id: id ?? this.id,
    houseId: houseId,
    listId: identical(listId, _unset) ? this.listId : listId as int?,
    name: name ?? this.name,
    // The type is immutable after creation, so it's never a copyWith argument.
    type: type,
    sortOrder: sortOrder ?? this.sortOrder,
    hint: hint ?? this.hint,
    multiline: multiline ?? this.multiline,
    defaultText: defaultText ?? this.defaultText,
    defaultNumber: defaultNumber ?? this.defaultNumber,
    defaultBool: defaultBool ?? this.defaultBool,
    defaultOptionId: defaultOptionId ?? this.defaultOptionId,
    dateMode: dateMode ?? this.dateMode,
    defaultOffsetDays: defaultOffsetDays ?? this.defaultOffsetDays,
    notifyDefault: notifyDefault ?? this.notifyDefault,
    leadDays: leadDays ?? this.leadDays,
    overridePolicy: overridePolicy ?? this.overridePolicy,
    stopWhenDone: stopWhenDone ?? this.stopWhenDone,
    options: options ?? this.options,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// The values a newly-created item should carry: each applicable field's
/// default ([FieldDefinition.seedValue]), for the fields in scope for [listId]
/// (house-wide ∪ that list) that define one. Empty when nothing has a default.
List<FieldValue> seedFieldValues(Iterable<FieldDefinition> defs, int? listId) {
  final out = <FieldValue>[];
  for (final def in defs) {
    if (def.listId != null && def.listId != listId) continue;
    final seed = def.seedValue();
    if (seed != null) out.add(seed);
  }
  return out;
}

/// A per-item typed value for a custom field. Rides the checklist item (like
/// [ItemPrice]); which value column is populated depends on the field's type,
/// and the `notify*` fields carry a date field's per-item reminder override.
class FieldValue {
  final int fieldId;
  final String? valueText;
  final double? valueNumber;
  final bool valueBool;
  final int? valueDate;
  final int? valueOptionId;

  /// Relative-date offset in days; drives the Re-anchor action.
  final int? offsetDays;

  /// Whether this value overrides the field's reminder default.
  final bool notifyOverride;
  final bool notifyEnabled;

  /// `null` inherits the field's `leadDays`.
  final int? notifyLeadDays;

  const FieldValue({
    required this.fieldId,
    this.valueText,
    this.valueNumber,
    this.valueBool = false,
    this.valueDate,
    this.valueOptionId,
    this.offsetDays,
    this.notifyOverride = false,
    this.notifyEnabled = false,
    this.notifyLeadDays,
  });

  factory FieldValue.fromJson(Map<String, dynamic> json) => FieldValue(
    fieldId: json['fieldId'] as int,
    valueText: json['valueText'] as String?,
    valueNumber: (json['valueNumber'] as num?)?.toDouble(),
    valueBool: json['valueBool'] as bool? ?? false,
    valueDate: json['valueDate'] as int?,
    valueOptionId: json['valueOptionId'] as int?,
    offsetDays: json['offsetDays'] as int?,
    notifyOverride: json['notifyOverride'] as bool? ?? false,
    notifyEnabled: json['notifyEnabled'] as bool? ?? false,
    notifyLeadDays: json['notifyLeadDays'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'fieldId': fieldId,
    'valueText': valueText,
    'valueNumber': valueNumber,
    'valueBool': valueBool,
    'valueDate': valueDate,
    'valueOptionId': valueOptionId,
    'offsetDays': offsetDays,
    'notifyOverride': notifyOverride,
    'notifyEnabled': notifyEnabled,
    'notifyLeadDays': notifyLeadDays,
  };
}
