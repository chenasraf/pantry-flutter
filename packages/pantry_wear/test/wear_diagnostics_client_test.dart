import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/diagnostic_log.dart';
import 'package:pantry_core/services/wear_diagnostics.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry_wear/pantry_wear.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel('dev.casraf.pantry/data_layer');
  const events = EventChannel('dev.casraf.pantry/data_layer/events');

  final calls = <MethodCall>[];
  late _StreamHandler handler;

  setUp(() async {
    calls.clear();
    handler = _StreamHandler();
    WearLinkService.instance.debugReset();
    WearLinkService.debugHostSupported = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(methods, (call) async {
        calls.add(call);
        return true;
      })
      ..setMockStreamHandler(events, handler);
    await DiagnosticLog.instance.debugReset();
    await WearDiagnosticsClient.instance.start();
  });

  tearDown(() async {
    await WearDiagnosticsClient.instance.debugReset();
    await DiagnosticLog.instance.debugReset();
    WearLinkService.debugHostSupported = null;
    WearLinkService.instance.debugReset();
  });

  test('the watch answers the phone that asked with its log', () async {
    DiagnosticLog.instance.warning('sync', 'Holding checklistItem.toggle');

    handler.emit({
      'delivery': 'message',
      'path': WearDiagnostics.requestPath,
      'payload': jsonEncode({'id': 'req-1'}),
      'nodeId': 'phone-1',
    });
    await pumpEventQueue();

    final call = calls.singleWhere((c) => c.method == 'stream');
    expect(call.arguments['path'], WearDiagnostics.responsePath);
    expect(call.arguments['nodeId'], 'phone-1');
    final payload = jsonDecode(call.arguments['payload'] as String) as Map;
    expect(payload['id'], 'req-1');
    expect(payload['log'], contains('Holding checklistItem.toggle'));
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
