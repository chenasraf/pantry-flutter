import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/wear_link_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel('dev.casraf.pantry/data_layer');
  const events = EventChannel('dev.casraf.pantry/data_layer/events');

  final link = WearLinkService.instance;
  final calls = <MethodCall>[];
  var available = true;

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methods, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'isAvailable':
              return available;
            case 'nodes':
              return [
                {'id': 'node-1', 'name': 'Pixel', 'nearby': true},
              ];
            case 'send':
            case 'publish':
            case 'clear':
              return true;
          }
          return null;
        });
  }

  setUp(() {
    calls.clear();
    available = true;
    link.debugReset();
    WearLinkService.debugHostSupported = true;
    install();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(methods, null)
      ..setMockStreamHandler(events, null);
    WearLinkService.debugHostSupported = null;
    link.debugReset();
  });

  test('reports availability from the channel and caches it', () async {
    expect(await link.isAvailable(), isTrue);
    expect(await link.isAvailable(), isTrue);
    expect(calls.where((c) => c.method == 'isAvailable'), hasLength(1));
  });

  test('every call no-ops off Android without touching the channel', () async {
    link.debugReset();
    WearLinkService.debugHostSupported = false;

    expect(await link.isAvailable(), isFalse);
    expect(await link.send('/p', const {}), isFalse);
    expect(await link.publish('/p', const {}), isFalse);
    expect(await link.clear('/p'), isFalse);
    expect(await link.nodes(), isEmpty);
    expect(calls, isEmpty);
  });

  test('an unavailable link answers false rather than throwing', () async {
    available = false;

    expect(await link.send('/p', const {'a': 1}), isFalse);
    expect(await link.nodes(), isEmpty);
    expect(calls.map((c) => c.method), everyElement('isAvailable'));
  });

  test('send encodes the payload as JSON and targets one node', () async {
    expect(await link.send('/creds', const {'user': 'me'}, nodeId: 'n1'), true);

    final call = calls.firstWhere((c) => c.method == 'send');
    expect(call.arguments['path'], '/creds');
    expect(jsonDecode(call.arguments['payload'] as String), {'user': 'me'});
    expect(call.arguments['nodeId'], 'n1');
  });

  test('send without a node id leaves the target to the platform', () async {
    await link.send('/creds', const {});

    final call = calls.firstWhere((c) => c.method == 'send');
    expect(call.arguments.containsKey('nodeId'), isFalse);
  });

  test('publish and clear reach their own methods', () async {
    expect(await link.publish('/session', const {'id': 7}), isTrue);
    expect(await link.clear('/session'), isTrue);

    expect(calls.map((c) => c.method), containsAll(['publish', 'clear']));
    expect(
      jsonDecode(
        calls.firstWhere((c) => c.method == 'publish').arguments['payload']
            as String,
      ),
      {'id': 7},
    );
  });

  test('a platform failure degrades to false', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methods, (call) async {
          if (call.method == 'isAvailable') return true;
          throw PlatformException(code: 'API_UNAVAILABLE');
        });

    expect(await link.send('/p', const {}), isFalse);
    expect(await link.nodes(), isEmpty);
  });

  test('nodes maps the platform list', () async {
    final nodes = await link.nodes();

    expect(nodes, hasLength(1));
    expect(nodes.single.id, 'node-1');
    expect(nodes.single.name, 'Pixel');
    expect(nodes.single.nearby, isTrue);
  });

  test('incoming payloads decode into messages by delivery', () async {
    final handler = _StreamHandler();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(events, handler);

    final received = <WearLinkMessage>[];
    final sub = link.messages.listen(received.add);
    await pumpEventQueue();

    handler.emit({
      'delivery': 'message',
      'path': '/creds',
      'payload': jsonEncode({'token': 'abc'}),
      'nodeId': 'node-1',
    });
    handler.emit({
      'delivery': 'dataItem',
      'path': '/session',
      'payload': jsonEncode({'id': 7}),
      'nodeId': null,
    });
    // Malformed payloads are dropped rather than killing the stream.
    handler.emit({'delivery': 'message', 'path': '/x', 'payload': 42});
    await pumpEventQueue();

    expect(received, hasLength(2));
    expect(received.first.delivery, WearLinkDelivery.message);
    expect(received.first.path, '/creds');
    expect(received.first.data, {'token': 'abc'});
    expect(received.first.nodeId, 'node-1');
    expect(received.last.delivery, WearLinkDelivery.dataItem);
    expect(received.last.data, {'id': 7});

    await sub.cancel();
  });

  test('two features can watch the link at once', () async {
    final handler = _StreamHandler();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(events, handler);

    final credentials = <String>[];
    final sessions = <String>[];
    final a = link.messages.listen((m) => credentials.add(m.path));
    final b = link.messages.listen((m) => sessions.add(m.path));
    await pumpEventQueue();

    handler.emit({
      'delivery': 'message',
      'path': '/creds',
      'payload': jsonEncode(const {}),
    });
    await pumpEventQueue();

    expect(credentials, ['/creds']);
    expect(sessions, ['/creds']);

    await a.cancel();
    await b.cancel();
  });

  test('the message stream is empty off Android', () async {
    link.debugReset();
    WearLinkService.debugHostSupported = false;

    expect(await link.messages.isEmpty, isTrue);
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
