import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Single source of truth for runtime platform decisions. Read these getters
/// instead of touching `Platform`, `kIsWeb`, or `defaultTargetPlatform`
/// directly — each native check has to be `kIsWeb`-guarded or it throws on
/// web, and centralising that here is what keeps callers from forgetting.
class PlatformInfo {
  PlatformInfo._();

  static bool _isWatch = false;

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

  /// `true` on Wear OS. Fixed by the entrypoint before `runApp` rather than
  /// probed at runtime: a watch is an Android device by every platform check,
  /// so nothing else can tell the two binaries apart, and the answer is needed
  /// synchronously inside constructors that run before the first frame.
  static bool get isWatch => _isWatch;

  /// Called once by the watch entrypoint. There is no way back — a process is
  /// one form factor for its whole life.
  static void markAsWatch() => _isWatch = true;

  /// Phone-shaped Android: excludes the watch, which answers `true` to
  /// [isAndroid] and would otherwise inherit every phone-only branch.
  static bool get isAndroidPhone => isAndroid && !isWatch;

  /// Human-readable platform name. Used for user-agent strings and
  /// debugging labels.
  static String get displayName {
    if (isWeb) return 'Web';
    if (isWatch) return 'Wear OS';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    if (isWindows) return 'Windows';
    return 'Unknown';
  }
}
