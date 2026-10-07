import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/cache_store.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/user_prefs_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/sync/sync_queue.dart';

SyncOp _prefs(String uuid, Map<String, dynamic> body) => SyncOp(
  uuid: uuid,
  entity: SyncEntity.userPrefs,
  op: SyncOpKind.update,
  houseId: 0,
  body: body,
  createdAt: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;
  final prefs = PrefsService.instance;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (_) async => null);
    await manager.reset();
  });

  tearDown(() async {
    await manager.reset();
    await prefs.setSuggestArchivedItemsCache(false);
    await prefs.setBarcodeFillNameCache(true);
    await prefs.setBarcodeFillImageCache(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
  });

  test('queued pref writes collapse into one, latest value per key', () {
    final q = SyncQueue(CacheStore('test_user_prefs_queue.json'));
    q.enqueue(_prefs('a', {'barcodeFillName': false}));
    q.enqueue(_prefs('b', {'barcodeFillImage': false}));
    q.enqueue(_prefs('c', {'barcodeFillName': true}));

    q.merge();

    expect(q.length, 1);
    expect(q.peek()!.body, {
      'barcodeFillName': true,
      'barcodeFillImage': false,
    });
  });

  test('pendingUserPrefs replays queued writes in order', () {
    manager.queueForTest
      ..enqueue(_prefs('a', {'barcodeFillName': false}))
      ..enqueue(
        _prefs('b', {'barcodeFillName': true, 'barcodeFillImage': false}),
      );

    expect(manager.pendingUserPrefs(), {
      'barcodeFillName': true,
      'barcodeFillImage': false,
    });
  });

  test('hydration keeps a pref whose write is still queued', () async {
    await prefs.setBarcodeFillNameCache(false);
    manager.queueForTest.enqueue(_prefs('a', {'barcodeFillName': false}));

    await UserPrefsService.instance.hydrate({
      'barcodeFillName': true,
      'barcodeFillImage': false,
      'suggestArchivedItems': true,
    });

    expect(prefs.barcodeFillName, isFalse);
    expect(prefs.barcodeFillImage, isFalse);
    expect(prefs.suggestArchivedItems, isTrue);
  });

  test(
    'hydration leaves the cached defaults when the server omits a key',
    () async {
      await UserPrefsService.instance.hydrate({'suggestArchivedItems': true});

      expect(prefs.barcodeFillName, isTrue);
      expect(prefs.barcodeFillCategory, isTrue);
      expect(prefs.barcodeFillImage, isTrue);
    },
  );
}
