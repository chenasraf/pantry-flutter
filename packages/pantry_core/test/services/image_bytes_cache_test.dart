import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/image_bytes_cache.dart';

class _FakeStore extends Fake implements ImageCacheManager {}

/// Counts the clients built through it, so a test can tell whether a request
/// went out under the app's TLS policy or under one captured before it existed.
class _CountingOverrides extends HttpOverrides {
  int built = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    built++;
    return super.createHttpClient(context);
  }
}

void main() {
  late HttpServer server;
  late String url;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    url = 'http://${server.address.address}:${server.port}/preview';
    server.listen((request) {
      request.response
        ..headers.contentType = ContentType('image', 'jpeg')
        ..add(const [0xFF, 0xD8, 0xFF]);
      request.response.close();
    });
  });

  tearDown(() async {
    HttpOverrides.global = null;
    await server.close(force: true);
  });

  test(
    'requests go out under the overrides current when they are made',
    () async {
      // Built ahead of the pinned-certificate overrides, the way a store is:
      // a service resolving them now would never see them.
      final service = ImageBytesCache.fileService;

      final overrides = _CountingOverrides();
      HttpOverrides.global = overrides;
      expect(overrides.built, 0);

      final response = await service.get(url);
      expect(response.statusCode, 200);
      expect(overrides.built, 1);
    },
  );

  test('the installed store is opened by the first image, not at boot', () {
    var opened = 0;
    ImageBytesCache.install(() {
      opened++;
      return _FakeStore();
    });

    expect(opened, 0);
    final first = ImageBytesCache.manager;
    expect(opened, 1);
    expect(ImageBytesCache.manager, same(first));
  });
}
