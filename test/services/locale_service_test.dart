import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/services/locale_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final store = <String, String>{};
  final locale = LocaleService.instance;

  setUp(() {
    store.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = (call.arguments as Map?) ?? const {};
          switch (call.method) {
            case 'readAll':
              return Map<String, String>.from(store);
            case 'read':
              return store[args['key'] as String];
            case 'write':
              store[args['key'] as String] = args['value'] as String;
              return null;
            case 'delete':
              store.remove(args['key'] as String);
              return null;
            case 'deleteAll':
              store.clear();
              return null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('apply() does not bump the revision (no navigator teardown)', () {
    final before = locale.revision;
    locale.apply();
    locale.apply();
    expect(locale.revision, before);
  });

  test('setLocale bumps the revision once per explicit change', () async {
    final before = locale.revision;
    await locale.setLocale('de');
    expect(locale.revision, before + 1);
    await locale.setLocale('en');
    expect(locale.revision, before + 2);
  });
}
