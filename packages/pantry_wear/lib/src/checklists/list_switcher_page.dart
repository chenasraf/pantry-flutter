import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/color.dart';

import '../scope/wear_scope.dart';
import '../widgets/wear_choice_page.dart';

/// Every list in the current house, plus the all-lists entry — which is a
/// selectable list here, exactly as on the phone, rather than a mode.
///
/// Archived and trashed lists cannot appear: `getLists` returns active lists
/// only, and the watch never calls the other two endpoints.
class ListSwitcherPage extends StatelessWidget {
  final List<ChecklistList> lists;
  final int? selectedId;

  const ListSwitcherPage({
    super.key,
    required this.lists,
    required this.selectedId,
  });

  @override
  Widget build(BuildContext context) => WearChoicePage<int>(
    selected: selectedId,
    empty: m.wear.noLists,
    onSelected: WearScope.instance.selectList,
    choices: [
      WearChoice(
        value: kAllListsId,
        label: m.checklists.allLists,
        icon: allListsIcon,
      ),
      for (final list in lists)
        WearChoice(
          value: list.id,
          label: list.name,
          icon: checklistIcon(list.icon),
          tint: parseHexColor(list.color) ?? Colors.white70,
        ),
    ],
  );
}
