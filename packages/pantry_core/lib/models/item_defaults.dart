import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:pantry_core/models/list_recurrence.dart';

/// Feature string a server advertises when a list can pre-fill every part of a
/// new item, not only its recurrence. Without it a list keeps the
/// `defaultRecurrence*` fields.
const String kListItemDefaultsFeature = 'list-item-defaults';

/// How one part of a new item is pre-filled.
enum ItemDefaultMode {
  /// The composer's own empty state.
  none,

  /// Always the value an editor picked.
  fixed,

  /// Whatever the last item added to the list used.
  remember;

  static ItemDefaultMode parse(Object? value) {
    for (final mode in values) {
      if (mode.name == value) return mode;
    }
    return ItemDefaultMode.none;
  }
}

/// The recurrence a list pre-fills.
@immutable
class RecurrenceDefaultValue {
  final ListRecurrenceKind kind;
  final String? rrule;
  final bool repeatFromCompletion;

  const RecurrenceDefaultValue({
    this.kind = ListRecurrenceKind.none,
    this.rrule,
    this.repeatFromCompletion = false,
  });

  static const staple = RecurrenceDefaultValue();

  /// Mirrors the server: a non-recurring default carries no rule, and a
  /// recurring one without a rule repeats weekly.
  RecurrenceDefaultValue normalized() {
    if (kind != ListRecurrenceKind.recurring) {
      return RecurrenceDefaultValue(kind: kind);
    }
    final rule = rrule;
    return RecurrenceDefaultValue(
      kind: kind,
      rrule: (rule == null || rule.isEmpty) ? kDefaultListRrule : rule,
      repeatFromCompletion: repeatFromCompletion,
    );
  }

  factory RecurrenceDefaultValue.fromJson(Map<String, dynamic> json) =>
      RecurrenceDefaultValue(
        kind: ListRecurrenceKind.parse(json['kind']),
        rrule: json['rrule'] as String?,
        repeatFromCompletion: json['repeatFromCompletion'] as bool? ?? false,
      ).normalized();

  Map<String, dynamic> toJson() => {
    'kind': kind.wire,
    'rrule': rrule,
    'repeatFromCompletion': repeatFromCompletion,
  };

  @override
  bool operator ==(Object other) =>
      other is RecurrenceDefaultValue &&
      other.kind == kind &&
      other.rrule == rrule &&
      other.repeatFromCompletion == repeatFromCompletion;

  @override
  int get hashCode => Object.hash(kind, rrule, repeatFromCompletion);
}

/// One pre-filled part of a new item.
@immutable
class ItemDefaultEntry<T> {
  final ItemDefaultMode mode;

  /// The pinned value, or what the list last used. `null` under
  /// [ItemDefaultMode.remember] means nothing has been remembered yet.
  final T? value;

  const ItemDefaultEntry(this.mode, [this.value]);

  /// The value a new item starts with: pinned or remembered, never under
  /// [ItemDefaultMode.none].
  T? get prefill => mode == ItemDefaultMode.none ? null : value;
}

/// The value columns a custom-field default carries. Only the column the
/// field's type uses is set, the same way the server stores it; reminder
/// settings belong to a single item and are never part of it.
@immutable
class ItemDefaultFieldValue {
  final String? valueText;
  final double? valueNumber;
  final bool? valueBool;

  /// An absolute date, in epoch seconds.
  final int? valueDate;
  final int? valueOptionId;

  /// A relative date, anchored to the day the item is created.
  final int? offsetDays;

  const ItemDefaultFieldValue({
    this.valueText,
    this.valueNumber,
    this.valueBool,
    this.valueDate,
    this.valueOptionId,
    this.offsetDays,
  });

  factory ItemDefaultFieldValue.fromJson(Map<String, dynamic> json) =>
      ItemDefaultFieldValue(
        valueText: json['valueText'] as String?,
        valueNumber: (json['valueNumber'] as num?)?.toDouble(),
        valueBool: json['valueBool'] as bool?,
        valueDate: json['valueDate'] as int?,
        valueOptionId: json['valueOptionId'] as int?,
        offsetDays: json['offsetDays'] as int?,
      );

