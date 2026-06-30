import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/services/api_client.dart';
import 'package:pantry/sync/sync_manager.dart';

void main() {
  // Restore the default (online) state so the global SyncManager singleton
  // doesn't leak an offline flag into other tests.
  tearDown(() => SyncManager.instance.setOnline(true));

  group('ApiClient offline short-circuit', () {
    test('reads fail fast with OfflineException when offline', () async {
      SyncManager.instance.setOnline(false);
      expect(
        () => ApiClient.instance.get<List, List>(
          '/houses/1/lists',
          fromJson: (data) => data,
        ),
        throwsA(isA<OfflineException>()),
      );
    });

    test('writes fail fast with OfflineException when offline', () async {
      SyncManager.instance.setOnline(false);
      expect(
        () => ApiClient.instance.post<Map<String, dynamic>, void>(
          '/houses/1/lists',
          body: {'name': 'x'},
          fromJson: (_) {},
        ),
        throwsA(isA<OfflineException>()),
      );
    });

    test('OfflineException carries statusCode 0 so it is retryable', () {
      const e = OfflineException();
      expect(e.statusCode, 0);
      expect(e, isA<ApiException>());
    });
  });
}
