import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

bool? _isiOSAppOnMacCache;

Future<bool> isiOSAppOnMac() async {
  if (_isiOSAppOnMacCache != null) return _isiOSAppOnMacCache!;
  if (!Platform.isIOS) return _isiOSAppOnMacCache = false;
  final info = await DeviceInfoPlugin().iosInfo;
  return _isiOSAppOnMacCache = info.isiOSAppOnMac;
}

/// Native desktop platforms (macOS, Windows, Linux) where pull-to-refresh
/// is awkward or unavailable, so a visible refresh affordance is needed.
bool get isDesktop {
  if (kIsWeb) return false;
  return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
}
