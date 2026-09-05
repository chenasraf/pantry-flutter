import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_wear/pantry_wear.dart';

ChecklistList _list(int id, String name, {int sortOrder = 0, String? color}) =>
    ChecklistList(
      id: id,
      houseId: 1,
      name: name,
      icon: 'cart',
      color: color,
      sortOrder: sortOrder,
      createdAt: 0,
      updatedAt: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.casraf.pantry/tile');
  final calls = <MethodCall>[];

  void answer([Future<Object?> Function(MethodCall)? handler]) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
          calls.add(call);
          return handler?.call(call) ?? Future<Object?>.value();
        });
  }

  Map<String, dynamic> payloadOf(MethodCall call) =>
      jsonDecode((call.arguments as Map)['payload'] as String)
          as Map<String, dynamic>;

  setUp(() {
    calls.clear();
    answer();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('publishes names, never counts', () async {
    await WearTileService.instance.publish(
      houseId: 1,
      houseName: 'Home',
      lists: [_list(4, 'Groceries')],
    );

    final payload = payloadOf(calls.single);
    expect(payload['houseId'], 1);
    expect(payload['houseName'], 'Home');
    final entry = (payload['lists'] as List).single as Map<String, dynamic>;
    expect(entry, containsPair('name', 'Groceries'));
    // A Tile cannot refresh itself, so anything it shows has to still be true
    // days later. Names are; counts are not.
    expect(entry.keys, isNot(contains('unchecked')));
    expect(entry.keys, isNot(contains('total')));
  });

  test('orders by sortOrder and caps at what one screen holds', () async {
    await WearTileService.instance.publish(
      houseId: 1,
      lists: [
        for (var i = 0; i < WearTileService.maxLists + 3; i++)
          _list(i, 'list $i', sortOrder: 100 - i),
      ],
    );

    final lists = payloadOf(calls.single)['lists'] as List;
    expect(lists.length, WearTileService.maxLists);
    // Lowest sortOrder first — the order the switcher offers them in.
    expect(
      (lists.first as Map)['name'],
      'list ${WearTileService.maxLists + 2}',
    );
  });

  test('a list without a colour leaves the accent to decide', () async {
    await WearTileService.instance.publish(
      houseId: 1,
      lists: [
        _list(1, 'Plain'),
        _list(2, 'Green', color: '#8BC34A'),
      ],
    );

    final lists = payloadOf(calls.single)['lists'] as List;
    expect((lists[0] as Map)['color'], isNull);
    expect((lists[1] as Map)['color'], '#8BC34A');
    expect(payloadOf(calls.single)['accent'], startsWith('#'));
  });

  test('clearing sends no payload for native to keep', () async {
    await WearTileService.instance.clear();

    expect(calls.single.method, 'clear');
    expect((calls.single.arguments as Map).containsKey('payload'), isFalse);
  });

  test('a missing channel is silence, not a throw', () async {
    answer((_) async => throw MissingPluginException());

    await expectLater(WearTileService.instance.clear(), completes);
  });

  test('a platform failure is silence, not a throw', () async {
    answer((_) async => throw PlatformException(code: 'NO_TILE'));

    await expectLater(
      WearTileService.instance.publish(houseId: 1, lists: [_list(1, 'a')]),
      completes,
    );
  });
}
