import 'package:flutter/foundation.dart';

import 'package:pantry_core/models/custom_field.dart';
import 'package:pantry_core/models/item_defaults.dart';

/// What a new item's chips start with, resolved from a list's [ItemDefaults].
@immutable
class ItemStartValues {
  final int? categoryId;
  final List<int> storeIds;
  final List<int> labelIds;
  final String quantity;
  final RecurrenceDefaultValue recurrence;
  final List<FieldValue> customFieldValues;

  const ItemStartValues({
    this.categoryId,
    this.storeIds = const [],
    this.labelIds = const [],
    this.quantity = '',
    this.recurrence = RecurrenceDefaultValue.staple,
    this.customFieldValues = const [],
  });

  /// Resolve [defaults] for a new item on list [listId]. Custom fields start
  /// from their own definition's default, which a list default replaces; a
  /// relative date is anchored to [today].
  factory ItemStartValues.resolve(
    ItemDefaults? defaults,
    Iterable<FieldDefinition> fieldDefs,
    int? listId, {
    DateTime? today,
  }) {
    final fieldValues = {
      for (final v in seedFieldValues(fieldDefs, listId, today: today))
        v.fieldId: v,
    };
    final applicable = {
      for (final def in fieldDefs)
        if (def.listId == null || def.listId == listId) def.id,
    };
    for (final field in defaults?.fields ?? const <ItemDefaultField>[]) {
      final value = field.mode == ItemDefaultMode.none ? null : field.value;
      if (value == null || !applicable.contains(field.fieldId)) continue;
      fieldValues[field.fieldId] = fieldValueFromDefault(
        field.fieldId,
        value,
        today: today,
      );
    }
    return ItemStartValues(
      categoryId: defaults?.category.prefill,
      storeIds: [...?defaults?.stores.prefill],
      labelIds: [...?defaults?.labels.prefill],
      quantity: defaults?.quantity.prefill ?? '',
      recurrence:
          (defaults?.recurrence.prefill ?? RecurrenceDefaultValue.staple)
              .normalized(),
      customFieldValues: fieldValues.values.toList(),
    );
  }
}

/// A field default in the shape items carry. A relative date default holds
/// only its offset, so it is anchored to [today].
FieldValue fieldValueFromDefault(
  int fieldId,
  ItemDefaultFieldValue value, {
  DateTime? today,
}) {
  final offset = value.offsetDays;
  return FieldValue(
    fieldId: fieldId,
    valueText: value.valueText,
    valueNumber: value.valueNumber,
    valueBool: value.valueBool ?? false,
    valueDate:
        value.valueDate ??
        (offset == null ? null : anchorDayEpoch(offset, today: today)),
    valueOptionId: value.valueOptionId,
    offsetDays: offset,
  );
}

/// The part of an item's value a list default keeps: only the column the
/// field's type uses. Reminder settings belong to a single item and are
/// dropped.
ItemDefaultFieldValue? fieldDefaultFromValue(
  FieldDefinition field,
  FieldValue? value,
) {
  if (value == null) return null;
  return switch (field.type) {
    FieldType.text => ItemDefaultFieldValue(valueText: value.valueText),
    FieldType.number => ItemDefaultFieldValue(valueNumber: value.valueNumber),
    FieldType.checkbox => ItemDefaultFieldValue(valueBool: value.valueBool),
    FieldType.select => ItemDefaultFieldValue(
      valueOptionId: value.valueOptionId,
    ),
    FieldType.date =>
      field.dateMode == FieldDateMode.relative
          ? ItemDefaultFieldValue(offsetDays: value.offsetDays)
          : ItemDefaultFieldValue(valueDate: value.valueDate),
  };
}

/// The write-back after an item is added: only the keys in "remember" mode
/// whose value differs from what is already remembered.
ItemDefaultsPatch rememberPatch(
  ItemDefaults? defaults, {
  required RecurrenceDefaultValue recurrence,
  required int? categoryId,
  required Iterable<int> storeIds,
  required Iterable<int> labelIds,
  required List<FieldValue> customFieldValues,
  required Iterable<FieldDefinition> fieldDefs,
}) {
  if (defaults == null) return const ItemDefaultsPatch();
  final entries = <String, ItemDefaultPatchEntry>{};

  void remember<T>(
    String key,
    ItemDefaultEntry<T> entry,
    T used,
    bool Function(T? a, T b) same,
    Object? Function(T) encode,
  ) {
    if (entry.mode != ItemDefaultMode.remember) return;
    if (same(entry.value, used)) return;
    entries[key] = ItemDefaultPatchEntry.value(encode(used));
  }

  final usedRecurrence = recurrence.normalized();
  remember(
    ItemDefaults.recurrenceKey,
    defaults.recurrence,
    usedRecurrence,
    (a, b) => a == b,
    (v) => v.toJson(),
  );
  final stores = [...storeIds];
  remember(
    ItemDefaults.storesKey,
    defaults.stores,
    stores,
    (a, b) => listEquals(a ?? const [], b),
    (v) => v,
  );
  if (defaults.category.mode == ItemDefaultMode.remember &&
      defaults.category.value != categoryId) {
    entries[ItemDefaults.categoryKey] = ItemDefaultPatchEntry.value(categoryId);
  }
  final labels = [...labelIds];
  remember(
    ItemDefaults.labelsKey,
    defaults.labels,
    labels,
    (a, b) => listEquals(a ?? const [], b),
    (v) => v,
  );

  final defsById = {for (final d in fieldDefs) d.id: d};
  final usedById = {for (final v in customFieldValues) v.fieldId: v};
  final fields = <int, ItemDefaultPatchEntry>{};
  for (final field in defaults.fields) {
    final def = defsById[field.fieldId];
    if (field.mode != ItemDefaultMode.remember || def == null) continue;
    final value = fieldDefaultFromValue(def, usedById[field.fieldId]);
    if (field.value == value) continue;
    fields[field.fieldId] = ItemDefaultPatchEntry.value(value?.toJson());
  }

  return ItemDefaultsPatch(entries: entries, fields: fields);
}
