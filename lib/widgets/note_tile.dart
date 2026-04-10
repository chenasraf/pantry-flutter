import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/note.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/views/notes/note_detail_view.dart';
import 'package:pantry/views/notes/note_form_view.dart';
import 'package:pantry/views/notes/notes_controller.dart';

class NoteTile extends StatelessWidget {
  final Note note;
  final NotesController controller;

  const NoteTile({super.key, required this.note, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor =
        _parseColor(note.color) ?? theme.colorScheme.surfaceContainerHighest;
    final textColor = _contrastColor(bgColor);

    if (controller.selectMode) {
      final isSelected = controller.selected.contains(note.id);
      return GestureDetector(
        onTap: () => controller.toggleSelection(note.id),
        child: Stack(
          children: [
            _buildCard(theme, bgColor, textColor),
            Positioned(
              top: 4,
              left: 4,
              child: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? theme.colorScheme.primary : textColor,
                size: 24,
              ),
            ),
          ],
        ),
      );
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != note.id,
      onAcceptWithDetails: (_) {},
      onMove: (_) => controller.hoverReorder(note.id),
      builder: (context, _, _) {
        return LongPressDraggable<int>(
          data: note.id,
          onDragStarted: () => controller.startDrag(note.id),
          onDragEnd: (_) => controller.endDrag(),
          onDraggableCanceled: (_, _) => controller.cancelDrag(),
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 160,
              height: 160,
              child: _buildCard(theme, bgColor, textColor),
            ),
          ),
          child: GestureDetector(
            onTap: () => _viewNote(context, bgColor, textColor),
            child: _buildCard(theme, bgColor, textColor),
          ),
        );
      },
    );
  }

  Widget _buildCard(ThemeData theme, Color bgColor, Color textColor) {
    final titleDir = detectTextDirection(note.title);
    final contentDir = detectTextDirection(note.content);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Directionality(
                  textDirection: titleDir,
                  child: Text(
                    note.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              _NoteMenuButton(
                note: note,
                controller: controller,
                color: textColor,
              ),
            ],
          ),
          if (note.content != null && note.content!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Expanded(
              child: Directionality(
                textDirection: contentDir,
                child: MarkdownBody(
                  data: note.content!,
                  shrinkWrap: true,
                  fitContent: false,
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    p: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withAlpha(200),
                    ),
                    h1: theme.textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    h2: theme.textTheme.titleSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    h3: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    listBullet: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withAlpha(200),
                    ),
                    strong: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    em: TextStyle(
                      color: textColor.withAlpha(200),
                      fontStyle: FontStyle.italic,
                    ),
                    code: TextStyle(
                      color: textColor,
                      backgroundColor: textColor.withAlpha(30),
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    blockquote: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withAlpha(180),
                      fontStyle: FontStyle.italic,
                    ),
                    a: TextStyle(
                      color: textColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _viewNote(BuildContext context, Color bgColor, Color textColor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteDetailView(
          note: note,
          controller: controller,
          bgColor: bgColor,
          textColor: textColor,
        ),
      ),
    );
  }

  static Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : null;
  }

  static Color _contrastColor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

class _NoteMenuButton extends StatelessWidget {
  final Note note;
  final NotesController controller;
  final Color color;

  const _NoteMenuButton({
    required this.note,
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 20, color: color),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _editNote(context);
          case 'delete':
            _confirmDelete(context);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 18),
              const SizedBox(width: 8),
              Text(m.notesWall.editNote),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 18),
              const SizedBox(width: 8),
              Text(m.common.delete),
            ],
          ),
        ),
      ],
    );
  }

  void _editNote(BuildContext context) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NoteFormView(controller: controller, note: note),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.notesWall.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteNote(note);
            },
            child: Text(m.common.delete),
          ),
        ],
      ),
    );
  }
}
