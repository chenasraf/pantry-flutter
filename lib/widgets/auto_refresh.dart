import 'dart:async';

import 'package:flutter/widgets.dart';

/// Wraps [child] and calls [onRefresh] every [interval] while the app is in the
/// foreground, so a view stays current without the user pulling to refresh.
///
/// A null or non-positive [interval] disables the timer entirely (manual
/// refresh only). The timer is paused while the app is backgrounded, and — when
/// [refreshOnResume] is true — [onRefresh] fires once immediately on return to
/// the foreground. Changing [interval] restarts the timer with the new value,
/// so it can be driven straight from a pref the parent watches.
class AutoRefresh extends StatefulWidget {
  final Duration? interval;
  final Future<void> Function() onRefresh;
  final bool refreshOnResume;
  final Widget child;

  const AutoRefresh({
    super.key,
    required this.interval,
    required this.onRefresh,
    required this.child,
    this.refreshOnResume = true,
  });

  /// Convenience for turning a stored interval in seconds into the [interval]
  /// this widget expects: a non-positive value means "off" (no timer).
  static Duration? durationFromSeconds(int seconds) =>
      seconds <= 0 ? null : Duration(seconds: seconds);

  @override
  State<AutoRefresh> createState() => _AutoRefreshState();
}

class _AutoRefreshState extends State<AutoRefresh> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void didUpdateWidget(AutoRefresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interval != widget.interval) _start();
  }

  @override
  void dispose() {
    _stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _enabled {
    final interval = widget.interval;
    return interval != null && interval > Duration.zero;
  }

  void _start() {
    _stop();
    if (!_enabled) return;
    _timer = Timer.periodic(widget.interval!, (_) => widget.onRefresh());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Skip the resume refresh when auto-refresh is off — "off" means no
        // automatic server calls, only manual pull-to-refresh.
        if (widget.refreshOnResume && _enabled) widget.onRefresh();
        _start();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _stop();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
