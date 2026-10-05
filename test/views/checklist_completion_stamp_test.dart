import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/date_format.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';
import 'package:pantry/views/checklists/progress_hero.dart';
import 'package:pantry/views/checklists/switcher_list_stage.dart';

import '../helpers/test_app.dart';

/// `lastCompletedAt` records when a list was last signed off. It is history,
/// not state: nothing clears it, so a list with open items still carries it
/// and must keep reading as what is left to do.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  final stamp =
      DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch ~/
      1000;

  Map<String, dynamic> listJson({int? lastCompletedAt}) => {
    'id': 10,
    'houseId': 1,
    'name': 'Boarding',
    'icon': 'list',
    'sortOrder': 0,
    'createdAt': 0,
    'updatedAt': 0,
    'lastCompletedAt': lastCompletedAt,
  };

  group('model', () {
    test('lastCompletedAt survives the cache round-trip', () {
      final list = ChecklistList.fromJson(listJson(lastCompletedAt: stamp));
      final again = ChecklistList.fromJson(list.toJson());

      expect(list.lastCompletedAt, stamp);
      expect(again.lastCompletedAt, stamp);
    });

    test('is null on servers that do not send it', () {
      final json = listJson()..remove('lastCompletedAt');

      expect(ChecklistList.fromJson(json).lastCompletedAt, isNull);
    });

    test('copyWith keeps it unless replaced', () {
      final list = ChecklistList.fromJson(listJson(lastCompletedAt: stamp));

      expect(list.copyWith(name: 'Leaving').lastCompletedAt, stamp);
      expect(list.copyWith(lastCompletedAt: 5).lastCompletedAt, 5);
    });
  });

  group('progress hero', () {
    Future<void> pumpHero(
      WidgetTester tester, {
      required int total,
      required int done,
      int? lastCompletedAt,
    }) => tester.pumpWidget(
      wrapForTest(
        ProgressHero(
          total: total,
          done: done,
          lastCompletedAt: lastCompletedAt,
        ),
      ),
    );

    testWidgets('a complete, stamped list shows when it was completed', (
      tester,
    ) async {
      await pumpHero(tester, total: 8, done: 8, lastCompletedAt: stamp);

      expect(find.text(m.checklists.allDone), findsOneWidget);
      expect(
        find.text(m.checklists.completedAt(relativeTime(stamp))),
        findsOneWidget,
      );
      expect(find.text(m.checklists.listProgress(8, 8)), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is Tooltip && w.message == formatDateTime(stamp),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a complete, unstamped list keeps its progress', (
      tester,
    ) async {
      await pumpHero(tester, total: 8, done: 8);

      expect(find.text(m.checklists.listProgress(8, 8)), findsOneWidget);
    });

    testWidgets('an incomplete list keeps its progress despite a stamp', (
      tester,
    ) async {
      await pumpHero(tester, total: 8, done: 5, lastCompletedAt: stamp);

      expect(find.text(m.checklists.itemsLeft(3)), findsOneWidget);
      expect(find.text(m.checklists.listProgress(5, 8)), findsOneWidget);
      expect(
        find.text(m.checklists.completedAt(relativeTime(stamp))),
        findsNothing,
      );
    });
  });

  group('with a server', () {
    late List<Map<String, dynamic>> items;

    Map<String, dynamic> item(int id, {bool done = false}) => {
      'id': id,
      'listId': 10,
      'name': 'Item $id',
      'done': done,
      'repeatFromCompletion': false,
      'sortOrder': id,
      'createdAt': 0,
      'updatedAt': 0,
    };

    http.Client server() => MockClient((request) async {
      final path = request.url.path;
      if (request.method != 'GET') {
        throw http.ClientException('offline', request.url);
      }
      Object data = const <Object>[];
      if (path.endsWith('/prefs')) data = <String, dynamic>{};
      if (path.endsWith('/lists')) data = [listJson(lastCompletedAt: stamp)];
      if (path.endsWith('/items') &&
          request.url.queryParameters['offset'] == '0') {
        data = items;
      }
      return http.Response(
        jsonEncode({
          'ocs': {
            'meta': {'status': 'ok', 'statuscode': 200, 'message': 'OK'},
            'data': data,
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    Future<void> withServer(Future<void> Function() body) =>
        http.runWithClient(body, server);

    Future<void> quiesce(WidgetTester tester) async {
      unawaited(manager.reset());
      await tester.pump(const Duration(seconds: 1));
    }

    Future<ChecklistsController> loaded(WidgetTester tester) async {
      final controller = ChecklistsController(houseId: 1);
      addTearDown(controller.dispose);
      await controller.load();
      await tester.pump();
      return controller;
    }

    setUp(() async {
      items = [];
      ServerVersionService.instance.debugSeed(
        features: {'checklist-completion-time': true},
        featuresAuthoritative: true,
      );
      ChecklistService.instance.cacheLists(1, const []);
      ChecklistService.instance.invalidateItemsFor(10);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(storageChannel, (call) async {
            final args = (call.arguments as Map?) ?? const {};
            const credentials = {
              'nextcloud_credentials':
                  '{"serverUrl":"https://cloud.example.com",'
                  '"loginName":"chen","appPassword":"secret"}',
            };
            if (call.method == 'read') return credentials[args['key']];
            if (call.method == 'readAll') return credentials;
            return null;
          });
      await AuthService.instance.loadCredentials();
      unawaited(manager.reset());
    });

    tearDown(() {
      unawaited(manager.reset());
      ServerVersionService.instance.debugSeed();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(storageChannel, null);
    });

    testWidgets('checking the last open item stamps the list right away', (
      tester,
    ) async {
      await withServer(() async {
        items = [item(1, done: true), item(2)];
        final controller = await loaded(tester);
        final before = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        await controller.toggleItem(
          controller.items.firstWhere((i) => i.id == 2),
        );

        final stamped = controller.currentList!.lastCompletedAt!;
        expect(stamped, greaterThanOrEqualTo(before));
        expect(controller.lists.single.lastCompletedAt, stamped);
        expect(
          ChecklistService.instance.getCachedLists(1)!.single.lastCompletedAt,
          stamped,
        );

        await quiesce(tester);
      });
    });

    testWidgets('checking an item with others still open leaves the stamp', (
      tester,
    ) async {
      await withServer(() async {
        items = [item(1), item(2)];
        final controller = await loaded(tester);

        await controller.toggleItem(controller.items.first);

        expect(controller.currentList!.lastCompletedAt, stamp);

        await quiesce(tester);
      });
    });

    testWidgets('unchecking keeps the stamp', (tester) async {
      await withServer(() async {
        items = [item(1, done: true)];
        final controller = await loaded(tester);

        await controller.toggleItem(controller.items.first);

        expect(controller.currentList!.lastCompletedAt, stamp);

        await quiesce(tester);
      });
    });

    Future<void> pumpSwitcher(
      WidgetTester tester,
      ChecklistsController controller,
      int count,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          ListStage(
            controller: controller,
            itemCountForList: (_) async => count,
            onCreateNew: () {},
            onEdit: (_) {},
            onDuplicate: (_) {},
            onOpenTrash: () {},
            onOpenArchive: () {},
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('the switcher shows when a finished list was completed', (
      tester,
    ) async {
      await withServer(() async {
        final controller = await loaded(tester);

        await pumpSwitcher(tester, controller, 0);

        expect(
          find.text(m.checklists.allDoneSummaryAt(relativeTime(stamp))),
          findsOneWidget,
        );
        expect(find.text(m.checklists.allDoneSummary), findsNothing);

        await quiesce(tester);
      });
    });

    testWidgets('the switcher shows what is left on a stamped open list', (
      tester,
    ) async {
      await withServer(() async {
        final controller = await loaded(tester);

        await pumpSwitcher(tester, controller, 3);

        expect(find.text(m.checklists.itemsSummary(3)), findsOneWidget);
        expect(
          find.text(m.checklists.allDoneSummaryAt(relativeTime(stamp))),
          findsNothing,
        );

        await quiesce(tester);
      });
    });
  });
}
