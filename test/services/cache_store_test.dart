import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/services/cache_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // path_provider's default implementation talks to this channel; point
  // `getApplicationDocumentsDirectory` at a real temp dir so the store writes
  // to disk during the test.
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('cache_store_test');
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') return tmp.path;
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    tmp.deleteSync(recursive: true);
  });

  test('a burst of concurrent un-awaited writes all survive to disk', () async {
    final store = CacheStore('burst.json');

    // Mirror the load()+precache burst: many mutations fired back-to-back
    // without awaiting, each triggering its own serialized save.
    for (var i = 0; i < 50; i++) {
      store.set('key_$i', i);
    }
    store.setList('items:1', [1, 2, 3], (n) => {'n': n});
    await store.flush();

    // A fresh instance reads whatever actually landed on disk. Before writes
    // were serialized, an earlier/smaller snapshot could finish last and drop
    // keys written after it (issue #92).
    final reloaded = CacheStore('burst.json');
    await reloaded.load();

    for (var i = 0; i < 50; i++) {
      expect(reloaded.get<int>('key_$i'), i, reason: 'key_$i was lost');
    }
    expect(reloaded.getList<int>('items:1', (j) => j['n'] as int), [1, 2, 3]);
  });

  test('last write wins after interleaved updates to the same key', () async {
    final store = CacheStore('lww.json');
    for (var i = 0; i < 20; i++) {
      store.set('v', i);
    }
    await store.flush();

    final reloaded = CacheStore('lww.json');
    await reloaded.load();
    expect(reloaded.get<int>('v'), 19);
  });
}
