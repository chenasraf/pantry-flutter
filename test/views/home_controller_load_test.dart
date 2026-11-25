import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry/views/home/home_controller.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async => null);
  });

  setUp(() async {
    await AuthService.instance.adoptCredentials(
      const NextcloudCredentials(
        serverUrl: 'https://cloud.example',
        loginName: 'ada',
        appPassword: 'secret',
      ),
    );
    SyncManager.instance.setOnline(true);
  });

  const houseBody =
      '{"id":3,"name":"Family","ownerUid":"bob","role":"member",'
      '"createdAt":0,"updatedAt":0}';

  test(
    'a cached empty house list still loads houses shared since then',
    () async {
      HouseService.instance.cache.setList('houses', const [], (h) => h);

      final controller = HomeController();
      await http.runWithClient(
        controller.load,
        () => MockClient((req) async {
          if (req.url.path.endsWith('/houses')) {
            return http.Response('{"ocs":{"data":[$houseBody]}}', 200);
          }
          return http.Response('{"ocs":{"data":{}}}', 200);
        }),
      );

      expect(controller.houses.map((h) => h.id), [3]);
      expect(controller.currentHouse?.id, 3);
      expect(controller.isLoading, isFalse);
    },
  );
}
