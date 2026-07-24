import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/sync/sync_manager.dart';
import 'package:pantry/sync/sync_op.dart';

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

  List<SyncOp> queued() => manager.queueForTest.all().toList();

  group('dead-lettering a poison op', () {
    test('drops the op itself and emits onSkipped', () async {
      final create = _op(
        uuid: 'c',
        entity: SyncEntity.category,
        op: SyncOpKind.create,
        tempEntityId: -1,
        body: {'name': 'Aisle 8'},
      );
      manager.queueForTest.enqueue(create);

      final skipped = manager.onSkipped.first;
      manager.deadLetterForTest(create);

      expect(queued(), isEmpty);
      final event = await skipped;
      expect(event.op.uuid, 'c');
      expect(event.reason, 'exhausted');
    });

    test('does not touch unrelated ops queued behind it', () {
      final create = _op(
        uuid: 'c',
        entity: SyncEntity.category,
        op: SyncOpKind.create,
        tempEntityId: -1,
      );
      final other = _op(
        uuid: 'o',
        entity: SyncEntity.store,
        op: SyncOpKind.create,
        tempEntityId: -2,
      );
      manager.queueForTest.enqueue(create);
      manager.queueForTest.enqueue(other);

      manager.deadLetterForTest(create);

      expect(queued().map((o) => o.uuid), ['o']);
    });
  });

  group('cascade cleanup for a dead category create', () {
    test('drops same-record follow-up update/delete on the temp id', () {
      final create = _op(
        uuid: 'c',
        entity: SyncEntity.category,
        op: SyncOpKind.create,
        tempEntityId: -1,
      );
      final update = _op(
        uuid: 'u',
        entity: SyncEntity.category,
        op: SyncOpKind.update,
        tempEntityId: -1,
        body: {'name': 'Renamed'},
      );
      manager.queueForTest.enqueue(create);
      manager.queueForTest.enqueue(update);

      manager.deadLetterForTest(create);

      expect(queued(), isEmpty);
    });

    test('strips the dead category from an item op but keeps the item', () {
      final create = _op(
        uuid: 'c',
        entity: SyncEntity.category,
        op: SyncOpKind.create,
        tempEntityId: -1,
      );
      final item = _op(
        uuid: 'i',
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.create,
        parentId: 5,
        tempEntityId: -9,
        body: {'name': 'Milk', 'categoryId': -1},
      );
      manager.queueForTest.enqueue(create);
      manager.queueForTest.enqueue(item);

      manager.deadLetterForTest(create);

      final remaining = queued();
      expect(remaining.map((o) => o.uuid), ['i']);
      expect(remaining.single.body.containsKey('categoryId'), isFalse);
      expect(remaining.single.body['name'], 'Milk');
    });

    test('prunes the dead id out of a category reorder', () {
      final create = _op(
        uuid: 'c',
        entity: SyncEntity.category,
        op: SyncOpKind.create,
        tempEntityId: -1,
      );
      final reorder = _op(
        uuid: 'r',
        entity: SyncEntity.category,
        op: SyncOpKind.reorder,
        body: {
          'order': [
            {'id': 7, 'sortOrder': 0},
            {'id': -1, 'sortOrder': 1},
            {'id': 8, 'sortOrder': 2},
          ],
        },
      );
      manager.queueForTest.enqueue(create);
      manager.queueForTest.enqueue(reorder);

      manager.deadLetterForTest(create);

      final remaining = queued();
      expect(remaining.map((o) => o.uuid), ['r']);
      final order = (remaining.single.body['order'] as List).cast<Map>();
      expect(order.map((e) => e['id']), [7, 8]);
    });
  });

  group('cascade cleanup for a dead list create', () {
    test('drops child item creates that named the dead list as parent', () {
      final list = _op(
        uuid: 'l',
        entity: SyncEntity.checklistList,
        op: SyncOpKind.create,
        tempEntityId: -1,
      );
      final item = _op(
        uuid: 'i',
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.create,
        parentId: -1,
        tempEntityId: -9,
        body: {'name': 'Milk'},
      );
      manager.queueForTest.enqueue(list);
      manager.queueForTest.enqueue(item);

      manager.deadLetterForTest(list);

      expect(queued(), isEmpty);
    });
  });

  group('cascade cleanup for a dead store create', () {
    test('removes the dead store from an item op storeIds', () {
      final store = _op(
        uuid: 's',
        entity: SyncEntity.store,
        op: SyncOpKind.create,
        tempEntityId: -1,
      );
      final item = _op(
        uuid: 'i',
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.create,
        parentId: 5,
        tempEntityId: -9,
        body: {
          'name': 'Milk',
          'storeIds': [-1, 42],
        },
      );
      manager.queueForTest.enqueue(store);
      manager.queueForTest.enqueue(item);

      manager.deadLetterForTest(store);

      final remaining = queued();
      expect(remaining.map((o) => o.uuid), ['i']);
      expect(remaining.single.body['storeIds'], [42]);
    });
  });
}
