import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_wear/pantry_wear.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.casraf.pantry/wear_host');
  final calls = <MethodCall>[];

  void answer(Future<Object?> Function(MethodCall) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
          calls.add(call);
          return handler(call);
        });
  }

  setUp(calls.clear);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('passes the url through and reports the platform answer', () async {
    answer((_) async => true);

    expect(
      await WearHostService.instance.openOnPhone('https://example.test/a'),
      isTrue,
    );
    expect(calls.single.method, 'openOnPhone');
    expect(calls.single.arguments, {'url': 'https://example.test/a'});
  });

  test('an unpaired phone is a false, not a throw', () async {
    answer((_) async => false);

    expect(await WearHostService.instance.openOnPhone('https://a.test'), false);
  });

  test('a missing channel is a false, not a throw', () async {
    answer((_) async => throw MissingPluginException());

    expect(await WearHostService.instance.openOnPhone('https://a.test'), false);
  });

  test('a platform failure is a false, not a throw', () async {
    answer((_) async => throw PlatformException(code: 'NO_NODE'));

    expect(await WearHostService.instance.openOnPhone('https://a.test'), false);
  });
}
