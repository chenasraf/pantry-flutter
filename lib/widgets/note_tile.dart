import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/note.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/utils/undo_snackbar.dart';
import 'package:pantry/views/notes/note_detail_view.dart';
import 'package:pantry/views/notes/note_form_view.dart';
import 'package:pantry/views/notes/notes_controller.dart';
import 'package:pantry/widgets/context_menu_region.dart';

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

    final hasMenu = _menuItems().isNotEmpty;

    if (controller.selectMode) {
      final isSelected = controller.selected.contains(note.id);
      return GestureDetector(
        onTap: () => controller.toggleSelection(note.id),
        child: Stack(
          children: [
            _buildCard(context, bgColor, textColor),
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

    Widget tappableCard = GestureDetector(
      onTap: () => _viewNote(context, bgColor, textColor),
      child: _buildCard(context, bgColor, textColor, showMenu: hasMenu),
    );
    if (hasMenu) {
      tappableCard = ContextMenuRegion<String>(
        itemBuilder: _menuItems,
        onSelected: (value) => _onMenuSelected(context, value),
        child: tappableCard,
      );
    }

    // Reordering notes is governed by canUpdateNotes; without it the card is
    // not draggable.
    if (!controller.permissions.canUpdateNotes) {
      return tappableCard;
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) =>
          details.data != note.id && controller.canDropOn(note.id),
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
              child: _buildCard(context, bgColor, textColor),
            ),
          ),
          child: tappableCard,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    Color bgColor,
    Color textColor, {
    bool showMenu = false,
  }) {
    final theme = Theme.of(context);
    final titleDir = detectTextDirection(note.title);
    final contentDir = detectTextDirection(note.content);

    return Hero(
      tag: 'note-${note.id}',
      child: Container(
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
                if (note.isPinned) ...[
                  Icon(Icons.push_pin, size: 14, color: textColor),
                  const SizedBox(width: 4),
                ],
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
                if (showMenu)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 20, color: textColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    itemBuilder: (_) => _menuItems(),
                    onSelected: (value) => _onMenuSelected(context, value),
                  ),
              ],
            ),
            if (note.content != null && note.content!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.white, Colors.transparent],
                    stops: const [0.0, 0.7, 1.0],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: Directionality(
                    textDirection: contentDir,
                    child: Markdown(
                      data: note.content!,
                      shrinkWrap: false,
                      softLineBreak: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      onTapLink: (text, href, title) {
                        if (href != null) {
                          launchUrl(Uri.parse(href));
                        }
                      },
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
              ),
            ],
          ],
        ),
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

  List<PopupMenuEntry<String>> _menuItems() => [
    if (controller.permissions.canUpdateNotes)
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
    if (hasFeature('note-pinning') && controller.permissions.canUpdateNotes)
      PopupMenuItem(
        value: 'pin',
        child: Row(
          children: [
            Icon(
              note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(note.isPinned ? m.notesWall.unpinNote : m.notesWall.pinNote),
          ],
        ),
      ),
    if (controller.permissions.canDeleteNotes)
      PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            const Icon(Icons.delete, size: 18),
            const SizedBox(width: 8),
            Text(_softDeleteLabel),
          ],
        ),
      ),
  ];

  String get _softDeleteLabel =>
      hasFeature('note-trash') ? m.common.remove : m.common.delete;

  void _onMenuSelected(BuildContext context, String value) {
    switch (value) {
      case 'edit':
        _editNote(context);
      case 'pin':
        controller.togglePin(note);
      case 'delete':
        _confirmDelete(context);
    }
  }

  void _editNote(BuildContext context) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NoteFormView(controller: controller, note: note),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.notesWall.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_softDeleteLabel),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      try {
        await controller.deleteNote(note);
        if (!context.mounted) return;
        if (hasFeature('note-trash')) {
          showUndoSnackBar(
            context,
            message: m.notesWall.noteRemoved(1),
            undoLabel: m.checklists.undo,
            onUndo: () => controller.restoreNote(note),
            undoFailedMessage: m.notesWall.restoreFailed,
          );
        } else {
          final messenger = ScaffoldMessenger.of(context);
          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(content: Text(m.notesWall.noteRemoved(1))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(m.notesWall.deleteFailed)));
        }
      }
    });
  }
}
