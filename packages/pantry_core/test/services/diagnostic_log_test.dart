import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_core/services/diagnostic_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final log = DiagnosticLog.instance;
  late Directory dir;

  setUp(() async {
    await log.debugReset();
    dir = await Directory.systemTemp.createTemp('diagnostic_log_test');
  });

  tearDown(() async {
    await log.debugReset();
    await dir.delete(recursive: true);
  });

  test('lines logged before init are kept and written once it runs', () async {
    log.info('app', 'early');
    await log.init(directory: dir);
    log.warning('sync', 'later');

    final entries = await log.entries();
    expect(entries.map((e) => (e.level, e.tag, e.message)), [
      (LogLevel.info, 'app', 'early'),
      (LogLevel.warning, 'sync', 'later'),
    ]);
    expect(
      await File('${dir.path}/logs/diagnostics.log').readAsString(),
      contains('later'),
    );
  });

  test('a multi-line error reads back as one entry', () async {
    await log.init(directory: dir);
    log.error('flutter', 'Boom', StateError('bad'), StackTrace.current);

    final entry = (await log.entries()).single;
    expect(entry.level, LogLevel.error);
    expect(entry.message, startsWith('Boom: Bad state: bad\n'));
  });

  test('the log stays under its cap and keeps the newest lines', () async {
    await log.init(maxBytes: 4096, directory: dir);
    for (var i = 0; i < 200; i++) {
      log.info('http', 'GET /houses/$i 200 (12 ms)');
    }
    final text = await log.read();

    var total = 0;
    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      total += f.lengthSync();
    }
    expect(total, lessThanOrEqualTo(4096 + 200));
    expect(text, contains('/houses/199 '));
    expect(text, isNot(contains('/houses/0 ')));
  });

  test('clear empties it', () async {
    await log.init(directory: dir);
    log.info('app', 'something');
    await log.clear();
    expect(await log.entries(), isEmpty);
  });
}
