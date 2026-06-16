import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/services/cache_store.dart';
import 'package:pantry/sync/id_remap.dart';
import 'package:pantry/sync/sync_op.dart';

SyncOp _op({
  String uuid = 'u',
  required SyncOpKind kind,
  int? entityId,
  int? tempEntityId,
}) => SyncOp(
  uuid: uuid,
  entity: SyncEntity.checklistItem,
  op: kind,
  houseId: 1,
  entityId: entityId,
  tempEntityId: tempEntityId,
  createdAt: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IdRemap.rewrite', () {
    test('no-op when there is no temp id', () {
      final remap = IdRemap(CacheStore('test_remap.json'));
      final op = _op(kind: SyncOpKind.update, entityId: 5);
      expect(identical(remap.rewrite(op), op), isTrue);
    });

    test('no-op when temp id is unbound', () {
      final remap = IdRemap(CacheStore('test_remap.json'));
      final op = _op(kind: SyncOpKind.update, tempEntityId: -1);
      final out = remap.rewrite(op);
      expect(out.entityId, isNull);
      expect(out.tempEntityId, -1);
    });

    test('binds and rewrites a temp id to a real one', () {
      final remap = IdRemap(CacheStore('test_remap.json'));
      remap.bind(SyncEntity.checklistItem, -7, 42);
      final op = _op(kind: SyncOpKind.update, tempEntityId: -7);
      final out = remap.rewrite(op);
      expect(out.entityId, 42);
      expect(out.tempEntityId, -7);
    });

    test('does not cross entity types', () {
      final remap = IdRemap(CacheStore('test_remap.json'));
      remap.bind(SyncEntity.note, -7, 99);
      final op = _op(kind: SyncOpKind.update, tempEntityId: -7);
      final out = remap.rewrite(op);
      expect(out.entityId, isNull);
    });

    test('forget removes a binding', () {
      final remap = IdRemap(CacheStore('test_remap.json'));
      remap.bind(SyncEntity.checklistItem, -3, 30);
      remap.forget(SyncEntity.checklistItem, -3);
      final op = _op(kind: SyncOpKind.delete, tempEntityId: -3);
      expect(remap.rewrite(op).entityId, isNull);
    });
  });
}
