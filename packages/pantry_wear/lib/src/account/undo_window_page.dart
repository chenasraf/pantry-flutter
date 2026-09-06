import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/prefs_service.dart';

import '../widgets/wear_choice_page.dart';

/// How an undo window is said, wherever it is said.
///
/// The same set `PrefsService` validates against — a value outside it is
/// silently refused, so the picker and the pref cannot drift apart.
String undoWindowLabel(int seconds) =>
    seconds == 0 ? m.wear.undoOff : m.wear.undoSeconds(seconds);

/// How long a tap stays reversible before it is written.
///
/// It is one answer for the whole watch rather than one per surface: a check,
/// an uncheck and a note's task line are the same gesture with different
/// nouns, and a watch that held one of them for two seconds and another for
/// five would be a watch with two rules.
///
/// *Off* is a real answer rather than a disabled state. It is how the watch
/// behaved before the window existed, and a wearer trading mis-tap protection
/// for a tap that lands immediately is choosing, not breaking anything.
class UndoWindowPage extends StatelessWidget {
  const UndoWindowPage({super.key});

  @override
  Widget build(BuildContext context) => WearChoicePage<int>(
    selected: PrefsService.instance.wearUndoSeconds,
    empty: '',
    onSelected: PrefsService.instance.setWearUndoSeconds,
    choices: [
      for (final seconds in PrefsService.validUndoSeconds)
        WearChoice(value: seconds, label: undoWindowLabel(seconds)),
    ],
  );
}
