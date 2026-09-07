import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/custom_field.dart';

void main() {
  group('FieldDefinition serialization', () {
    test('round-trips a select field with options through JSON', () {
      const def = FieldDefinition(
        id: 5,
        houseId: 2,
        listId: 9,
        name: 'Aisle',
        type: FieldType.select,
        sortOrder: 3,
        hint: 'Pick one',
        options: [
          FieldOption(id: 1, label: 'Dairy', sortOrder: 0, valueCount: 2),
          FieldOption(id: 2, label: 'Produce', sortOrder: 1),
        ],
        createdAt: 100,
        updatedAt: 200,
      );

      final decoded = FieldDefinition.fromJson(def.toJson());

      expect(decoded.type, FieldType.select);
      expect(decoded.listId, 9);
      expect(decoded.options.map((o) => o.label), ['Dairy', 'Produce']);
      expect(decoded.options.first.valueCount, 2);
    });

    test('round-trips date reminder config, mapping wire enums', () {
      const def = FieldDefinition(
        id: 6,
        houseId: 2,
        name: 'Expiry',
        type: FieldType.date,
        sortOrder: 0,
        dateMode: FieldDateMode.relative,
        defaultOffsetDays: 7,
        notifyDefault: true,
        leadDays: 2,
        overridePolicy: FieldOverridePolicy.itemOverride,
        stopWhenDone: true,
        createdAt: 1,
        updatedAt: 1,
      );

      final json = def.toJson();
      expect(json['dateMode'], 'relative');
      expect(json['overridePolicy'], 'item-override');

      final decoded = FieldDefinition.fromJson(json);
      expect(decoded.dateMode, FieldDateMode.relative);
      expect(decoded.overridePolicy, FieldOverridePolicy.itemOverride);
      expect(decoded.stopWhenDone, isTrue);
      expect(decoded.listId, isNull);
    });

    test('copyWith listId sentinel distinguishes "clear" from "unchanged"', () {
      const def = FieldDefinition(
        id: 1,
        houseId: 2,
        listId: 4,
        name: 'X',
        type: FieldType.text,
        sortOrder: 0,
        createdAt: 1,
        updatedAt: 1,
      );

      expect(def.copyWith(name: 'Y').listId, 4);
      expect(def.copyWith(listId: null).listId, isNull);
      expect(def.copyWith(listId: 8).listId, 8);
    });
  });

  group('seedFieldValues', () {
    FieldDefinition def(
      int id,
      FieldType type, {
      int? listId,
      String? defaultText,
      double? defaultNumber,
      bool defaultBool = false,
      int? defaultOptionId,
    }) => FieldDefinition(
      id: id,
      houseId: 1,
      listId: listId,
      name: 'F$id',
      type: type,
      sortOrder: id,
      defaultText: defaultText,
      defaultNumber: defaultNumber,
      defaultBool: defaultBool,
      defaultOptionId: defaultOptionId,
      createdAt: 0,
      updatedAt: 0,
    );

    test('emits a value only for fields that define a default', () {
      final defs = [
        def(1, FieldType.text, defaultText: 'hi'),
        def(2, FieldType.text), // no default → skipped
        def(3, FieldType.number, defaultNumber: 4),
        def(4, FieldType.checkbox, defaultBool: true),
        def(5, FieldType.checkbox), // false default → skipped
        def(6, FieldType.select, defaultOptionId: 9),
        def(7, FieldType.date), // date has no default → skipped
      ];

      final seeds = seedFieldValues(defs, null);

      expect(seeds.map((v) => v.fieldId), [1, 3, 4, 6]);
      expect(seeds[0].valueText, 'hi');
      expect(seeds[1].valueNumber, 4);
      expect(seeds[2].valueBool, isTrue);
      expect(seeds[3].valueOptionId, 9);
    });

    test('applies the effective-list scope', () {
      final defs = [
        def(1, FieldType.text, defaultText: 'global'),
        def(2, FieldType.text, listId: 10, defaultText: 'list-10'),
        def(3, FieldType.text, listId: 99, defaultText: 'other-list'),
      ];

      expect(seedFieldValues(defs, 10).map((v) => v.fieldId), [1, 2]);
      expect(seedFieldValues(defs, null).map((v) => v.fieldId), [1]);
    });
  });

  group('ListItem.customFields serialization', () {
    test('round-trips values through toJson/fromJson', () {
      final item = ListItem(
        id: 1,
        listId: 2,
        name: 'Milk',
        done: false,
        repeatFromCompletion: false,
        deleteOnDone: false,
        sortOrder: 0,
        createdAt: 100,
        updatedAt: 200,
        customFields: const [
          FieldValue(fieldId: 5, valueText: 'B12'),
          FieldValue(
            fieldId: 6,
            valueDate: 1788000000,
            notifyOverride: true,
            notifyEnabled: true,
            notifyLeadDays: 1,
          ),
        ],
      );

      final decoded = ListItem.fromJson(item.toJson());

      expect(decoded.customFields, hasLength(2));
      expect(decoded.customFields.first.valueText, 'B12');
      final date = decoded.customFields[1];
      expect(date.valueDate, 1788000000);
      expect(date.notifyOverride, isTrue);
      expect(date.notifyLeadDays, 1);
    });

    test('treats a missing customFields key as empty', () {
      final decoded = ListItem.fromJson({
        'id': 1,
        'listId': 2,
        'name': 'Milk',
        'done': false,
        'repeatFromCompletion': false,
        'sortOrder': 0,
        'createdAt': 100,
        'updatedAt': 200,
      });

      expect(decoded.customFields, isEmpty);
    });
  });
}
