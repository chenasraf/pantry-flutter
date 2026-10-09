import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/views/checklists/item_defaults_draft.dart';
import 'package:pantry_core/models/item_defaults.dart';
import 'package:pantry_core/models/list_recurrence.dart';

ItemDefaults _defaults() => ItemDefaults.fromJson({
  'recurrence': {
    'mode': 'remember',
    'value': {'kind': 'once'},
  },
  'stores': {
    'mode': 'fixed',
    'value': [3, 1],
  },
  'category': {'mode': 'remember', 'value': 12},
  'labels': {'mode': 'none'},
  'quantity': {'mode': 'fixed', 'value': '1'},
  'fields': [
    {
      'fieldId': 7,
      'mode': 'fixed',
      'value': {'valueText': 'Fridge'},
    },
  ],
});

void main() {
  test('seeds every key, and a remembered value seeds the editor', () {
    final draft = ItemDefaultsDraft.from(_defaults());
    expect(draft.modeOf('category'), ItemDefaultMode.remember);
    expect(draft.categoryId, 12);
    expect(draft.recurrence.kind, ListRecurrenceKind.once);
    expect(draft.quantity, '1');
    expect(draft.fieldModeOf(7), ItemDefaultMode.fixed);
  });

  test('starts empty keys from nothing', () {
    final draft = ItemDefaultsDraft.from(null);
    expect(draft.modeOf('stores'), ItemDefaultMode.none);
    expect(draft.storeIds, isEmpty);
    expect(draft.patchAgainst(null).isEmpty, isTrue);
  });

  test('sends nothing when nothing changed', () {
    final d = _defaults();
    expect(ItemDefaultsDraft.from(d).patchAgainst(d).isEmpty, isTrue);
  });

  test('sends a pinned value only when it changed', () {
    final d = _defaults();
    final draft = ItemDefaultsDraft.from(d)..storeIds = [1, 3];
    expect(draft.patchAgainst(d).isEmpty, isTrue, reason: 'same set');
    draft.storeIds = [1];
    expect(draft.patchAgainst(d).toJson(), {
      'stores': {
        'mode': 'fixed',
        'value': [1],
      },
    });
  });

  test('never resends a remembered key, so what the list learned is kept', () {
    final d = _defaults();
    final draft = ItemDefaultsDraft.from(d)..categoryId = 99;
    expect(draft.patchAgainst(d).isEmpty, isTrue);
  });

  test('switches a key to remember without a value', () {
    final d = _defaults();
    final draft = ItemDefaultsDraft.from(d)
      ..modes['stores'] = ItemDefaultMode.remember;
    expect(draft.patchAgainst(d).toJson(), {
      'stores': {'mode': 'remember'},
    });
  });

  test('clears a key back to not set', () {
    final d = _defaults();
    final draft = ItemDefaultsDraft.from(d)
      ..modes['quantity'] = ItemDefaultMode.none;
    expect(draft.patchAgainst(d).toJson(), {
      'quantity': {'mode': 'none'},
    });
  });

  test('pins a recurrence, normalised the way the server stores it', () {
    final d = _defaults();
    final draft = ItemDefaultsDraft.from(d)
      ..modes['recurrence'] = ItemDefaultMode.fixed
      ..recurrence = const RecurrenceDefaultValue(
        kind: ListRecurrenceKind.recurring,
      );
    expect(draft.patchAgainst(d).toJson(), {
      'recurrence': {
        'mode': 'fixed',
        'value': {
          'kind': 'recurring',
          'rrule': kDefaultListRrule,
          'repeatFromCompletion': false,
        },
      },
    });
  });

  test(
    'sends only the fields that changed, and returns one to its default',
    () {
      final d = _defaults();
      final draft = ItemDefaultsDraft.from(d);
      draft.fields[7] = (mode: ItemDefaultMode.none, value: null);
      draft.fields[9] = (
        mode: ItemDefaultMode.fixed,
        value: const ItemDefaultFieldValue(offsetDays: 3),
      );
      draft.fields[11] = (mode: ItemDefaultMode.none, value: null);
      expect(draft.patchAgainst(d).toJson(), {
        'fields': [
          {'fieldId': 7, 'mode': 'none'},
          {
            'fieldId': 9,
            'mode': 'fixed',
            'value': {'offsetDays': 3},
          },
        ],
      });
    },
  );
}
