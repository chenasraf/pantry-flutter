import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/sync/sync_ids.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_wear/src/account/sign_out_page.dart';
import 'package:pantry_wear/src/scope/wear_scope.dart';
import 'package:pantry_wear/src/wear_shape.dart';

import 'wear_fixtures.dart';

/// What the watch does with a write of its own: what bounds the cache holding
/// it, and what a sign-out owes a wearer who still has one waiting.
///
/// Every cache-store call goes through [WidgetTester.runAsync]. A store reads
/// its directory over a platform channel and writes over real file I/O, and
/// neither is driven to completion by the fake-async zone a `testWidgets` body
/// runs in — a `load()` awaited directly there simply never returns.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');

  final sync = SyncManager.instance;
  final checklists = ChecklistService.instance;

  late Directory dir;
  final storage = <String, String>{};

  setUp(() async {
    WearShape.markFrom(['round']);
    storage.clear();
    dir = await Directory.systemTemp.createTemp('wear_offline_test');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(pathProvider, (call) async => dir.path);
    messenger.setMockMethodCallHandler(secureStorage, (call) async {
      final key = call.arguments['key'] as String? ?? '';
      return switch (call.method) {
        'read' => storage[key],
        'write' => storage[key] = call.arguments['value'] as String,
        'readAll' => Map<String, String>.from(storage),
        _ => null,
      };
    });
    await AuthService.instance.adoptCredentials(
      const NextcloudCredentials(
        serverUrl: 'https://cloud.example',
        loginName: 'ada',
        appPassword: 'secret',
      ),
    );
    await PrefsService.instance.setLastHouseId(1);
    await sync.reset();
    sync.setOnline(true);
    await checklists.cache.clear();
  });

  tearDown(() async {
    // The queue empties before the online flag comes back. Restoring it first
    // would kick a drain at a server this suite does not run, and the teardown
    // would then wait on it.
    await sync.reset();
    sync.setOnline(true);
    await checklists.cache.clear();
    await dir.delete(recursive: true);
  });

  group('scope bounds the cache', () {
    /// Two lists cached, sitting on the first — the state a switcher tap acts
    /// on.
    Future<void> seedTwoLists(WidgetTester tester) => tester.runAsync(() async {
      await checklists.cache.load();
      checklists.cacheItems(4, [testItem(id: 1, name: 'Milk')]);
      checklists.cacheItems(9, [testItem(id: 2, name: 'Bulbs', listId: 9)]);
      checklists.selectedListId = 4;
      await checklists.cache.flush();
    });

    testWidgets('leaving a list is what drops its items', (tester) async {
      await seedTwoLists(tester);

      // The watch owns one `(house, list)` pair, so nothing accumulates and
      // nothing has to be evicted — a stronger guarantee than a byte ceiling,
      // whose worst bug deletes an offline copy someone was relying on.
      await tester.runAsync(() => WearScope.instance.selectList(9));

      expect(checklists.getCachedItems(4), isNull);
      expect(checklists.getCachedItems(9), isNotNull);
    });

    testWidgets('the all-lists view keeps every list it is made of', (
      tester,
    ) async {
      await seedTwoLists(tester);

      await tester.runAsync(() => WearScope.instance.selectList(kAllListsId));

      expect(checklists.getCachedItems(4), isNotNull);
      expect(checklists.getCachedItems(9), isNotNull);
    });

    testWidgets('the pruned cache is what reaches disk', (tester) async {
      await seedTwoLists(tester);

      final held = await tester.runAsync(() async {
        await WearScope.instance.selectList(9);
        await checklists.cache.flush();
        final file = File('${dir.path}/checklist_cache.json');
        return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      });

      expect(held!.keys, isNot(contains('items:4')));
      expect(held.keys, contains('items:9'));
    });
  });

  group('signing out', () {
    SyncOp queuedCheck(int itemId) => SyncOp(
      uuid: SyncIds.newOpUuid(),
      entity: SyncEntity.checklistItem,
      op: SyncOpKind.toggle,
      houseId: 1,
      parentId: 4,
      entityId: itemId,
      createdAt: 0,
    );

    /// Queues [count] checks, offline so no drain reaches for a server this
    /// suite does not run — and inside [WidgetTester.runAsync], because an
    /// enqueue writes the queue file and a write started in the fake-async
    /// zone never finishes, wedging the `reset()` in teardown behind it.
    Future<void> queue(WidgetTester tester, int count) =>
        tester.runAsync(() async {
          sync.setOnline(false);
          for (var i = 1; i <= count; i++) {
            sync.enqueue(queuedCheck(i));
          }
        });

    /// The page *is* the confirmation: reaching it took a deliberate push, and
    /// the leading-edge strip it carries is the cancel a card on a crowded page
    /// could not offer.
    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(450, 450);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SignOutPage())),
      );
      await tester.pump();
    }

    testWidgets('an empty queue asks and says nothing else', (tester) async {
      await pump(tester);

      expect(find.text(m.wear.signOutTitle), findsOneWidget);
      expect(find.text(m.wear.signOutBody), findsOneWidget);
      expect(find.text(m.common.logout), findsOneWidget);
      expect(find.text(m.wear.signOutAnyway), findsNothing);
    });

    testWidgets('an unsent write is said out loud first', (tester) async {
      await queue(tester, 2);
      await pump(tester);

      // A 401 happens *to* the wearer and holds the queue; this is chosen, and
      // "signed out" has to mean the household data is off a watch that may
      // just have been handed to someone else. So the count is named, and
      // draining first is the offer rather than the only way out.
      expect(find.text(m.wear.signOutPending(2)), findsOneWidget);
      expect(find.text(m.wear.signOutWait), findsOneWidget);
      expect(find.text(m.wear.signOutAnyway), findsOneWidget);
    });

    testWidgets('choosing to wait holds the wearer there while it does', (
      tester,
    ) async {
      await queue(tester, 1);
      await pump(tester);

      // A 401 is what makes this deterministic *and* what makes it worth
      // asserting: the op is held rather than dropped, so the wait is real and
      // the watch must not sign out from under an unsent check-off.
      await http.runWithClient(() async {
        await tester.tap(find.text(m.wear.signOutWait));
        await tester.pump();
      }, () => MockClient((_) async => http.Response('{}', 401)));

      // The 401 arms the shared grace window before the degraded state is
      // published; let it fire rather than leaving a timer behind the page.
      await tester.pump(const Duration(seconds: 4));

      expect(sync.pendingCount.value, 1);
      expect(find.text(m.wear.signOutSending), findsOneWidget);
      expect(
        find.text(m.wear.signOutAnyway),
        findsNothing,
        reason:
            'the wearer has committed to waiting; the escape reappears '
            'only by leaving the page',
      );
    });
  });
}
