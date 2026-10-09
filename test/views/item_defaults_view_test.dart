import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/models/item_defaults.dart';
import 'package:pantry_core/models/list_recurrence.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';
import 'package:pantry/views/checklists/item_defaults_view.dart';
import 'package:pantry/views/checklists/switcher_form_stage.dart';

import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  Map<String, dynamic> list() => {
    'id': 10,
    'houseId': 1,
    'name': 'Groceries',
    'icon': 'cart',
    'sortOrder': 0,
    'createdAt': 0,
    'updatedAt': 0,
    'itemDefaults': {
      'recurrence': {
        'mode': 'remember',
        'value': {'kind': 'once'},
      },
      'stores': {'mode': 'none'},
      'category': {'mode': 'remember', 'value': 4},
      'labels': {'mode': 'none'},
      'quantity': {'mode': 'none'},
      'fields': <Object>[],
    },
  };

  late List<http.Request> requests;

  http.Client server() => MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    Object data = const <Object>[];
    if (request.method != 'GET') {
      throw http.ClientException('offline', request.url);
    } else if (path.endsWith('/prefs')) {
      data = <String, dynamic>{};
    } else if (path.endsWith('/lists')) {
      data = [list()];
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

  setUp(() async {
    requests = [];
    ServerVersionService.instance.debugSeed(
      features: {
        kListItemDefaultsFeature: true,
        kListDefaultRecurrenceFeature: true,
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

  Future<void> quiesce(WidgetTester tester) async {
    unawaited(manager.reset());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('saving sends only what changed and applies it at once', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);
      await tester.pumpWidget(
        wrapForTest(
          ItemDefaultsView(
            controller: controller,
            list: controller.lists.single,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final d = m.checklists.itemDefaults;
      // A remembering key reads as what it follows.
      expect(
        find.text(d.lastUsed(m.checklists.compose.chipCategory)),
        findsOneWidget,
      );

      await tester.tap(find.text(m.checklists.compose.chipQuantity));
      await tester.pumpAndSettle();
      await tester.tap(find.text(d.modeFixed));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '2');
      await tester.tap(find.text(m.common.save));
      await tester.pumpAndSettle();

      expect(controller.lists.single.itemDefaults!.quantity.value, '2');
      // The category stayed on "remember", so what it learned is not resent.
      final patch = requests.lastWhere((r) => r.method == 'PATCH');
      expect(patch.url.path, endsWith('/lists/10/item-defaults'));
      expect(jsonDecode(patch.body), {
        'quantity': {'mode': 'fixed', 'value': '2'},
      });
      await quiesce(tester);
    });
  });

  testWidgets('a list the user cannot edit is shown read-only', (tester) async {
    await withServer(() async {
      final controller = await loaded(tester);
      controller.permissions = const HousePermissions(canEditLists: false);
      await tester.pumpWidget(
        wrapForTest(
          ItemDefaultsView(
            controller: controller,
            list: controller.lists.single,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(m.checklists.itemDefaults.readOnly), findsOneWidget);
      expect(find.text(m.common.save), findsNothing);
      await quiesce(tester);
    });
  });

  testWidgets('the list form links to the defaults instead of its own radio', (
    tester,
  ) async {
    await withServer(() async {
      final controller = await loaded(tester);
      Future<void> pumpForm({required bool editing}) async {
        await tester.pumpWidget(
          wrapForTest(
            ListFormStage(
              key: ValueKey(editing),
              controller: controller,
              existing: editing ? controller.lists.single : null,
              onBack: () {},
              onSaved: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpForm(editing: true);
      expect(find.text(m.checklists.listRecurrence.remember), findsNothing);
      final link = find.text(m.checklists.itemDefaults.title);
      expect(link, findsOneWidget);

      // A list that does not exist yet has no defaults to edit.
      await pumpForm(editing: false);
      expect(find.text(m.checklists.listRecurrence.remember), findsNothing);
      expect(find.text(m.checklists.itemDefaults.title), findsNothing);
      await quiesce(tester);
    });
  });
}
