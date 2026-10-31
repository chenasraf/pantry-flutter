import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry/views/categories/categories_view.dart';
import 'package:pantry/views/categories/category_form_view.dart';

/// Opened from a list, the manager shows that list's categories and the
/// globals — but a reorder still renumbers every category in the house, or the
/// hidden ones fall out of the persisted order.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  const groceries = 10;
  const hardware = 20;

  Map<String, dynamic> category(int id, String name, int? listId) => {
    'id': id,
    'houseId': 1,
    'name': name,
    'icon': 'tag',
    'color': '',
    'sortOrder': id - 1,
    'listId': listId,
    'createdAt': 0,
    'updatedAt': 0,
  };

  Map<String, dynamic> list(int id, String name, int sortOrder) => {
    'id': id,
    'houseId': 1,
    'name': name,
    'icon': 'list',
    'sortOrder': sortOrder,
    'createdAt': 0,
    'updatedAt': 0,
  };

  final categories = [
    category(1, 'Pantry', null),
    category(2, 'Misc', null),
    category(3, 'Dairy', groceries),
    category(4, 'Screws', hardware),
  ];
  final lists = [
    list(groceries, 'Groceries', 0),
    list(hardware, 'Hardware', 1),
  ];

  /// Serves reads only; writes fail as retryable so a reorder stays queued.
  http.Client server() => MockClient((request) async {
    if (request.method != 'GET') {
      throw http.ClientException('offline', request.url);
    }
    final path = request.url.path;
    Object data = const <Object>[];
    if (path.endsWith('/prefs')) data = {'categorySort': 'custom'};
    if (path.endsWith('/categories')) data = categories;
    if (path.endsWith('/lists')) data = lists;
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

  Future<void> pumpManager(WidgetTester tester, {int? listId}) async {
    await tester.pumpWidget(
      MaterialApp(home: CategoriesView(houseId: 1, listId: listId)),
    );
    await tester.pump();
    await tester.pump();
  }

  /// Takes the queue's retry timer off the clock; see
  /// shopping_billed_offline_test.dart for why this isn't awaited.
  Future<void> quiesce(WidgetTester tester) async {
    unawaited(manager.reset());
    await tester.pump(const Duration(seconds: 1));
  }

  setUp(() async {
    ServerVersionService.instance.debugSeed(
      pantryVersion: Version.parse('0.28.0'),
    );
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

  testWidgets('without a list, every category and section shows', (
    tester,
  ) async {
    await withServer(() async {
      await pumpManager(tester);

      for (final name in ['Pantry', 'Misc', 'Dairy', 'Screws']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('GROCERIES'), findsOneWidget);
      expect(find.text('HARDWARE'), findsOneWidget);

      await quiesce(tester);
    });
  });

  testWidgets('from a list, other lists\' categories are hidden', (
    tester,
  ) async {
    await withServer(() async {
      await pumpManager(tester, listId: groceries);

      for (final name in ['Pantry', 'Misc', 'Dairy']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('GROCERIES'), findsOneWidget);
      expect(find.text('Screws'), findsNothing);
      expect(find.text('HARDWARE'), findsNothing);

      await quiesce(tester);
    });
  });

  testWidgets('a reorder in the narrowed view keeps hidden categories', (
    tester,
  ) async {
    await withServer(() async {
      await pumpManager(tester, listId: groceries);

      // The first reorderable is the globals section.
      final globals = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView).first,
      );
      globals.onReorderItem!(0, 1);
      await tester.pump();

      final op = manager.queueForTest
          .all()
          .where(
            (op) =>
                op.entity == SyncEntity.category && op.op == SyncOpKind.reorder,
          )
          .single;
      final order = [
        for (final e in op.body['order'] as List) (e as Map)['id'] as int,
      ];
      expect(order, [2, 1, 3, 4]);

      await quiesce(tester);
    });
  });

  List<int> queuedOrder() {
    final op = manager.queueForTest.all().lastWhere(
      (op) => op.entity == SyncEntity.category && op.op == SyncOpKind.reorder,
    );
    return [for (final e in op.body['order'] as List) (e as Map)['id'] as int];
  }

  List<String> globalNames(WidgetTester tester) => [
    for (final tile in tester.widgetList<ListTile>(
      find.descendant(
        of: find.byType(ReorderableListView).first,
        matching: find.byType(ListTile),
      ),
    ))
      ((tile.title as Text).data)!,
  ];

  testWidgets('repeated reorders each build on the last', (tester) async {
    await withServer(() async {
      await pumpManager(tester);

      ReorderableListView globals() => tester.widget<ReorderableListView>(
        find.byType(ReorderableListView).first,
      );
      globals().onReorderItem!(0, 1);
      await tester.pump();
      globals().onReorderItem!(0, 1);
      await tester.pump();

      expect(globalNames(tester), ['Pantry', 'Misc']);
      expect(queuedOrder(), [1, 2, 3, 4]);

      await quiesce(tester);
    });
  });

  testWidgets('a reorder survives a refresh that lands before it syncs', (
    tester,
  ) async {
    await withServer(() async {
      await pumpManager(tester);

      tester
          .widget<ReorderableListView>(find.byType(ReorderableListView).first)
          .onReorderItem!(0, 1);
      await tester.pump();

      await tester.drag(find.byType(ListView).first, const Offset(0, 300));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(globalNames(tester), ['Misc', 'Pantry']);

      await quiesce(tester);
    });
  });

  testWidgets('creating a category keeps a reorder made before it', (
    tester,
  ) async {
    await withServer(() async {
      await pumpManager(tester);

      tester
          .widget<ReorderableListView>(find.byType(ReorderableListView).first)
          .onReorderItem!(0, 1);
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Bakery');
      await tester.tap(find.widgetWithText(InkWell, 'Save'));
      await tester.pumpAndSettle();

      expect(globalNames(tester), ['Misc', 'Pantry', 'Bakery']);

      // Dragged to the top, the new category's temp id rides the order.
      final bakery = tester
          .widget<ReorderableListView>(find.byType(ReorderableListView).first)
          .onReorderItem!;
      bakery(2, 0);
      await tester.pump();
      expect(globalNames(tester), ['Bakery', 'Misc', 'Pantry']);
      final order = queuedOrder();
      expect(order.first, isNegative);
      expect(order.skip(1), [2, 1, 3, 4]);

      await quiesce(tester);
    });
  });

  testWidgets('a new category is house-wide, even opened from a list', (
    tester,
  ) async {
    await withServer(() async {
      await pumpManager(tester, listId: groceries);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(CategoryFormView), findsOneWidget);
      final scope = tester.widget<DropdownButtonFormField<int?>>(
        find.byType(DropdownButtonFormField<int?>),
      );
      expect(scope.initialValue, isNull);

      await quiesce(tester);
    });
  });
}
