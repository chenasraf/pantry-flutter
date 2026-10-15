import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/cache_store.dart';
import 'package:pantry_core/sync/id_remap.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/sync/sync_queue.dart';

int _seq = 0;
SyncQueue _newQueue() =>
    SyncQueue(CacheStore('test_item_sort_queue_${_seq++}.json'));

SyncOp _sort(String uuid, int listId, String sort) => SyncOp(
  uuid: uuid,
  entity: SyncEntity.checklistList,
  op: SyncOpKind.setItemSort,
  houseId: 1,
  entityId: listId >= 0 ? listId : null,
  tempEntityId: listId < 0 ? listId : null,
  body: {'itemSort': sort},
  createdAt: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('merge — item sort', () {
    test('only the latest sort per list is sent', () {
      final q = _newQueue()
        ..enqueue(_sort('a', 5, 'name_asc'))
        ..enqueue(_sort('b', 5, 'newest'))
        ..enqueue(_sort('c', 5, 'category'));
      q.merge();
      expect(q.length, 1);
      expect(q.peek()!.uuid, 'c');
    });

    test('interleaved lists each keep their own latest', () {
      final q = _newQueue()
        ..enqueue(_sort('a', 5, 'name_asc'))
        ..enqueue(_sort('b', 6, 'oldest'))
        ..enqueue(_sort('c', 5, 'newest'))
        ..enqueue(_sort('d', 6, 'store'));
      q.merge();
      expect(q.all().map((o) => o.uuid), ['c', 'd']);
    });

    test('house-wide sorts collapse per house, apart from list sorts', () {
      SyncOp house(String uuid, int houseId, String sort) => SyncOp(
        uuid: uuid,
        entity: SyncEntity.checklistList,
        op: SyncOpKind.setItemSort,
        houseId: houseId,
        body: {'itemSort': sort},
        createdAt: 0,
      );
      final q = _newQueue()
        ..enqueue(house('a', 1, 'name_asc'))
        ..enqueue(house('b', 2, 'oldest'))
        ..enqueue(_sort('c', 5, 'store'))
        ..enqueue(house('d', 1, 'newest'));
      q.merge();
      expect(q.all().map((o) => o.uuid), ['b', 'c', 'd']);
    });

    test('a pending sort is dropped when its list is deleted', () {
      final q = _newQueue()
        ..enqueue(_sort('a', 5, 'newest'))
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
      expect(q.all().map((o) => o.uuid), ['d']);
    });
  });

  test('a sort on an unsynced list resolves to its real id', () {
    final remap = IdRemap(CacheStore('test_item_sort_remap.json'))
      ..bind(SyncEntity.checklistList, -1, 10);
    final op = remap.rewrite(_sort('a', -1, 'newest'));
    expect(op.entityId, 10);
    expect(op.body, {'itemSort': 'newest'});
  });
}
