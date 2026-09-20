import 'dart:convert';

/// The relay's wire contract, held in core because both halves speak it: the
/// watch asks, the phone performs the request and answers.
///
/// Paths are stable across releases — a phone and a watch update on their own
/// schedules, and an older peer that does not know these paths simply never
/// answers, which the asking side already has to survive.
class WearRelay {
  WearRelay._();

  /// Watch → phone, carrying a [WearRelayRequest]. Rides a message: it is small
  /// and it is only worth anything while the phone is awake to hear it, which
  /// is exactly what a message tests.
  static const requestPath = '/relay/request';

  /// Phone → watch, carrying a [WearRelayResponse]. Rides a channel, because a
  /// response carries whatever the server said — a photo among it — and a
  /// channel is ordered, unbounded and fails whole rather than arriving
  /// truncated.
  static const responsePath = '/relay/response';

  /// How long the watch waits for the phone before giving up on it.
  ///
  /// Generous next to a link round trip and mean next to the request's own
  /// budget: the phone has to receive, wake, perform a LAN request and stream
  /// an answer back, while the wearer is holding a wrist up in a doorway. What
  /// happens at the deadline is what would have happened with no relay at all,
  /// so erring short costs a fallback rather than a failure.
  static const timeout = Duration(seconds: 20);
}

/// One request a watch could not route, described well enough for another
/// device to make it.
///
/// The credential travels in [headers], where the direct request already put
/// it. That is the same secret the pairing grant handed over, on the same
/// carrier — the phone is being asked to talk to a server it is already signed
/// in to, as the account it already holds.
class WearRelayRequest {
  /// What the answer is addressed to. A watch may have several in flight —
  /// a poll and a queue drain overlap constantly — and a channel carries no
  /// reply-to of its own.
  final String id;

  final String method;
  final String url;
  final Map<String, String> headers;

  /// Base64, because the payload crosses the link as JSON and a body is bytes:
  /// a multipart upload is not text, and a JSON body that went through a string
  /// on the way would be re-encoded by whatever charset the far side assumed.
  final String? body;

  const WearRelayRequest({
    required this.id,
    required this.method,
    required this.url,
    required this.headers,
    this.body,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'method': method,
    'url': url,
    'headers': headers,
    'body': ?body,
  };

  /// Null for a payload this build cannot read, which is what an older peer's
  /// idea of the contract looks like. A relay that cannot be understood is one
  /// that does not answer, and the asking side falls back to its own failure.
  static WearRelayRequest? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final method = json['method'];
    final url = json['url'];
    if (id is! String || method is! String || url is! String) return null;
    if (id.isEmpty || method.isEmpty || url.isEmpty) return null;
    final rawHeaders = json['headers'];
    final body = json['body'];
    if (body != null && body is! String) return null;
    return WearRelayRequest(
      id: id,
      method: method.toUpperCase(),
      url: url,
      headers: rawHeaders is Map
          ? {
              for (final entry in rawHeaders.entries)
                if (entry.value is String)
                  '${entry.key}': entry.value as String,
            }
          : const {},
      body: body as String?,
    );
  }

  List<int>? get bodyBytes => body == null ? null : base64Decode(body!);

  static String? encodeBody(List<int>? bytes) =>
      bytes == null ? null : base64Encode(bytes);
}

/// What the other device got back, or why it got nothing.
///
/// A [status] of zero is the second case, and it is deliberately not an error
/// payload: the asking device already knows how to be told that a request never
/// arrived, and giving that condition one spelling means the relay adds no new
/// failure state to anything upstream.
class WearRelayResponse {
  final String id;

  /// The server's status code, or 0 when the phone could not reach it either.
  final int status;
  final Map<String, String> headers;

  /// Base64 of the response body, for the reason the request's is.
  final String? body;

  const WearRelayResponse({
    required this.id,
    required this.status,
    this.headers = const {},
    this.body,
  });

  /// The phone saying it is no better off than the watch.
  factory WearRelayResponse.unreachable(String id) =>
      WearRelayResponse(id: id, status: 0);

  bool get reached => status > 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'headers': headers,
    'body': ?body,
  };

  static WearRelayResponse? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final status = json['status'];
    if (id is! String || id.isEmpty || status is! int) return null;
    final rawHeaders = json['headers'];
    final body = json['body'];
    if (body != null && body is! String) return null;
    return WearRelayResponse(
      id: id,
      status: status,
      headers: rawHeaders is Map
          ? {
              for (final entry in rawHeaders.entries)
                if (entry.value is String)
                  '${entry.key}': entry.value as String,
            }
          : const {},
      body: body as String?,
    );
  }

  List<int> get bodyBytes => body == null ? const [] : base64Decode(body!);

  static String? encodeBody(List<int>? bytes) =>
      bytes == null || bytes.isEmpty ? null : base64Encode(bytes);
}
