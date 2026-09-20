import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/cert_trust_service.dart';
import 'package:pantry_core/sync/sync_manager.dart';

/// What happens to a request this device cannot get to the server when another
/// one can.
///
/// The relay is reached for at one point only — a request that never arrived —
/// and what it answers has to be indistinguishable from a direct answer. A
/// caller told it is offline while holding a fresh response falls back to a
/// cache it did not need, and a certificate refusal left standing puts a
/// *Server not verified* notice above working data.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final sync = SyncManager.instance;

  /// Requests the relay was asked to make.
  final asked = <ApiRequest>[];

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (call) async => null);
  });

  setUp(() async {
    asked.clear();
    ApiClient.relay = null;
    await sync.reset();
    sync.setOnline(true);
    CertTrustService.instance.reportReachable();
    await AuthService.instance.adoptCredentials(
      const NextcloudCredentials(
        serverUrl: 'https://pantry.local',
        loginName: 'ada',
        appPassword: 'secret',
      ),
    );
  });

  tearDown(() async {
    ApiClient.relay = null;
    await sync.reset();
    sync.setOnline(true);
  });

  /// A relay that answers every request with [status] and [body].
  void relayAnswers({int status = 200, String body = '{"ok":true}'}) {
    ApiClient.relay = (request) async {
      asked.add(request);
      return http.Response(body, status);
    };
  }

  /// A relay that is there but no better off — the phone out of the house, or
  /// no phone in range at all.
  void relayCannotHelp() {
    ApiClient.relay = (request) async {
      asked.add(request);
      return null;
    };
  }

  /// A server this device has no route to, the way each failure actually
  /// arrives.
  http.Client unroutable({Object? error}) => MockClient(
    (request) async =>
        throw error ?? const SocketException('Network is unreachable'),
  );

  Future<Map<String, dynamic>> get() => http.runWithClient(
    () => ApiClient.instance.get<Map<String, dynamic>, Map<String, dynamic>>(
      '/houses',
      fromJson: (data) => data,
    ),
    unroutable,
  );

  group('a request that never arrived', () {
    test('is handed to the relay, described well enough to make', () async {
      relayAnswers();

      await get();

      expect(asked.single.method, 'GET');
      expect(asked.single.uri.host, 'pantry.local');
      expect(asked.single.uri.path, endsWith('/houses'));
      expect(asked.single.headers['Authorization'], isNotNull);
    });

    test('is answered by the relay as if it had gone out from here', () async {
      relayAnswers(body: '{"houses":[]}');

      expect(await get(), {'houses': []});
    });

    test('leaves the app online, because a server did answer', () async {
      relayAnswers();

      await get();

      // A read that fell back to the cache here would be discarding the
      // response it is holding, and the queue would hold writes it could send.
      expect(sync.isOnline, isTrue);
    });
  });

  group('a body', () {
    test('crosses to the relay whole', () async {
      relayAnswers();

      await http.runWithClient(
        () =>
            ApiClient.instance.post<Map<String, dynamic>, Map<String, dynamic>>(
              '/houses/1/lists/7/items/42/toggle',
              body: const {'done': true},
              fromJson: (data) => data,
            ),
        unroutable,
      );

      expect(asked.single.method, 'POST');
      expect(jsonDecode(utf8.decode(asked.single.body!)), {'done': true});
      // The charset package:http used to append survives the move, so a
      // relayed write puts the same bytes and the same content type on the
      // wire as a direct one.
      expect(
        asked.single.headers['Content-Type'],
        'application/json; charset=utf-8',
      );
    });
  });

  group('a refused certificate', () {
    /// The watch's own store has no pin; the phone's does. This is the shape
    /// that shipped broken twice.
    http.Client refusesCert() => MockClient(
      (_) async => throw const HandshakeException(
        'Handshake error in client',
        OSError('CERTIFICATE_VERIFY_FAILED: self signed certificate'),
      ),
    );

    test('is rescued, and no refusal is left standing', () async {
      relayAnswers();

      await http.runWithClient(
        () =>
            ApiClient.instance.get<Map<String, dynamic>, Map<String, dynamic>>(
              '/houses',
              fromJson: (data) => data,
            ),
        refusesCert,
      );

      // A handshake succeeded somewhere, so a notice reading "Server not
      // verified" over freshly fetched data would be a lie the wearer cannot
      // act on.
      expect(CertTrustService.instance.untrustedHost.value, isNull);
      expect(sync.isOnline, isTrue);
    });

    test('still names the host when nobody can reach it', () async {
      relayCannotHelp();

      await expectLater(
        http.runWithClient(
          () => ApiClient.instance
              .get<Map<String, dynamic>, Map<String, dynamic>>(
                '/houses',
                fromJson: (data) => data,
              ),
          refusesCert,
        ),
        throwsA(isA<CertUntrustedException>()),
      );

      expect(CertTrustService.instance.untrustedHost.value, 'pantry.local');
    });
  });

  group('when the relay cannot help either', () {
    test('the direct failure is what the caller gets', () async {
      relayCannotHelp();

      await expectLater(get(), throwsA(isA<OfflineException>()));
      expect(sync.isOnline, isFalse);
    });

    test('a relay that throws is a relay that did not deliver', () async {
      ApiClient.relay = (request) async => throw StateError('link died');

      // Its own failure must not replace the honest one, or a caller branching
      // on being offline would meet an error it has no path for.
      await expectLater(get(), throwsA(isA<OfflineException>()));
      expect(sync.isOnline, isFalse);
    });
  });

  group('with no relay installed', () {
    test('nothing about a failure changes', () async {
      await expectLater(get(), throwsA(isA<OfflineException>()));

      expect(sync.isOnline, isFalse);
      expect(asked, isEmpty);
    });

    test('and a server that answers is never offered to one', () async {
      relayAnswers();

      final body = await http.runWithClient(
        () =>
            ApiClient.instance.get<Map<String, dynamic>, Map<String, dynamic>>(
              '/houses',
              fromJson: (data) => data,
            ),
        () => MockClient((_) async => http.Response('{"direct":true}', 200)),
      );

      // Nobody whose server answers meets the relay at runtime.
      expect(body, {'direct': true});
      expect(asked, isEmpty);
    });
  });
}
