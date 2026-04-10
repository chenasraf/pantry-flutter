import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/views/notes/notes_controller.dart';

class NoteSortButton extends StatelessWidget {
  final NotesController controller;

  const NoteSortButton({super.key, required this.controller});

  static const _sortKeys = [
    'newest',
    'oldest',
    'title_asc',
    'title_desc',
    'custom',
  ];

  static String _label(String key) => switch (key) {
    'newest' => m.notesWall.sort.newestFirst,
    'oldest' => m.notesWall.sort.oldestFirst,
    'title_asc' => m.notesWall.sort.titleAZ,
    'title_desc' => m.notesWall.sort.titleZA,
    'custom' => m.notesWall.sort.custom,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      tooltip: '',
      onSelected: controller.setSortBy,
      itemBuilder: (context) => [
        for (final key in _sortKeys)
          PopupMenuItem<String>(
            value: key,
            child: Row(
              children: [
                Icon(
                  key == controller.sortBy
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: key == controller.sortBy
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
