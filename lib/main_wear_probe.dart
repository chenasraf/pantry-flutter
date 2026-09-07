import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Ambient probe. Answers two questions the shipping app cannot be asked:
/// whether ambient callbacks reach an app on this watch through the AndroidX
/// observer, and — only if they do — whether Flutter repaints once they have.
///
/// It depends on neither `pantry_core` nor `pantry_wear` on purpose. The tick
/// count is evidence about what the platform does to a Dart timer, so the only
/// timer in the process has to be this one.
///
/// Strings are hardcoded English rather than routed through `messages.i18n.yaml`:
/// a measurement rig has one reader, and translating it would put throwaway keys
/// in front of every translator.
const _channel = MethodChannel('dev.casraf.pantry/ambient_probe');
const _eventChannel = EventChannel('dev.casraf.pantry/ambient_probe_events');

void main() {
  runApp(const AmbientProbeApp());
}

class AmbientProbeApp extends StatelessWidget {
  const AmbientProbeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const AmbientProbePage(),
    );
  }
}

class AmbientProbePage extends StatefulWidget {
  const AmbientProbePage({super.key});

  @override
  State<AmbientProbePage> createState() => _AmbientProbePageState();
}

class _AmbientProbePageState extends State<AmbientProbePage>
    with WidgetsBindingObserver {
  Timer? _timer;
  StreamSubscription<dynamic>? _events;

  /// One per second while a Dart timer is being serviced. The whole point of
  /// the number is what it reads after the watch has been asleep.
  int _ticks = 0;

  /// Incremented in [build]. A frame that was not built cannot have been
  /// painted, so this is the ceiling on how often the screen can have changed.
  int _paints = 0;

  DateTime _startedAt = DateTime.now();
  Map<Object?, Object?> _snapshot = const {};

  /// When the app last lost the foreground, and the tick count at that moment.
  DateTime? _pausedAt;
  int _pausedTicks = 0;
  Duration? _lastSleep;
  int _ticksDuringSleep = 0;

  final List<String> _lifecycle = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _ticks++;
      unawaited(_read());
    });
    _events = _eventChannel.receiveBroadcastStream().listen((_) => _read());
    unawaited(_read());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_events?.cancel());
    super.dispose();
  }

  /// The measurement that decides whether a poll may be left unguarded: how many
  /// times a one-second timer fired while the screen was off, against how long
  /// it was off for.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final now = DateTime.now();
    if (state == AppLifecycleState.resumed) {
      final pausedAt = _pausedAt;
      if (pausedAt != null) {
        _lastSleep = now.difference(pausedAt);
        _ticksDuringSleep = _ticks - _pausedTicks;
        _pausedAt = null;
      }
      debugPrint('[AmbientProbe] $_summary');
    } else if (_pausedAt == null) {
      _pausedAt = now;
      _pausedTicks = _ticks;
    }
    setState(() {
      _lifecycle.insert(0, '${_clock(now)}  ${state.name}');
      if (_lifecycle.length > 12) _lifecycle.removeLast();
    });
  }

  Future<void> _read() async {
    final snapshot = await _channel.invokeMethod<Map<Object?, Object?>>(
      'snapshot',
    );
    if (!mounted || snapshot == null) return;
    setState(() => _snapshot = snapshot);
  }

  Future<void> _reset() async {
    final snapshot = await _channel.invokeMethod<Map<Object?, Object?>>(
      'reset',
    );
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot ?? const {};
      _ticks = 0;
      _paints = 0;
      _startedAt = DateTime.now();
      _lastSleep = null;
      _ticksDuringSleep = 0;
      _pausedAt = null;
      _lifecycle.clear();
    });
  }

  int get _enters => (_snapshot['enters'] as int?) ?? 0;
  int get _exits => (_snapshot['exits'] as int?) ?? 0;
  int get _updates => (_snapshot['updates'] as int?) ?? 0;
  bool get _isAmbient => (_snapshot['isAmbient'] as bool?) ?? false;

  /// `null` when the platform would not answer — which is not the same as off,
  /// and has to be read on the watch's own settings screen instead.
  int? get _aod => _snapshot['aodSetting'] as int?;

  String get _summary =>
      'enters: $_enters  exits: $_exits  updates: $_updates  ticks: $_ticks';

  static String _clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    _paints++;
    final now = DateTime.now();
    final elapsed = now.difference(_startedAt).inSeconds;
    final log = (_snapshot['log'] as List<Object?>? ?? const []).reversed
        .take(8)
        .cast<Map<Object?, Object?>>()
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          // Round glass, and the ambient guidance keeps content clear of the
          // edge — generous enough that nothing lands under the bezel on either
          // shape.
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 22,
            vertical: 12,
          ),
          child: ListView(
            children: [
              _AodBanner(aod: _aod),
              const SizedBox(height: 8),
              // The repaint canary. In ambient this is the thing to look at: if
              // the screen is ours and updating, the seconds move; if it is a
              // frozen screenshot, they do not.
              Center(
                child: Text(
                  _clock(now),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w300,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Center(
                child: Text(
                  _isAmbient ? 'AMBIENT' : 'interactive',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    color: _isAmbient ? Colors.amber : Colors.white38,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Row(label: 'enters', value: '$_enters'),
              _Row(label: 'exits', value: '$_exits'),
              _Row(label: 'updates', value: '$_updates'),
              const Divider(height: 16),
              _Row(label: 'ticks', value: '$_ticks'),
              _Row(label: 'elapsed', value: '${elapsed}s'),
              _Row(label: 'paints', value: '$_paints'),
              if (_lastSleep != null) ...[
                const Divider(height: 16),
                _Row(label: 'slept', value: '${_lastSleep!.inSeconds}s'),
                _Row(label: 'ticks then', value: '$_ticksDuringSleep'),
              ],
              const Divider(height: 16),
              _Row(
                label: 'burn-in',
                value: _flag(_snapshot['burnInProtectionRequired']),
              ),
              _Row(
                label: 'low-bit',
                value: _flag(_snapshot['deviceHasLowBitAmbient']),
              ),
              const SizedBox(height: 12),
              if (log.isNotEmpty) ...[
                const Text('events', style: TextStyle(color: Colors.white38)),
                for (final entry in log)
                  Text(
                    '${_clock(DateTime.fromMillisecondsSinceEpoch((entry['at'] as int?) ?? 0))}  ${entry['event']}',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                const SizedBox(height: 12),
              ],
              if (_lifecycle.isNotEmpty) ...[
                const Text(
                  'lifecycle',
                  style: TextStyle(color: Colors.white38),
                ),
                for (final line in _lifecycle)
                  Text(
                    line,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                const SizedBox(height: 12),
              ],
              Center(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  static String _flag(Object? value) => switch (value) {
    true => 'yes',
    false => 'no',
    _ => '—',
  };
}

/// The one reading that decides whether a run counts. A zero recorded with
/// always-on display switched off measures the setting, not the platform.
class _AodBanner extends StatelessWidget {
  const _AodBanner({required this.aod});

  final int? aod;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (aod) {
      1 => ('AOD ON', Colors.greenAccent),
      0 => ('AOD OFF — run is void', Colors.redAccent),
      _ => ('AOD UNKNOWN — check settings', Colors.amberAccent),
    };
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        // Outlined rather than filled: the ambient guidance is to keep the
        // screen overwhelmingly black, and this is the one element that would
        // otherwise be a solid block of colour.
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
