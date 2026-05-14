import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/utils/checklist_icons.dart';

const int _kCreateNewListSentinel = -1;

class ChecklistSelector extends StatefulWidget {
  final List<ChecklistList> lists;
  final ChecklistList? currentList;
  final ValueChanged<ChecklistList> onSelected;
  final VoidCallback onCreateNew;

  const ChecklistSelector({
    super.key,
    required this.lists,
    required this.currentList,
    required this.onSelected,
    required this.onCreateNew,
  });

  @override
  State<ChecklistSelector> createState() => _ChecklistSelectorState();
}

class _ChecklistSelectorState extends State<ChecklistSelector> {
  int _resetCount = 0;

  void _handleChanged(int? id) {
    if (id == null) return;
    if (id == _kCreateNewListSentinel) {
      // Force the dropdown to drop its internal -1 state and snap back to
      // the current list before we open the create flow.
      setState(() => _resetCount++);
      widget.onCreateNew();
      return;
    }
    final list = widget.lists.firstWhere((l) => l.id == id);
    widget.onSelected(list);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, top: 8, bottom: 8),
      child: DropdownButtonFormField<int>(
        key: ValueKey('${widget.currentList?.id}-$_resetCount'),
        initialValue: widget.currentList?.id,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        items: [
          ...widget.lists.map(
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
          ),
          DropdownMenuItem(
            value: _kCreateNewListSentinel,
            child: Row(
              children: [
                Icon(Icons.add, size: 20, color: primary),
                const SizedBox(width: 8),
                Text(m.checklists.createList, style: TextStyle(color: primary)),
              ],
            ),
          ),
        ],
        selectedItemBuilder: (context) => [
          ...widget.lists.map(
            (list) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(checklistIcon(list.icon), size: 20),
                const SizedBox(width: 8),
                Text(list.name, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox.shrink(),
        ],
        onChanged: _handleChanged,
      ),
    );
  }
}
