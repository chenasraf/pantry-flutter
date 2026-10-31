import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/list_kind.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/list_kind_strings.dart';

import '../scope/wear_scope.dart';
import '../widgets/wear_choice_page.dart';

/// Every list in the current house, plus the all-lists entry — which is a
/// selectable list here, exactly as on the phone, rather than a mode.
/// Inventories follow the checklists under their own heading, each with its
/// needs-restock count and, from two on, headed by "All inventories";
/// templates are left to the phone.
///
/// The Inventories page opens it with [inventoriesOnly], picking into its own
/// scope.
///
/// Archived and trashed lists cannot appear: `getLists` returns active lists
/// only, and the watch never calls the other two endpoints.
class ListSwitcherPage extends StatelessWidget {
  final List<ChecklistList> lists;
  final List<ChecklistList> inventories;
  final int? selectedId;
  final bool inventoriesOnly;

  const ListSwitcherPage({
    super.key,
    required this.lists,
    this.inventories = const [],
    required this.selectedId,
    this.inventoriesOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    // Headed only when there is a second kind to tell the first from.
    final grouped = inventories.isNotEmpty && !inventoriesOnly;
    final checklistSection = grouped ? m.listKinds.checklist.title : null;
    final inventorySection = grouped ? m.listKinds.inventory.title : null;
    final allInventories =
        ServerFeature.inventoryAllView && inventories.length >= 2;
    final scope = inventoriesOnly ? WearScope.inventory : WearScope.instance;
    return WearChoicePage<int>(
      selected: selectedId,
      empty: inventoriesOnly
          ? ListKind.inventory.strings.emptyTitle
          : m.wear.noLists,
      onSelected: scope.selectList,
      choices: [
        if (!inventoriesOnly)
          WearChoice(
            value: kAllListsId,
            label: m.checklists.allLists,
            icon: allListsIcon,
            section: checklistSection,
          ),
        if (!inventoriesOnly)
          for (final list in lists)
            WearChoice(
              value: list.id,
              label: list.name,
              icon: checklistIcon(list.icon),
              tint: parseHexColor(list.color) ?? Colors.white70,
              section: checklistSection,
            ),
        if (allInventories)
          WearChoice(
            value: kAllInventoriesId,
            label: ListKind.inventory.strings.allTitle,
            icon: allListsIcon,
            section: inventorySection,
          ),
        for (final list in inventories)
          WearChoice(
            value: list.id,
            label: list.name,
            icon: checklistIcon(list.icon),
            tint: parseHexColor(list.color) ?? Colors.white70,
            section: inventorySection,
            badge: (list.needsRestock ?? 0) > 0 ? '${list.needsRestock}' : null,
            badgeLabel: (list.needsRestock ?? 0) > 0
                ? m.stock.needsRestockCount(list.needsRestock!)
                : null,
          ),
      ],
    );
  }
}
