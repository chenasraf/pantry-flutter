import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/custom_field.dart';
import 'package:pantry_core/models/item_defaults.dart';
import 'package:pantry_core/models/item_start_values.dart';
import 'package:pantry_core/models/list_recurrence.dart';
import 'package:pantry_core/services/server_version_service.dart';

FieldDefinition _field(
  int id,
  FieldType type, {
  int? listId,
  String? defaultText,
  FieldDateMode? dateMode,
}) => FieldDefinition(
  id: id,
  houseId: 1,
  listId: listId,
  name: 'f$id',
  type: type,
  sortOrder: 0,
  defaultText: defaultText,
  dateMode: dateMode,
  createdAt: 0,
  updatedAt: 0,
);

ItemDefaults _parse(Map<String, dynamic> json) => ItemDefaults.fromJson(json);

const _complete = {
  'recurrence': {
    'mode': 'remember',
    'value': {'kind': 'once', 'rrule': null, 'repeatFromCompletion': false},
  },
  'stores': {
    'mode': 'fixed',
    'value': [3],
  },
  'category': {'mode': 'remember', 'value': 12},
  'labels': {'mode': 'none'},
  'quantity': {'mode': 'fixed', 'value': '1'},
  'fields': [
    {
      'fieldId': 7,
      'mode': 'remember',
      'value': {'valueOptionId': 4},
    },
    {
      'fieldId': 9,
      'mode': 'fixed',
      'value': {'offsetDays': 3},
    },
  ],
};

