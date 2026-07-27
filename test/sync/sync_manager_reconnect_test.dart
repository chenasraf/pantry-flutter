import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/sync/sync_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final manager = SyncManager.instance;

  setUp(() async {
    await manager.reset();
    // Reset the connectivity state each test starts from a known "online".
    manager.setOnline(true);
  });
  tearDown(() async {
    await manager.reset();
    manager.setOnline(true);
  });

  group('onReconnect', () {
    test('fires when connectivity transitions offline -> online', () async {
      final events = <void>[];
      final sub = manager.onReconnect.listen(events.add);
      addTearDown(sub.cancel);

      manager.setOnline(false);
      manager.setOnline(true);
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
    });

    test('does not fire on an online -> online no-op', () async {
      final events = <void>[];
      final sub = manager.onReconnect.listen(events.add);
      addTearDown(sub.cancel);

      // Already online (from setUp); a redundant online signal is not a
      // reconnect.
      manager.setOnline(true);
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });

    test('does not fire when going offline', () async {
      final events = <void>[];
      final sub = manager.onReconnect.listen(events.add);
      addTearDown(sub.cancel);

      manager.setOnline(false);
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });
  });
}
