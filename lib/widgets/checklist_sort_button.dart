import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';

class ChecklistSortButton extends StatelessWidget {
  final String currentSort;
  final ValueChanged<String> onSelected;

  const ChecklistSortButton({
    super.key,
    required this.currentSort,
    required this.onSelected,
  });

  static const _sortKeys = [
    'newest',
    'oldest',
    'name_asc',
    'name_desc',
    'custom',
  ];

  static String _label(String key) => switch (key) {
    'newest' => m.checklists.sort.newestFirst,
    'oldest' => m.checklists.sort.oldestFirst,
    'name_asc' => m.checklists.sort.nameAZ,
    'name_desc' => m.checklists.sort.nameZA,
    'custom' => m.checklists.sort.custom,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      tooltip: '',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final key in _sortKeys)
          PopupMenuItem<String>(
            value: key,
            child: Row(
              children: [
                Icon(
                  key == currentSort
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: key == currentSort
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Text(_label(key)),
              ],
            ),
          ),
      ],
    );
  }
}
