import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What the watch is asking the app to look like right now.
@immutable
class WearAmbientState {
  const WearAmbientState({
    this.isAmbient = false,
    this.burnInProtectionRequired = false,
    this.deviceHasLowBitAmbient = false,
  });

  /// The screen is dimmed and still ours to draw.
  final bool isAmbient;

  /// The panel retains what sits still on it, so a dimmed screen has to move
  /// its content periodically rather than hold one arrangement.
  final bool burnInProtectionRequired;

  /// The dimmed panel has too few bits per channel for anti-aliasing to read as
  /// smoothing rather than as dirt.
  final bool deviceHasLowBitAmbient;

  @override
  bool operator ==(Object other) =>
      other is WearAmbientState &&
      other.isAmbient == isAmbient &&
      other.burnInProtectionRequired == burnInProtectionRequired &&
      other.deviceHasLowBitAmbient == deviceHasLowBitAmbient;

  @override
  int get hashCode =>
      Object.hash(isAmbient, burnInProtectionRequired, deviceHasLowBitAmbient);
}

/// The dimmed screen, and the app's claim on it.
///
/// The watch hands the display to the app rather than to the watch face for as
/// long as the wearer's *hide apps after…* setting allows, and redraws it about
/// once a minute. Both halves of that come from the activity's ambient
/// observer, which is also the thing that told the system this app wants the
/// screen at all.
///
/// [notifyListeners] fires on every update the system sends, not only on a
/// changed value: an update is the one moment a dimmed screen is permitted to
/// repaint, so a clock or a count that skipped it would sit wrong for a minute.
class WearAmbient extends ChangeNotifier {
  WearAmbient._();

  static final WearAmbient instance = WearAmbient._();

  static const _channel = EventChannel('dev.casraf.pantry/ambient');

  StreamSubscription<dynamic>? _sub;

  WearAmbientState _state = const WearAmbientState();

  WearAmbientState get state => _state;

  bool get isAmbient => _state.isAmbient;

  /// Attaches to the activity, which replies with the state it already holds —
  /// so a listener that starts mid-doze is not left drawing the interactive
  /// theme over a dimmed screen until the next update.
  Future<void> start() async {
    if (_sub != null) return;
    _sub = _channel.receiveBroadcastStream().listen((event) {
      final map = event as Map<Object?, Object?>?;
      if (map == null) return;
      _state = WearAmbientState(
        isAmbient: map['isAmbient'] as bool? ?? false,
        burnInProtectionRequired:
            map['burnInProtectionRequired'] as bool? ?? false,
        deviceHasLowBitAmbient: map['deviceHasLowBitAmbient'] as bool? ?? false,
      );
      notifyListeners();
    }, onError: (_) {});
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    _sub = null;
    super.dispose();
  }
}
