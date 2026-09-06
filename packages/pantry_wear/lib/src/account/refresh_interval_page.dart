import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/prefs_service.dart';

import '../widgets/wear_choice_page.dart';

/// How a refresh interval is said, wherever it is said.
///
/// The same set `PrefsService` validates against — a value outside it is
/// silently refused, so the picker and the pref cannot drift apart.
String refreshIntervalLabel(int seconds) => switch (seconds) {
  0 => m.wear.refreshOff,
  < 60 => m.wear.refreshSeconds(seconds),
  _ => m.wear.refreshMinutes(seconds ~/ 60),
};

/// How often the watch re-reads what it is showing.
///
/// It does not inherit the phone's refresh interval: that one was chosen for a
/// screen on mains power, and following it would put the watch's endurance in
/// a pref set on a device that has none of its constraints.
///
/// *Off* is a real answer rather than a disabled state — the watch still reads
/// on every arrival and every resume, and a wearer who wants nothing else is
/// choosing a battery, not breaking the app.
class RefreshIntervalPage extends StatelessWidget {
  const RefreshIntervalPage({super.key});

  /// The set `PrefsService` validates against; a value outside it is refused.
  static const _seconds = [0, 15, 30, 60, 120, 300];

  @override
  Widget build(BuildContext context) => WearChoicePage<int>(
    selected: PrefsService.instance.wearPollSeconds,
    empty: '',
    onSelected: PrefsService.instance.setWearPollSeconds,
    choices: [
      for (final seconds in _seconds)
        WearChoice(value: seconds, label: refreshIntervalLabel(seconds)),
    ],
  );
}
