import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginController extends ChangeNotifier {
  String _serverUrl = '';
  String get serverUrl => _serverUrl;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPolling = false;
  bool get isPolling => _isPolling;

  String? _error;
  String? get error => _error;

  Timer? _pollTimer;
  LoginFlowResult? _loginFlow;

  void setServerUrl(String url) {
    _serverUrl = url;
    _error = null;
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
    notifyListeners();

    try {
      final normalizedUrl = _normalizeUrl(_serverUrl);
      _loginFlow = await AuthService.instance.initiateLoginFlow(normalizedUrl);

      await launchUrl(
        Uri.parse(_loginFlow!.loginUrl),
        mode: LaunchMode.inAppBrowserView,
      );

      _isLoading = false;
      _isPolling = true;
      notifyListeners();

      _startPolling(normalizedUrl);
    } catch (e) {
      _isLoading = false;
      _error = 'Could not connect to server. Please check the URL.';
      notifyListeners();
    }
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
          _onLoginSuccess?.call();
        }
      } catch (e, stack) {
        debugPrint('[LoginController] Poll error: $e');
        debugPrint('[LoginController] Stack: $stack');
        // Transient network errors — keep polling
      }
    });
  }

  VoidCallback? _onLoginSuccess;
  void setOnLoginSuccess(VoidCallback callback) {
    _onLoginSuccess = callback;
  }

  void cancelLogin() {
    _pollTimer?.cancel();
    _isPolling = false;
    _isLoading = false;
    _loginFlow = null;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
