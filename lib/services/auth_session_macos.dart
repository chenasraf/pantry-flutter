import 'package:flutter/services.dart';

/// Thin wrapper around the macOS-native ASWebAuthenticationSession plumbing in
/// `MainFlutterWindow.swift`. Lets us start an in-app auth session and, unlike
/// `flutter_web_auth_2`, programmatically dismiss it once we already have
/// credentials via Nextcloud's login-flow-v2 polling.
class AuthSessionMacOS {
  static const _channel = MethodChannel('dev.casraf.pantry/auth_session');

  /// Presents ASWebAuthenticationSession. Resolves when the session ends —
  /// either because the user reached [callbackScheme]:// (unused for Nextcloud
  /// flow v2 but required by the API), the user dismissed it, or [cancel] was
  /// called. Throws a [PlatformException] in the cancel/dismiss cases.
  static Future<String?> start({
    required String url,
    required String callbackScheme,
  }) async {
    return await _channel.invokeMethod<String>('start', {
      'url': url,
      'callbackScheme': callbackScheme,
    });
  }

  /// Closes the current session immediately.
  static Future<void> cancel() async {
    await _channel.invokeMethod<void>('cancel');
  }
}
