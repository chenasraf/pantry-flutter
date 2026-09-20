import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry_core/services/wear_relay.dart';

import 'wear_pairing_host.dart';

/// The phone's half of the relay: it makes a request the watch could not, and
/// streams back whatever the server said.
///
/// The phone is not a better-connected watch — it is a differently connected
/// one. A watch linked over Bluetooth gets the phone's *internet* through the
/// companion proxy, which routes as though the request came from the open web,
/// so a household server on the wearer's own LAN is reachable from this device
/// and from nowhere else in the house. That is the whole of what this is for.
///
/// It is a socket and not a queue. The watch keeps its own ops, their order,
/// their ids and the count it shows the wearer; this performs one request and
/// answers it. A phone that took ownership of the write instead would clear the
/// watch's sync dot on receipt rather than on the server's answer, and bind a
/// created row's real id in the wrong device's id map.
class WearRelayHost {
  WearRelayHost._();

  static final WearRelayHost instance = WearRelayHost._();

  final _link = WearLinkService.instance;

  StreamSubscription<WearLinkMessage>? _messages;

  /// Ceiling on one relayed request, independent of what the watch is willing
  /// to wait. A phone holding a socket open on a server that stopped answering
  /// is doing the wearer no good after the watch has given up on it.
  static const _budget = Duration(seconds: 18);

  /// Requests in flight, by id, so a payload delivered twice is answered by the
  /// work already running rather than performing the wearer's write twice.
  ///
  /// It guards a duplicate *delivery* and nothing more: a watch that gives up
  /// waiting and asks again asks under a new id, which this cannot recognise
  /// and must not — that retry is the queue's at-least-once contract, which the
  /// server arbitrates, exactly as it does for a request the watch sent itself.
  final _inFlight = <String, Future<WearRelayResponse>>{};

  Future<void> init() async {
    if (_messages != null) return;
    if (!await _link.isAvailable()) return;
    _messages = _link.messages.listen(_onMessage);
  }

  Future<void> dispose() async {
    await _messages?.cancel();
    _messages = null;
  }

  void _onMessage(WearLinkMessage message) {
    if (message.path != WearRelay.requestPath) return;
    final nodeId = message.nodeId;
    if (nodeId == null) return;
    // Only for the watch this phone signed in. The relay carries the
    // household's credential to a household server, so the question of who may
    // ask it is the question pairing already answered — and a watch that missed
    // its unpair must not go on being served.
    if (nodeId != WearPairingHost.instance.paired.value?.nodeId) return;
    final request = WearRelayRequest.fromJson(message.data);
    // A payload this build cannot read goes unanswered rather than
    // half-performed: the watch's own timeout is the reply, and it has a
    // direct failure to fall back on.
    if (request == null) return;
    unawaited(_serve(nodeId, request));
  }

  Future<void> _serve(String nodeId, WearRelayRequest request) async {
    final pending = _inFlight[request.id];
    final answer = await (pending ?? _run(request));
    await _link.stream(WearRelay.responsePath, answer.toJson(), nodeId: nodeId);
  }

  Future<WearRelayResponse> _run(WearRelayRequest request) {
    final work = _perform(request);
    _inFlight[request.id] = work;
    return work.whenComplete(() => _inFlight.remove(request.id));
  }

  /// Perform it with this phone's own stack, which is what makes it worth
  /// asking: the certificate store the wearer accepted on this screen, the DNS
  /// this network hands out, and a route onto it.
  ///
  /// Every failure collapses to one answer. The watch already knows how to be
  /// told that a request never arrived, and it is holding the same news from
  /// its own attempt — so a phone that cannot help says exactly that rather
  /// than describing how.
  Future<WearRelayResponse> _perform(WearRelayRequest request) async {
    final url = Uri.tryParse(request.url);
    if (url == null || !url.hasScheme || url.host.isEmpty) {
      return WearRelayResponse.unreachable(request.id);
    }
    // Only the server this phone is signed in to. The relay exists to reach
    // one household server that the watch cannot; a phone willing to fetch any
    // address on its behalf would be a way onto the whole home network, and
    // the watch has never had a reason to ask for anything else.
    if (!_isOurServer(url)) {
      debugPrint('[WearRelayHost] refused ${url.origin}: not our server');
      return WearRelayResponse.unreachable(request.id);
    }
    try {
      final response = await _dispatch(request, url).timeout(_budget);
      return WearRelayResponse(
        id: request.id,
        status: response.statusCode,
        headers: response.headers,
        body: WearRelayResponse.encodeBody(response.bodyBytes),
      );
    } catch (e) {
      debugPrint('[WearRelayHost] ${request.method} ${url.host} failed: $e');
      return WearRelayResponse.unreachable(request.id);
    }
  }

  /// Same scheme, host and port as the session's server. Compared by origin
  /// rather than by whole URL, because Nextcloud serves the API under the
  /// instance's path and an image from another path on the same instance.
  bool _isOurServer(Uri url) {
    final server = AuthService.instance.credentials?.serverUrl;
    final ours = server == null ? null : Uri.tryParse(server);
    if (ours == null || ours.host.isEmpty) return false;
    return url.scheme == ours.scheme &&
        url.host == ours.host &&
        url.port == ours.port;
  }

  Future<http.Response> _dispatch(WearRelayRequest request, Uri url) {
    final body = request.bodyBytes;
    return switch (request.method) {
      'GET' => http.get(url, headers: request.headers),
      'POST' => http.post(url, headers: request.headers, body: body),
      'PUT' => http.put(url, headers: request.headers, body: body),
      'PATCH' => http.patch(url, headers: request.headers, body: body),
      'DELETE' => http.delete(url, headers: request.headers, body: body),
      _ => throw ArgumentError('Unsupported method ${request.method}'),
    };
  }
}
