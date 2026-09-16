import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry/views/photos/photo_board_controller.dart';
import 'package:pantry_core/widgets/avif_image.dart';

class UploadTile extends StatelessWidget {
  final UploadTask task;
  final PhotoBoardController controller;

  const UploadTile({super.key, required this.task, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = task.error != null;
    final isQueued = task.isQueued;

    return GestureDetector(
      onTap: hasError ? () => controller.retryUpload(task) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (task.thumbnailBytes != null)
              AvifMemoryImage(
                task.thumbnailBytes!,
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.4),
              )
            else if (task.pendingFile != null)
              AvifFileImage(
                task.pendingFile!,
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.4),
                errorWidget: Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
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
                  : isQueued
                  ? Tooltip(
                      message: m.photoBoard.waitingForConnection,
                      child: Icon(
                        Icons.cloud_off,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 32,
                      ),
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
            // A queued upload has nowhere to go if dismissed — the op keeps its
            // bytes and lands anyway, so the tile would only stop reporting it.
            if (!isQueued)
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
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
