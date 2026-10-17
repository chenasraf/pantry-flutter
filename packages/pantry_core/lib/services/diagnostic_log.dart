import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/utils/log_masker.dart';

enum LogLevel {
  info('I'),
  warning('W'),
  error('E');

  final String code;
  const LogLevel(this.code);

  static LogLevel? fromCode(String code) {
    for (final level in values) {
      if (level.code == code) return level;
    }
    return null;
  }
}

class LogEntry {
  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;

  const LogEntry(this.time, this.level, this.tag, this.message);

  /// One entry per line; a multi-line message continues on indented lines so
  /// the file stays readable as plain text.
  String toLine() =>
      '${time.toUtc().toIso8601String()} ${level.code} $tag '
      '${message.replaceAll('\n', '\n  ')}';

  static final _head = RegExp(r'^(\d{4}-\d\d-\d\dT\S+) ([IWE]) (\S+) ?(.*)$');

  static List<LogEntry> parse(String text) {
    final entries = <LogEntry>[];
    for (final line in text.split('\n')) {
      final m = _head.firstMatch(line);
      final time = m == null ? null : DateTime.tryParse(m[1]!);
      final level = m == null ? null : LogLevel.fromCode(m[2]!);
      if (time != null && level != null) {
        entries.add(LogEntry(time, level, m![3]!, m[4]!));
      } else if (entries.isNotEmpty && line.startsWith('  ')) {
        final last = entries.removeLast();
        entries.add(
          LogEntry(
            last.time,
            last.level,
            last.tag,
            '${last.message}\n${line.substring(2)}',
          ),
        );
      }
    }
    return entries;
  }
}

/// A size-capped log of requests, sync activity and errors, kept on the device
/// so a user can hand it over when something goes wrong.
///
/// Writing never blocks and never throws into the caller: a line is masked,
/// queued and appended on the next turn of the event loop. Lines logged before
/// [init] — or on a platform with no file system — are held in memory.
class DiagnosticLog {
  DiagnosticLog._();

  static final DiagnosticLog instance = DiagnosticLog._();

  static const _fileName = 'diagnostics.log';
  static const _previousName = 'diagnostics.1.log';

  /// Lines held while there is nowhere to write them.
  static const _memoryCap = 1000;

  Directory? _dir;
  int _maxBytes = 1024 * 1024;
  final _pending = <String>[];
  Future<void>? _draining;

  File? get _current => _dir == null ? null : File('${_dir!.path}/$_fileName');
  File? get _previous =>
      _dir == null ? null : File('${_dir!.path}/$_previousName');

  /// Start writing to disk. [maxBytes] caps both files together: the log
  /// rotates when the current file reaches half of it.
  Future<void> init({int maxBytes = 1024 * 1024, Directory? directory}) async {
    _maxBytes = maxBytes;
    if (kIsWeb) return;
    try {
      final base = directory ?? await getApplicationSupportDirectory();
      final dir = Directory('${base.path}/logs');
      await dir.create(recursive: true);
      _dir = dir;
      _kick();
    } catch (e) {
      debugPrint('[DiagnosticLog] unavailable: $e');
    }
  }

  void info(String tag, String message) => _add(LogLevel.info, tag, message);

  void warning(String tag, String message) =>
      _add(LogLevel.warning, tag, message);

  void error(String tag, String message, [Object? error, StackTrace? stack]) {
    final buffer = StringBuffer(message);
    if (error != null) buffer.write(': $error');
    if (stack != null) {
      // The top of a trace says where; the rest is framework plumbing that
      // would push everything else out of the log.
      final frames = stack.toString().trimRight().split('\n').take(12);
      buffer.write('\n${frames.join('\n')}');
    }
    _add(LogLevel.error, tag, buffer.toString());
  }

  /// Log uncaught framework and platform errors, then hand them on to
  /// whatever was handling them before.
  void installErrorHandlers() {
    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      error('flutter', details.exceptionAsString(), null, details.stack);
      if (previousFlutter != null) {
        previousFlutter(details);
      } else {
        FlutterError.presentError(details);
      }
    };
    final dispatcher = PlatformDispatcher.instance;
    final previousPlatform = dispatcher.onError;
    dispatcher.onError = (e, stack) {
      error('uncaught', 'Unhandled error', e, stack);
      return previousPlatform?.call(e, stack) ?? false;
    };
  }

  LogMasker get _masker {
    final creds = AuthService.instance.credentials;
    return LogMasker(
      serverHost: creds == null ? null : Uri.tryParse(creds.serverUrl)?.host,
      loginName: creds?.loginName,
    );
  }

  void _add(LogLevel level, String tag, String message) {
    try {
      final entry = LogEntry(DateTime.now(), level, tag, message);
      final line = _masker.mask(entry.toLine());
      // Every request is an info line; the console only wants trouble.
      if (level != LogLevel.info) debugPrint(line);
      _pending.add(line);
      if (_dir == null && _pending.length > _memoryCap) {
        _pending.removeRange(0, _pending.length - _memoryCap);
      }
      _kick();
    } catch (_) {}
  }

  void _kick() {
    if (_dir == null || _draining != null) return;
    _draining = _drain().whenComplete(() => _draining = null);
  }

  Future<void> _drain() async {
    try {
      final file = _current!;
      final limit = _maxBytes ~/ 2;
      var size = await file.exists() ? await file.length() : 0;
      while (_pending.isNotEmpty) {
        // Fill the current file up to its half of the cap and no further, so
        // a burst logged in one go still rotates on time.
        final chunk = StringBuffer();
        var bytes = 0;
        while (_pending.isNotEmpty && size + bytes < limit) {
          final line = '${_pending.removeAt(0)}\n';
          chunk.write(line);
          bytes += line.length;
        }
        if (bytes > 0) {
          await file.writeAsString(
            chunk.toString(),
            mode: FileMode.append,
            flush: true,
          );
          size += bytes;
        }
        if (size >= limit) {
          // Windows refuses to rename onto a file that exists.
          final previous = _previous!;
          if (await previous.exists()) await previous.delete();
          await file.rename(previous.path);
          size = 0;
        }
      }
    } catch (e) {
      debugPrint('[DiagnosticLog] write failed: $e');
    }
  }

  /// Everything logged, oldest first, masked again with the credential known
  /// now — a line written before sign-in could not name the server yet.
  Future<String> read() async {
    final parts = <String>[];
    final dir = _dir;
    if (dir != null) {
      await _draining;
      for (final file in [_previous!, _current!]) {
        try {
          if (await file.exists()) parts.add(await file.readAsString());
        } catch (_) {}
      }
    }
    if (_pending.isNotEmpty) parts.add('${_pending.join('\n')}\n');
    return _masker.mask(parts.join());
  }

  Future<List<LogEntry>> entries() async => LogEntry.parse(await read());

  /// Mask [text] the way every logged line is, for text that travels with
  /// the log without being part of it.
  String mask(String text) => _masker.mask(text);

  Future<void> clear() async {
    _pending.clear();
    await _draining;
    for (final file in [_previous, _current]) {
      try {
        if (file != null && await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  @visibleForTesting
  Future<void> debugReset() async {
    await clear();
    _dir = null;
  }
}
