import 'package:flutter/services.dart';

/// The rotating bezel and the crown.
///
/// Flutter's own pointer-signal path never sees either: the value rides
/// `AXIS_SCROLL`, which the engine does not read, while the horizontal and
/// vertical scroll axes it does read stay at zero. The activity forwards the
/// raw axis instead, one event per detent.
class RotaryService {
  RotaryService._();

  static final RotaryService instance = RotaryService._();

  static const _channel = EventChannel('dev.casraf.pantry/rotary');

  /// One subscription to the platform, shared by every reader.
  ///
  /// Each `receiveBroadcastStream` call opens its own, and the activity holds a
  /// single sink — so a second call would silently strand the first reader.
  /// This one stream still detaches and re-attaches as its listener count
  /// crosses zero, so nothing leaks while no screen is watching.
  static final _events = _channel.receiveBroadcastStream();

  /// One event per detent, `+1.0` clockwise and `-1.0` counter-clockwise.
  ///
  /// Broadcast, because a page and the list inside it both want to steer by
  /// the bezel and only one of them is focused at a time.
  Stream<double> get detents =>
      _events.map((event) => (event as num).toDouble()).handleError((_) {});
}
