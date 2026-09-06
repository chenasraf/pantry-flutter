import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/cert_trust_service.dart';

/// Telling a certificate problem apart from an unreachable host.
///
/// Both surfaces that accept a typed address branch on this, and only one of
/// the two outcomes is worth offering a fingerprint for: a watch that took the
/// wrong branch would either hide a self-signed server behind "couldn't reach
/// that server", or ask the wearer to trust a certificate nothing sent.
void main() {
  test('a handshake exception is one', () {
    expect(
      CertTrustService.isHandshakeFailure(const HandshakeException('nope')),
      isTrue,
    );
  });

  test('so is one that reached us wrapped', () {
    expect(
      CertTrustService.isHandshakeFailure(
        Exception('HandshakeException: CERTIFICATE_VERIFY_FAILED'),
      ),
      isTrue,
    );
  });

  test('an unreachable host is not', () {
    expect(
      CertTrustService.isHandshakeFailure(
        const SocketException('Failed host lookup'),
      ),
      isFalse,
    );
  });

  test('a host and its default port are one pin set', () {
    expect(
      CertTrustService.hostKey('cloud.example', 443, isHttps: true),
      'cloud.example',
    );
    expect(
      CertTrustService.hostKey('cloud.example', 8443, isHttps: true),
      'cloud.example:8443',
    );
  });
}
