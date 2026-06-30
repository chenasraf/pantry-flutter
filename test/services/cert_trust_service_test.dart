import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/services/cert_trust_service.dart';

/// Stands in for the app's real global override: a pinned-cert HttpOverrides
/// that rejects everything (nothing pinned yet). [CertTrustService.probe] must
/// still capture the server certificate while this is installed — that's the
/// exact situation a first-time self-signed connection hits.
class _RejectingOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => false;
  }
}

void main() {
  group('CertTrustService.probe against a self-signed server', () {
    late HttpServer server;
    late Uri uri;
    HttpOverrides? previous;

    setUp(() async {
      final ctx = SecurityContext()
        ..useCertificateChain('test/fixtures/self_signed_cert.pem')
        ..usePrivateKey('test/fixtures/self_signed_key.pem');
      server = await HttpServer.bindSecure('127.0.0.1', 0, ctx);
      server.listen((req) async {
        req.response.write('ok');
        await req.response.close();
      });
      uri = Uri.parse('https://127.0.0.1:${server.port}');
      // Install a rejecting global override, mirroring the running app.
      previous = HttpOverrides.current;
      HttpOverrides.global = _RejectingOverrides();
    });

    tearDown(() async {
      HttpOverrides.global = previous;
      await server.close(force: true);
    });

    test(
      'returns the captured certificate even with a rejecting global override',
      () async {
        // Regression guard: probe used to wrap its client in
        // HttpOverrides.runZoned(createHttpClient: (ctx) => HttpClient(...)),
        // which recursed until the stack overflowed and wedged the login flow.
        final cert = await CertTrustService.instance.probe(uri);
        expect(cert, isNotNull);
        expect(CertTrustService.fingerprintOf(cert!), isNotEmpty);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
