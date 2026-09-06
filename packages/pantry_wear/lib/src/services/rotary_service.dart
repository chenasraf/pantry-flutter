import 'dart:async';

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
  static final _events = _channel
      .receiveBroadcastStream()
      .map((event) => (event as num).toDouble())
      .handleError((_) {});

  int _readers = 0;

  /// How many readers are attached to [detents] right now.
  ///
  /// Exactly one is the rule everywhere — a page and a route pushed over it are
  /// both mounted, so leaving both subscribed means one turn of the bezel moves
  /// two things. Rotary is not injectable over adb, so the only way to hold
  /// that rule is a test that counts, and this is what it counts.
  int get readerCount => _readers;

  /// One event per detent, `+1.0` clockwise and `-1.0` counter-clockwise.
  ///
  /// A reader of its own each time, over the one platform subscription, so a
  /// page and the route covering it are told apart rather than sharing a
  /// listener count of one.
  Stream<double> get detents {
    late final StreamController<double> reader;
    StreamSubscription<double>? source;
    reader = StreamController<double>.broadcast(
      onListen: () {
        _readers++;
        source = _events.listen(reader.add);
      },
      onCancel: () async {
        _readers--;
        final sub = source;
        source = null;
        await sub?.cancel();
      },
    );
    return reader.stream;
  }
}
