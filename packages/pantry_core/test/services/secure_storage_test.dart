import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/cert_trust_service.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  void mockFailingStore() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => throw PlatformException(
            code: 'Exception encountered',
            message: 'javax.crypto.BadPaddingException',
          ),
        );
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('android never resets the store on error', () {
    expect(secureStorage.aOptions.toMap()['resetOnError'], 'false');
  });

  test(
    'a store that will not decrypt leaves the app logged out, not reset',
    () async {
      mockFailingStore();

      await AuthService.instance.loadCredentials();
      await PrefsService.instance.load();
      await CertTrustService.instance.load();

      expect(AuthService.instance.isLoggedIn, isFalse);
      expect(PrefsService.instance.lastHouseId, isNull);
    },
  );
}
