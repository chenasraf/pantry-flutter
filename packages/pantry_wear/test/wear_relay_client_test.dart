import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry_core/services/wear_relay.dart';
import 'package:pantry_wear/src/services/wear_relay_client.dart';

/// The watch's half of the relay: asking the phone for a request it had no
/// route for.
///
/// Answers arrive on a channel, which carries no reply-to of its own, and a
/// watch has several requests in flight constantly — a poll and a queue drain
/// overlap all day. So the id is the whole of what tells two answers apart, and
/// what happens to an answer nobody is waiting for.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel('dev.casraf.pantry/data_layer');
  const events = EventChannel('dev.casraf.pantry/data_layer/events');

  final link = WearLinkService.instance;
  final client = WearRelayClient.instance;

  final sent = <MethodCall>[];
  late _StreamHandler handler;
  var nodes = <Map<String, Object>>[
    {'id': 'phone-1', 'name': 'Pixel', 'nearby': true},
  ];

  /// The request the watch put on the wire, or null if it sent none.
  WearRelayRequest? asked() {
    final call = sent.cast<MethodCall?>().lastWhere(
      (c) =>
          c!.method == 'send' && c.arguments['path'] == WearRelay.requestPath,
      orElse: () => null,
    );
    if (call == null) return null;
    return WearRelayRequest.fromJson(
      jsonDecode(call.arguments['payload'] as String) as Map<String, dynamic>,
    );
  }

  setUp(() {
    sent.clear();
    nodes = [
      {'id': 'phone-1', 'name': 'Pixel', 'nearby': true},
    ];
    handler = _StreamHandler();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(methods, (call) async {
        sent.add(call);
        if (call.method == 'isAvailable') return true;
        if (call.method == 'nodes') return nodes;
        return true;
      })
      ..setMockStreamHandler(events, handler);
    link.debugReset();
    WearLinkService.debugHostSupported = true;
    client.install();
  });

  tearDown(() {
    client.uninstall();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(methods, null)
      ..setMockStreamHandler(events, null);
    WearLinkService.debugHostSupported = null;
    link.debugReset();
  });

  ApiRequest houses() => ApiRequest(
    method: 'GET',
    uri: Uri.parse('https://pantry.local/api/houses'),
    headers: const {'Authorization': 'Basic abc'},
    timeout: const Duration(seconds: 15),
  );

  /// The phone answering whatever the watch last asked.
  Future<void> answer({
    int status = 200,
    String body = '{"houses":[]}',
    String? id,
  }) async {
    final requestId = id ?? asked()!.id;
    handler.emit({
      'delivery': 'channel',
      'path': WearRelay.responsePath,
      'payload': jsonEncode(
        WearRelayResponse(
          id: requestId,
          status: status,
          body: WearRelayResponse.encodeBody(utf8.encode(body)),
        ).toJson(),
      ),
      'nodeId': 'phone-1',
    });
    await Future<void>.delayed(Duration.zero);
  }

  test('it installs itself as the relay and describes the request', () async {
    expect(ApiClient.relay, isNotNull);

    final pending = ApiClient.relay!(houses());
    await Future<void>.delayed(Duration.zero);

    expect(asked()?.method, 'GET');
    expect(asked()?.url, 'https://pantry.local/api/houses');
    expect(asked()?.headers['Authorization'], 'Basic abc');

    await answer();
    final response = await pending;
    expect(response?.statusCode, 200);
    expect(response?.body, '{"houses":[]}');
  });

  test('an answer is matched to the request that is waiting for it', () async {
    final first = ApiClient.relay!(houses());
    await Future<void>.delayed(Duration.zero);
    final firstId = asked()!.id;

    final second = ApiClient.relay!(houses());
    await Future<void>.delayed(Duration.zero);
    final secondId = asked()!.id;
    expect(secondId, isNot(firstId));

    // Out of order, which a link gives no guarantee against.
    await answer(id: secondId, body: '{"second":true}');
    await answer(id: firstId, body: '{"first":true}');

    expect((await first)?.body, '{"first":true}');
    expect((await second)?.body, '{"second":true}');
  });

  test('an answer nobody is waiting for is dropped', () async {
    await answer(id: 'never-asked');

    // The caller took the direct failure's path long ago. Nothing to complete,
    // and nothing to throw about.
    expect(sent.map((c) => c.method), isNot(contains('stream')));
  });

  test('an error status is handed back, not swallowed', () async {
    final pending = ApiClient.relay!(houses());
    await Future<void>.delayed(Duration.zero);

    await answer(status: 404, body: 'gone');

    // The queue needs a 404 to drop a row that is gone, and a 401 to hold
    // rather than drop. Only "never arrived" is the relay's to report.
    expect((await pending)?.statusCode, 404);
  });

  test('a phone saying it could not help is no answer at all', () async {
    final pending = ApiClient.relay!(houses());
    await Future<void>.delayed(Duration.zero);

    handler.emit({
      'delivery': 'channel',
      'path': WearRelay.responsePath,
      'payload': jsonEncode(
        WearRelayResponse.unreachable(asked()!.id).toJson(),
      ),
      'nodeId': 'phone-1',
    });

    // Null, so the caller falls back to the failure it already had rather than
    // learning a new outcome.
    expect(await pending, isNull);
  });

  test('with no phone in range it does not wait', () async {
    nodes = [];

    // Twenty seconds of waiting for a phone that is demonstrably not there
    // would be twenty seconds the wearer stares at a spinner.
    expect(await ApiClient.relay!(houses()), isNull);
    expect(asked(), isNull);
  });

  test('uninstalling leaves no second path behind', () {
    client.uninstall();

    expect(ApiClient.relay, isNull);
  });
}

class _StreamHandler extends MockStreamHandler {
  MockStreamHandlerEventSink? _sink;

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) =>
      _sink = events;

  @override
  void onCancel(Object? arguments) => _sink = null;

  void emit(Object? event) => _sink?.success(event);
}
