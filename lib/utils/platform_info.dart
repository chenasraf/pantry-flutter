import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Single source of truth for runtime platform decisions. Read these getters
/// instead of touching `Platform`, `kIsWeb`, or `defaultTargetPlatform`
/// directly — each native check has to be `kIsWeb`-guarded or it throws on
/// web, and centralising that here is what keeps callers from forgetting.
class PlatformInfo {
  PlatformInfo._();

  static bool? _isiOSAppOnMacCache;

  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isLinux => !kIsWeb && Platform.isLinux;
  static bool get isFuchsia => !kIsWeb && Platform.isFuchsia;

  /// Native desktop platforms (macOS, Windows, Linux). Excludes web — use
  /// [isDesktopHost] when the decision is about "desktop-shaped runtime"
  /// rather than "this is a native desktop binary".
  static bool get isDesktop => isMacOS || isWindows || isLinux;

  /// Like [isDesktop] but also includes web. Use for layout / interaction
  /// decisions where web behaves like desktop (no touch, large viewport).
  static bool get isDesktopHost => isWeb || isDesktop;

  /// Native mobile platforms (Android, iOS). Excludes web.
  static bool get isMobile => isAndroid || isIOS;

  /// `true` when running as an iOS-built binary on an Apple Silicon Mac.
  /// Async because the device-info plugin call is, but the result is
  /// cached after the first read.
  static Future<bool> get isiOSAppOnMac async {
    if (_isiOSAppOnMacCache != null) return _isiOSAppOnMacCache!;
    if (!isIOS) return _isiOSAppOnMacCache = false;
    final info = await DeviceInfoPlugin().iosInfo;
    return _isiOSAppOnMacCache = info.isiOSAppOnMac;
  }

  /// Human-readable platform name. Used for user-agent strings and
  /// debugging labels.
  static String get displayName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    if (isWindows) return 'Windows';
    return 'Unknown';
  }
}
