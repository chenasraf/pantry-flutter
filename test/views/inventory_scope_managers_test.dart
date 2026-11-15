import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/custom_field.dart';
import 'package:pantry_core/models/label.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/custom_field_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/custom_fields/custom_fields_view.dart';
import 'package:pantry/views/labels/labels_view.dart';
import 'package:pantry/widgets/create_label_dialog.dart';

/// Labels and custom fields can be scoped to an inventory, so their managers
/// load lists of every kind to name each section and offer each scope.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  const groceries = 10;
  const freezer = 30;

  Map<String, dynamic> list(int id, String name, String kind) => {
    'id': id,
    'houseId': 1,
    'name': name,
    'kind': kind,
    'icon': 'list',
    'sortOrder': id,
    'createdAt': 0,
    'updatedAt': 0,
  };

  Map<String, dynamic> label(int id, String name, int? listId) => {
    'id': id,
    'houseId': 1,
    'listId': listId,
    'name': name,
    'icon': 'tag',
    'color': '#ef4444',
    'sortOrder': id,
    'createdAt': 0,
    'updatedAt': 0,
  };

  Map<String, dynamic> field(int id, String name, int? listId) => {
    'id': id,
    'houseId': 1,
    'listId': listId,
    'name': name,
    'type': 'text',
    'sortOrder': id,
    'createdAt': 0,
    'updatedAt': 0,
  };

  http.Client server() => MockClient((request) async {
    final path = request.url.path;
    Object data = const <Object>[];
    if (request.method != 'GET') {
      throw http.ClientException('offline', request.url);
    } else if (path.endsWith('/prefs')) {
      data = <String, dynamic>{};
    } else if (path.endsWith('/houses/1/lists')) {
      data = [list(groceries, 'Groceries', 'checklist')];
    } else if (path.endsWith('/houses/1/inventories')) {
      data = [list(freezer, 'Freezer', 'inventory')];
    } else if (path.endsWith('/houses/1/labels')) {
      data = [label(1, 'Organic', groceries), label(2, 'Icy', freezer)];
    } else if (path.endsWith('/houses/1/fields')) {
      data = [field(1, 'Brand', groceries), field(2, 'Frozen on', freezer)];
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

  /// Section headers are styled in caps, so match regardless of case.
  Finder header(String text) => find.byWidgetPredicate(
    (w) => w is Text && w.data?.toLowerCase() == text.toLowerCase(),
  );

  Finder orphanHeader() => find.byWidgetPredicate(
    (w) => w is Text && (w.data?.startsWith('#') ?? false),
  );

  setUp(() async {
    ServerVersionService.instance.debugSeed(
      pantryVersion: Version.parse('0.39.0'),
    );
    ChecklistService.instance.cacheListsOfEveryKind(1, const []);
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

  testWidgets('the label manager names inventory sections', (tester) async {
    await withServer(() async {
      await tester.pumpWidget(const MaterialApp(home: LabelsView(houseId: 1)));
      await tester.pumpAndSettle();

      expect(header('Freezer'), findsOneWidget);
      expect(find.text('Icy'), findsOneWidget);
      expect(orphanHeader(), findsNothing);

      await quiesce(tester);
    });
  });

  testWidgets('the custom field manager names inventory sections', (
    tester,
  ) async {
    await withServer(() async {
      await tester.pumpWidget(
        const MaterialApp(home: CustomFieldsView(houseId: 1)),
      );
      await tester.pumpAndSettle();

      expect(header('Freezer'), findsOneWidget);
      expect(find.text('Frozen on'), findsOneWidget);
      expect(orphanHeader(), findsNothing);

      await quiesce(tester);
    });
  });

  testWidgets('the custom field manager names sections offline from cache', (
    tester,
  ) async {
    ChecklistService.instance.cacheListsOfEveryKind(1, [
      for (final l in [
        list(groceries, 'Groceries', 'checklist'),
        list(freezer, 'Freezer', 'inventory'),
      ])
        ChecklistList.fromJson(l),
    ]);
    CustomFieldService.instance.cacheFields(1, [
      FieldDefinition.fromJson(field(2, 'Frozen on', freezer)),
    ]);
    addTearDown(() => CustomFieldService.instance.cacheFields(1, const []));
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          const MaterialApp(home: CustomFieldsView(houseId: 1)),
        );
        await tester.pumpAndSettle();
        expect(find.text('Frozen on'), findsOneWidget);
        expect(header('Freezer'), findsOneWidget);
        expect(orphanHeader(), findsNothing);
        await quiesce(tester);
      },
      () => MockClient(
        (request) async => throw http.ClientException('offline', request.url),
      ),
    );
  });

  group('the label dialog', () {
    Label existing(int? listId) => Label.fromJson(label(2, 'Icy', listId));

    Future<void> pumpDialog(WidgetTester tester, Label label) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CreateLabelDialog(houseId: 1, existing: label)),
        ),
      );
      await tester.pumpAndSettle();
    }

    Map<String, dynamic> savedBody() => manager.queueForTest
        .all()
        .lastWhere(
          (op) => op.entity == SyncEntity.label && op.op == SyncOpKind.update,
        )
        .body;

    testWidgets('shows and keeps an inventory scope', (tester) async {
      await withServer(() async {
        await pumpDialog(tester, existing(freezer));

        final dropdown = tester.widget<DropdownButton<int?>>(
          find.byType(DropdownButton<int?>),
        );
        expect(dropdown.value, freezer);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(savedBody()['listId'], freezer);

        await quiesce(tester);
      });
    });

    testWidgets('keeps a scope whose list is not loaded', (tester) async {
      await withServer(() async {
        await pumpDialog(tester, existing(99));

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(savedBody()['listId'], 99);

        await quiesce(tester);
      });
    });
  });
}
