import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry/views/shopping/shopping_item_row.dart';
import 'package:pantry/views/shopping/shopping_session_controller.dart';

import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

/// An all-stores trip is never standing in one shop: the server refuses to
/// advance it, and each row has to say which of the trip's shops carry it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  Map<String, dynamic> store(int id, String name) => {
    'id': id,
    'houseId': 1,
    'name': name,
    'icon': 'store',
    'color': '#336699',
    'createdAt': 0,
    'updatedAt': 0,
  };

  final stores = [
    store(7, 'Corner shop'),
    store(8, 'Market'),
    store(9, 'Mall'),
  ];

  /// Every request the controller made, by path.
  final requested = <String>[];

  http.Client server() => MockClient((request) async {
    final path = request.url.path;
    requested.add(path);
    final Object data;
    if (path.endsWith('/stores')) {
      data = stores;
    } else if (path.endsWith('/review')) {
      data = {'stores': [], 'grandTotal': [], 'uncheckedCount': 0};
    } else if (path.endsWith('/advance')) {
      return http.Response('', 400);
    } else {
      data = <dynamic>[];
    }
    return http.Response(
      jsonEncode({
        'ocs': {'data': data},
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  });

  ShoppingSession session({
    required bool allStores,
    List<int> storeIds = const [7, 8],
  }) => ShoppingSession(
    id: 12,
    houseId: 1,
    userId: 'chen',
    listIds: const [4],
    stores: [
      for (var i = 0; i < storeIds.length; i++)
        ShoppingSessionStore(storeId: storeIds[i], position: i),
    ],
    activeStoreId: null,
    includeUnassigned: true,
    isPrivate: false,
    allStores: allStores,
    lastSeenAt: 0,
    memberIds: const ['chen'],
    live: true,
    createdAt: 0,
    updatedAt: 0,
  );

  Future<ShoppingSessionController> loaded(ShoppingSession session) async {
    final controller = ShoppingSessionController(session: session);
    await http.runWithClient(() async {
      await controller.load();
      // Reference data loads in the background; let it land.
      await Future<void>.delayed(Duration.zero);
    }, server);
    return controller;
  }

  setUp(() async {
    requested.clear();
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
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  group('opening the trip', () {
    test('an all-stores trip is not moved to its first store', () async {
      final controller = await loaded(session(allStores: true));
      addTearDown(controller.dispose);

      expect(requested.where((p) => p.endsWith('/advance')), isEmpty);
      expect(controller.session.activeStoreId, isNull);
    });

    test('a store-by-store trip still lands on its first store', () async {
      final controller = await loaded(session(allStores: false));
      addTearDown(controller.dispose);

      expect(requested.where((p) => p.endsWith('/advance')), hasLength(1));
    });
  });

  group('the stores a row names', () {
    test('only the item\'s stores that are on the trip', () async {
      final controller = await loaded(session(allStores: true));
      addTearDown(controller.dispose);

      final item = makeListItem(storeIds: [9, 8, 7]);

      expect(controller.tripStoresOf(item).map((s) => s.id), [7, 8]);
    });

    test('every store the item has on a storeless trip', () async {
      final controller = await loaded(
        session(allStores: true, storeIds: const []),
      );
      addTearDown(controller.dispose);

      final item = makeListItem(storeIds: [9, 7]);

      expect(controller.tripStoresOf(item).map((s) => s.id), [9, 7]);
    });

    test('none for an unassigned item', () async {
      final controller = await loaded(session(allStores: true));
      addTearDown(controller.dispose);

      expect(controller.tripStoresOf(makeListItem()), isEmpty);
    });
  });

  group('the row', () {
    Future<void> pumpRow(
      WidgetTester tester,
      ShoppingSessionController controller,
      ListItem item,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          ChangeNotifierProvider<PrefsService>.value(
            value: PrefsService.instance,
            child: ListView(
              children: [
                ShoppingItemRow(
                  item: item,
                  controller: controller,
                  onCheck: () {},
                  onSkip: () {},
                  onView: () {},
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('names the trip\'s stores on an all-stores trip', (
      tester,
    ) async {
      final controller = await tester.runAsync(
        () => loaded(session(allStores: true)),
      );
      addTearDown(controller!.dispose);

      await pumpRow(tester, controller, makeListItem(storeIds: [7, 9]));

      expect(find.text('Corner shop'), findsOneWidget);
      expect(find.text('Mall'), findsNothing);
    });

    testWidgets('names no store on a store-by-store trip', (tester) async {
      final controller = await tester.runAsync(
        () => loaded(session(allStores: false)),
      );
      addTearDown(controller!.dispose);

      await pumpRow(tester, controller, makeListItem(storeIds: [7, 9]));

      expect(find.text('Corner shop'), findsNothing);
    });
  });
}
