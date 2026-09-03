import 'package:flutter/services.dart';

/// Hands a link to the paired phone to open.
///
/// The watch has no browser worth the name, so where a phone screen calls
/// `launchUrl` a watch screen calls this and tells the wearer to look at their
/// phone. Nothing here reaches core: every one of the phone's own link call
/// sites is phone-only, so there is no shared seam to build.
class WearHostService {
  WearHostService._();

  static final WearHostService instance = WearHostService._();

  static const _channel = MethodChannel('dev.casraf.pantry/wear_host');

  /// Opens [url] on the paired phone. `false` when nothing is paired, the
  /// phone is out of range, or the wearer's phone has no app for the link.
  Future<bool> openOnPhone(String url) async {
    try {
      return await _channel.invokeMethod<bool>('openOnPhone', {'url': url}) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
