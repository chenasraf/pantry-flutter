import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Give `path_provider` a real directory to hand out for the whole suite.
///
/// `CacheStore` resolves its file through `getApplicationDocumentsDirectory`,
/// so any test that builds a widget owning a store reaches the channel
/// transitively. Unanswered it throws `MissingPluginException`, which the store
/// catches and reports through `debugPrint` — the test still passes and the
/// only trace is a line of noise, which is exactly what makes a real write
/// failure unreadable.
///
/// A test asserting on file contents still installs its own handler in `setUp`;
/// this is the default underneath it.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final documents = Directory.systemTemp.createTempSync('pantry_test_docs');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => documents.path,
      );

  tearDownAll(() {
    if (documents.existsSync()) documents.deleteSync(recursive: true);
  });

  await testMain();
}