void main() {
  group('ItemDefaults.fromJson', () {
    test('reads every key of a complete object', () {
      final d = _parse(_complete);
      expect(d.recurrence.mode, ItemDefaultMode.remember);
      expect(d.recurrence.value!.kind, ListRecurrenceKind.once);
      expect(d.stores.value, [3]);
      expect(d.category.value, 12);
      expect(d.labels.mode, ItemDefaultMode.none);
      expect(d.quantity.value, '1');
      expect(d.field(7)!.value!.valueOptionId, 4);
      expect(d.field(9)!.value!.offsetDays, 3);
    });

    test('remember without a value has nothing remembered yet', () {
      final d = _parse({
        'category': {'mode': 'remember', 'value': null},
        'stores': {'mode': 'remember'},
      });
      expect(d.category.mode, ItemDefaultMode.remember);
      expect(d.category.value, isNull);
      expect(d.stores.value, isNull);
    });

    test('a recurring default without a rule repeats weekly', () {
      final d = _parse({
        'recurrence': {
          'mode': 'fixed',
          'value': {'kind': 'recurring'},
        },
      });
      expect(d.recurrence.value!.rrule, kDefaultListRrule);
    });

    test('survives a cache round-trip', () {
      final d = _parse(_complete);
      expect(_parse(d.toJson()).toJson(), d.toJson());
    });

    test('a list carries its defaults through its own JSON', () {
      final list = ChecklistList.fromJson({
        'id': 1,
        'houseId': 1,
        'name': 'L',
        'icon': 'x',
        'sortOrder': 0,
        'createdAt': 0,
        'updatedAt': 0,
        'itemDefaults': _complete,
      });
      final again = ChecklistList.fromJson(list.toJson());
      expect(again.itemDefaults!.stores.value, [3]);
    });
  });

  group('ItemStartValues.resolve', () {
    test('starts empty without defaults', () {
      final s = ItemStartValues.resolve(null, const [], 1);
      expect(s.categoryId, isNull);
      expect(s.storeIds, isEmpty);
      expect(s.quantity, '');
      expect(s.recurrence, RecurrenceDefaultValue.staple);
    });

    test('uses pinned and remembered values but ignores keys not set', () {
      final s = ItemStartValues.resolve(
        _parse({
          ..._complete,
          'labels': {
            'mode': 'none',
            'value': [5],
          },
        }),
        const [],
        1,
      );
      expect(s.categoryId, 12);
      expect(s.storeIds, [3]);
      expect(s.labelIds, isEmpty);
      expect(s.quantity, '1');
      expect(s.recurrence.kind, ListRecurrenceKind.once);
    });

    test('a list default replaces the field definition default', () {
      final defs = [_field(7, FieldType.text, defaultText: 'Fridge')];
      final s = ItemStartValues.resolve(
        _parse({
          'fields': [
            {
              'fieldId': 7,
              'mode': 'fixed',
              'value': {'valueText': 'Pantry'},
            },
          ],
        }),
        defs,
        1,
      );
      expect(s.customFieldValues.single.valueText, 'Pantry');
    });

    test('keeps the field definition default while nothing is remembered', () {
      final defs = [_field(7, FieldType.text, defaultText: 'Fridge')];
      final s = ItemStartValues.resolve(
        _parse({
          'fields': [
            {'fieldId': 7, 'mode': 'remember'},
          ],
        }),
        defs,
        1,
      );
      expect(s.customFieldValues.single.valueText, 'Fridge');
    });

    test('anchors a relative date to today', () {
      final defs = [
        _field(9, FieldType.date, dateMode: FieldDateMode.relative),
      ];
      final s = ItemStartValues.resolve(
        _parse(_complete),
        defs,
        1,
        today: DateTime(2026, 1, 30, 15),
      );
      final value = s.customFieldValues.single;
      expect(value.offsetDays, 3);
      expect(
        value.valueDate,
        DateTime(2026, 2, 2).millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('skips a list default for a field scoped to another list', () {
      final defs = [_field(9, FieldType.date, listId: 2)];
      final s = ItemStartValues.resolve(_parse(_complete), defs, 1);
      expect(s.customFieldValues, isEmpty);
    });
  });

  group('rememberPatch', () {
    final defs = [
      _field(7, FieldType.select),
      _field(9, FieldType.date, dateMode: FieldDateMode.relative),
      _field(11, FieldType.text),
    ];
    final defaults = _parse({
      ..._complete,
      'labels': {
        'mode': 'remember',
        'value': [1],
      },
      'fields': [
        {
          'fieldId': 7,
          'mode': 'remember',
          'value': {'valueOptionId': 4},
        },
        {'fieldId': 9, 'mode': 'remember'},
        {
          'fieldId': 11,
          'mode': 'fixed',
          'value': {'valueText': 'x'},
        },
      ],
    });

    ItemDefaultsPatch patch({
      RecurrenceDefaultValue recurrence = const RecurrenceDefaultValue(
        kind: ListRecurrenceKind.once,
      ),
      int? categoryId = 12,
      List<int> storeIds = const [9],
      List<int> labelIds = const [1],
      List<FieldValue> fields = const [
        FieldValue(fieldId: 7, valueOptionId: 4),
      ],
    }) => rememberPatch(
      defaults,
      recurrence: recurrence,
      categoryId: categoryId,
      storeIds: storeIds,
      labelIds: labelIds,
      customFieldValues: fields,
      fieldDefs: defs,
    );

    test('sends nothing when every remembered value is unchanged', () {
      expect(patch().isEmpty, isTrue);
    });

    test('writes only remembering keys whose value changed', () {
      final p = patch(categoryId: 4, labelIds: [1, 2]).toJson();
      expect(p, {
        'category': {'value': 4},
        'labels': {
          'value': [1, 2],
        },
      });
    });

    test('remembers a relative date as its offset only', () {
      final p = patch(
        fields: const [
          FieldValue(fieldId: 7, valueOptionId: 4),
          FieldValue(fieldId: 9, valueDate: 1700000000, offsetDays: 5),
        ],
      );
      expect(p.toJson(), {
        'fields': [
          {
            'fieldId': 9,
            'value': {'offsetDays': 5},
          },
        ],
      });
    });

    test('is value-only, so anyone who can add items may send it', () {
      expect(patch(categoryId: 1).isValueOnly, isTrue);
    });
  });

  group('applyPatch', () {
    test('a value-only patch keeps the mode', () {
      final d = _parse(_complete).applyPatch(
        const ItemDefaultsPatch(
          entries: {'category': ItemDefaultPatchEntry.value(4)},
        ),
      );
      expect(d.category.mode, ItemDefaultMode.remember);
      expect(d.category.value, 4);
    });

    test('switching to remember forgets what was there', () {
      final d = _parse(_complete).applyPatch(
        const ItemDefaultsPatch(
          entries: {'stores': ItemDefaultPatchEntry.mode(.remember)},
        ),
      );
      expect(d.stores.mode, ItemDefaultMode.remember);
      expect(d.stores.value, isNull);
    });

    test('pinning nothing is no default at all', () {
      final d = _parse(_complete).applyPatch(
        const ItemDefaultsPatch(
          entries: {'quantity': ItemDefaultPatchEntry.mode(.fixed, '  ')},
        ),
      );
      expect(d.quantity.mode, ItemDefaultMode.none);
    });

    test('a field set to none goes back to its own default', () {
      final d = _parse(_complete).applyPatch(
        const ItemDefaultsPatch(fields: {7: ItemDefaultPatchEntry.mode(.none)}),
      );
      expect(d.field(7), isNull);
      expect(d.field(9), isNotNull);
    });
  });

  group('ItemDefaultsPatch.then', () {
    test('a later value keeps the earlier mode', () {
      final merged =
          const ItemDefaultsPatch(
            entries: {'category': ItemDefaultPatchEntry.mode(.fixed, 1)},
          ).then(
            const ItemDefaultsPatch(
              entries: {'category': ItemDefaultPatchEntry.value(2)},
            ),
          );
      expect(merged.toJson(), {
        'category': {'mode': 'fixed', 'value': 2},
      });
    });

    test('a later mode replaces the earlier value', () {
      final merged =
          const ItemDefaultsPatch(
            entries: {
              'stores': ItemDefaultPatchEntry.value([1]),
            },
          ).then(
            const ItemDefaultsPatch(
              entries: {'stores': ItemDefaultPatchEntry.mode(.remember)},
            ),
          );
      expect(merged.toJson(), {
        'stores': {'mode': 'remember'},
      });
    });

    test('lands where applying both in turn would', () {
      const a = ItemDefaultsPatch(
        entries: {'category': ItemDefaultPatchEntry.value(3)},
        fields: {
          7: ItemDefaultPatchEntry.value({'valueOptionId': 1}),
        },
      );
      const b = ItemDefaultsPatch(
        entries: {
          'labels': ItemDefaultPatchEntry.value([2]),
        },
        fields: {
          7: ItemDefaultPatchEntry.value({'valueOptionId': 2}),
        },
      );
      final base = _parse({
        ..._complete,
        'labels': {'mode': 'remember'},
      });
      expect(
        base.applyPatch(a.then(b)).toJson(),
        base.applyPatch(a).applyPatch(b).toJson(),
      );
    });
  });

  group('configSignature', () {
    test('ignores what remembering keys learn', () {
      final d = _parse(_complete);
      final learned = d.applyPatch(
        const ItemDefaultsPatch(
          entries: {'category': ItemDefaultPatchEntry.value(99)},
        ),
      );
      expect(learned.configSignature, d.configSignature);
    });

    test('changes when a pinned value changes', () {
      final d = _parse(_complete);
      final edited = d.applyPatch(
        const ItemDefaultsPatch(
          entries: {
            'stores': ItemDefaultPatchEntry.mode(.fixed, [4]),
          },
        ),
      );
      expect(edited.configSignature, isNot(d.configSignature));
    });
  });

  group('recurrenceDefault with item defaults', () {
    tearDown(() => ServerVersionService.instance.debugSeed());

    ChecklistList list() => ChecklistList.fromJson({
      'id': 1,
      'houseId': 1,
      'name': 'L',
      'icon': 'x',
      'sortOrder': 0,
      'createdAt': 0,
      'updatedAt': 0,
      'defaultRecurrenceMode': 'remember',
      'defaultRecurrenceKind': 'once',
      'itemDefaults': {
        'recurrence': {
          'mode': 'fixed',
          'value': {'kind': 'recurring'},
        },
      },
    });

    test('reads the recurrence key and never remembers on its own', () {
      ServerVersionService.instance.debugSeed(
        features: {
          kListItemDefaultsFeature: true,
          kListDefaultRecurrenceFeature: true,
        },
        featuresAuthoritative: true,
      );
      final d = list().recurrenceDefault;
      expect(d.kind, ListRecurrenceKind.recurring);
      expect(d.rrule, kDefaultListRrule);
      expect(d.remembers, isFalse);
    });

    test('without the capability the legacy fields still apply', () {
      ServerVersionService.instance.debugSeed(
        features: {kListDefaultRecurrenceFeature: true},
        featuresAuthoritative: true,
      );
      final d = list().recurrenceDefault;
      expect(d.kind, ListRecurrenceKind.once);
      expect(d.remembers, isTrue);
    });
  });
}