  Map<String, dynamic> toJson() => {
    'valueText': ?valueText,
    'valueNumber': ?valueNumber,
    'valueBool': ?valueBool,
    'valueDate': ?valueDate,
    'valueOptionId': ?valueOptionId,
    'offsetDays': ?offsetDays,
  };

  @override
  bool operator ==(Object other) =>
      other is ItemDefaultFieldValue && mapEquals(other.toJson(), toJson());

  @override
  int get hashCode => Object.hashAll(toJson().entries.map((e) => e.toString()));
}

/// A list default for one custom field. A field without one starts from its
/// own definition's default.
@immutable
class ItemDefaultField {
  final int fieldId;
  final ItemDefaultMode mode;
  final ItemDefaultFieldValue? value;

  const ItemDefaultField({
    required this.fieldId,
    required this.mode,
    this.value,
  });

  factory ItemDefaultField.fromJson(Map<String, dynamic> json) {
    final value = json['value'];
    return ItemDefaultField(
      fieldId: json['fieldId'] as int,
      mode: ItemDefaultMode.parse(json['mode']),
      value: value is Map
          ? ItemDefaultFieldValue.fromJson(Map<String, dynamic>.from(value))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'fieldId': fieldId,
    'mode': mode.name,
    if (value != null) 'value': value!.toJson(),
  };
}

/// What new items on a list start with.
@immutable
class ItemDefaults {
  final ItemDefaultEntry<RecurrenceDefaultValue> recurrence;
  final ItemDefaultEntry<List<int>> stores;
  final ItemDefaultEntry<int> category;
  final ItemDefaultEntry<List<int>> labels;

  /// Never [ItemDefaultMode.remember]: a quantity belongs to the item it was
  /// typed for.
  final ItemDefaultEntry<String> quantity;
  final List<ItemDefaultField> fields;

  const ItemDefaults({
    this.recurrence = const ItemDefaultEntry(.none),
    this.stores = const ItemDefaultEntry(.none),
    this.category = const ItemDefaultEntry(.none),
    this.labels = const ItemDefaultEntry(.none),
    this.quantity = const ItemDefaultEntry(.none),
    this.fields = const [],
  });

  static const empty = ItemDefaults();

  static const recurrenceKey = 'recurrence';
  static const storesKey = 'stores';
  static const categoryKey = 'category';
  static const labelsKey = 'labels';
  static const quantityKey = 'quantity';
  static const fieldsKey = 'fields';

  ItemDefaultField? field(int fieldId) {
    for (final f in fields) {
      if (f.fieldId == fieldId) return f;
    }
    return null;
  }

