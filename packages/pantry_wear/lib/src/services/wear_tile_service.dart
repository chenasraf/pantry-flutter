import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/theming_service.dart';

/// Publishes what the list Tile draws.
///
/// The Tile is rendered by the system from a ProtoLayout the app hands over,
/// and the system asks for it whenever it likes — most often with no Flutter
/// engine anywhere. So the Tile never runs Dart and never reads a cache: the
/// app pushes a small snapshot to native, native keeps it, and the Tile is
/// built from that alone.
///
/// The snapshot carries **names, not counts**. A count the Tile cannot refresh
/// is a number that goes wrong within minutes of the app closing, and the Tile
/// has no way to fetch one; list names change about as often as lists are
/// created, so a snapshot days old is still true. That is what lets the Tile
/// have no freshness interval at all.
class WearTileService {
  WearTileService._();

  static final WearTileService instance = WearTileService._();

  static const _channel = MethodChannel('dev.casraf.pantry/tile');

  /// How many lists the snapshot carries. The Tile is one fixed screen with no
  /// scrolling of any kind, so the cap is a layout fact rather than a policy:
  /// past this the rows stop being thumb-sized on a 1.4" screen.
  static const maxLists = 4;

  @visibleForTesting
  static MethodChannel get channel => _channel;

  /// Hand the Tile the current house's lists, lowest `sortOrder` first.
  ///
  /// Safe to call on every read — native compares the payload with what it
  /// already holds and only wakes the Tile when it differs, which keeps a
  /// 60-second poll from redrawing a system surface 60 times an hour.
  Future<void> publish({
    required int houseId,
    String? houseName,
    required List<ChecklistList> lists,
  }) {
    final ordered = [...lists]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return _send('publish', {
      'houseId': houseId,
      'houseName': houseName,
      'accent': _hex(ThemingService.instance.effectiveColor),
      'lists': [
        for (final l in ordered.take(maxLists))
          {'id': l.id, 'name': l.name, 'icon': l.icon, 'color': l.color},
      ],
    });
  }

  /// Drop the snapshot. Signing out or being unpaired has to take the Tile with
  /// it — otherwise a watch that no longer has an account keeps showing a
  /// household's list names on its face, which is the same leak by a slower
  /// route.
  Future<void> clear() => _send('clear', const {});

  Future<void> _send(String method, Map<String, Object?> args) async {
    try {
      await _channel.invokeMethod<void>(method, {
        if (args.isNotEmpty) 'payload': jsonEncode(args),
      });
    } on PlatformException catch (_) {
    } on MissingPluginException catch (_) {}
  }

  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
