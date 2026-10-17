import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry/services/wear_diagnostics_host.dart';
import 'package:pantry_core/services/wear_diagnostics.dart';
import 'package:pantry_core/services/wear_link_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel('dev.casraf.pantry/data_layer');
  const events = EventChannel('dev.casraf.pantry/data_layer/events');

  late _StreamHandler handler;
  var delivered = true;

  tearDown(() {
    WearLinkService.debugHostSupported = null;
    WearLinkService.instance.debugReset();
  });

  setUp(() {
    WearLinkService.instance.debugReset();
    WearLinkService.debugHostSupported = true;
    delivered = true;
    handler = _StreamHandler();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(methods, (call) async {
        if (call.method == 'isAvailable') return true;
        if (call.method == 'send' &&
            call.arguments['path'] == WearDiagnostics.requestPath) {
          final id =
              (jsonDecode(call.arguments['payload'] as String) as Map)['id'];
          // Another request's answer first: only this one's may be taken.
          scheduleMicrotask(() {
            handler.emit(_answer('someone-else', 'wrong log'));
            handler.emit(_answer(id as String, 'watch log'));
          });
          return delivered;
        }
        return true;
      })
      ..setMockStreamHandler(events, handler);
  });

  test("the phone reads back the watch's answer to its own request", () async {
    expect(await WearDiagnosticsHost.instance.fetch(), 'watch log');
  });

  test('no watch to deliver to reads as none', () async {
    delivered = false;
    expect(await WearDiagnosticsHost.instance.fetch(), isNull);
  });
}

Map<String, Object?> _answer(String id, String log) => {
  'delivery': 'channel',
  'path': WearDiagnostics.responsePath,
  'payload': jsonEncode({'id': id, 'log': log}),
  'nodeId': 'watch-1',
};

class _StreamHandler extends MockStreamHandler {
  MockStreamHandlerEventSink? _sink;

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) =>
      _sink = events;

  @override
  void onCancel(Object? arguments) => _sink = null;

  void emit(Object? event) => _sink?.success(event);
}
