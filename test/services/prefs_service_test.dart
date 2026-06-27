import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/services/prefs_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final store = <String, String>{};
  final prefs = PrefsService.instance;

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
            case 'containsKey':
              return store.containsKey(args['key'] as String);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('load restores dismissed progress-hero list ids', () async {
    store['progress_hero_hidden_list_ids'] = '3,7';

    await prefs.load();

    expect(prefs.isListProgressHeroHidden(3), isTrue);
    expect(prefs.isListProgressHeroHidden(7), isTrue);
    expect(prefs.isListProgressHeroHidden(4), isFalse);
  });

  test('setListProgressHeroHidden persists across a reload', () async {
    await prefs.clear();

    await prefs.setListProgressHeroHidden(42, true);
    expect(prefs.isListProgressHeroHidden(42), isTrue);
    expect(store['progress_hero_hidden_list_ids'], '42');

    // A fresh load (e.g. next app start / background refresh rebuild) must keep
    // the card hidden — this is the bug where it reappeared.
    await prefs.load();
    expect(prefs.isListProgressHeroHidden(42), isTrue);

    // Un-hiding removes it again.
    await prefs.setListProgressHeroHidden(42, false);
    expect(prefs.isListProgressHeroHidden(42), isFalse);
    expect(store['progress_hero_hidden_list_ids'], '');
  });
}
