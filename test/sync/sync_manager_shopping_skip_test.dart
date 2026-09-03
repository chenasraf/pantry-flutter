import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';

SyncOp _op({
  required String uuid,
  required SyncOpKind op,
  int houseId = 1,
  int? entityId,
  int? parentId,
}) => SyncOp(
  uuid: uuid,
  entity: SyncEntity.shoppingSkip,
  op: op,
  houseId: houseId,
  entityId: entityId,
  parentId: parentId,
  createdAt: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final manager = SyncManager.instance;

  setUp(() async => manager.reset());
  tearDown(() async => manager.reset());

  group('pendingShoppingSkippedIds', () {
    test('empty queue yields an empty set', () {
      expect(manager.pendingShoppingSkippedIds(1, 5), isEmpty);
    });

    test('a queued skip (create) contributes its item id', () {
      manager.queueForTest.enqueue(
        _op(uuid: 'a', op: SyncOpKind.create, entityId: 42, parentId: 5),
      );
      expect(manager.pendingShoppingSkippedIds(1, 5), {42});
    });

    test('an unskip (delete) is excluded — undo must bring the item back', () {
      manager.queueForTest.enqueue(
        _op(uuid: 'b', op: SyncOpKind.delete, entityId: 42, parentId: 5),
      );
      expect(manager.pendingShoppingSkippedIds(1, 5), isEmpty);
    });

    test('skips from another session are ignored', () {
      manager.queueForTest.enqueue(
        _op(uuid: 'c', op: SyncOpKind.create, entityId: 42, parentId: 6),
      );
      expect(manager.pendingShoppingSkippedIds(1, 5), isEmpty);
    });

    test('skips from another house are ignored', () {
      manager.queueForTest.enqueue(
        _op(
          uuid: 'd',
          op: SyncOpKind.create,
          houseId: 99,
          entityId: 42,
          parentId: 5,
        ),
      );
      expect(manager.pendingShoppingSkippedIds(1, 5), isEmpty);
    });

    test('a skip does not leak into the checked-ids set', () {
      manager.queueForTest.enqueue(
        _op(uuid: 'e', op: SyncOpKind.create, entityId: 42, parentId: 5),
      );
      expect(manager.pendingShoppingCheckedIds(1, 5), isEmpty);
      expect(manager.pendingShoppingSkippedIds(1, 5), {42});
    });
  });

  group('pendingShoppingUnskippedIds', () {
    test('empty queue yields an empty set', () {
      expect(manager.pendingShoppingUnskippedIds(1, 5), isEmpty);
    });

    test('a queued unskip (delete) contributes its item id', () {
      manager.queueForTest.enqueue(
        _op(uuid: 'a', op: SyncOpKind.delete, entityId: 42, parentId: 5),
      );
      expect(manager.pendingShoppingUnskippedIds(1, 5), {42});
    });

    test('a skip (create) is excluded — it is a removal, not a restore', () {
      manager.queueForTest.enqueue(
        _op(uuid: 'b', op: SyncOpKind.create, entityId: 42, parentId: 5),
      );
      expect(manager.pendingShoppingUnskippedIds(1, 5), isEmpty);
    });

    test('unskips from another session are ignored', () {
      manager.queueForTest.enqueue(
        _op(uuid: 'c', op: SyncOpKind.delete, entityId: 42, parentId: 6),
      );
      expect(manager.pendingShoppingUnskippedIds(1, 5), isEmpty);
    });

    test('unskips from another house are ignored', () {
      manager.queueForTest.enqueue(
        _op(
          uuid: 'd',
          op: SyncOpKind.delete,
          houseId: 99,
          entityId: 42,
          parentId: 5,
        ),
      );
      expect(manager.pendingShoppingUnskippedIds(1, 5), isEmpty);
    });

    test('skip and unskip separate cleanly', () {
      manager.queueForTest.enqueue(
        _op(uuid: 'e', op: SyncOpKind.create, entityId: 1, parentId: 5),
      );
      manager.queueForTest.enqueue(
        _op(uuid: 'f', op: SyncOpKind.delete, entityId: 2, parentId: 5),
      );
      expect(manager.pendingShoppingSkippedIds(1, 5), {1});
      expect(manager.pendingShoppingUnskippedIds(1, 5), {2});
    });
  });
}
