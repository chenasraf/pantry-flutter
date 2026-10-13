import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry/views/checklists/checklists_body_controller.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';
import 'package:pantry/widgets/overflow_menu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final storage = <String, String>{};

  late ChecklistsController domain;
  late ChecklistsBodyController body;

  setUp(() {
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async {
          final args = (call.arguments as Map?) ?? const {};
          switch (call.method) {
            case 'readAll':
              return Map<String, String>.from(storage);
            case 'write':
              storage[args['key'] as String] = args['value'] as String;
              return null;
            case 'delete':
              storage.remove(args['key'] as String);
              return null;
            case 'deleteAll':
              storage.clear();
              return null;
          }
          return null;
        });
    ServerVersionService.instance.debugSeed(
      features: {'shopping': true},
      featuresAuthoritative: true,
    );
    domain = ChecklistsController(houseId: 1);
    body = ChecklistsBodyController(
      domain: domain,
      scrollController: null,
      appBarSpecHolder: null,
    );
  });

  tearDown(() async {
    body.dispose();
    domain.dispose();
    await PrefsService.instance.clear();
    ServerVersionService.instance.debugSeed();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
  });

  test('groups keep their order and drop the empty ones', () {
    final ids = body.overflowGroups().map((g) => g.id).toList();

    // No list is open, so nothing per-list (trash, archive, list) is offered.
    expect(ids, containsAllInOrder(['view', 'shopping']));
    expect(ids, isNot(contains('trash')));
    expect(ids, isNot(contains('archive')));
    expect(ids, isNot(contains('list')));
    expect(ids, isNot(contains('select')));
  });

  test('the grid inlines sort choices; the list collapses them to one row', () {
    final grid = body.overflowGroups().firstWhere((g) => g.id == 'view');
    expect(grid.entries.whereType<OverflowRadioAction>(), isNotEmpty);

    final list = body.overflowItems();
    expect(list.whereType<OverflowRadioAction>(), isEmpty);
    expect(
      list.whereType<OverflowAction>().map((a) => a.value),
      contains('sort'),
    );
  });

  test('the list style heads its groups', () async {
    // With the FAB off its action joins history, making a two-row group.
    await PrefsService.instance.setStartShoppingFabEnabled(false);
    final headers = body.overflowItems().whereType<OverflowHeader>().map(
      (h) => h.label,
    );

    expect(headers, contains(m.checklists.menu.shopping));
  });

  test('groups on the toolbar are left out of the overflow', () {
    final values = body
        .overflowItems({'view', 'shopping'})
        .map(overflowEntryValue)
        .toList();

    expect(values, isNot(contains('sort')));
    expect(values, isNot(contains('shopping_history')));
  });

  test('the menu style persists and rejects unknown values', () async {
    final prefs = PrefsService.instance;
    expect(prefs.listMenuStyle, 'grid');

    await prefs.setListMenuStyle('list');
    await prefs.setListMenuStyle('bogus');
    await prefs.load();

    expect(prefs.listMenuStyle, 'list');
  });
}
