import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:pantry_core/models/shopping_session.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry/views/shopping/shopping_session_controller.dart';
import 'package:pantry/views/shopping/shopping_session_widgets.dart';

import '../helpers/test_app.dart';
import '../helpers/test_models.dart';

/// A shopper walking a store reads the category they are standing in off the
/// header, so it stays put while any of its items are on screen and only
/// leaves when the next category takes over.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final dairy = makeCategory(id: 1, name: 'Dairy', sortOrder: 0);
  final produce = makeCategory(id: 2, name: 'Produce', sortOrder: 1);

  final items = [
    for (var i = 0; i < 8; i++)
      makeListItem(id: i + 1, name: 'Dairy $i', categoryId: dairy.id),
    for (var i = 0; i < 8; i++)
      makeListItem(id: i + 11, name: 'Produce $i', categoryId: produce.id),
  ];

  http.Client server() => MockClient((request) async {
    final path = request.url.path;
    final Object data;
    if (path.endsWith('/categories')) {
      data = [dairy.toJson(), produce.toJson()];
    } else if (path.endsWith('/items')) {
      data = items.map((i) => i.toJson()).toList();
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

  ShoppingSession session() => ShoppingSession(
    id: 12,
    houseId: 1,
    userId: 'chen',
    listIds: const [4],
    stores: const [],
    activeStoreId: null,
    includeUnassigned: true,
    isPrivate: false,
    lastSeenAt: 0,
    memberIds: const ['chen'],
    live: true,
    createdAt: 0,
    updatedAt: 0,
  );

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

  Future<ShoppingSessionController> pumpArea(WidgetTester tester) async {
    final controller = ShoppingSessionController(session: session());
    addTearDown(controller.dispose);
    // Loading talks to the (mocked) server, which the fake-async clock a
    // widget test runs under would never let complete.
    await tester.runAsync(
      () => http.runWithClient(() async {
        await controller.load();
        // Reference data (the categories the headers are built from) is
        // fetched off to the side of the load.
        await Future<void>.delayed(Duration.zero);
      }, server),
    );

    await tester.pumpWidget(
      wrapForTest(
        ChangeNotifierProvider<PrefsService>.value(
          value: PrefsService.instance,
          child: SizedBox(
            height: 400,
            child: ShoppingItemArea(
              controller: controller,
              onCheck: (_) async {},
              onSkip: (_) {},
              onView: (_) {},
              onRefresh: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return controller;
  }

  ScrollPosition position(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable)).position;

  /// Whether a header is drawn in the top sliver-height of the list — i.e.
  /// pinned, rather than scrolled along with its rows.
  Matcher atTopOf(WidgetTester tester) {
    final listTop = tester.getTopLeft(find.byType(CustomScrollView)).dy;
    return inInclusiveRange(listTop, listTop + 40);
  }

  testWidgets('the category header stays put while its items scroll under it', (
    tester,
  ) async {
    await pumpArea(tester);
    expect(find.text('Dairy 0'), findsOneWidget);

    position(tester).jumpTo(150);
    await tester.pump();

    // The first rows have gone under the header, and the header has not moved.
    expect(find.text('Dairy 0'), findsNothing);
    expect(find.text('Dairy'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Dairy')).dy, atTopOf(tester));
  });

  testWidgets('the next category pushes the previous header off', (
    tester,
  ) async {
    await pumpArea(tester);

    position(tester).jumpTo(position(tester).maxScrollExtent);
    await tester.pump();

    expect(find.text('Dairy'), findsNothing);
    expect(find.text('Produce'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Produce')).dy, atTopOf(tester));
  });
}
