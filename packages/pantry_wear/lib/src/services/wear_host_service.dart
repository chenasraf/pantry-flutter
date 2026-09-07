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

  /// Whether this watch has a bezel or a crown at all.
  ///
  /// Answered by enumerating input devices for the same source
  /// `onGenericMotionEvent` filters on, which is a claim about hardware the
  /// platform makes rather than one we have watched arrive — nothing here has
  /// seen a detent yet, and a settings page needs the answer before the wearer
  /// has turned anything.
  ///
  /// So it fails towards yes: a useless row on a watch with no crown costs one
  /// line, where a hidden row on a watch that has one costs a setting the
  /// wearer can neither reach nor discover.
  Future<bool> hasRotary() async {
    try {
      return await _channel.invokeMethod<bool>('hasRotary') ?? true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true;
    }
  }

  /// Whether this watch will draw anything the app posts.
  ///
  /// Asked of the system every time rather than remembered: the wearer can
  /// change it from the system's own screen or by long-pressing a chip, neither
  /// of which comes back through the app. Unanswerable means yes, so a watch
  /// that cannot say draws the row as granted rather than accusing itself of a
  /// block it has not got.
  Future<bool> notificationsEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('notificationsEnabled') ?? true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true;
    }
  }

  /// Ask for the runtime notification grant.
  ///
  /// Answers nothing: the wearer replies long after this returns, and once they
  /// have refused Android stops showing the prompt at all. [notificationsEnabled]
  /// is where the answer is read.
  Future<void> requestNotifications() async {
    try {
      await _channel.invokeMethod<void>('requestNotifications');
    } on PlatformException catch (_) {
    } on MissingPluginException catch (_) {}
  }

  /// Open the watch's own notification screen for this app. `false` when the
  /// watch has no such screen to open.
  Future<bool> openNotificationSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openNotificationSettings') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
