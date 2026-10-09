import 'package:flutter/foundation.dart';

import 'package:pantry_core/models/item_defaults.dart';

/// A list's item defaults as the defaults screen edits them: one mode per key,
/// plus every key's value — kept even while a key is not "fixed", so switching
/// back to it finds what was there.
class ItemDefaultsDraft {
  final Map<String, ItemDefaultMode> modes;
  RecurrenceDefaultValue recurrence;
  List<int> storeIds;
  int? categoryId;
  List<int> labelIds;
  String quantity;
  final Map<int, ({ItemDefaultMode mode, ItemDefaultFieldValue? value})> fields;

  ItemDefaultsDraft._({
    required this.modes,
    required this.recurrence,
    required this.storeIds,
    required this.categoryId,
    required this.labelIds,
    required this.quantity,
    required this.fields,
  });

  static const keys = [
    ItemDefaults.recurrenceKey,
    ItemDefaults.storesKey,
    ItemDefaults.categoryKey,
    ItemDefaults.labelsKey,
    ItemDefaults.quantityKey,
  ];

  /// Seed from the stored defaults. A remembered value seeds the editor too,
  /// so switching a key from "remember" to "fixed" starts from what the list
  /// last used.
  factory ItemDefaultsDraft.from(ItemDefaults? defaults) {
    final d = defaults ?? ItemDefaults.empty;
    return ItemDefaultsDraft._(
      modes: {
        ItemDefaults.recurrenceKey: d.recurrence.mode,
        ItemDefaults.storesKey: d.stores.mode,
        ItemDefaults.categoryKey: d.category.mode,
        ItemDefaults.labelsKey: d.labels.mode,
        ItemDefaults.quantityKey: d.quantity.mode,
      },
      recurrence: d.recurrence.value ?? RecurrenceDefaultValue.staple,
      storeIds: [...?d.stores.value],
      categoryId: d.category.value,
      labelIds: [...?d.labels.value],
      quantity: d.quantity.value ?? '',
      fields: {
        for (final f in d.fields) f.fieldId: (mode: f.mode, value: f.value),
      },
    );
  }

  ItemDefaultMode modeOf(String key) => modes[key] ?? ItemDefaultMode.none;

  ItemDefaultMode fieldModeOf(int fieldId) =>
      fields[fieldId]?.mode ?? ItemDefaultMode.none;

  /// Only the keys this draft changed against [original]. A key left on
  /// "remember" is never sent, so saving never wipes what the list learned
  /// while the screen was open.
  ItemDefaultsPatch patchAgainst(ItemDefaults? original) {
    final before = original ?? ItemDefaults.empty;
    final entries = <String, ItemDefaultPatchEntry>{};

    void diff<T>(
      String key,
      ItemDefaultEntry<T> stored,
      T value,
      bool Function(T? a, T b) same,
      Object? Function(T) encode,
    ) {
      final mode = modeOf(key);
      if (mode == stored.mode &&
          (mode != ItemDefaultMode.fixed || same(stored.value, value))) {
        return;
      }
      entries[key] = mode == ItemDefaultMode.fixed
          ? ItemDefaultPatchEntry.mode(mode, encode(value))
          : ItemDefaultPatchEntry.mode(mode);
    }

    final recurrence = this.recurrence.normalized();
    diff(
      ItemDefaults.recurrenceKey,
      before.recurrence,
      recurrence,
      (a, b) => a == b,
      (v) => v.toJson(),
    );
    final stores = [...storeIds]..sort();
    diff(
      ItemDefaults.storesKey,
      before.stores,
      stores,
      (a, b) => listEquals(a == null ? null : ([...a]..sort()), b),
      (v) => v,
    );
    diff(
      ItemDefaults.categoryKey,
      before.category,
      categoryId,
      (a, b) => a == b,
      (v) => v,
    );
    final labels = [...labelIds]..sort();
    diff(
      ItemDefaults.labelsKey,
      before.labels,
      labels,
      (a, b) => listEquals(a == null ? null : ([...a]..sort()), b),
      (v) => v,
    );
    diff(
      ItemDefaults.quantityKey,
      before.quantity,
      quantity.trim(),
      (a, b) => (a ?? '') == b,
      (v) => v,
    );

    final fieldEntries = <int, ItemDefaultPatchEntry>{};
    final stored = {for (final f in before.fields) f.fieldId: f};
    for (final fieldId in {...stored.keys, ...fields.keys}) {
      final was = stored[fieldId];
      final wasMode = was?.mode ?? ItemDefaultMode.none;
      final now = fields[fieldId];
      final mode = now?.mode ?? ItemDefaultMode.none;
      if (mode == wasMode &&
          (mode != ItemDefaultMode.fixed || was?.value == now?.value)) {
        continue;
      }
      fieldEntries[fieldId] = mode == ItemDefaultMode.fixed
          ? ItemDefaultPatchEntry.mode(mode, now?.value?.toJson())
          : ItemDefaultPatchEntry.mode(mode);
    }

    return ItemDefaultsPatch(entries: entries, fields: fieldEntries);
  }
}
