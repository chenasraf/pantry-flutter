import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/auth_session_macos.dart';
import 'package:pantry/services/cert_trust_service.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:url_launcher/url_launcher.dart';

class PendingCertPrompt {
  final String host;
  final String fingerprint;
  final String subject;
  final String issuer;
  final DateTime validFrom;
  final DateTime validTo;

  const PendingCertPrompt({
    required this.host,
    required this.fingerprint,
    required this.subject,
    required this.issuer,
    required this.validFrom,
    required this.validTo,
  });
}

class LoginController extends ChangeNotifier {
  String _serverUrl = '';
  String get serverUrl => _serverUrl;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPolling = false;
  bool get isPolling => _isPolling;

  String? _error;
  String? get error => _error;

  String? _errorDetails;
  String? get errorDetails => _errorDetails;

  /// Set when the most recent connection attempt failed because the
  /// server presented an untrusted certificate. Drives the trust-cert
  /// dialog in [LoginView].
  PendingCertPrompt? _pendingCert;
  PendingCertPrompt? get pendingCert => _pendingCert;

  Timer? _pollTimer;
  LoginFlowResult? _loginFlow;

  /// The full certificate captured during the failed handshake. Kept
  /// alongside [_pendingCert] so [acceptPendingCert] can pin the exact
  /// cert the user saw without re-probing.
  X509Certificate? _pendingCertObject;
  String? _pendingCertHostKey;

  void setServerUrl(String url) {
    _serverUrl = url;
    _error = null;
    _errorDetails = null;
    notifyListeners();
  }

  String _normalizeUrl(String url) {
    url = url.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }

  Future<void> startLogin() async {
    if (_serverUrl.isEmpty) {
      _error = 'Please enter a server URL';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _errorDetails = null;
    _pendingCert = null;
    _pendingCertObject = null;
    _pendingCertHostKey = null;
    notifyListeners();

    final normalizedUrl = _normalizeUrl(_serverUrl);
    try {
      unawaited(ServerVersionService.instance.fetch(serverUrl: normalizedUrl));
      _loginFlow = await AuthService.instance.initiateLoginFlow(normalizedUrl);

      if (PlatformInfo.isMacOS) {
        // Nextcloud login flow v2 has no callback URL — the placeholder scheme
        // below satisfies ASWebAuthenticationSession but is never reached.
        // Polling drives completion; we dismiss the sheet ourselves once we
        // have credentials.
        unawaited(
          AuthSessionMacOS.start(
            url: _loginFlow!.loginUrl,
            callbackScheme: 'pantry',
          ).catchError((_) => null),
        );
      } else {
        await launchUrl(
          Uri.parse(_loginFlow!.loginUrl),
          mode: LaunchMode.inAppBrowserView,
        );
      }

      _isLoading = false;
      _isPolling = true;
      notifyListeners();

      _startPolling(normalizedUrl);
    } catch (e, st) {
      if (_isHandshakeFailure(e)) {
        await _probeCertificate(normalizedUrl, e, st);
        return;
      }
      _isLoading = false;
      _error = m.login.couldNotConnect;
      _errorDetails = '${e.runtimeType}: $e\n\n$st';
      notifyListeners();
    }
  }

  bool _isHandshakeFailure(Object e) {
    if (e is HandshakeException) return true;
    final msg = e.toString();
    return msg.contains('CERTIFICATE_VERIFY_FAILED') ||
        msg.contains('HandshakeException');
  }

  Future<void> _probeCertificate(
    String normalizedUrl,
    Object originalError,
    StackTrace originalStack,
  ) async {
    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) {
      _failWithOriginalError(originalError, originalStack);
      return;
    }
    final cert = await CertTrustService.instance.probe(uri);
    if (cert == null) {
      _failWithOriginalError(originalError, originalStack);
      return;
    }
    final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
    final hostKey = CertTrustService.hostKey(
      uri.host,
      port,
      isHttps: uri.scheme == 'https',
    );
    _pendingCertObject = cert;
    _pendingCertHostKey = hostKey;
    _pendingCert = PendingCertPrompt(
      host: hostKey,
      fingerprint: CertTrustService.fingerprintOf(cert),
      subject: cert.subject,
      issuer: cert.issuer,
      validFrom: cert.startValidity,
      validTo: cert.endValidity,
    );
    _isLoading = false;
    notifyListeners();
  }

  void _failWithOriginalError(Object e, StackTrace st) {
    _isLoading = false;
    _error = m.login.couldNotConnect;
    _errorDetails = '${e.runtimeType}: $e\n\n$st';
    notifyListeners();
  }

  /// User confirmed the cert fingerprint — pin it and retry the login.
  Future<void> acceptPendingCert() async {
    final cert = _pendingCertObject;
    final hostKey = _pendingCertHostKey;
    if (cert == null || hostKey == null) return;
    await CertTrustService.instance.pin(hostKey, cert);
    _pendingCert = null;
    _pendingCertObject = null;
    _pendingCertHostKey = null;
    notifyListeners();
    await startLogin();
  }

  void dismissPendingCert() {
    if (_pendingCert == null) return;
    _pendingCert = null;
    _pendingCertObject = null;
    _pendingCertHostKey = null;
    notifyListeners();
  }

  void _startPolling(String serverUrl) {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final creds = await AuthService.instance.pollLoginFlow(
          serverUrl,
          _loginFlow!,
        );
        if (creds != null) {
          timer.cancel();
          _isPolling = false;
          notifyListeners();
          if (PlatformInfo.isMacOS) {
            unawaited(AuthSessionMacOS.cancel());
          }
          _onLoginSuccess?.call();
        }
      } catch (e, st) {
        debugPrint('[LoginController] Poll error: $e\n$st');
      }
    });
  }

  VoidCallback? _onLoginSuccess;
  void setOnLoginSuccess(VoidCallback callback) {
    _onLoginSuccess = callback;
  }

  void cancelLogin() {
    _pollTimer?.cancel();
    if (PlatformInfo.isMacOS) {
      unawaited(AuthSessionMacOS.cancel());
    }
    _isPolling = false;
    _isLoading = false;
    _loginFlow = null;
    _error = null;
    _errorDetails = null;
    _pendingCert = null;
    _pendingCertObject = null;
    _pendingCertHostKey = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
