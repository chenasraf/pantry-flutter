import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';

/// Android aborts a backgrounded app's sockets, so the offline warm-up of the
/// lists not on screen must not keep sending requests once the app leaves the
/// foreground.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final manager = SyncManager.instance;

  const groceries = 10;
  const hardware = 20;

  Map<String, dynamic> list(int id, String name) => {
    'id': id,
    'houseId': 1,
    'name': name,
    'icon': 'list',
    'sortOrder': id,
    'createdAt': 0,
    'updatedAt': 0,
  };

  late List<http.Request> requests;

  http.Client server() => MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    final Object data = path.endsWith('/lists')
        ? [list(groceries, 'Groceries'), list(hardware, 'Hardware')]
        : path.endsWith('/prefs')
        ? {'checklistItemSort': 'custom'}
        : const <Object>[];
    return http.Response(
      jsonEncode({
        'ocs': {'data': data},
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  });

  bool fetchedItemsOf(int listId) => requests.any(
    (r) => r.method == 'GET' && r.url.path.endsWith('/lists/$listId/items'),
  );

  setUp(() async {
    requests = [];
    ChecklistService.instance.selectedListId = null;
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
    manager.setOnline(true);
  });

  tearDown(() {
    unawaited(manager.reset());
    manager.setOnline(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  Future<void> loadIn(WidgetTester tester, AppLifecycleState state) async {
    tester.binding.handleAppLifecycleStateChanged(state);
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await http.runWithClient(() async {
      final controller = ChecklistsController(houseId: 1);
      addTearDown(controller.dispose);
      await controller.load();
      await tester.pump(const Duration(seconds: 1));
      unawaited(manager.reset());
      await tester.pump(const Duration(seconds: 1));
    }, server);
  }

  testWidgets('in the foreground the other lists are warmed', (tester) async {
    await loadIn(tester, AppLifecycleState.resumed);
    expect(fetchedItemsOf(groceries), isTrue);
    expect(fetchedItemsOf(hardware), isTrue);
  });

  testWidgets('in the background the warm-up does not run', (tester) async {
    await loadIn(tester, AppLifecycleState.paused);
    expect(fetchedItemsOf(groceries), isTrue);
    expect(fetchedItemsOf(hardware), isFalse);
  });
}
