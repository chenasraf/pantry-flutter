import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry/views/shopping/shopping_history_view.dart';

import '../helpers/test_app.dart';

/// A finished trip can be deleted only by the shopper who started it, only on
/// a server that knows how, and only once the shopper has confirmed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  var deleteStatus = 200;
  var historyReads = 0;
  final deletes = <String>[];

  http.Client server() => MockClient((request) async {
    final path = request.url.path;
    if (request.method == 'DELETE') {
      deletes.add(path);
      return http.Response(
        jsonEncode({
          'ocs': {
            'data': {'success': deleteStatus == 200},
          },
        }),
        deleteStatus,
        headers: {'content-type': 'application/json'},
      );
    }
    final Object data;
    if (path.endsWith('/sessions/history')) {
      historyReads++;
      data = [
        for (final (id, user, store) in [
          (5, 'chen', 'Store A'),
          (6, 'ada', 'Store B'),
        ])
          {
            'id': id,
            'userId': user,
            'createdAt': 1000,
            'closedAt': 2000,
            'stores': [store],
            'itemCount': 2,
            'grandTotal': [],
          },
      ];
    } else {
      data = const [];
    }
    return http.Response(
      jsonEncode({
        'ocs': {'data': data},
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  });

  Future<void> withServer(Future<void> Function() body) =>
      http.runWithClient(body, server);

  Future<void> openHistory(WidgetTester tester) async {
    await tester.pumpWidget(wrapForTest(const ShoppingHistoryView(houseId: 1)));
    await tester.pumpAndSettle();
    // The reference data the list caches is written behind a debounce timer,
    // which would otherwise still be pending when the test ends.
    await tester.pump(const Duration(seconds: 1));
  }

  Finder menuOf(String store) => find.descendant(
    of: find.ancestor(of: find.text(store), matching: find.byType(Card)),
    matching: find.byIcon(Icons.more_vert),
  );

  Future<void> chooseDelete(WidgetTester tester, String store) async {
    await tester.tap(menuOf(store));
    await tester.pumpAndSettle();
    await tester.tap(find.text(m.shopping.deleteTrip));
    await tester.pumpAndSettle();
  }

  void seed({required bool canDelete}) => ServerVersionService.instance
      .debugSeed(features: {'shopping-history-delete': canDelete});

  setUp(() async {
    deleteStatus = 200;
    historyReads = 0;
    deletes.clear();
    seed(canDelete: true);
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
    ServerVersionService.instance.debugSeed();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  testWidgets('an older server offers no delete', (tester) async {
    seed(canDelete: false);
    await withServer(() async {
      await openHistory(tester);

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });
  });

  testWidgets('only the shopper\'s own trip offers delete', (tester) async {
    await withServer(() async {
      await openHistory(tester);

      expect(menuOf('Store A'), findsOneWidget);
      expect(menuOf('Store B'), findsNothing);
    });
  });

  testWidgets('a confirmed delete removes the row without a refetch', (
    tester,
  ) async {
    await withServer(() async {
      await openHistory(tester);
      final readsBefore = historyReads;

      await chooseDelete(tester, 'Store A');
      expect(find.text(m.shopping.deleteTripBody), findsOneWidget);
      await tester.tap(find.text(m.common.delete));
      await tester.pumpAndSettle();

      expect(deletes, [
        '/ocs/v2.php/apps/pantry/api/houses/1/shopping/sessions/5',
      ]);
      expect(find.text('Store A'), findsNothing);
      expect(find.text('Store B'), findsOneWidget);
      expect(historyReads, readsBefore);
    });
  });

  testWidgets('a cancelled delete leaves the row', (tester) async {
    await withServer(() async {
      await openHistory(tester);

      await chooseDelete(tester, 'Store A');
      await tester.tap(find.text(m.common.cancel));
      await tester.pumpAndSettle();

      expect(deletes, isEmpty);
      expect(find.text('Store A'), findsOneWidget);
    });
  });

  testWidgets('a failed delete leaves the row and says so', (tester) async {
    deleteStatus = 404;
    await withServer(() async {
      await openHistory(tester);

      await chooseDelete(tester, 'Store A');
      await tester.tap(find.text(m.common.delete));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(deletes, hasLength(1));
      expect(find.text('Store A'), findsOneWidget);
      expect(find.text(m.shopping.deleteTripFailed), findsOneWidget);

      // Let the toast run out so no timer outlives the test.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('the trip\'s summary can delete it too', (tester) async {
    await withServer(() async {
      await openHistory(tester);

      await tester.tap(find.text('Store A'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(m.shopping.deleteTrip));
      await tester.pumpAndSettle();
      await tester.tap(find.text(m.common.delete));
      await tester.pumpAndSettle();

      expect(deletes, hasLength(1));
      expect(find.text(m.shopping.historyTitle), findsOneWidget);
      expect(find.text('Store A'), findsNothing);
    });
  });
}
