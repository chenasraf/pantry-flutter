import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/shopping/shopping_session_controller.dart';

/// Where trip checks wait for the trip to finish, every item in the trip log
/// is still open on its list. The cart is the log, not the items' done state.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  Map<String, dynamic> item(int id, String name, {required bool done}) => {
    'id': id,
    'listId': 4,
    'name': name,
    'done': done,
    'repeatFromCompletion': false,
    'sortOrder': id,
    'createdAt': 0,
    'updatedAt': 0,
  };

  http.Client server() => MockClient((request) async {
    final path = request.url.path;
    final Object data;
    if (path.endsWith('/review')) {
      data = {
        'stores': [
          {
            'storeId': 7,
            'items': [
              item(1, 'Milk', done: true),
              item(2, 'Bread', done: false),
            ],
            'estimate': [],
            'noPriceCount': 2,
          },
        ],
        'grandTotal': [],
        'uncheckedCount': 0,
      };
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

  const session = ShoppingSession(
    id: 12,
    houseId: 1,
    userId: 'chen',
    listIds: [4],
    stores: [ShoppingSessionStore(storeId: 7, position: 0)],
    activeStoreId: 7,
    includeUnassigned: true,
    isPrivate: false,
    lastSeenAt: 0,
    memberIds: ['chen'],
    live: true,
    createdAt: 0,
    updatedAt: 0,
  );

  Future<ShoppingSessionController> loadedOn(String version) async {
    ServerVersionService.instance.debugSeed(
      pantryVersion: Version.parse(version),
    );
    final controller = ShoppingSessionController(session: session);
    await http.runWithClient(controller.load, server);
    return controller;
  }

  setUp(() async {
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
    ServerVersionService.instance.debugSeed();
  });

  test('every logged item is in the cart, open or not', () async {
    final controller = await loadedOn('0.39.0');
    addTearDown(controller.dispose);

    expect(controller.doneItems.map((i) => i.name), ['Milk', 'Bread']);
    expect(controller.inCartCount, 2);
  });

  test('a check that came straight back stays off the cart', () async {
    final controller = await loadedOn('0.38.0');
    addTearDown(controller.dispose);

    expect(controller.doneItems.map((i) => i.name), ['Milk']);
  });
}
