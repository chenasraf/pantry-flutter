import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/item_lifecycle.dart';
import 'package:pantry_core/models/list_recurrence.dart';
import 'package:pantry_core/services/server_version_service.dart';

void main() {
  tearDown(() => ServerVersionService.instance.debugSeed());

  void seedRecurrenceDefault(bool enabled) {
    ServerVersionService.instance.debugSeed(
      features: {if (enabled) kListDefaultRecurrenceFeature: true},
      featuresAuthoritative: true,
    );
  }

  Map<String, dynamic> listJson(Map<String, dynamic> extra) => {
    'id': 7,
    'houseId': 1,
    'name': 'Groceries',
    'icon': 'cart',
    'sortOrder': 0,
    'createdAt': 0,
    'updatedAt': 0,
    ...extra,
  };

  group('fromJson', () {
    test('reads the recurrence default a capable server sends', () {
      final list = ChecklistList.fromJson(
        listJson({
          'deleteOnDoneDefault': false,
          'defaultRecurrenceMode': 'recurring',
          'defaultRecurrenceKind': 'recurring',
          'defaultRrule': 'FREQ=DAILY;INTERVAL=2',
          'defaultRepeatFromCompletion': true,
        }),
      );

      expect(list.defaultRecurrenceMode, ListRecurrenceMode.recurring);
      expect(list.defaultRecurrenceKind, ListRecurrenceKind.recurring);
      expect(list.defaultRrule, 'FREQ=DAILY;INTERVAL=2');
      expect(list.defaultRepeatFromCompletion, isTrue);
    });

    test('derives the recurrence from the one-time flag alone', () {
      final once = ChecklistList.fromJson(
        listJson({'deleteOnDoneDefault': true}),
      );
      final staple = ChecklistList.fromJson(
        listJson({'deleteOnDoneDefault': false}),
      );

      expect(once.defaultRecurrenceKind, ListRecurrenceKind.once);
      expect(once.deleteOnDoneDefault, isTrue);
      expect(staple.defaultRecurrenceKind, ListRecurrenceKind.none);
      expect(staple.deleteOnDoneDefault, isFalse);
      // Nothing was pinned, so both still follow the last item added.
      expect(once.defaultRecurrenceMode, ListRecurrenceMode.remember);
    });

    test('survives a cache round-trip', () {
      final list = ChecklistList.fromJson(
        listJson({
          'defaultRecurrenceMode': 'remember',
          'defaultRecurrenceKind': 'recurring',
          'defaultRrule': 'FREQ=WEEKLY;INTERVAL=3',
          'defaultRepeatFromCompletion': true,
        }),
      );

      final restored = ChecklistList.fromJson(list.toJson());
      expect(restored.defaultRecurrenceMode, ListRecurrenceMode.remember);
      expect(restored.defaultRecurrenceKind, ListRecurrenceKind.recurring);
      expect(restored.defaultRrule, 'FREQ=WEEKLY;INTERVAL=3');
      expect(restored.defaultRepeatFromCompletion, isTrue);
    });
  });

  group('recurrenceDefault', () {
    setUp(() => seedRecurrenceDefault(true));

    test('a pinned mode names the recurrence and stops remembering', () {
      final list = ChecklistList.fromJson(
        listJson({
          'defaultRecurrenceMode': 'once',
          'defaultRecurrenceKind': 'once',
        }),
      );

      final resolved = list.recurrenceDefault;
      expect(resolved.kind, ListRecurrenceKind.once);
      expect(resolved.remembers, isFalse);
    });

    test('remember defers to the recurrence the last item used', () {
      final list = ChecklistList.fromJson(
        listJson({
          'defaultRecurrenceMode': 'remember',
          'defaultRecurrenceKind': 'recurring',
          'defaultRrule': 'FREQ=DAILY;INTERVAL=1',
          'defaultRepeatFromCompletion': true,
        }),
      );

      final resolved = list.recurrenceDefault;
      expect(resolved.kind, ListRecurrenceKind.recurring);
      expect(resolved.effectiveRrule, 'FREQ=DAILY;INTERVAL=1');
      expect(resolved.repeatFromCompletion, isTrue);
      expect(resolved.remembers, isTrue);
    });

    test('a recurring default without a rule falls back to weekly', () {
      final list = ChecklistList.fromJson(
        listJson({
          'defaultRecurrenceMode': 'recurring',
          'defaultRecurrenceKind': 'recurring',
        }),
      );

      expect(list.recurrenceDefault.effectiveRrule, kDefaultListRrule);
    });

    test('a non-recurring default carries no rule', () {
      final list = ChecklistList.fromJson(
        listJson({
          'defaultRecurrenceMode': 'once',
          'defaultRecurrenceKind': 'once',
          'defaultRrule': 'FREQ=DAILY;INTERVAL=1',
        }),
      );

      expect(list.recurrenceDefault.effectiveRrule, isNull);
    });

    test('a server without the capability keeps remembering the flag', () {
      seedRecurrenceDefault(false);
      final list = ChecklistList.fromJson(
        listJson({
          'deleteOnDoneDefault': true,
          // A pinned mode left over in the cache must not take effect against a
          // server that cannot honour it.
          'defaultRecurrenceMode': 'recurring',
          'defaultRecurrenceKind': 'once',
          'defaultRrule': 'FREQ=DAILY;INTERVAL=1',
        }),
      );

      final resolved = list.recurrenceDefault;
      expect(resolved.kind, ListRecurrenceKind.once);
      expect(resolved.remembers, isTrue);
      expect(resolved.effectiveRrule, isNull);
    });
  });

  group('normalizeRecurrenceDefault', () {
    test('pinning a mode also pins the recurrence', () {
      final result = normalizeRecurrenceDefault(
        mode: ListRecurrenceMode.once,
        currentKind: ListRecurrenceKind.recurring,
      );

      expect(result.kind, ListRecurrenceKind.once);
    });

    test('remember leaves the recurrence where it stands', () {
      final result = normalizeRecurrenceDefault(
        mode: ListRecurrenceMode.remember,
        currentKind: ListRecurrenceKind.recurring,
        rrule: 'FREQ=DAILY;INTERVAL=1',
        repeatFromCompletion: true,
      );

      expect(result.kind, ListRecurrenceKind.recurring);
      expect(result.rrule, 'FREQ=DAILY;INTERVAL=1');
      expect(result.repeatFromCompletion, isTrue);
    });

    test('a non-recurring default drops the rule it was handed', () {
      final result = normalizeRecurrenceDefault(
        mode: ListRecurrenceMode.none,
        currentKind: ListRecurrenceKind.none,
        rrule: 'FREQ=DAILY;INTERVAL=1',
        repeatFromCompletion: true,
      );

      expect(result.rrule, isNull);
      expect(result.repeatFromCompletion, isFalse);
    });

    test('a recurring default without a rule gets the fallback', () {
      final result = normalizeRecurrenceDefault(
        mode: ListRecurrenceMode.recurring,
        currentKind: ListRecurrenceKind.none,
      );

      expect(result.kind, ListRecurrenceKind.recurring);
      expect(result.rrule, kDefaultListRrule);
    });
  });

  group('covers', () {
    const weekly = ListRecurrenceDefault(
      kind: ListRecurrenceKind.recurring,
      rrule: 'FREQ=WEEKLY;INTERVAL=1',
      remembers: true,
    );

    test('an identical recurrence needs no write', () {
      expect(
        weekly.covers(
          kind: ListRecurrenceKind.recurring,
          rrule: 'FREQ=WEEKLY;INTERVAL=1',
          repeatFromCompletion: false,
        ),
        isTrue,
      );
    });

    test('a rule spelled without its default parts still matches', () {
      // The recurrence editor drops INTERVAL=1, so the rule an item carries is
      // rarely the literal string the list stores.
      expect(
        weekly.covers(
          kind: ListRecurrenceKind.recurring,
          rrule: 'FREQ=WEEKLY',
          repeatFromCompletion: false,
        ),
        isTrue,
      );
    });

    test('a different rule or origin does', () {
      expect(
        weekly.covers(
          kind: ListRecurrenceKind.recurring,
          rrule: 'FREQ=DAILY;INTERVAL=1',
          repeatFromCompletion: false,
        ),
        isFalse,
      );
      expect(
        weekly.covers(
          kind: ListRecurrenceKind.recurring,
          rrule: 'FREQ=WEEKLY;INTERVAL=1',
          repeatFromCompletion: true,
        ),
        isFalse,
      );
      expect(
        weekly.covers(
          kind: ListRecurrenceKind.once,
          repeatFromCompletion: false,
        ),
        isFalse,
      );
    });

    test('two non-recurring items match whatever rule the default holds', () {
      const once = ListRecurrenceDefault(
        kind: ListRecurrenceKind.once,
        rrule: 'FREQ=WEEKLY;INTERVAL=1',
      );

      expect(
        once.covers(kind: ListRecurrenceKind.once, repeatFromCompletion: false),
        isTrue,
      );
    });
  });

  group('lifecycle bridge', () {
    test('maps both ways', () {
      expect(ListRecurrenceKind.none.lifecycle, ItemLifecycle.staple);
      expect(ListRecurrenceKind.once.lifecycle, ItemLifecycle.once);
      expect(ListRecurrenceKind.recurring.lifecycle, ItemLifecycle.recurring);
      for (final kind in ListRecurrenceKind.values) {
        expect(kind.lifecycle.recurrenceKind, kind);
      }
    });
  });
}
