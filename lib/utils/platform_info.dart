import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';

bool? _isiOSAppOnMacCache;

Future<bool> isiOSAppOnMac() async {
  if (_isiOSAppOnMacCache != null) return _isiOSAppOnMacCache!;
  if (!Platform.isIOS) return _isiOSAppOnMacCache = false;
  final info = await DeviceInfoPlugin().iosInfo;
  return _isiOSAppOnMacCache = info.isiOSAppOnMac;
}
