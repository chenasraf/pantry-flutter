import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';

class ChecklistsErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ChecklistsErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(m.common.retry)),
          ],
        ),
      ),
    );
  }
}

class ChecklistsTrashBanner extends StatelessWidget {
  final VoidCallback onExit;

  const ChecklistsTrashBanner({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
      child: Row(
        children: [
          Icon(Icons.delete_outline, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              m.checklists.trashTitle,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          TextButton.icon(
            onPressed: onExit,
            icon: const Icon(Icons.close, size: 16),
            label: Text(m.checklists.exitTrash),
          ),
        ],
      ),
    );
  }
}

class ChecklistsArchiveBanner extends StatelessWidget {
  final VoidCallback onExit;

  const ChecklistsArchiveBanner({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
      child: Row(
        children: [
          Icon(Icons.archive_outlined, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              m.checklists.archiveTitle,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          TextButton.icon(
            onPressed: onExit,
            icon: const Icon(Icons.close, size: 16),
            label: Text(m.checklists.exitArchive),
          ),
        ],
      ),
    );
  }
}
