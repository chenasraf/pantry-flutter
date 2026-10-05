import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';
import 'package:pantry/views/checklists/switcher_duplicate_stage.dart';
import 'package:pantry/views/checklists/switcher_list_stage.dart';

import '../helpers/test_app.dart';

/// Duplicating a list is served whole by the server — new ids for the copy's
/// items and for any list-scoped taxonomy — so the controller calls it
/// directly instead of queueing it, and has to refetch the taxonomy after.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  const source = 10;
  const copy = 30;

  Map<String, dynamic> list(int id, String name, {int? lastCompletedAt}) => {
    'id': id,
    'houseId': 1,
    'name': name,
    'icon': 'list',
    'sortOrder': 0,
    'createdAt': 0,
    'updatedAt': 0,
    'lastCompletedAt': lastCompletedAt,
  };

  late List<http.Request> requests;
  late bool failDuplicate;

  http.Client server() => MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    Object data = const <Object>[];
    if (path.endsWith('/duplicate')) {
      if (failDuplicate) return http.Response('boom', 500);
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      data = list(copy, body['name'] as String);
    } else if (request.method != 'GET') {
      throw http.ClientException('offline', request.url);
    } else if (path.endsWith('/prefs')) {
      data = <String, dynamic>{};
    } else if (path.endsWith('/lists')) {
      data = [list(source, 'Boarding', lastCompletedAt: 1700000000)];
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

  /// Takes the queue's retry timer off the clock; see
  /// shopping_billed_offline_test.dart for why this isn't awaited.
  Future<void> quiesce(WidgetTester tester) async {
    unawaited(manager.reset());
    await tester.pump(const Duration(seconds: 1));
  }

  Iterable<String> taxonomyFetches() => requests
      .where((r) => r.method == 'GET')
      .map((r) => r.url.path)
      .where(
        (p) =>
            p.endsWith('/categories') ||
            p.endsWith('/labels') ||
            p.endsWith('/fields'),
      );

  setUp(() async {
    requests = [];
    failDuplicate = false;
    ServerVersionService.instance.debugSeed(
      features: {
        'checklist-duplicate': true,
        'checklist-completion-time': true,
        'labels': true,
      },
      featuresAuthoritative: true,
    );
    ChecklistService.instance.cacheLists(1, const []);
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

  Future<ChecklistsController> loaded(WidgetTester tester) async {
    final controller = ChecklistsController(houseId: 1);
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pump();
    return controller;
  }

  testWidgets('the copy is created, selected and its taxonomy refetched', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);
      final original = controller.lists.single;
      requests.clear();

      await controller.duplicateList(
        original,
        name: 'Duplicate of Boarding',
        resetDone: false,
      );

      final calls = requests
          .where((r) => r.url.path.endsWith('/duplicate'))
          .toList();
      expect(calls, hasLength(1));
      expect(calls.single.url.path, endsWith('/lists/$source/duplicate'));
      expect(jsonDecode(calls.single.body), {
        'name': 'Duplicate of Boarding',
        'resetDone': false,
      });
      expect(controller.lists.map((l) => l.id), [source, copy]);
      expect(controller.currentList?.id, copy);
      expect(controller.currentList?.lastCompletedAt, isNull);
      expect(
        taxonomyFetches().where((p) => p.endsWith('/categories')),
        isNotEmpty,
      );
      expect(taxonomyFetches().where((p) => p.endsWith('/labels')), isNotEmpty);
      expect(manager.queueForTest.all(), isEmpty);

      await quiesce(tester);
    });
  });

  testWidgets('a failed duplicate leaves the lists untouched', (tester) async {
    await withServer(() async {
      final controller = await loaded(tester);
      final original = controller.lists.single;
      failDuplicate = true;

      await expectLater(
        controller.duplicateList(original, name: 'Copy', resetDone: true),
        throwsA(anything),
      );

      expect(controller.lists.map((l) => l.id), [source]);
      expect(controller.currentList?.id, source);
      expect(manager.queueForTest.all(), isEmpty);

      await quiesce(tester);
    });
  });

  testWidgets('lists the server cannot copy from are not offered', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);
      final original = controller.lists.single;

      expect(controller.canDuplicateList(original), isTrue);
      expect(controller.canDuplicateList(allListsSentinel(1)), isFalse);
      expect(
        controller.canDuplicateList(original.copyWith(id: -4)),
        isFalse,
        reason: 'a list whose create has not synced has no server id',
      );

      ServerVersionService.instance.debugSeed(
        features: const {},
        featuresAuthoritative: true,
      );
      expect(controller.canDuplicateList(original), isFalse);

      requests.clear();
      await expectLater(
        controller.duplicateList(
          allListsSentinel(1),
          name: 'Copy',
          resetDone: true,
        ),
        throwsStateError,
      );
      expect(requests, isEmpty);

      await quiesce(tester);
    });
  });

  Future<void> pumpSwitcher(
    WidgetTester tester,
    ChecklistsController controller,
  ) async {
    await tester.pumpWidget(
      wrapForTest(
        ListStage(
          controller: controller,
          itemCountForList: (_) async => 1,
          onCreateNew: () {},
          onEdit: (_) {},
          onDuplicate: (_) {},
          onOpenTrash: () {},
          onOpenArchive: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
  }

  testWidgets('the switcher offers Duplicate on servers that support it', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);

      await pumpSwitcher(tester, controller);

      expect(find.text(m.checklists.duplicateList), findsOneWidget);

      await quiesce(tester);
    });
  });

  testWidgets('the switcher hides Duplicate without the capability', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);
      ServerVersionService.instance.debugSeed(
        features: {'checklist-trash': true},
        featuresAuthoritative: true,
      );

      await pumpSwitcher(tester, controller);

      expect(find.text(m.checklists.removeList), findsOneWidget);
      expect(find.text(m.checklists.duplicateList), findsNothing);

      await quiesce(tester);
    });
  });

  testWidgets('the form prefills the name and resets done by default', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);
      var duplicated = 0;
      await tester.pumpWidget(
        wrapForTest(
          DuplicateListStage(
            controller: controller,
            source: controller.lists.single,
            onBack: () {},
            onDuplicated: () => duplicated++,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.widgetWithText(
          TextField,
          m.checklists.duplicateListName('Boarding'),
        ),
        findsOneWidget,
      );
      final reset = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(reset.value, isTrue);

      requests.clear();
      await tester.tap(find.text(m.checklists.duplicateList));
      await tester.pump();
      await tester.pump();

      final call = requests.singleWhere(
        (r) => r.url.path.endsWith('/duplicate'),
      );
      expect(jsonDecode(call.body), {
        'name': m.checklists.duplicateListName('Boarding'),
        'resetDone': true,
      });
      expect(duplicated, 1);

      await quiesce(tester);
    });
  });
}
