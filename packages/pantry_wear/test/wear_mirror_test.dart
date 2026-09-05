import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/category_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/store_service.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry_core/services/wear_mirror_service.dart';
import 'package:pantry_core/sync/sync_ids.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/services/wear_mirror_client.dart';
import 'package:pantry_wear/src/shell/wear_shell.dart';
import 'package:pantry_wear/src/wear_shape.dart';

import 'wear_fixtures.dart';

/// The watch's half of the phone→watch mirror.
///
/// The invariant under everything here: **seed once, never mirror again, and
/// the watch is still fully correct.** A snapshot only ever saves the watch a
/// request it could have made itself, which is what turns standalone, F-Droid,
/// LTE and out-of-range watches into one case rather than four.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel('dev.casraf.pantry/data_layer');
  const events = EventChannel('dev.casraf.pantry/data_layer/events');
  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final link = WearLinkService.instance;
  final mirror = WearMirrorService.instance;
  final client = WearMirrorClient.instance;

  final sent = <MethodCall>[];
  final storage = <String, String>{};
  late _StreamHandler handler;

  Map<String, dynamic> snapshot(List<Map<String, dynamic>> rows) =>
      mirror.snapshot(rows, capturedAt: DateTime.fromMillisecondsSinceEpoch(1));

  void emit(
    String path,
    Map<String, dynamic> payload, {
    String delivery = 'channel',
  }) {
    handler.emit({
      'delivery': delivery,
      'path': path,
      'payload': jsonEncode(payload),
      'nodeId': 'phone-1',
    });
  }

  /// The paths the watch sent, in order — its scope reports and its requests.
  List<String> sentPaths() => [
    for (final call in sent)
      if (call.method == 'send') call.arguments['path'] as String,
  ];

  setUp(() async {
    WearShape.markFrom(['round']);
    sent.clear();
    storage.clear();
    handler = _StreamHandler();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(methods, (call) async {
        sent.add(call);
        if (call.method == 'isAvailable') return true;
        if (call.method == 'nodes') {
          return [
            {'id': 'phone-1', 'name': 'Pixel', 'nearby': true},
          ];
        }
        return true;
      })
      ..setMockStreamHandler(events, handler)
      ..setMockMethodCallHandler(secureStorage, (call) async {
        final args = (call.arguments as Map?) ?? const {};
        switch (call.method) {
          case 'readAll':
            return Map<String, String>.from(storage);
          case 'write':
            storage[args['key'] as String] = args['value'] as String;
            return null;
          case 'delete':
            storage.remove(args['key'] as String);
            return null;
        }
        return null;
      });

    link.debugReset();
    WearLinkService.debugHostSupported = true;
    await mirror.clear();
    await ChecklistService.instance.cache.clear();
    await CategoryService.instance.cache.clear();
    await StoreService.instance.cache.clear();
  });

  tearDown(() async {
    await client.debugReset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(methods, null)
      ..setMockStreamHandler(events, null)
      ..setMockMethodCallHandler(secureStorage, null);
    WearLinkService.debugHostSupported = null;
    link.debugReset();
  });

  group('landing', () {
    test('a snapshot lands in the cache the page already reads', () async {
      await client.start();
      await pumpEventQueue();

      emit(
        mirror.pathFor(MirrorEntity.items, 4),
        snapshot([
          testItem(id: 1, name: 'Milk').toJson(),
          testItem(id: 2, name: 'Bread').toJson(),
        ]),
      );
      await pumpEventQueue();

      expect(ChecklistService.instance.getCachedItems(4)?.map((i) => i.name), [
        'Milk',
        'Bread',
      ]);
      expect(client.landedAt, isNotNull);
    });

    test('a mirror path on the wrong carrier is not landed', () async {
      await client.start();
      await pumpEventQueue();

      // `sendMessage` guarantees neither delivery nor ordering, so a snapshot
      // claiming to have arrived that way did not arrive whole.
      emit(
        mirror.pathFor(MirrorEntity.items, 4),
        snapshot([testItem(id: 1, name: 'Milk').toJson()]),
        delivery: 'message',
      );
      await pumpEventQueue();

      expect(ChecklistService.instance.getCachedItems(4), isNull);
      expect(client.landedAt, isNull);
    });

    test('credential traffic on the link is not a snapshot', () async {
      await client.start();
      await pumpEventQueue();

      emit('/creds', const {'token': 'abc'});
      await pumpEventQueue();

      expect(client.landedAt, isNull);
    });
  });

  group('scope authority', () {
    test('the watch reports what it is showing, once per change', () async {
      await PrefsService.instance.setLastHouseId(1);
      ChecklistService.instance.selectedListId = 4;

      await client.start();
      await pumpEventQueue();
      sent.clear();

      // The same scope again: the phone already holds it, and re-sending would
      // only make it re-fetch a list nothing has changed.
      await client.reportScope();
      expect(sentPaths(), isEmpty);

      ChecklistService.instance.selectedListId = 9;
      await client.reportScope();

      expect(sentPaths(), [WearMirrorService.scopeReportPath]);
      final report = MirrorScopeReport.fromJson(
        jsonDecode(sent.last.arguments['payload'] as String)
            as Map<String, dynamic>,
      );
      expect(report.houseId, 1);
      expect(report.listId, 9);
    });

    test('a trip is reported alongside the list it spans', () async {
      await PrefsService.instance.setLastHouseId(1);
      await client.start();
      await pumpEventQueue();
      sent.clear();

      client.setSession(12);
      await pumpEventQueue();

      final report = MirrorScopeReport.fromJson(
        jsonDecode(sent.last.arguments['payload'] as String)
            as Map<String, dynamic>,
      );
      expect(report.sessionId, 12);
    });

    test('a watch with no house yet reports nothing to mirror', () async {
      await PrefsService.instance.clear();
      await client.start();
      await pumpEventQueue();

      expect(sentPaths(), isNot(contains(WearMirrorService.scopeReportPath)));
    });

    test('waking asks rather than waiting to be told', () async {
      await PrefsService.instance.setLastHouseId(1);
      await client.start();
      await pumpEventQueue();

      expect(sentPaths(), contains(WearMirrorService.mirrorRequestPath));
    });
  });

  group('the seed-once invariant', () {
    testWidgets('one snapshot is enough to draw the page', (tester) async {
      // Landing writes through a cache store, whose drain cannot finish inside
      // the widget tester's fake-async zone — an unfinished one would still be
      // in flight when the next test awaits it.
      await tester.runAsync(() async {
        mirror.land(
          mirror.pathFor(MirrorEntity.lists, 1),
          snapshot([testList().toJson()]),
        );
        mirror.land(
          mirror.pathFor(MirrorEntity.categories, 1),
          snapshot([testCategory(id: 1, name: 'Dairy').toJson()]),
        );
        mirror.land(
          mirror.pathFor(MirrorEntity.items, 4),
          snapshot([
            testItem(id: 1, name: 'Milk', categoryId: 1).toJson(),
            testItem(id: 2, name: 'Butter', categoryId: 1).toJson(),
          ]),
        );
        await ChecklistService.instance.cache.flush();
        await CategoryService.instance.cache.flush();
        await mirror.cache.flush();
      });

      // Nothing but what one seed left in the caches — no fetch, and no
      // snapshot after it.
      final controller = ChecklistsController.seeded(
        houseId: 1,
        list: ChecklistService.instance.getCachedLists(1)!.single,
        lists: ChecklistService.instance.getCachedLists(1)!,
        items: ChecklistService.instance.getCachedItems(4)!,
        categories: CategoryService.instance.getCached(1)!,
      );

      tester.view.physicalSize = const Size(450, 450);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: WearShell(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Butter'), findsOneWidget);
      expect(find.text('Dairy'), findsWidgets);
      expect(find.text('Groceries'), findsWidgets);
    });

    test('a snapshot does not touch the queue holding a local write', () async {
      // The case that matters: a check made in an aisle, with the write still
      // unsent, while the phone is close enough to push a snapshot.
      SyncManager.instance.setOnline(false);
      final op = SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.checklistItem,
        op: SyncOpKind.toggle,
        houseId: 1,
        parentId: 4,
        entityId: 1,
        createdAt: 0,
      );
      SyncManager.instance.enqueue(op);
      addTearDown(() => SyncManager.instance.reset());

      // The server's view of the row, which predates the wearer's check.
      mirror.land(
        mirror.pathFor(MirrorEntity.items, 4),
        snapshot([testItem(id: 1, name: 'Milk').toJson()]),
      );

      // The wearer's intent is the queue's, and a snapshot is not a writer of
      // it — a credential problem or a stale mirror can lose the cache, never
      // the record of what the wearer asked for.
      expect(SyncManager.instance.pendingItemIds(1), contains(1));
    });
  });
}

class _StreamHandler extends MockStreamHandler {
  MockStreamHandlerEventSink? _sink;

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) =>
      _sink = events;

  @override
  void onCancel(Object? arguments) => _sink = null;

  void emit(Object? event) => _sink?.success(event);
}
