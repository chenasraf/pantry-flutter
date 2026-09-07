import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/prefs_service.dart';

import '../widgets/wear_choice_page.dart';

/// How a crown setting is said, wherever it is said.
String crownSteeringLabel(bool turnsPages) =>
    turnsPages ? m.wear.crownTurnsPages : m.wear.crownScrollsList;

/// What a turn of the bezel or crown steers: the page you are on, or which
/// page you are on.
///
/// A turn has exactly one meaning at a time. Handing the crown to the pager
/// takes it from the lists, which then scroll by touch alone — the alternative
/// is a handoff at the ends of a list, where the whole failure lands on a
/// boundary that is invisible off a wrist and pages while you are still
/// reading if it is even slightly wrong.
class CrownSteeringPage extends StatelessWidget {
  const CrownSteeringPage({super.key});

  @override
  Widget build(BuildContext context) => WearChoicePage<bool>(
    selected: PrefsService.instance.wearCrownTurnsPages,
    empty: '',
    onSelected: PrefsService.instance.setWearCrownTurnsPages,
    choices: [
      WearChoice(
        value: false,
        label: crownSteeringLabel(false),
        icon: Icons.swap_vert,
      ),
      WearChoice(
        value: true,
        label: crownSteeringLabel(true),
        icon: Icons.swap_horiz,
      ),
    ],
  );
}
