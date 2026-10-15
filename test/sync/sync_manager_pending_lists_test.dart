import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';

SyncOp _op({
  required String uuid,
  required SyncEntity entity,
  required SyncOpKind op,
  int houseId = 1,
  int? entityId,
  int? tempEntityId,
  int? parentId,
  Map<String, dynamic> body = const {},
}) => SyncOp(
  uuid: uuid,
  entity: entity,
  op: op,
  houseId: houseId,
  entityId: entityId,
  tempEntityId: tempEntityId,
  parentId: parentId,
  body: body,
  createdAt: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final manager = SyncManager.instance;

  setUp(() async => manager.reset());
  tearDown(() async => manager.reset());

  group('pendingListIds', () {
    test('empty queue yields an empty set', () {
      expect(manager.pendingListIds(1), isEmpty);
    });

    test('item op contributes its parent list id', () {
      manager.queueForTest.enqueue(
        _op(
          uuid: 'a',
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.toggle,
          parentId: 5,
          entityId: 42,
        ),
      );
      expect(manager.pendingListIds(1), {5});
    });

    test('list op contributes both its real and temp ids', () {
      manager.queueForTest.enqueue(
        _op(
          uuid: 'b',
          entity: SyncEntity.checklistList,
          op: SyncOpKind.create,
          tempEntityId: -3,
        ),
      );
      manager.queueForTest.enqueue(
        _op(
          uuid: 'c',
          entity: SyncEntity.checklistList,
          op: SyncOpKind.update,
          entityId: 7,
        ),
      );
      expect(manager.pendingListIds(1), {-3, 7});
    });

    test('ops from other houses are ignored', () {
      manager.queueForTest.enqueue(
        _op(
          uuid: 'd',
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.toggle,
          houseId: 99,
          parentId: 8,
        ),
      );
      expect(manager.pendingListIds(1), isEmpty);
    });

    test('a batch op poisons the result to null (lists unknowable)', () {
      manager.queueForTest.enqueue(
        _op(
          uuid: 'e',
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.batch,
          body: {
            'batchAction': 'move',
            'itemIds': [1, 2],
            'targetListId': 9,
          },
        ),
      );
      expect(manager.pendingListIds(1), isNull);
    });

    test('category/note ops contribute no list ids', () {
      manager.queueForTest.enqueue(
        _op(
          uuid: 'f',
          entity: SyncEntity.category,
          op: SyncOpKind.create,
          tempEntityId: -1,
        ),
      );
      manager.queueForTest.enqueue(
        _op(
          uuid: 'g',
          entity: SyncEntity.note,
          op: SyncOpKind.update,
          entityId: 4,
        ),
      );
      expect(manager.pendingListIds(1), isEmpty);
    });
  });

  group('pendingListRecordIds', () {
    test('counts list ops and reordered lists, not item ops', () {
      manager.queueForTest
        ..enqueue(
          _op(
            uuid: 'a',
            entity: SyncEntity.checklistList,
            op: SyncOpKind.create,
            tempEntityId: -1,
          ),
        )
        ..enqueue(
          _op(
            uuid: 'b',
            entity: SyncEntity.checklistList,
            op: SyncOpKind.update,
            entityId: 2,
          ),
        )
        ..enqueue(
          _op(
            uuid: 'c',
            entity: SyncEntity.checklistList,
            op: SyncOpKind.reorder,
            body: {
              'order': [
                {'id': 3, 'sortOrder': 0},
                {'id': 4, 'sortOrder': 1},
              ],
            },
          ),
        )
        ..enqueue(
          _op(
            uuid: 'd',
            entity: SyncEntity.checklistItem,
            op: SyncOpKind.update,
            entityId: 50,
            parentId: 5,
          ),
        )
        ..enqueue(
          _op(
            uuid: 'e',
            entity: SyncEntity.checklistList,
            op: SyncOpKind.update,
            houseId: 2,
            entityId: 6,
          ),
        );
      expect(manager.pendingListRecordIds(1), {-1, 2, 3, 4});
    });
  });
}