  factory ItemDefaults.fromJson(Map<String, dynamic> json) {
    ItemDefaultEntry<T> entry<T>(String key, T? Function(Object? raw) parse) {
      final raw = json[key];
      if (raw is! Map) return ItemDefaultEntry<T>(.none);
      final mode = ItemDefaultMode.parse(raw['mode']);
      if (mode == ItemDefaultMode.none) return ItemDefaultEntry<T>(.none);
      return ItemDefaultEntry<T>(mode, parse(raw['value']));
    }

    final fields = json[fieldsKey];
    return ItemDefaults(
      recurrence: entry(recurrenceKey, _parseRecurrence),
      stores: entry(storesKey, _parseIds),
      category: entry(categoryKey, _parseId),
      labels: entry(labelsKey, _parseIds),
      quantity: entry(quantityKey, _parseQuantity),
      fields: fields is List
          ? [
              for (final f in fields)
                if (f is Map)
                  ItemDefaultField.fromJson(Map<String, dynamic>.from(f)),
            ].where((f) => f.mode != ItemDefaultMode.none).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> entry<T>(
      ItemDefaultEntry<T> e,
      Object? Function(T) encode,
    ) => {
      'mode': e.mode.name,
      if (e.mode != ItemDefaultMode.none && e.value != null)
        'value': encode(e.value as T),
    };
    return {
      recurrenceKey: entry(recurrence, (v) => v.toJson()),
      storesKey: entry(stores, (v) => v),
      categoryKey: entry(category, (v) => v),
      labelsKey: entry(labels, (v) => v),
      quantityKey: entry(quantity, (v) => v),
      fieldsKey: [for (final f in fields) f.toJson()],
    };
  }

  /// These defaults once [patch] lands, merged the way the server merges it,
  /// so an optimistic update matches what comes back.
  ItemDefaults applyPatch(ItemDefaultsPatch patch) {
    ItemDefaultEntry<T> merge<T>(
      String key,
      ItemDefaultEntry<T> current,
      T? Function(Object? raw) parse,
    ) {
      final incoming = patch.entries[key];
      if (incoming == null) return current;
      final mode = incoming.mode ?? current.mode;
      if (key == quantityKey && mode == ItemDefaultMode.remember) {
        return current;
      }
      return _settle(mode, incoming.hasValue ? parse(incoming.value) : null);
    }

    var fields = this.fields;
    if (patch.fields.isNotEmpty) {
      final byId = {for (final f in this.fields) f.fieldId: f};
      for (final MapEntry(key: fieldId, value: incoming)
          in patch.fields.entries) {
        final mode = incoming.mode ?? byId[fieldId]?.mode ?? .none;
        final value = incoming.hasValue && incoming.value is Map
            ? ItemDefaultFieldValue.fromJson(
                Map<String, dynamic>.from(incoming.value as Map),
              )
            : null;
        final settled = _settle<ItemDefaultFieldValue>(mode, value);
        if (settled.mode == ItemDefaultMode.none) {
          byId.remove(fieldId);
        } else {
          byId[fieldId] = ItemDefaultField(
            fieldId: fieldId,
            mode: settled.mode,
            value: settled.value,
          );
        }
      }
      fields = byId.values.toList();
    }

    return ItemDefaults(
      recurrence: merge(recurrenceKey, recurrence, _parseRecurrence),
      stores: merge(storesKey, stores, _parseIds),
      category: merge(categoryKey, category, _parseId),
      labels: merge(labelsKey, labels, _parseIds),
      quantity: merge(quantityKey, quantity, _parseQuantity),
      fields: fields,
    );
  }

  /// The defaults an editor configured, without what remembering keys have
  /// learned. It changes when someone edits the defaults, not on every add,
  /// which is what tells a composer to re-seed the item it is building.
  String get configSignature {
    Object? pinned<T>(ItemDefaultEntry<T> e, Object? Function(T) encode) =>
        e.mode == ItemDefaultMode.fixed && e.value != null
        ? {'mode': e.mode.name, 'value': encode(e.value as T)}
        : {'mode': e.mode.name};
    return jsonEncode({
      recurrenceKey: pinned(recurrence, (v) => v.toJson()),
      storesKey: pinned(stores, (v) => v),
      categoryKey: pinned(category, (v) => v),
      labelsKey: pinned(labels, (v) => v),
      quantityKey: pinned(quantity, (v) => v),
      fieldsKey: [
        for (final f in fields)
          {
            'fieldId': f.fieldId,
            'mode': f.mode.name,
            if (f.mode == ItemDefaultMode.fixed) 'value': f.value?.toJson(),
          },
      ],
    });
  }
}

/// A key without a value falls back: "remember" starts empty until something
/// is remembered, and "fixed" to nothing is no default at all.
ItemDefaultEntry<T> _settle<T>(ItemDefaultMode mode, T? value) {
  if (mode == ItemDefaultMode.none) return ItemDefaultEntry<T>(.none);
  if (value == null) {
    return mode == ItemDefaultMode.remember
        ? ItemDefaultEntry<T>(.remember)
        : ItemDefaultEntry<T>(.none);
  }
  return ItemDefaultEntry<T>(mode, value);
}

RecurrenceDefaultValue? _parseRecurrence(Object? raw) => raw is Map
    ? RecurrenceDefaultValue.fromJson(Map<String, dynamic>.from(raw))
    : null;

List<int>? _parseIds(Object? raw) =>
    raw is List ? [for (final id in raw) (id as num).toInt()] : null;

int? _parseId(Object? raw) => raw is num ? raw.toInt() : null;

String? _parseQuantity(Object? raw) {
  final q = raw is String ? raw.trim() : null;
  return (q == null || q.isEmpty) ? null : q;
}

/// One key of an [ItemDefaultsPatch]. A [mode] of `null` keeps the key's
/// current mode, which is how an add-item form writes back what it used.
@immutable
class ItemDefaultPatchEntry {
  final ItemDefaultMode? mode;
  final bool hasValue;

