import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/wear_relay.dart';

/// The relay's wire contract.
///
/// A phone and a watch update on their own schedules, so each end has to
/// survive the other's idea of this payload. The rule both halves follow is
/// that an unreadable payload is answered with silence — the asking side has a
/// timeout and a direct failure to fall back on, where a half-read request
/// would be a write performed from guesses.
void main() {
  test('a request survives the crossing whole', () {
    const request = WearRelayRequest(
      id: 'req-1',
      method: 'POST',
      url: 'https://pantry.local/api/items/42/toggle',
      headers: {'Authorization': 'Basic abc', 'Accept': 'application/json'},
      body: 'eyJkb25lIjp0cnVlfQ==',
    );

    final back = WearRelayRequest.fromJson(
      jsonDecode(jsonEncode(request.toJson())) as Map<String, dynamic>,
    );

    expect(back?.id, 'req-1');
    expect(back?.method, 'POST');
    expect(back?.url, request.url);
    expect(back?.headers, request.headers);
    expect(utf8.decode(back!.bodyBytes!), '{"done":true}');
  });

  test('a body is bytes at both ends, whatever it holds', () {
    // A multipart upload is not text and a JSON body is bytes of UTF-8. One
    // shape crosses, so nothing re-encodes a photo on the way.
    final bytes = List<int>.generate(512, (i) => i % 256);

    final back = WearRelayRequest.fromJson({
      'id': 'req-1',
      'method': 'POST',
      'url': 'https://pantry.local/api/photos',
      'headers': const <String, String>{},
      'body': WearRelayRequest.encodeBody(bytes),
    });

    expect(back?.bodyBytes, bytes);
  });

  test('a request carrying no body says so rather than saying empty', () {
    const request = WearRelayRequest(
      id: 'req-1',
      method: 'GET',
      url: 'https://pantry.local/api/houses',
      headers: {},
    );

    expect(request.toJson().containsKey('body'), isFalse);
    expect(WearRelayRequest.encodeBody(null), isNull);
  });

  test('a method is read case-insensitively and answered upper-case', () {
    final back = WearRelayRequest.fromJson({
      'id': 'req-1',
      'method': 'get',
      'url': 'https://pantry.local/api/houses',
    });

    expect(back?.method, 'GET');
  });

  group('a payload this build cannot read is refused outright', () {
    test('missing the fields a request is made of', () {
      expect(WearRelayRequest.fromJson(const {}), isNull);
      expect(
        WearRelayRequest.fromJson(const {'id': 'req-1', 'method': 'GET'}),
        isNull,
      );
      expect(
        WearRelayRequest.fromJson(const {
          'id': '',
          'method': 'GET',
          'url': 'https://pantry.local',
        }),
        isNull,
      );
    });

    test('a body that is not what a body is', () {
      expect(
        WearRelayRequest.fromJson(const {
          'id': 'req-1',
          'method': 'GET',
          'url': 'https://pantry.local',
          'body': 42,
        }),
        isNull,
      );
    });

    test('but headers it cannot use are simply dropped', () {
      // Headers are additive and a strange one is not worth refusing a
      // wearer's write over.
      final back = WearRelayRequest.fromJson(const {
        'id': 'req-1',
        'method': 'GET',
        'url': 'https://pantry.local',
        'headers': {'Accept': 'application/json', 'X-Weird': 7},
      });

      expect(back?.headers, const {'Accept': 'application/json'});
    });
  });

  group('the response', () {
    test('survives the crossing whole', () {
      final response = WearRelayResponse(
        id: 'req-1',
        status: 200,
        headers: const {'etag': 'W/"abc"'},
        body: WearRelayResponse.encodeBody(utf8.encode('{"houses":[]}')),
      );

      final back = WearRelayResponse.fromJson(
        jsonDecode(jsonEncode(response.toJson())) as Map<String, dynamic>,
      );

      expect(back?.status, 200);
      expect(back?.headers['etag'], 'W/"abc"');
      expect(utf8.decode(back!.bodyBytes), '{"houses":[]}');
      expect(back.reached, isTrue);
    });

    test('says unreachable in one way, not many', () {
      final answer = WearRelayResponse.unreachable('req-1');

      // The asking device already knows how to be told a request never
      // arrived; a second spelling would be a third outcome for every caller
      // upstream to learn.
      expect(answer.status, 0);
      expect(answer.reached, isFalse);
      expect(answer.bodyBytes, isEmpty);
    });

    test('carries an error status as an answer', () {
      // The server was reached and said no. The queue needs a 404 in order to
      // drop a row that is gone, and a 401 to hold rather than drop.
      expect(
        WearRelayResponse.fromJson(const {
          'id': 'req-1',
          'status': 404,
        })?.reached,
        isTrue,
      );
    });

    test('is refused when it is not one', () {
      expect(WearRelayResponse.fromJson(const {}), isNull);
      expect(WearRelayResponse.fromJson(const {'id': 'req-1'}), isNull);
      expect(
        WearRelayResponse.fromJson(const {'id': 'req-1', 'status': '200'}),
        isNull,
      );
    });
  });
}
