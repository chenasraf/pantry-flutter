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

  test(
    'the notification grant is read from the system, never remembered',
    () async {
      var enabled = false;
      answer((_) async => enabled);

      expect(await WearHostService.instance.notificationsEnabled(), isFalse);

      // The wearer can grant it from the system's own screen, which never comes
      // back through the app — so a second read has to ask again.
      enabled = true;
      expect(await WearHostService.instance.notificationsEnabled(), isTrue);
    },
  );

  test('a watch that cannot say is drawn as granted', () async {
    answer((_) async => throw MissingPluginException());

    // A row accusing the watch of a block it has not got sends the wearer to a
    // system screen that agrees with the app.
    expect(await WearHostService.instance.notificationsEnabled(), isTrue);
  });

  test('asking for the grant answers nothing', () async {
    answer((_) async => null);

    await WearHostService.instance.requestNotifications();

    // The wearer replies long after the call returns, and once they have
    // refused the prompt never appears again — so there is nothing here that
    // could describe either.
    expect(calls.single.method, 'requestNotifications');
  });

  test(
    'a watch with no notification screen reports it rather than throwing',
    () async {
      answer((_) async => throw PlatformException(code: 'NO_ACTIVITY'));

      expect(
        await WearHostService.instance.openNotificationSettings(),
        isFalse,
      );
    },
  );
}
