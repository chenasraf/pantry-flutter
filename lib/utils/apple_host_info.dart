import 'package:device_info_plus/device_info_plus.dart';
import 'package:pantry_core/utils/platform_info.dart';

bool? _isiOSAppOnMacCache;

/// `true` when running as an iOS-built binary on an Apple Silicon Mac.
/// Async because the device-info plugin call is, but the result is cached
/// after the first read.
Future<bool> isiOSAppOnMac() async {
  if (_isiOSAppOnMacCache != null) return _isiOSAppOnMacCache!;
  if (!PlatformInfo.isIOS) return _isiOSAppOnMacCache = false;
  final info = await DeviceInfoPlugin().iosInfo;
  return _isiOSAppOnMacCache = info.isiOSAppOnMac;
}
