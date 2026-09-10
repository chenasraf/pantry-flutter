import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_wear/src/checklists/checklists_controller.dart';
import 'package:pantry_wear/src/scope/wear_scope.dart';

import 'wear_fixtures.dart';

/// How many times the watch reads, and what a read is allowed to set off.
///
/// A first sign-in resolves both halves of scope — no remembered house, no
/// remembered list — and it resolves them from inside the read that is already
/// drawing them. Announcing either one there re-enters that read, so the one
/// read the wearer asked for becomes three racing each other, writing the
/// items in whatever order their requests happen to land.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final storage = <String, String>{};

  setUp(() async {
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async {
          final args = (call.arguments as Map?) ?? const {};
          return switch (call.method) {
            'read' => storage[args['key'] as String],
            'write' => storage[args['key'] as String] = args['value'] as String,
            'readAll' => Map<String, String>.from(storage),
            _ => null,
          };
        });
    ChecklistService.instance.selectedListId = null;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
    ChecklistService.instance.selectedListId = null;
  });

  const houses = [
    House(
      id: 7,
      name: 'Home',
      ownerUid: 'casraf',
      role: 'owner',
      createdAt: 0,
      updatedAt: 0,
    ),
  ];

  test('resolving scope inside a read says nothing about it', () async {
    var announced = 0;
    void listener() => announced++;
    WearScope.instance.addListener(listener);
    addTearDown(() => WearScope.instance.removeListener(listener));

    expect(await WearScope.instance.resolveHouse(houses), 7);
    expect(await WearScope.instance.resolveList([testList()]), testList().id);

    // The read that called these is already going to draw what they landed on.
    // Announcing it there is what turned one read into three.
    expect(announced, 0);
  });

  test('and the wearer choosing it says so', () async {
    var announced = 0;
    void listener() => announced++;
    WearScope.instance.addListener(listener);
    addTearDown(() => WearScope.instance.removeListener(listener));

    await WearScope.instance.selectList(testList(id: 99).id);
    expect(announced, 1);
  });

  test('a refresh asked for while one is running is folded into it', () {
    final controller = ChecklistsController();
    addTearDown(controller.dispose);

    final first = controller.refresh();
    final second = controller.refresh();

    // Not a second traversal of the read path — the caller wants the current
    // answer, and two traversals write the items in whichever order their
    // requests land.
    expect(identical(first, second), isTrue);
  });

  test('and one asked for after it has finished is its own read', () async {
    final controller = ChecklistsController();
    addTearDown(controller.dispose);

    final first = controller.refresh();
    await first;
    final second = controller.refresh();

    expect(identical(first, second), isFalse);
    await second;
  });
}
