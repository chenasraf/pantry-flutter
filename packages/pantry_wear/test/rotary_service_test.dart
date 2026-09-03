import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_wear/pantry_wear.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = EventChannel('dev.casraf.pantry/rotary');
  final handler = _StreamHandler();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(channel, handler);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(channel, null);
  });

  test('carries one signed detent per event', () async {
    final detents = <double>[];
    final sub = RotaryService.instance.detents.listen(detents.add);
    await pumpEventQueue();

    handler.emit(1.0);
    handler.emit(-1.0);
    handler.emit(1);
    await pumpEventQueue();

    expect(detents, [1.0, -1.0, 1.0]);

    await sub.cancel();
  });

  test('the bezel still arrives after every listener has gone', () async {
    final first = <double>[];
    final firstSub = RotaryService.instance.detents.listen(first.add);
    await pumpEventQueue();
    handler.emit(1.0);
    await pumpEventQueue();
    await firstSub.cancel();

    final second = <double>[];
    final secondSub = RotaryService.instance.detents.listen(second.add);
    await pumpEventQueue();
    handler.emit(-1.0);
    await pumpEventQueue();

    expect(first, [1.0]);
    expect(second, [-1.0]);

    await secondSub.cancel();
  });

  test('two listeners both see the bezel', () async {
    final page = <double>[];
    final list = <double>[];
    final a = RotaryService.instance.detents.listen(page.add);
    final b = RotaryService.instance.detents.listen(list.add);
    await pumpEventQueue();

    handler.emit(1.0);
    await pumpEventQueue();

    expect(page, [1.0]);
    expect(list, [1.0]);

    await a.cancel();
    await b.cancel();
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
