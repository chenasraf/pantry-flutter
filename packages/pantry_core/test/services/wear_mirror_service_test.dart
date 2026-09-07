import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/category.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/note.dart';
import 'package:pantry_core/models/store.dart';
import 'package:pantry_core/services/category_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/note_service.dart';
import 'package:pantry_core/services/shopping_service.dart';
import 'package:pantry_core/services/store_service.dart';
import 'package:pantry_core/services/wear_mirror_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mirror = WearMirrorService.instance;

  ListItem item(int id, {int listId = 4, bool done = false}) => ListItem(
    id: id,
    listId: listId,
    name: 'item $id',
    storeIds: const [],
    done: done,
    repeatFromCompletion: false,
    deleteOnDone: false,
    sortOrder: id,
    createdAt: 0,
    updatedAt: 0,
  );

  Map<String, dynamic> snapshotOf(
    List<Map<String, dynamic>> rows, {
    DateTime? capturedAt,
  }) => mirror.snapshot(
    rows,
    capturedAt: capturedAt ?? DateTime.fromMillisecondsSinceEpoch(1000),
  );

  setUp(() async {
    await mirror.clear();
    await ChecklistService.instance.cache.clear();
    await CategoryService.instance.cache.clear();
    await StoreService.instance.cache.clear();
    await NoteService.instance.cache.clear();
    await ShoppingService.instance.cache.clear();
  });

  group('paths', () {
    test('a path round-trips to the scope it addresses', () {
      final path = mirror.pathFor(MirrorEntity.items, 4);

      expect(path, '/mirror/items/4');
      expect(mirror.scopeOf(path), (entity: MirrorEntity.items, key: 4));
    });

    test('control and credential traffic is not a mirror path', () {
      expect(mirror.scopeOf(WearMirrorService.scopeReportPath), isNull);
      expect(mirror.scopeOf('/creds'), isNull);
      expect(mirror.scopeOf('/mirror/items'), isNull);
      expect(mirror.scopeOf('/mirror/items/all'), isNull);
    });

    test('an entity this build does not know is not landed', () {
      expect(mirror.scopeOf('/mirror/recipes/1'), isNull);
      expect(mirror.land('/mirror/recipes/1', snapshotOf(const [])), isFalse);
    });
  });

  group('landing', () {
    test('items land through the seam a fetch writes', () {
      final landed = mirror.land(
        mirror.pathFor(MirrorEntity.items, 4),
        snapshotOf([item(1).toJson(), item(2).toJson()]),
      );

      expect(landed, isTrue);
      expect(ChecklistService.instance.getCachedItems(4)?.map((i) => i.id), [
        1,
        2,
      ]);
    });

    test('lists, categories, stores and notes each land on their own', () {
      mirror.land(
        mirror.pathFor(MirrorEntity.lists, 1),
        snapshotOf([
          ChecklistList(
            id: 4,
            houseId: 1,
            name: 'Groceries',
            icon: 'shopping-cart',
            sortOrder: 0,
            createdAt: 0,
            updatedAt: 0,
          ).toJson(),
        ]),
      );
      mirror.land(
        mirror.pathFor(MirrorEntity.categories, 1),
        snapshotOf([
          Category(
            id: 7,
            houseId: 1,
            name: 'Produce',
            icon: 'vegetable',
            color: '#6FBF73',
            sortOrder: 0,
            createdAt: 0,
            updatedAt: 0,
          ).toJson(),
        ]),
      );
      mirror.land(
        mirror.pathFor(MirrorEntity.stores, 1),
        snapshotOf([
          Store(
            id: 9,
            houseId: 1,
            name: 'Market',
            icon: 'supermarket',
            color: '#5BA8E0',
            sortOrder: 0,
            createdAt: 0,
            updatedAt: 0,
          ).toJson(),
        ]),
      );
      mirror.land(
        mirror.pathFor(MirrorEntity.notes, 1),
        snapshotOf([
          Note(
            id: 3,
            houseId: 1,
            title: 'Wifi',
            content: '- [ ] reset router',
            color: '#FFCC00',
            createdBy: 'casraf',
            sortOrder: 0,
            createdAt: 0,
            updatedAt: 0,
          ).toJson(),
        ]),
      );

      expect(ChecklistService.instance.getCachedLists(1), hasLength(1));
      expect(CategoryService.instance.getCached(1)?.single.name, 'Produce');
      expect(StoreService.instance.getCached(1)?.single.name, 'Market');
      expect(NoteService.instance.getCachedNotes(1)?.single.title, 'Wifi');
    });

    test('a trip keeps one snapshot, not one per session it has seen', () {
      mirror.land(
        mirror.pathFor(MirrorEntity.sessionItems, 12),
        snapshotOf([item(1).toJson()]),
      );
      mirror.land(
        mirror.pathFor(MirrorEntity.sessionItems, 13),
        snapshotOf([item(2).toJson()]),
      );

      expect(ShoppingService.instance.getCachedItems(13), hasLength(1));
      expect(ShoppingService.instance.getCachedItems(12), isNull);
    });

    test('replaying a snapshot leaves the same state behind', () {
      final path = mirror.pathFor(MirrorEntity.items, 4);
      final payload = snapshotOf([item(1).toJson(), item(2).toJson()]);

      mirror.land(path, payload);
      mirror.land(path, payload);

      expect(ChecklistService.instance.getCachedItems(4), hasLength(2));
    });

    test('a malformed payload lands nothing rather than half of it', () {
      final path = mirror.pathFor(MirrorEntity.items, 4);
      mirror.land(path, snapshotOf([item(1).toJson()]));

      expect(mirror.land(path, const {'rows': 'not-a-list'}), isFalse);
      expect(mirror.land(path, const {}), isFalse);
      expect(
        mirror.land(path, const {
          'rows': [1, 2],
        }),
        isFalse,
      );
      expect(ChecklistService.instance.getCachedItems(4), hasLength(1));
    });

    test('landing notifies, so a page can re-read what arrived', () {
      var notified = 0;
      void listener() => notified += 1;
      mirror.addListener(listener);
      addTearDown(() => mirror.removeListener(listener));

      mirror.land(
        mirror.pathFor(MirrorEntity.items, 4),
        snapshotOf([item(1).toJson()]),
      );
      mirror.land('/mirror/nope/4', snapshotOf(const []));

      expect(notified, 1);
    });
  });

  group('capturedAt', () {
    test('records when each snapshot was taken, not when it arrived', () {
      mirror.land(
        mirror.pathFor(MirrorEntity.items, 4),
        snapshotOf(
          const [],
          capturedAt: DateTime.fromMillisecondsSinceEpoch(5000),
        ),
      );

      expect(
        mirror.capturedAt(MirrorEntity.items, 4),
        DateTime.fromMillisecondsSinceEpoch(5000),
      );
      expect(mirror.capturedAt(MirrorEntity.items, 9), isNull);
    });

    test('the newest wins, whatever order the scopes arrive in', () {
      mirror.land(
        mirror.pathFor(MirrorEntity.items, 4),
        snapshotOf(
          const [],
          capturedAt: DateTime.fromMillisecondsSinceEpoch(9000),
        ),
      );
      mirror.land(
        mirror.pathFor(MirrorEntity.lists, 1),
        snapshotOf(
          const [],
          capturedAt: DateTime.fromMillisecondsSinceEpoch(3000),
        ),
      );

      expect(mirror.lastCapturedAt, DateTime.fromMillisecondsSinceEpoch(9000));
    });

    test('nothing landed reads as nothing landed, not as long ago', () {
      expect(mirror.lastCapturedAt, isNull);
    });
  });
}
