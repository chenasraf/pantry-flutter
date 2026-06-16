import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/services/cache_store.dart';
import 'package:pantry/sync/sync_op.dart';
import 'package:pantry/sync/sync_queue.dart';

int _seq = 0;
SyncQueue _newQueue() => SyncQueue(CacheStore('test_queue_${_seq++}.json'));

SyncOp _op({
  required String uuid,
  required SyncEntity entity,
  required SyncOpKind op,
  int? entityId,
  int? tempEntityId,
  int? parentId,
  Map<String, dynamic> body = const {},
  int createdAt = 0,
  int houseId = 1,
}) => SyncOp(
  uuid: uuid,
  entity: entity,
  op: op,
  houseId: houseId,
  entityId: entityId,
  tempEntityId: tempEntityId,
  parentId: parentId,
  body: body,
  createdAt: createdAt,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('basic enqueue/peek/pop', () {
    test('FIFO ordering', () {
      final q = _newQueue();
      q.enqueue(_op(uuid: 'a', entity: SyncEntity.note, op: SyncOpKind.create));
      q.enqueue(_op(uuid: 'b', entity: SyncEntity.note, op: SyncOpKind.create));
      expect(q.peek()?.uuid, 'a');
      q.pop('a');
      expect(q.peek()?.uuid, 'b');
      q.pop('b');
      expect(q.isEmpty, isTrue);
    });
  });

  group('merge — updates', () {
    test('multiple updates on same record collapse, latest fields win', () {
      final q = _newQueue();
      q.enqueue(
        _op(
          uuid: 'u1',
          entity: SyncEntity.note,
          op: SyncOpKind.update,
          entityId: 1,
          body: {'title': 'A', 'content': 'X'},
        ),
      );
      q.enqueue(
        _op(
          uuid: 'u2',
          entity: SyncEntity.note,
          op: SyncOpKind.update,
          entityId: 1,
          body: {'title': 'B'},
        ),
      );
      q.merge();
      expect(q.length, 1);
      final merged = q.peek()!;
      expect(merged.uuid, 'u2');
      expect(merged.body['title'], 'B');
      expect(merged.body['content'], 'X');
    });
  });

  group('merge — create + update', () {
    test('update folds into create body', () {
      final q = _newQueue();
      q.enqueue(
        _op(
          uuid: 'c',
          entity: SyncEntity.note,
          op: SyncOpKind.create,
          tempEntityId: -1,
          body: {'title': 'A'},
        ),
      );
      q.enqueue(
        _op(
          uuid: 'u',
          entity: SyncEntity.note,
          op: SyncOpKind.update,
          tempEntityId: -1,
          body: {'title': 'B', 'content': 'X'},
        ),
      );
      q.merge();
      expect(q.length, 1);
      expect(q.peek()!.uuid, 'c');
      expect(q.peek()!.body['title'], 'B');
      expect(q.peek()!.body['content'], 'X');
    });
  });

  group('merge — create + delete on temp', () {
    test('drops both ops', () {
      final q = _newQueue();
      q.enqueue(
        _op(
          uuid: 'c',
          entity: SyncEntity.note,
          op: SyncOpKind.create,
          tempEntityId: -1,
        ),
      );
      q.enqueue(
        _op(
          uuid: 'd',
          entity: SyncEntity.note,
          op: SyncOpKind.delete,
          tempEntityId: -1,
        ),
      );
      q.merge();
      expect(q.isEmpty, isTrue);
    });
  });

  group('merge — update + delete', () {
    test('drops the earlier update', () {
      final q = _newQueue();
      q.enqueue(
        _op(
          uuid: 'u',
          entity: SyncEntity.note,
          op: SyncOpKind.update,
          entityId: 5,
          body: {'title': 'X'},
        ),
      );
      q.enqueue(
        _op(
          uuid: 'd',
          entity: SyncEntity.note,
          op: SyncOpKind.delete,
          entityId: 5,
        ),
      );
      q.merge();
      expect(q.length, 1);
      expect(q.peek()!.uuid, 'd');
    });
  });

  group('merge — toggles', () {
    test('even count collapses to nothing', () {
      final q = _newQueue();
      for (var i = 0; i < 4; i++) {
        q.enqueue(
          _op(
            uuid: 't$i',
            entity: SyncEntity.checklistItem,
            op: SyncOpKind.toggle,
            entityId: 10,
          ),
        );
      }
      q.merge();
      expect(q.isEmpty, isTrue);
    });

    test('odd count collapses to one (the most recent)', () {
      final q = _newQueue();
      for (var i = 0; i < 3; i++) {
        q.enqueue(
          _op(
            uuid: 't$i',
            entity: SyncEntity.checklistItem,
            op: SyncOpKind.toggle,
            entityId: 10,
          ),
        );
      }
      q.merge();
      expect(q.length, 1);
      expect(q.peek()!.uuid, 't2');
    });
  });

  group('merge — reorders', () {
    test('keeps only the latest reorder per parent', () {
      final q = _newQueue();
      q.enqueue(
        _op(
          uuid: 'r1',
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.reorder,
          parentId: 1,
        ),
      );
      q.enqueue(
        _op(
          uuid: 'r2',
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.reorder,
          parentId: 1,
        ),
      );
      q.enqueue(
        _op(
          uuid: 'r3',
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.reorder,
          parentId: 2,
        ),
      );
      q.merge();
      expect(q.length, 2);
      final uuids = q.all().map((o) => o.uuid).toSet();
      expect(uuids, {'r2', 'r3'});
    });
  });

  group('merge — trash interactions', () {
    test('delete + restore cancel out', () {
      final q = _newQueue();
      q.enqueue(
        _op(
          uuid: 'd',
          entity: SyncEntity.note,
          op: SyncOpKind.delete,
          entityId: 1,
        ),
      );
      q.enqueue(
        _op(
          uuid: 'r',
          entity: SyncEntity.note,
          op: SyncOpKind.restore,
          entityId: 1,
        ),
      );
      q.merge();
      expect(q.isEmpty, isTrue);
    });

    test('delete + permanentDelete keeps only the permanent', () {
      final q = _newQueue();
      q.enqueue(
        _op(
          uuid: 'd',
          entity: SyncEntity.note,
          op: SyncOpKind.delete,
          entityId: 1,
        ),
      );
      q.enqueue(
        _op(
          uuid: 'p',
          entity: SyncEntity.note,
          op: SyncOpKind.permanentDelete,
          entityId: 1,
        ),
      );
      q.merge();
      expect(q.length, 1);
      expect(q.peek()!.uuid, 'p');
    });

    test('restore + permanentDelete keeps only the permanent', () {
      final q = _newQueue();
      q.enqueue(
        _op(
          uuid: 'r',
          entity: SyncEntity.note,
          op: SyncOpKind.restore,
          entityId: 1,
        ),
      );
      q.enqueue(
        _op(
          uuid: 'p',
          entity: SyncEntity.note,
          op: SyncOpKind.permanentDelete,
          entityId: 1,
        ),
      );
      q.merge();
      expect(q.length, 1);
      expect(q.peek()!.uuid, 'p');
    });
  });

  group('merge — preserves order across distinct records', () {
    test('multiple records each independently collapsed', () {
      final q = _newQueue();
      q.enqueue(
        _op(
          uuid: 'a1',
          entity: SyncEntity.note,
          op: SyncOpKind.update,
          entityId: 1,
          body: {'title': 'A'},
        ),
      );
      q.enqueue(
        _op(
          uuid: 'b1',
          entity: SyncEntity.note,
          op: SyncOpKind.update,
          entityId: 2,
          body: {'title': 'X'},
        ),
      );
      q.enqueue(
        _op(
          uuid: 'a2',
          entity: SyncEntity.note,
          op: SyncOpKind.update,
          entityId: 1,
          body: {'title': 'B'},
        ),
      );
      q.merge();
      expect(q.length, 2);
      final byId = {for (final o in q.all()) o.entityId: o};
      expect(byId[1]!.body['title'], 'B');
      expect(byId[2]!.body['title'], 'X');
    });
  });
}
