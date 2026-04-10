import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/views/photos/photo_board_controller.dart';

class PhotoAddButton extends StatelessWidget {
  final PhotoBoardController controller;

  const PhotoAddButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'photo_folder',
          onPressed: () => _createFolder(context),
          child: const Icon(Icons.create_new_folder),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'photo_upload',
          onPressed: () => _pickPhotos(context),
          child: const Icon(Icons.add_photo_alternate),
        ),
      ],
    );
  }

  Future<void> _pickPhotos(BuildContext context) async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isNotEmpty) {
      controller.uploadPhotos(files);
    }
  }

  void _createFolder(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.photoBoard.newFolder),
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: m.photoBoard.folderName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                controller.createFolder(name);
                Navigator.pop(ctx);
              }
            },
            child: Text(m.common.save),
          ),
        ],
      ),
    );
  }
}
