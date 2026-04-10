import 'package:flutter/material.dart';

import 'package:pantry/models/checklist.dart';
import 'package:pantry/utils/checklist_icons.dart';

class ChecklistSelector extends StatelessWidget {
  final List<ChecklistList> lists;
  final ChecklistList? currentList;
  final ValueChanged<ChecklistList> onSelected;

  const ChecklistSelector({
    super.key,
    required this.lists,
    required this.currentList,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: DropdownButtonFormField<int>(
        initialValue: currentList?.id,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        items: lists
            .map(
              (list) => DropdownMenuItem(
                value: list.id,
                child: Row(
                  children: [
                    Icon(checklistIcon(list.icon), size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(list.name, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        selectedItemBuilder: (context) => lists
            .map(
              (list) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(checklistIcon(list.icon), size: 20),
                  const SizedBox(width: 8),
                  Text(list.name, overflow: TextOverflow.ellipsis),
                ],
              ),
            )
            .toList(),
        onChanged: (id) {
          if (id == null) return;
          final list = lists.firstWhere((l) => l.id == id);
          onSelected(list);
        },
      ),
    );
  }
}
