import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/services/house_service.dart';

import '../scope/wear_scope.dart';
import '../widgets/wear_choice_page.dart';

/// Which household the watch is showing.
///
/// The one control that changes it, and it lives here rather than on the
/// checklists page: switching household is rare enough that it earns no chrome
/// in the primary view, where the rail's two-step switcher already spends what
/// there is on the list.
///
/// A single-household wearer still gets the row and still gets this page. The
/// control being sometimes absent is worse than it being sometimes short:
/// somebody who joins a second household later has nowhere to learn where the
/// switch lives.
class HouseSwitcherPage extends StatefulWidget {
  const HouseSwitcherPage({super.key});

  @override
  State<HouseSwitcherPage> createState() => _HouseSwitcherPageState();
}

class _HouseSwitcherPageState extends State<HouseSwitcherPage> {
  late List<House> _houses = HouseService.instance.getCached() ?? const [];

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  /// The cache draws the page and the network only ever adds to it: a watch
  /// that cannot reach the server still switches between the households it
  /// already knows about.
  Future<void> _refresh() async {
    try {
      final houses = await HouseService.instance.getHouses();
      if (mounted) setState(() => _houses = houses);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WearChoicePage<int>(
      selected: WearScope.instance.houseId,
      empty: m.wear.noHouses,
      onSelected: WearScope.instance.selectHouse,
      choices: [
        for (final house in _houses)
          WearChoice(
            value: house.id,
            label: house.name,
            icon: Icons.home_outlined,
            tint: scheme.primary,
          ),
      ],
    );
  }
}
