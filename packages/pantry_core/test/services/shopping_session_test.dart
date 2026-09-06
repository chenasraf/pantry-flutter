import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/services/shopping_service.dart';
import 'package:pantry_core/services/wear_mirror_service.dart';
import 'package:pantry_core/sync/sync_ids.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';

/// The two things a trip needs to survive on a device whose process dies
/// constantly: a record of itself that outlives the process, and a way for the
/// total typed at a till to wait out the dead link a till is usually behind.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final shopping = ShoppingService.instance;
  final sync = SyncManager.instance;
  final mirror = WearMirrorService.instance;

  ShoppingSession session({int id = 12, int? activeStoreId = 7}) =>
      ShoppingSession(
        id: id,
        houseId: 1,
        userId: 'ada',
        listIds: const [4],
        stores: const [ShoppingSessionStore(storeId: 7, position: 0)],
        activeStoreId: activeStoreId,
        includeUnassigned: true,
        isPrivate: false,
        lastSeenAt: 0,
        live: true,
        createdAt: 0,
        updatedAt: 0,
      );

  ListItem item(int id) => ListItem(
    id: id,
    listId: 4,
    name: 'item $id',
    storeIds: const [],
    done: false,
    repeatFromCompletion: false,
    deleteOnDone: false,
    sortOrder: id,
    createdAt: 0,
    updatedAt: 0,
  );

  SyncOp billed({int? storeId, double? total, String currency = 'USD'}) =>
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.shoppingSession,
        op: SyncOpKind.update,
        houseId: 1,
        parentId: 12,
        entityId: storeId,
        body: {
          'billedTotal': total,
          'billedCurrency': total == null ? null : currency,
        },
        createdAt: 0,
      );

  setUp(() async {
    await shopping.cache.clear();
    await mirror.clear();
    await sync.reset();
    sync.setOnline(false);
  });

  tearDown(() async {
    await sync.reset();
    sync.setOnline(true);
    await shopping.cache.clear();
  });

  group('the trip outlives the process', () {
    test('a recorded trip reads back whole', () {
      shopping.cacheSession(session());

      final held = shopping.getCachedSession();
      expect(held?.id, 12);
      expect(held?.activeStoreId, 7);
      expect(held?.orderedStoreIds, [7]);
    });

    test('clearing the trip takes its items with it', () {
      shopping.cacheSession(session());
      shopping.cacheItems(12, [item(1)]);

      shopping.cacheSession(null);

      expect(shopping.getCachedSession(), isNull);
      expect(
        shopping.getCachedItems(12),
        isNull,
        reason:
            'a closed trip is never read again, and a later trip whose '
            'own fetch fails must not fall back onto it',
      );
    });

    test('a mirrored trip lands where the watch already reads one', () {
      final landed = mirror.land(
        mirror.pathFor(MirrorEntity.session, 12),
        mirror.snapshot([
          session(activeStoreId: 7).toJson(),
        ], capturedAt: DateTime.fromMillisecondsSinceEpoch(1000)),
      );

      expect(landed, isTrue);
      expect(shopping.getCachedSession()?.id, 12);
    });

    test('a snapshot that cannot vouch for a trip does not end one', () {
      shopping.cacheSession(session());

      // Discovering that a trip is over is the watch's own read to make: an
      // empty or mismatched payload would clear a trip the wearer is standing
      // in the middle of.
      expect(
        mirror.land(
          mirror.pathFor(MirrorEntity.session, 12),
          mirror.snapshot(
            const [],
            capturedAt: DateTime.fromMillisecondsSinceEpoch(1000),
          ),
        ),
        isFalse,
      );
      expect(
        mirror.land(
          mirror.pathFor(MirrorEntity.session, 12),
          mirror.snapshot([
            session(id: 13).toJson(),
          ], capturedAt: DateTime.fromMillisecondsSinceEpoch(1000)),
        ),
        isFalse,
      );
      expect(shopping.getCachedSession()?.id, 12);
    });
  });

  group('a total typed at the till', () {
    test('is readable before it drains, per store and storeless', () {
      sync.enqueue(billed(storeId: 7, total: 12.5));
      sync.enqueue(billed(total: 40));

      final pending = sync.pendingSessionBilled(1, 12);
      expect(pending[7]?.total, 12.5);
      expect(pending[7]?.currency, 'USD');
      expect(pending[null]?.total, 40);
    });

    test('a correction is what shows, not the figure it replaced', () {
      sync.enqueue(billed(storeId: 7, total: 12.5));
      sync.enqueue(billed(storeId: 7, total: 13));

      expect(sync.pendingSessionBilled(1, 12)[7]?.total, 13);
    });

    test('an emptied field clears the figure rather than leaving it', () {
      sync.enqueue(billed(storeId: 7, total: null));

      final pending = sync.pendingSessionBilled(1, 12);
      expect(pending.containsKey(7), isTrue);
      expect(pending[7]?.total, isNull);
    });

    test('another trip is another record', () {
      sync.enqueue(billed(storeId: 7, total: 12.5));

      expect(sync.pendingSessionBilled(1, 99), isEmpty);
    });

    test('two trips at one shop do not collapse into each other', () {
      sync.enqueue(billed(storeId: 7, total: 12.5));
      sync.enqueue(
        SyncOp(
          uuid: SyncIds.newOpUuid(),
          entity: SyncEntity.shoppingSession,
          op: SyncOpKind.update,
          houseId: 1,
          parentId: 99,
          entityId: 7,
          body: const {'billedTotal': 40.0, 'billedCurrency': 'USD'},
          createdAt: 0,
        ),
      );

      // The store id repeats across trips, so the queue's update-collapse has
      // to key on the trip as well or the earlier total is simply lost.
      sync.queueForTest.merge();

      expect(sync.pendingSessionBilled(1, 12)[7]?.total, 12.5);
      expect(sync.pendingSessionBilled(1, 99)[7]?.total, 40.0);
    });
  });
}
