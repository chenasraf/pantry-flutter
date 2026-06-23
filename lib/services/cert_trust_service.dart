import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Per-host pinned certificate fingerprints. Lets users connect to
/// Nextcloud servers with self-signed certificates by accepting the
/// certificate on first connect; subsequent connections only succeed if
/// the SHA-256 fingerprint still matches the pinned value, so a MITM
/// swapping in a different self-signed cert would still be rejected.
class CertTrustService {
  CertTrustService._();
  static final CertTrustService instance = CertTrustService._();

  static const _storageKey = 'pinned_cert_fingerprints';
  final _storage = const FlutterSecureStorage();

  /// host[:port] -> set of accepted SHA-256 fingerprints (uppercase hex).
  Map<String, Set<String>> _pinned = {};

  /// Load persisted pins. Call BEFORE [install] so the first request
  /// already has the pinned set available.
  Future<void> load() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _pinned = {
        for (final e in decoded.entries)
          e.key: (e.value as List).cast<String>().toSet(),
      };
    } catch (e) {
      debugPrint('[CertTrustService] Failed to decode pinned certs: $e');
    }
  }

  bool isPinned(String hostKey, X509Certificate cert) {
    final fps = _pinned[hostKey];
    if (fps == null || fps.isEmpty) return false;
    return fps.contains(fingerprintOf(cert));
  }

  Future<void> pin(String hostKey, X509Certificate cert) async {
    final fp = fingerprintOf(cert);
    final set = _pinned.putIfAbsent(hostKey, () => <String>{});
    if (!set.add(fp)) return;
    await _persist();
  }

  Future<void> _persist() async {
    final encoded = jsonEncode({
      for (final e in _pinned.entries) e.key: e.value.toList(),
    });
    await _storage.write(key: _storageKey, value: encoded);
  }

  /// "AA:BB:CC:..." colon-separated uppercase hex of SHA-256 over DER.
  static String fingerprintOf(X509Certificate cert) {
    final digest = sha256.convert(cert.der);
    return digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }

  /// Key used in [_pinned]. Default ports are dropped so `host` and
  /// `host:443` resolve to the same pin set.
  static String hostKey(String host, int port, {required bool isHttps}) {
    final defaultPort = isHttps ? 443 : 80;
    return port == defaultPort ? host : '$host:$port';
  }

  /// Install the [HttpOverrides] that consult the pin store.
  void install() {
    HttpOverrides.global = _PinnedHttpOverrides(this);
  }

  /// Connect to [uri] and return the server's certificate even if it
  /// fails validation. Returns null if the TLS handshake couldn't be
  /// reached at all (DNS failure, connection refused, timeout, etc.).
  ///
  /// Every step is individually bounded so a server that accepts the
  /// connection but never answers can't wedge the caller in an infinite
  /// spinner — the cert is captured during the handshake, so even if the
  /// later request/drain times out we still return what we saw.
  Future<X509Certificate?> probe(Uri uri) async {
    return HttpOverrides.runZoned<Future<X509Certificate?>>(() async {
      X509Certificate? captured;
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..badCertificateCallback = (cert, host, port) {
          captured = cert;
          // Accept once so the request completes and the socket can
          // close cleanly. We never reuse this client for real work.
          return true;
        };
      try {
        final req = await client
            .headUrl(uri)
            .timeout(const Duration(seconds: 10));
        final resp = await req.close().timeout(const Duration(seconds: 10));
        await resp.drain<void>().timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[CertTrustService] probe failed: $e');
      } finally {
        client.close(force: true);
      }
      return captured;
    }, createHttpClient: (ctx) => HttpClient(context: ctx));
  }
}

class _PinnedHttpOverrides extends HttpOverrides {
  final CertTrustService trust;
  _PinnedHttpOverrides(this.trust);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) {
        final key = CertTrustService.hostKey(host, port, isHttps: true);
        return trust.isPinned(key, cert);
      };
  }
}
