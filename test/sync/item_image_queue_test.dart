import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/pending_upload_store.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';

import '../helpers/test_models.dart';

final _bytes = Uint8List.fromList([9, 8, 7]);

SyncOp _imageOp(
  String uuid, {
  required SyncOpKind kind,
  int? entityId,
  int? tempEntityId,
  int listId = 10,
}) => SyncOp(
  uuid: uuid,
  entity: SyncEntity.checklistItem,
  op: kind,
  houseId: 1,
  parentId: listId,
  entityId: entityId,
  tempEntityId: tempEntityId,
  body: kind == SyncOpKind.setImage
      ? {'fileName': 'shot.jpg', 'mimeType': 'image/jpeg'}
      : const {},
  createdAt: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final manager = SyncManager.instance;

  setUp(() async {
    await manager.reset();
    manager.setOnline(true);
  });
  tearDown(() async {
    await manager.reset();
    manager.setOnline(true);
  });

  List<SyncOp> queued() => manager.queueForTest.all().toList();

  group('attaching an image offline', () {
    test(
      'queues the attachment with its bytes instead of dropping it',
      () async {
        manager.setOnline(false);
        final controller = ChecklistsController(houseId: 1);
        addTearDown(controller.dispose);

        await controller.uploadItemImage(
          makeListItem(id: 42, listId: 10),
          bytes: _bytes,
          fileName: 'shot.jpg',
          mimeType: 'image/jpeg',
        );

        final op = queued().single;
        expect(op.op, SyncOpKind.setImage);
        expect(op.entityId, 42);
        expect(op.parentId, 10);
        expect(op.body['fileName'], 'shot.jpg');
        expect(await PendingUploadStore.instance.read(op.uuid), _bytes);
      },
    );

    test(
      'an image on an unsynced item waits on that item\'s real id',
      () async {
        manager.setOnline(false);
        final controller = ChecklistsController(houseId: 1);
        addTearDown(controller.dispose);

        await controller.uploadItemImage(
          makeListItem(id: -5, listId: 10),
          bytes: _bytes,
          fileName: 'shot.jpg',
          mimeType: 'image/jpeg',
        );

        // No server id to address yet — the queue holds the op until the item's
        // create binds one, which is what the temp id is for.
        final op = queued().single;
        expect(op.tempEntityId, -5);
        expect(op.entityId, isNull);
        expect(await PendingUploadStore.instance.read(op.uuid), _bytes);
      },
    );

    test('removing an image queues a clear', () async {
      manager.setOnline(false);
      final controller = ChecklistsController(houseId: 1);
      addTearDown(controller.dispose);

      await controller.deleteItemImage(makeListItem(id: 42, listId: 10));

      final op = queued().single;
      expect(op.op, SyncOpKind.clearImage);
      expect(op.entityId, 42);
    });
  });

  group('showing an image that has not uploaded yet', () {
    test('the item offers the queued file while it waits', () async {
      manager.setOnline(false);
      final controller = ChecklistsController(houseId: 1);
      addTearDown(controller.dispose);

      await controller.uploadItemImage(
        makeListItem(id: 42, listId: 10),
        bytes: _bytes,
        fileName: 'shot.jpg',
        mimeType: 'image/jpeg',
      );
      await pumpEventQueue();

      final file = controller.pendingItemImage(42);
      expect(file, isNotNull);
      expect(file!.readAsBytesSync(), _bytes);
    });

    test('an image on an unsynced item answers to both its ids', () async {
      manager.setOnline(false);
      final op = _imageOp('img', kind: SyncOpKind.setImage, tempEntityId: -5);
      await PendingUploadStore.instance.save(op.uuid, _bytes);
      manager.queueForTest.enqueue(op);
      manager.remapForTest.bind(SyncEntity.checklistItem, -5, 99);

      final controller = ChecklistsController(houseId: 1);
      addTearDown(controller.dispose);
      await pumpEventQueue();

      // The row may still be drawn under the temp id or already under the real
      // one, depending on whether the create's applied event has landed.
      expect(controller.pendingItemImage(-5), isNotNull);
      expect(controller.pendingItemImage(99), isNotNull);
    });

    test('a queued removal takes the picture back off the row', () async {
      manager.setOnline(false);
      final controller = ChecklistsController(houseId: 1);
      addTearDown(controller.dispose);

      final item = makeListItem(id: 42, listId: 10);
      await controller.uploadItemImage(
        item,
        bytes: _bytes,
        fileName: 'shot.jpg',
        mimeType: 'image/jpeg',
      );
      await pumpEventQueue();
      expect(controller.pendingItemImage(42), isNotNull);

      await controller.deleteItemImage(item);
      await pumpEventQueue();

      expect(controller.pendingItemImage(42), isNull);
    });

    test('nothing is offered once the upload lands', () async {
      manager.setOnline(false);
      final controller = ChecklistsController(houseId: 1);
      addTearDown(controller.dispose);

      await controller.uploadItemImage(
        makeListItem(id: 42, listId: 10),
        bytes: _bytes,
        fileName: 'shot.jpg',
        mimeType: 'image/jpeg',
      );
      await pumpEventQueue();

      manager.queueForTest.pop(queued().single.uuid);
      manager.pendingCount.value = 0;
      await pumpEventQueue();

      expect(controller.pendingItemImage(42), isNull);
    });
  });

  group('collapsing queued image writes', () {
    test('two attachments on one item leave only the last', () {
      manager.queueForTest.enqueue(
        _imageOp('a', kind: SyncOpKind.setImage, entityId: 42),
      );
      manager.queueForTest.enqueue(
        _imageOp('b', kind: SyncOpKind.setImage, entityId: 42),
      );

      manager.queueForTest.merge();

      expect(queued().map((o) => o.uuid), ['b']);
    });

    test('attach then remove leaves only the removal', () {
      manager.queueForTest.enqueue(
        _imageOp('a', kind: SyncOpKind.setImage, tempEntityId: -5),
      );
      manager.queueForTest.enqueue(
        _imageOp('b', kind: SyncOpKind.clearImage, tempEntityId: -5),
      );

      manager.queueForTest.merge();

      expect(queued().map((o) => o.uuid), ['b']);
    });

    test('attachments on different items are left alone', () {
      manager.queueForTest.enqueue(
        _imageOp('a', kind: SyncOpKind.setImage, entityId: 42),
      );
      manager.queueForTest.enqueue(
        _imageOp('b', kind: SyncOpKind.setImage, entityId: 43),
      );

      manager.queueForTest.merge();

      expect(queued().map((o) => o.uuid), ['a', 'b']);
    });

    test('an attachment to an item being deleted is dropped', () {
      manager.queueForTest.enqueue(
        _imageOp('img', kind: SyncOpKind.setImage, entityId: 42),
      );
      manager.queueForTest.enqueue(
        SyncOp(
          uuid: 'del',
          entity: SyncEntity.checklistItem,
          op: SyncOpKind.delete,
          houseId: 1,
          parentId: 10,
          entityId: 42,
          createdAt: 0,
        ),
      );

      manager.queueForTest.merge();

      expect(queued().map((o) => o.uuid), ['del']);
    });

    test(
      'an attachment to an item created and deleted offline never ships',
      () {
        manager.queueForTest.enqueue(
          SyncOp(
            uuid: 'create',
            entity: SyncEntity.checklistItem,
            op: SyncOpKind.create,
            houseId: 1,
            parentId: 10,
            tempEntityId: -5,
            body: const {'name': 'Milk'},
            createdAt: 0,
          ),
        );
        manager.queueForTest.enqueue(
          _imageOp('img', kind: SyncOpKind.setImage, tempEntityId: -5),
        );
        manager.queueForTest.enqueue(
          SyncOp(
            uuid: 'del',
            entity: SyncEntity.checklistItem,
            op: SyncOpKind.delete,
            houseId: 1,
            parentId: 10,
            tempEntityId: -5,
            createdAt: 0,
          ),
        );

        manager.queueForTest.merge();

        // Nothing survives: an image addressing a temp id whose create is gone
        // would hold the head of the queue forever.
        expect(queued(), isEmpty);
      },
    );
  });
}
