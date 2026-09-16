import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry/views/shopping/shopping_session_controller.dart';

/// Presence attributes a *trip* to a store, not a person: housemates sharing a
/// trip arrive as one entry under whoever started it. The store pills read
/// their avatars from that entry, so they have to unpack the member list —
/// rendering one avatar per entry hides every joiner and puts the viewer's own
/// face back on the pill.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  /// Serves the four reads a poll makes; everything else (reference data) gets
  /// an empty list, which each loader treats as "nothing to show".
  http.Client serverWith(List<Map<String, dynamic>> presence) => MockClient((
    request,
  ) async {
    final path = request.url.path;
    final Object data;
    if (path.endsWith('/presence') || path.endsWith('/presence/heartbeat')) {
      data = presence;
    } else if (path.endsWith('/review')) {
      data = {'stores': [], 'grandTotal': [], 'uncheckedCount': 0};
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

  Map<String, dynamic> entry({
    required String userId,
    required List<String> memberIds,
    int? activeStoreId = 7,
  }) => {
    'userId': userId,
    'sessionId': 12,
    'activeStoreId': activeStoreId,
    'lastSeenAt': 0,
    'memberIds': memberIds,
  };

  ShoppingSession session({String userId = 'dana'}) => ShoppingSession(
    id: 12,
    houseId: 1,
    userId: userId,
    listIds: const [4],
    stores: const [ShoppingSessionStore(storeId: 7, position: 0)],
    activeStoreId: 7,
    includeUnassigned: true,
    isPrivate: false,
    lastSeenAt: 0,
    memberIds: userId == 'chen' ? const ['chen', 'dana'] : [userId, 'chen'],
    live: true,
    createdAt: 0,
    updatedAt: 0,
  );

  Future<ShoppingSessionController> loadedWith(
    List<Map<String, dynamic>> presence, {
    String starter = 'dana',
  }) async {
    final controller = ShoppingSessionController(
      session: session(userId: starter),
    );
    await http.runWithClient(controller.load, () => serverWith(presence));
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
  });

  test('a joiner shows on the pill of the store the trip is at', () async {
    final controller = await loadedWith([
      entry(userId: 'dana', memberIds: ['dana', 'chen', 'sam']),
    ]);
    addTearDown(controller.dispose);

    expect(controller.presenceAt(7), ['dana', 'sam']);
  });

  test('the viewer never ends up on the pill as the starter', () async {
    final controller = await loadedWith([
      entry(userId: 'chen', memberIds: ['chen', 'dana']),
    ], starter: 'chen');
    addTearDown(controller.dispose);

    expect(controller.presenceAt(7), ['dana']);
  });

  test('a trip at another store leaves this pill empty', () async {
    final controller = await loadedWith([
      entry(userId: 'dana', memberIds: ['dana', 'sam'], activeStoreId: 9),
    ]);
    addTearDown(controller.dispose);

    expect(controller.presenceAt(7), isEmpty);
    expect(controller.presenceAt(9), ['dana', 'sam']);
  });

  test('a joined trip is not the joiner\'s to make private', () async {
    final controller = await loadedWith([]);
    addTearDown(controller.dispose);

    expect(controller.isStarter, isFalse);
    expect(controller.companions, ['dana']);
  });

  test('the shopper who started it keeps the owner-only affordances', () async {
    final controller = await loadedWith([], starter: 'chen');
    addTearDown(controller.dispose);

    expect(controller.isStarter, isTrue);
    expect(controller.companions, ['dana']);
  });
}
