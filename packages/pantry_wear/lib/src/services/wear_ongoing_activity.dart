import 'package:flutter/services.dart';
import 'package:pantry_core/i18n.dart';

/// The live-trip chip on the watch face.
///
/// The chip outlives the process that posted it and has no engine behind it to
/// correct anything, so it carries one string that is true for exactly as long
/// as the trip is — never the store, which a leg advanced on the phone would
/// leave naming a shop the wearer has walked out of. Everything else about a
/// trip is on the rail, where somebody is looking at the app.
///
/// [post] is safe to call on an already-posted chip and is meant to be: Android
/// gives the notification half an hour and re-posting is the only thing that
/// restarts it.
class WearOngoingActivityService {
  WearOngoingActivityService._();

  static final WearOngoingActivityService instance =
      WearOngoingActivityService._();

  static const _channel = MethodChannel('dev.casraf.pantry/ongoing_activity');

  /// Draw the chip, and restart the half hour Android gives it.
  Future<void> post() => _send('post', {'status': m.wear.shoppingTripChip});

  /// Take the chip down. Cancelling a chip that is not up costs nothing, which
  /// is what lets a launch that finds no trip clear one a closed trip left
  /// behind.
  Future<void> cancel() => _send('cancel', const {});

  Future<void> _send(String method, Map<String, Object?> args) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on PlatformException catch (_) {
    } on MissingPluginException catch (_) {}
  }
}
