import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/cache_store.dart';
import 'package:pantry_core/sync/id_remap.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/sync/sync_queue.dart';

int _seq = 0;
SyncQueue _newQueue() =>
    SyncQueue(CacheStore('test_item_defaults_queue_${_seq++}.json'));

SyncOp _defaults(String uuid, int listId, Map<String, dynamic> body) => SyncOp(
  uuid: uuid,
  entity: SyncEntity.checklistList,
  op: SyncOpKind.setItemDefaults,
  houseId: 1,
  entityId: listId > 0 ? listId : null,
  tempEntityId: listId < 0 ? listId : null,
  body: body,
  createdAt: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('merge — item defaults', () {
    test('write-backs on one list fold into one, per key', () {
      final q = _newQueue()
        ..enqueue(
          _defaults('a', 5, {
            'category': {'value': 1},
            'stores': {
              'value': [1],
            },
          }),
        )
        ..enqueue(
          _defaults('b', 5, {
            'category': {'value': 2},
          }),
        );
      q.merge();
      expect(q.length, 1);
      expect(q.peek()!.uuid, 'b');
      expect(q.peek()!.body, {
        'category': {'value': 2},
        'stores': {
          'value': [1],
        },
      });
    });

    test('a later mode change replaces an earlier write-back', () {
      final q = _newQueue()
        ..enqueue(
          _defaults('a', 5, {
            'stores': {
              'value': [1],
            },
          }),
        )
        ..enqueue(
          _defaults('b', 5, {
            'stores': {'mode': 'none'},
          }),
        );
      q.merge();
      expect(q.peek()!.body, {
        'stores': {'mode': 'none'},
      });
    });

    test('different lists stay apart', () {
      final q = _newQueue()
        ..enqueue(
          _defaults('a', 5, {
            'category': {'value': 1},
          }),
        )
        ..enqueue(
          _defaults('b', 6, {
            'category': {'value': 2},
          }),
        );
      q.merge();
      expect(q.length, 2);
    });

    test('a pending write-back is dropped when its list is deleted', () {
      final q = _newQueue()
        ..enqueue(
          _defaults('a', 5, {
            'category': {'value': 1},
          }),
        )
        ..enqueue(
          SyncOp(
            uuid: 'd',
            entity: SyncEntity.checklistList,
            op: SyncOpKind.delete,
            houseId: 1,
            entityId: 5,
            createdAt: 0,
          ),
        );
      q.merge();
      expect(q.length, 1);
      expect(q.peek()!.uuid, 'd');
    });
  });

  group('IdRemap.rewrite — item defaults', () {
    test('resolves the list and the stores, labels and category it names', () {
      final remap = IdRemap(CacheStore('test_item_defaults_remap.json'))
        ..bind(SyncEntity.checklistList, -1, 10)
        ..bind(SyncEntity.store, -2, 20)
        ..bind(SyncEntity.label, -3, 30)
        ..bind(SyncEntity.category, -4, 40);
      final op = remap.rewrite(
        _defaults('a', -1, {
          'stores': {
            'value': [-2, 7],
          },
          'labels': {
            'mode': 'fixed',
            'value': [-3],
          },
          'category': {'value': -4},
          'quantity': {'mode': 'fixed', 'value': '2'},
        }),
      );
      expect(op.entityId, 10);
      expect(op.body, {
        'stores': {
          'value': [20, 7],
        },
        'labels': {
          'mode': 'fixed',
          'value': [30],
        },
        'category': {'value': 40},
        'quantity': {'mode': 'fixed', 'value': '2'},
      });
    });
  });
}
