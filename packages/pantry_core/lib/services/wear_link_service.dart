import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pantry_core/utils/platform_info.dart';

/// How a payload crossed the link.
enum WearLinkDelivery {
  /// Fire-and-forget, nothing left behind afterwards. The only acceptable
  /// carrier for a credential.
  message,

  /// Persisted and mirrored until deleted, and included in cloud backup.
  dataItem,
}

/// A peer on the other end of the link — for a watch, the paired phone.
class WearLinkNode {
  final String id;
  final String name;
  final bool nearby;

  const WearLinkNode({
    required this.id,
    required this.name,
    required this.nearby,
  });
}

/// One payload received from a peer.
class WearLinkMessage {
  final String path;
  final Map<String, dynamic> data;
  final WearLinkDelivery delivery;
  final String? nodeId;

  const WearLinkMessage({
    required this.path,
    required this.data,
    required this.delivery,
    this.nodeId,
  });
}

/// The link between a paired phone and watch.
///
/// A transport and nothing more: paths and payloads are opaque here, and what
/// a given path *means* — a credential handoff, a mirrored shopping session —
/// is layered above. The traffic runs both ways, so both halves of the app use
/// the same object rather than a sender and a receiver.
///
/// Core also serves iOS, macOS, Linux, Windows and web, and an Android build
/// without Play services carries no Data Layer either. Every call therefore
/// degrades to a no-op instead of throwing, and [isAvailable] is the honest
/// answer a pairing entry point should hide itself on.
class WearLinkService {
  WearLinkService._();

  static final WearLinkService instance = WearLinkService._();

  static const _methods = MethodChannel('dev.casraf.pantry/data_layer');

  /// A method channel and an event channel are both named handlers on one
  /// messenger, so the stream carries a name of its own.
  static const _channel = EventChannel('dev.casraf.pantry/data_layer/events');

  /// One subscription to the platform, shared by every reader. Each
  /// `receiveBroadcastStream` call opens its own, and the activity holds a
  /// single sink — so a second call would silently strand the first reader.
  static final _events = _channel.receiveBroadcastStream();

  static bool? _debugHostSupported;

  /// Tests run on the host OS, where [PlatformInfo.isAndroid] is false and
  /// every call would short-circuit before reaching the mocked channel.
  @visibleForTesting
  static set debugHostSupported(bool? value) => _debugHostSupported = value;

  bool get _hostSupported => _debugHostSupported ?? PlatformInfo.isAndroid;

  bool? _available;

  /// Whether the Data Layer is actually reachable: an Android host, with the
  /// channel registered and Play services present. Cached, since none of the
  /// three can change within a process.
  Future<bool> isAvailable() async {
    if (_available != null) return _available!;
    if (!_hostSupported) return _available = false;
    try {
      _available = await _methods.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      _available = false;
    } on MissingPluginException {
      _available = false;
    }
    return _available!;
  }

  /// Peers currently connected. Empty when nothing is paired, which is also
  /// what an unavailable link reports.
  Future<List<WearLinkNode>> nodes() async {
    if (!await isAvailable()) return const [];
    try {
      final raw = await _methods.invokeListMethod<dynamic>('nodes');
      return (raw ?? const [])
          .cast<Map<Object?, Object?>>()
          .map(
            (node) => WearLinkNode(
              id: node['id'] as String? ?? '',
              name: node['name'] as String? ?? '',
              nearby: node['nearby'] as bool? ?? false,
            ),
          )
          .toList(growable: false);
    } on PlatformException {
      return const [];
    }
  }

  /// Deliver [data] to one peer, or to every connected peer when [nodeId] is
  /// omitted. Leaves nothing persisted on either side.
  Future<bool> send(String path, Map<String, dynamic> data, {String? nodeId}) =>
      _invoke('send', {
        'path': path,
        'payload': jsonEncode(data),
        'nodeId': ?nodeId,
      });

  /// Mirror [data] at [path] until it is overwritten or cleared. Every write
  /// is urgent — an ordinary one can sit undelivered for half an hour.
  ///
  /// Persisted and backed up, so nothing secret belongs here; use [send].
  Future<bool> publish(String path, Map<String, dynamic> data) =>
      _invoke('publish', {'path': path, 'payload': jsonEncode(data)});

  /// Drop whatever [publish] left at [path].
  Future<bool> clear(String path) => _invoke('clear', {'path': path});

  /// Payloads arriving from peers, by either delivery. Broadcast: the link is
  /// one transport shared by every feature layered on it.
  ///
  /// A feature that stops listening tears down only its own view, and the
  /// shared stream re-attaches to the platform for the next one.
  Stream<WearLinkMessage> get messages => !_hostSupported
      ? const Stream<WearLinkMessage>.empty()
      : _events
            .map(_decode)
            .where((message) => message != null)
            .cast<WearLinkMessage>()
            .handleError((_) {});

  Future<bool> _invoke(String method, Map<String, dynamic> arguments) async {
    if (!await isAvailable()) return false;
    try {
      return await _methods.invokeMethod<bool>(method, arguments) ?? false;
    } on PlatformException {
      return false;
    }
  }

  WearLinkMessage? _decode(dynamic event) {
    if (event is! Map) return null;
    final payload = event['payload'];
    if (payload is! String) return null;
    final decoded = jsonDecode(payload);
    if (decoded is! Map) return null;
    return WearLinkMessage(
      path: event['path'] as String? ?? '',
      data: Map<String, dynamic>.from(decoded),
      delivery: event['delivery'] == 'dataItem'
          ? WearLinkDelivery.dataItem
          : WearLinkDelivery.message,
      nodeId: event['nodeId'] as String?,
    );
  }

  /// Forget the cached availability answer, so a test can set up a different
  /// link.
  @visibleForTesting
  void debugReset() => _available = null;
}
