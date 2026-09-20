import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry_core/services/wear_relay.dart';
import 'package:pantry_core/sync/sync_ids.dart';

/// The watch's half of the relay: a request it could not get to the server,
/// handed to the phone beside it.
///
/// This exists for one situation, and it is not the one the link was built
/// around. A watch linked over Bluetooth is handed the phone's *internet*, not
/// the phone's *network*: the companion proxy routes as though the request came
/// from the open web, so a household server on the wearer's own LAN has no
/// route across a link that is working perfectly. Forcing the watch onto Wi-Fi
/// fixes it, which is the wearer doing by hand what this does for them.
///
/// **Only ever asked after the watch's own request failed.** The direct path
/// stays the baseline — `mirror.md`'s invariant, unchanged — so a standalone
/// watch, an LTE watch and a watch with no Data Layer at all need no case, and
/// nobody whose server answers meets this code at runtime.
class WearRelayClient {
  WearRelayClient._();

  static final WearRelayClient instance = WearRelayClient._();

  final _link = WearLinkService.instance;

  /// Answers waited on, by the id they will arrive under. A poll and a queue
  /// drain overlap constantly, so the id is what tells two answers apart —
  /// a channel carries no reply-to of its own.
  final _waiting = <String, Completer<WearRelayResponse>>{};

  StreamSubscription<WearLinkMessage>? _messages;
  var _installed = false;

  /// When the link last reported no phone, or null if the last answer was that
  /// there is one.
  DateTime? _absentSince;

  /// Long enough that one page's worth of failed reads asks once, short enough
  /// that a wearer who walks back to their phone is not left waiting on it.
  static const _absenceWindow = Duration(seconds: 10);

  /// Make this watch's failed requests reach for the phone.
  ///
  /// Called from the watch entrypoint. The link is not touched here: a watch
  /// asks about it on the first request it cannot make, which for almost every
  /// wearer is never, and a cold start has better uses for a channel round trip
  /// than a capability it will not need.
  void install() {
    if (_installed) return;
    _installed = true;
    ApiClient.relay = _ask;
  }

  @visibleForTesting
  void uninstall() {
    _installed = false;
    _absentSince = null;
    ApiClient.relay = null;
    unawaited(_messages?.cancel());
    _messages = null;
    for (final completer in _waiting.values) {
      if (!completer.isCompleted) {
        completer.complete(WearRelayResponse.unreachable(''));
      }
    }
    _waiting.clear();
  }

  /// Ask the phone to make [request], or answer null when it cannot be asked.
  ///
  /// Null and a refusal are deliberately the same answer to the caller: it
  /// already knows how to handle a request that never reached a server, and
  /// giving the relay its own failure mode would mean every call site upstream
  /// learning a third outcome.
  Future<http.Response?> _ask(ApiRequest request) async {
    if (!await _attach()) return null;
    // A phone that is not there cannot be waited on for twenty seconds.
    if (!await _phoneInRange()) return null;

    final id = SyncIds.newOpUuid();
    final completer = Completer<WearRelayResponse>();
    _waiting[id] = completer;
    try {
      final sent = await _link.send(
        WearRelay.requestPath,
        WearRelayRequest(
          id: id,
          method: request.method,
          url: request.uri.toString(),
          headers: request.headers,
          body: WearRelayRequest.encodeBody(request.body),
        ).toJson(),
      );
      if (!sent) return null;

      final answer = await completer.future.timeout(
        WearRelay.timeout,
        // A phone that never answers is a phone that could not help, which is
        // the same thing the direct failure already said.
        onTimeout: () => WearRelayResponse.unreachable(id),
      );
      if (!answer.reached) return null;
      return http.Response.bytes(
        answer.bodyBytes,
        answer.status,
        headers: answer.headers,
      );
    } finally {
      _waiting.remove(id);
    }
  }

  /// Whether there is a phone to ask, with a short memory of there not being.
  ///
  /// `nodes()` is a live channel call, and the failures that reach here do not
  /// arrive one at a time: a cache-first read opens a page by fetching lists,
  /// items, categories, labels, stores and fields, and offline every one of
  /// them fails. Paying a round trip per failure would put seconds in front of
  /// the cache fallback on a watch that is simply out of range — against a
  /// 671 ms cold start, and in service of a phone that was absent a moment ago.
  ///
  /// Only the *negative* is remembered, and only briefly. A watch that found a
  /// phone asks it again next time, so the answer that matters is never stale;
  /// what the window costs is noticing a phone that arrives mid-burst, one
  /// beat late.
  Future<bool> _phoneInRange() async {
    final since = _absentSince;
    if (since != null && DateTime.now().difference(since) < _absenceWindow) {
      return false;
    }
    final nodes = await _link.nodes();
    _absentSince = nodes.isEmpty ? DateTime.now() : null;
    return nodes.isNotEmpty;
  }

  Future<bool> _attach() async {
    if (_messages != null) return true;
    if (!await _link.isAvailable()) return false;
    _messages = _link.messages.listen(_onMessage);
    return true;
  }

  void _onMessage(WearLinkMessage message) {
    if (message.path != WearRelay.responsePath) return;
    final answer = WearRelayResponse.fromJson(message.data);
    // An answer to a request that already timed out, or one this build cannot
    // read, is dropped rather than guessed at: the caller has long since taken
    // the direct failure's path.
    if (answer == null) return;
    final completer = _waiting[answer.id];
    if (completer == null || completer.isCompleted) return;
    completer.complete(answer);
  }
}
