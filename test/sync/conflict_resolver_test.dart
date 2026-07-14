import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/sync/conflict_resolver.dart';
import 'package:pantry/sync/sync_op.dart';

SyncOp _op(SyncOpKind kind, {int createdAt = 100, int? entityId = 1}) => SyncOp(
  uuid: 'u',
  entity: SyncEntity.note,
  op: kind,
  houseId: 1,
  entityId: entityId,
  createdAt: createdAt,
);

void main() {
  const resolver = ConflictResolver();

  group('LWW by updatedAt', () {
    test('applies when local is strictly newer than server', () {
      final op = _op(SyncOpKind.update, createdAt: 200);
      expect(resolver.shouldApply(op, serverUpdatedAt: 100), isTrue);
    });

    test('rejects when server is newer', () {
      final op = _op(SyncOpKind.update, createdAt: 100);
      expect(resolver.shouldApply(op, serverUpdatedAt: 200), isFalse);
    });

    test('rejects on equal timestamps (server wins ties)', () {
      final op = _op(SyncOpKind.update, createdAt: 100);
      expect(resolver.shouldApply(op, serverUpdatedAt: 100), isFalse);
    });

    test('applies when server has no record', () {
      final op = _op(SyncOpKind.update);
      expect(resolver.shouldApply(op, serverUpdatedAt: null), isTrue);
    });
  });

  group('server tombstone', () {
    test('drops pending update if server has tombstoned the record', () {
      final op = _op(SyncOpKind.update, createdAt: 999);
      expect(
        resolver.shouldApply(op, serverUpdatedAt: 100, serverDeletedAt: 500),
        isFalse,
      );
    });

    test('drops pending toggle/reorder when tombstoned', () {
      expect(
        resolver.shouldApply(
          _op(SyncOpKind.toggle),
          serverUpdatedAt: 0,
          serverDeletedAt: 50,
        ),
        isFalse,
      );
      expect(
        resolver.shouldApply(
          _op(SyncOpKind.reorder),
          serverUpdatedAt: 0,
          serverDeletedAt: 50,
        ),
        isFalse,
      );
    });

    test('drops pending delete when tombstoned', () {
      expect(
        resolver.shouldApply(
          _op(SyncOpKind.delete),
          serverUpdatedAt: 0,
          serverDeletedAt: 50,
        ),
        isFalse,
      );
    });

    test('restore allowed only if newer than tombstone', () {
      expect(
        resolver.shouldApply(
          _op(SyncOpKind.restore, createdAt: 100),
          serverUpdatedAt: null,
          serverDeletedAt: 50,
        ),
        isTrue,
      );
      expect(
        resolver.shouldApply(
          _op(SyncOpKind.restore, createdAt: 10),
          serverUpdatedAt: null,
          serverDeletedAt: 50,
        ),
        isFalse,
      );
    });

    test('drops pending archive when tombstoned', () {
      expect(
        resolver.shouldApply(
          _op(SyncOpKind.archive),
          serverUpdatedAt: 0,
          serverDeletedAt: 50,
        ),
        isFalse,
      );
    });

    test('unarchive allowed only if newer than tombstone', () {
      expect(
        resolver.shouldApply(
          _op(SyncOpKind.unarchive, createdAt: 100),
          serverUpdatedAt: null,
          serverDeletedAt: 50,
        ),
        isTrue,
      );
      expect(
        resolver.shouldApply(
          _op(SyncOpKind.unarchive, createdAt: 10),
          serverUpdatedAt: null,
          serverDeletedAt: 50,
        ),
        isFalse,
      );
    });

    test('permanentDelete and emptyTrash always apply over a tombstone', () {
      expect(
        resolver.shouldApply(
          _op(SyncOpKind.permanentDelete),
          serverUpdatedAt: null,
          serverDeletedAt: 50,
        ),
        isTrue,
      );
      expect(
        resolver.shouldApply(
          _op(SyncOpKind.emptyTrash, entityId: null),
          serverUpdatedAt: null,
          serverDeletedAt: 50,
        ),
        isTrue,
      );
    });
  });
}
