import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/views/photos/photo_board_controller.dart';

class PhotoSortButton extends StatelessWidget {
  final PhotoBoardController controller;

  const PhotoSortButton({super.key, required this.controller});

  static const _sortKeys = [
    'newest',
    'oldest',
    'description_asc',
    'description_desc',
    'custom',
  ];

  static String _label(String key) => switch (key) {
    'newest' => m.photoBoard.sort.newestFirst,
    'oldest' => m.photoBoard.sort.oldestFirst,
    'description_asc' => m.photoBoard.sort.captionAZ,
    'description_desc' => m.photoBoard.sort.captionZA,
    'custom' => m.photoBoard.sort.custom,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      tooltip: '',
      onSelected: (value) {
        if (value == '_folders_first') {
          controller.setFoldersFirst(!controller.foldersFirst);
        } else {
          controller.setSortBy(value);
        }
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem<String>(
          value: '_folders_first',
          checked: controller.foldersFirst,
          child: Text(m.photoBoard.sort.foldersFirst),
        ),
        const PopupMenuDivider(),
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
