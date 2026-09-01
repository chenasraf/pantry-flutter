import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/models/custom_field.dart';
import 'package:pantry/views/custom_fields/custom_field_drafts.dart';

// The editor mutates `options` in place — adding a row, dropping blank ones on
// submit — so a draft must never hand back a list it can't grow or shrink.

void main() {
  group('FieldDraft.options', () {
    test('a draft built without options can still grow one', () {
      final d = FieldDraft(name: 'Aisle', type: FieldType.select);
      d.options.add(OptionDraft(id: null, label: 'Dairy'));
      expect(d.options, hasLength(1));
    });

    test('a draft built without options can be pruned', () {
      final d = FieldDraft(name: 'Notes', type: FieldType.text);
      d.options.removeWhere((o) => o.label.trim().isEmpty);
      expect(d.options, isEmpty);
    });

    test('the caller keeps its own list', () {
      final source = [OptionDraft(id: 1, label: 'Dairy')];
      final d = FieldDraft(
        name: 'Aisle',
        type: FieldType.select,
        options: source,
      );
      d.options.add(OptionDraft(id: null, label: 'Bakery'));
      expect(source, hasLength(1));
      expect(d.options, hasLength(2));
    });
  });
}
