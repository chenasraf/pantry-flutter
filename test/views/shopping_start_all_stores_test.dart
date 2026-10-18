import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/version.dart';
import 'package:pantry/views/shopping/shopping_start_view.dart';

import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

/// The "Shop all at once" switch exists only where the server can run such a
/// trip, and while it is on the trip has no store order to arrange.
void main() {
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

  /// The body each trip start sent.
  final created = <Map<String, dynamic>>[];

  http.Client server() => MockClient((request) async {
    final path = request.url.path;
    Object? data;
    if (path.endsWith('/shopping/sessions') && request.method == 'POST') {
      created.add(jsonDecode(request.body) as Map<String, dynamic>);
      return http.Response('', 500);
    } else if (path.endsWith('/sessions/current')) {
      data = null;
    } else if (path.endsWith('/houses/1/lists')) {
      data = [makeChecklistList(id: 4, houseId: 1).toJson()];
    } else if (path.endsWith('/lists/4/items')) {
      data = [
        makeListItem(id: 1, listId: 4, storeIds: [7]).toJson(),
        makeListItem(id: 2, listId: 4, storeIds: [8]).toJson(),
      ];
    } else if (path.endsWith('/stores')) {
      data = [store(7, 'Corner shop'), store(8, 'Market')];
    } else if (path.endsWith('/prefs')) {
      data = <String, dynamic>{};
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

  Future<void> pumpStart(WidgetTester tester, {required String version}) async {
    ServerVersionService.instance.debugSeed(
      pantryVersion: Version.parse(version),
    );
    await tester.runAsync(
      () => http.runWithClient(() async {
        await tester.pumpWidget(
          wrapForTest(const ShoppingStartView(houseId: 1)),
        );
        // The start screen reads from the network on mount; let it all land.
        for (var i = 0; i < 20; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      }, server),
    );
    await tester.pump();
  }

  setUp(() async {
    created.clear();
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

  tearDown(() async {
    ServerVersionService.instance.debugSeed();
    await PrefsService.instance.setShopAllStoresCache(false);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  testWidgets('an older server gets no switch and no flag', (tester) async {
    await PrefsService.instance.setShopAllStoresCache(true);
    await pumpStart(tester, version: '0.37.1');

    expect(find.text(m.shopping.shopAllStores), findsNothing);
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));

    await tester.runAsync(
      () => http.runWithClient(() async {
        await tester.tap(find.text(m.shopping.start));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }, server),
    );

    expect(created.single.containsKey('allStores'), isFalse);
  });

  testWidgets('with the switch off, the stores keep their order', (
    tester,
  ) async {
    await pumpStart(tester, version: '0.38.0');

    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, m.shopping.shopAllStores),
          )
          .value,
      isFalse,
    );
    expect(find.text(m.shopping.storesHint), findsOneWidget);
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));
  });

  testWidgets('with the switch on, the store order goes and the trip is '
      'combined', (tester) async {
    await PrefsService.instance.setShopAllStoresCache(true);
    await pumpStart(tester, version: '0.38.0');

    expect(find.text(m.shopping.storesHintAll), findsOneWidget);
    expect(find.byIcon(Icons.drag_handle), findsNothing);

    await tester.runAsync(
      () => http.runWithClient(() async {
        await tester.tap(find.text(m.shopping.start));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }, server),
    );

    expect(created.single['allStores'], isTrue);
  });
}