  /// The value in its wire shape.
  final Object? value;

  const ItemDefaultPatchEntry._(this.mode, this.hasValue, this.value);

  /// Change the mode; [ItemDefaultMode.fixed] takes the [value] it pins.
  const ItemDefaultPatchEntry.mode(ItemDefaultMode mode, [Object? value])
    : this._(mode, mode == ItemDefaultMode.fixed, value);

  /// Remember [value] without touching the mode.
  const ItemDefaultPatchEntry.value(Object? value) : this._(null, true, value);

  factory ItemDefaultPatchEntry.fromJson(Map<String, dynamic> json) =>
      ItemDefaultPatchEntry._(
        json.containsKey('mode') ? ItemDefaultMode.parse(json['mode']) : null,
        json.containsKey('value'),
        json['value'],
      );

  Map<String, dynamic> toJson() => {
    if (mode != null) 'mode': mode!.name,
    if (hasValue) 'value': value,
  };

  /// This entry followed by [later], as one entry the server would merge to
  /// the same result. A later mode is a whole new spec; a later value-only
  /// entry keeps this one's mode.
  ItemDefaultPatchEntry then(ItemDefaultPatchEntry later) => later.mode != null
      ? later
      : ItemDefaultPatchEntry._(mode, true, later.value);
}

/// A change to a list's [ItemDefaults], merged by the server per key (custom
/// fields per field). Keys it leaves out are untouched.
@immutable
class ItemDefaultsPatch {
  final Map<String, ItemDefaultPatchEntry> entries;
  final Map<int, ItemDefaultPatchEntry> fields;

  const ItemDefaultsPatch({this.entries = const {}, this.fields = const {}});

  bool get isEmpty => entries.isEmpty && fields.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Whether every key only writes back a value, which anyone who can add
  /// items may send for a remembering key.
  bool get isValueOnly =>
      entries.values.every((e) => e.mode == null) &&
      fields.values.every((e) => e.mode == null);

  factory ItemDefaultsPatch.fromJson(Map<String, dynamic> json) {
    final entries = <String, ItemDefaultPatchEntry>{};
    final fields = <int, ItemDefaultPatchEntry>{};
    for (final MapEntry(:key, :value) in json.entries) {
      if (key == ItemDefaults.fieldsKey && value is List) {
        for (final f in value) {
          if (f is! Map) continue;
          final map = Map<String, dynamic>.from(f);
          fields[map['fieldId'] as int] = ItemDefaultPatchEntry.fromJson(map);
        }
      } else if (value is Map) {
        entries[key] = ItemDefaultPatchEntry.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
    }
    return ItemDefaultsPatch(entries: entries, fields: fields);
  }

  Map<String, dynamic> toJson() => {
    for (final MapEntry(:key, :value) in entries.entries) key: value.toJson(),
    if (fields.isNotEmpty)
      ItemDefaults.fieldsKey: [
        for (final MapEntry(:key, :value) in fields.entries)
          {'fieldId': key, ...value.toJson()},
      ],
  };

  /// This patch followed by [later], so queued patches for one list can be
  /// sent as one.
  ItemDefaultsPatch then(ItemDefaultsPatch later) {
    ItemDefaultPatchEntry merge(
      ItemDefaultPatchEntry? earlier,
      ItemDefaultPatchEntry next,
    ) => earlier == null ? next : earlier.then(next);
    return ItemDefaultsPatch(
      entries: {
        ...entries,
        for (final MapEntry(:key, :value) in later.entries.entries)
          key: merge(entries[key], value),
      },
      fields: {
        ...fields,
        for (final MapEntry(:key, :value) in later.fields.entries)
          key: merge(fields[key], value),
      },
    );
  }
}
