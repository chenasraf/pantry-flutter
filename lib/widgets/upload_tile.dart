import 'package:flutter/material.dart';

import 'package:pantry/views/photos/photo_board_controller.dart';

class UploadTile extends StatelessWidget {
  final UploadTask task;
  final PhotoBoardController controller;

  const UploadTile({super.key, required this.task, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = task.error != null;

    return GestureDetector(
      onTap: hasError ? () => controller.retryUpload(task) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (task.thumbnailBytes != null)
              Image.memory(
                task.thumbnailBytes!,
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.4),
              )
            else
              Container(color: theme.colorScheme.surfaceContainerHighest),
            Center(
              child: hasError
                  ? Icon(
                      Icons.refresh,
                      color: theme.colorScheme.error,
                      size: 32,
                    )
                  : SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        value: task.progress > 0 ? task.progress : null,
                        strokeWidth: 3,
                      ),
                    ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => controller.dismissUpload(task),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
