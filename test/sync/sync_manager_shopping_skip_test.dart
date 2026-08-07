import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/sync/sync_manager.dart';
import 'package:pantry/sync/sync_op.dart';

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
}
