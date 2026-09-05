import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/cache_store.dart';

/// `CacheStore` serves two things that look alike and are not.
///
/// Ten of its files are regenerable renderings — refetched, or rebuilt by
/// laying the queue back over a snapshot. Two are the durable record of what
/// the user asked for, which nothing can reconstruct. Only the first class may
/// wait behind a debounce, and the difference has to be structural rather than
/// a convention each writer remembers.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cache_store_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => dir.path,
        );
  });

  tearDown(() async => dir.delete(recursive: true));

  Future<Map<String, dynamic>?> onDisk(String name) async {
    final file = File('${dir.path}/$name');
    if (!await file.exists()) return null;
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  test('a queue-class write is on disk without being flushed', () async {
    final store = CacheStore(
      'durability_queue.json',
      durability: CacheDurability.queue,
    );

    store.set('ops', 1);
    // One turn of the event loop — the write itself is async, but nothing
    // stands between the mutation and it.
    await Future<void>.delayed(Duration.zero);
    await store.flush();

    expect(await onDisk('durability_queue.json'), {'ops': 1});
  });

  test('a cache-class write waits, and a flush is what lands it', () async {
    final store = CacheStore('durability_cache.json');

    store.set('lists', 1);
    await Future<void>.delayed(Duration.zero);
    expect(
      await onDisk('durability_cache.json'),
      isNull,
      reason:
          'the trickle a settings screen produces should not be one write '
          'per keystroke',
    );

    await store.flush();
    expect(await onDisk('durability_cache.json'), {'lists': 1});
  });

  test('a debounced write lands on its own without a flush', () async {
    final store = CacheStore('durability_debounce.json');

    store.set('lists', 1);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    expect(await onDisk('durability_debounce.json'), {'lists': 1});
  });

  test('flushAll reaches a store nobody is holding', () async {
    // The checkpoint's whole job: an owner that never registered itself is
    // exactly the one whose write would otherwise be lost.
    CacheStore('durability_sweep.json').set('notes', 1);

    await CacheStore.flushAll();

    expect(await onDisk('durability_sweep.json'), {'notes': 1});
  });

  test('the last value wins when several land in one beat', () async {
    final store = CacheStore('durability_coalesce.json');

    store.set('lists', 1);
    store.set('lists', 2);
    store.set('lists', 3);
    await store.flush();

    expect(await onDisk('durability_coalesce.json'), {'lists': 3});
  });
}
