import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pantry_core/models/list_link.dart';

import '../scope/wear_scope.dart';

/// Requests to open a particular list, arriving from outside the app: the list
/// Tile, or a `pantry://list/...` VIEW intent.
///
/// The two arrivals take different routes because they happen at different
/// moments, and each takes the cheapest one for its moment:
///
/// * **A cold launch** carries the link in the Dart entrypoint arguments,
///   beside the screen shape and for the same reason — the first channel round
///   trip lands 311 ms after the first frame, and a Tile tap that draws the
///   wrong list for a third of a second before correcting itself is the one
///   case where that is visible. Read before `runApp`, the target list is the
///   first thing drawn.
/// * **A tap on an app already running** cannot use entrypoint arguments at
///   all — the engine is up — so it arrives on an event channel from
///   `onNewIntent`.
///
/// Both are normalised to a `pantry://` URL in the activity, so this side
/// knows one grammar however the intent carried it.
class WearDeepLink extends ChangeNotifier {
  WearDeepLink._();

  static final WearDeepLink instance = WearDeepLink._();

  static const _channel = EventChannel('dev.casraf.pantry/deep_link');

  @visibleForTesting
  static EventChannel get channel => _channel;

  ListLink? _pending;

  /// The request waiting to be applied, or null. Cleared by [take].
  ListLink? get pending => _pending;

  StreamSubscription<dynamic>? _subscription;

  /// The launch link, out of the arguments the activity passed the entrypoint.
  ///
  /// Scans rather than indexes: the shape argument rides the same list, and
  /// two readers agreeing on a position is a coupling that breaks silently the
  /// first time one of them stops being passed.
  void markFrom(List<String> args) {
    for (final arg in args) {
      final link = _parse(arg);
      if (link != null) {
        _pending = link;
        return;
      }
    }
  }

  /// Listen for taps arriving while the app is already up. Never cancelled —
  /// the singleton lives as long as the process, and a cancel would drop the
  /// activity's sink for anything else reading it.
  Future<void> start() async {
    if (_subscription != null) return;
    try {
      _subscription = _channel.receiveBroadcastStream().listen((event) {
        final link = _parse(event as String?);
        if (link == null) return;
        _pending = link;
        notifyListeners();
      }, onError: (_) {});
    } on MissingPluginException catch (_) {}
  }

  /// The pending request, cleared. A request is acted on once: re-applying it
  /// on the next rebuild would drag the wearer back to the Tile's list every
  /// time they changed lists by hand.
  ListLink? take() {
    final link = _pending;
    _pending = null;
    return link;
  }

  /// Move scope onto the pending request, if there is one. Returns whether it
  /// moved, so a caller with a pager to align knows whether to.
  ///
  /// Both levels persist, exactly as they do on the phone: arriving at a list
  /// is choosing it, so `pantry://list/<house>/<list>` means the same thing on
  /// both devices and the Tile is a legitimate "make this my list" shortcut. A
  /// link naming no house leaves the current one alone — the short form only
  /// ever comes from within a house the watch is already in.
  Future<bool> applyPending() async {
    final link = take();
    if (link == null) return false;
    final house = link.houseId;
    if (house != null) {
      await WearScope.instance.open(house, link.listId);
    } else {
      await WearScope.instance.selectList(link.listId);
    }
    return true;
  }

  static ListLink? _parse(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    return uri == null ? null : ListLink.fromUri(uri);
  }
}
