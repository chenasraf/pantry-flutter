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

  group('IdRemap.rewrite — batch bodies', () {
    SyncOp batch(Map<String, dynamic> body) => SyncOp(
      uuid: 'b',
      entity: SyncEntity.checklistItem,
      op: SyncOpKind.batch,
      houseId: 1,
      body: body,
      createdAt: 0,
    );

    test('remaps temp item ids and leaves real ids untouched', () {
      final remap = IdRemap(CacheStore('test_remap.json'));
      remap.bind(SyncEntity.checklistItem, -1, 101);
      remap.bind(SyncEntity.checklistItem, -2, 102);
      final op = batch({
        'batchAction': 'delete',
        'itemIds': [-1, 5, -2],
      });
      final out = remap.rewrite(op);
      expect(out.body['itemIds'], [101, 5, 102]);
    });

    test('leaves unresolved temp item ids in place', () {
      final remap = IdRemap(CacheStore('test_remap.json'));
      remap.bind(SyncEntity.checklistItem, -1, 101);
      final op = batch({
        'batchAction': 'move',
        'itemIds': [-1, -9],
        'targetListId': 7,
      });
      final out = remap.rewrite(op);
      // -9 is still unbound, so it survives for the dependency check to catch.
      expect(out.body['itemIds'], [101, -9]);
    });

    test('remaps a temp target list id (move to an offline-created list)', () {
      final remap = IdRemap(CacheStore('test_remap.json'));
      remap.bind(SyncEntity.checklistList, -4, 44);
      final op = batch({
        'batchAction': 'move',
        'itemIds': [1, 2],
        'targetListId': -4,
      });
      expect(remap.rewrite(op).body['targetListId'], 44);
    });

    test('remaps a temp category id, and null clears stay null', () {
      final remap = IdRemap(CacheStore('test_remap.json'));
      remap.bind(SyncEntity.category, -3, 33);
      final assign = batch({
        'batchAction': 'category',
        'itemIds': [1],
        'categoryId': -3,
      });
      expect(remap.rewrite(assign).body['categoryId'], 33);

      final clear = batch({
        'batchAction': 'category',
        'itemIds': [1],
        'categoryId': null,
      });
      expect(remap.rewrite(clear).body['categoryId'], isNull);
    });

    test('returns the same instance when nothing needs rewriting', () {
      final remap = IdRemap(CacheStore('test_remap.json'));
      final op = batch({
        'batchAction': 'delete',
        'itemIds': [1, 2, 3],
      });
      expect(identical(remap.rewrite(op), op), isTrue);
    });
  });
}
