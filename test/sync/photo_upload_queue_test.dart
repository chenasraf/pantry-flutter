import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pantry_core/services/pending_upload_store.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry/views/photos/photo_board_controller.dart';

final _bytes = Uint8List.fromList([1, 2, 3, 4]);

SyncOp _photoOp(String uuid, {int houseId = 1}) => SyncOp(
  uuid: uuid,
  entity: SyncEntity.photo,
  op: SyncOpKind.create,
  houseId: houseId,
  tempEntityId: -1,
  body: {'fileName': 'shot.jpg', 'mimeType': 'image/jpeg'},
  createdAt: 0,
);

Future<File> _blob(String uuid) async {
  final docs = await getApplicationDocumentsDirectory();
  return File('${docs.path}/pending_uploads/$uuid');
}

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

  group('PendingUploadStore', () {
    test('round-trips bytes under the op uuid', () async {
      await PendingUploadStore.instance.save('op_a', _bytes);
      expect(await PendingUploadStore.instance.read('op_a'), _bytes);

      await PendingUploadStore.instance.delete('op_a');
      expect(await PendingUploadStore.instance.read('op_a'), isNull);
    });

    test('sweep keeps only the named blobs', () async {
      await PendingUploadStore.instance.save('op_keep', _bytes);
      await PendingUploadStore.instance.save('op_drop', _bytes);

      await PendingUploadStore.instance.sweep({'op_keep'});

      expect(await PendingUploadStore.instance.read('op_keep'), _bytes);
      expect(await PendingUploadStore.instance.read('op_drop'), isNull);
    });
  });

  group('queued photo uploads', () {
    test('pendingPhotoUploads reports only this house\'s photo ops', () {
      manager.queueForTest.enqueue(_photoOp('op_mine'));
      manager.queueForTest.enqueue(_photoOp('op_theirs', houseId: 2));
      manager.queueForTest.enqueue(
        SyncOp(
          uuid: 'op_note',
          entity: SyncEntity.note,
          op: SyncOpKind.create,
          houseId: 1,
          createdAt: 0,
        ),
      );

      expect(manager.pendingPhotoUploads(1).map((o) => o.uuid), ['op_mine']);
    });

    test('dropping the op leaves the bytes for a manual retry', () async {
      await PendingUploadStore.instance.save('op_dead', _bytes);
      final file = await _blob('op_dead');

      final op = _photoOp('op_dead');
      manager.queueForTest.enqueue(op);
      manager.deadLetterForTest(op);

      expect(manager.pendingPhotoUploads(1), isEmpty);
      expect(file.existsSync(), isTrue);
    });

    test('sign-out clears every blob', () async {
      await PendingUploadStore.instance.save('op_gone', _bytes);

      await manager.reset();

      expect(await PendingUploadStore.instance.read('op_gone'), isNull);
    });
  });

  group('PhotoBoardController offline capture', () {
    test('queues the photo with its bytes instead of dropping it', () async {
      manager.setOnline(false);
      final controller = PhotoBoardController(houseId: 1);
      addTearDown(controller.dispose);

      await controller.uploadPhotos([
        XFile.fromData(
          _bytes,
          name: 'shot.jpg',
          path: 'shot.jpg',
          mimeType: 'image/jpeg',
        ),
      ]);

      final queued = manager.pendingPhotoUploads(1);
      expect(queued, hasLength(1));
      expect(queued.single.body['fileName'], 'shot.jpg');
      expect(queued.single.body['mimeType'], 'image/jpeg');
      expect(
        await PendingUploadStore.instance.read(queued.single.uuid),
        _bytes,
      );

      // The tile stays on the board, marked as waiting rather than in flight,
      // so the capture never reads as lost — and draws off disk rather than
      // pinning the full-resolution image in memory until the link returns.
      expect(controller.uploads, hasLength(1));
      final task = controller.uploads.single;
      expect(task.isQueued, isTrue);
      expect(task.error, isNull);
      expect(task.thumbnailBytes, isNull);
      expect(task.pendingFile?.existsSync(), isTrue);
    });

    test('re-adopts a queued upload left by an earlier session', () async {
      manager.setOnline(false);
      final op = _photoOp('op_restored');
      await PendingUploadStore.instance.save(op.uuid, _bytes);
      manager.queueForTest.enqueue(op);

      final controller = PhotoBoardController(houseId: 1);
      addTearDown(controller.dispose);
      await pumpEventQueue();

      expect(controller.uploads, hasLength(1));
      final task = controller.uploads.single;
      expect(task.opUuid, 'op_restored');
      expect(task.fileName, 'shot.jpg');
      expect(task.pendingFile?.readAsBytesSync(), _bytes);
    });

    test('retrying a dropped upload reclaims its bytes', () async {
      manager.setOnline(false);
      final op = _photoOp('op_dropped');
      await PendingUploadStore.instance.save(op.uuid, _bytes);
      manager.queueForTest.enqueue(op);

      final controller = PhotoBoardController(houseId: 1);
      addTearDown(controller.dispose);
      await pumpEventQueue();

      manager.deadLetterForTest(op);
      await pumpEventQueue();

      final task = controller.uploads.single;
      expect(task.isQueued, isFalse);
      expect(task.error, 'exhausted');

      await controller.retryUpload(task);

      // Still offline, so it goes straight back to the queue — under a fresh op
      // carrying the same picture.
      final requeued = manager.pendingPhotoUploads(1);
      expect(requeued, hasLength(1));
      expect(requeued.single.uuid, isNot('op_dropped'));
      expect(
        await PendingUploadStore.instance.read(requeued.single.uuid),
        _bytes,
      );
      expect((await _blob('op_dropped')).existsSync(), isFalse);
    });
  });
}
