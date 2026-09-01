import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/utils/checklist_icons.dart';

/// Per-list color swatches the user can pick from in the create form. Values
/// must come from the backend's `ChecklistColor` enum (Material Design 500
/// hues, lowercase hex) — anything else gets rejected by the API.
const List<String> kListColorSwatches = [
  '#f44336', // red
  '#ff9800', // orange
  '#ffc107', // amber
  '#4caf50', // green
  '#00bcd4', // cyan
  '#2196f3', // blue
  '#673ab7', // deep purple
  '#e91e63', // pink
];

class SwitcherColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const SwitcherColorSwatch({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: color, width: 2) : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 0,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

/// The synthetic "All lists" entry rendered at the top of the switcher. It's
/// not draggable, not editable, has no overflow menu, and doesn't show an
/// item count (the count would require fetching across every list).
class AllListsTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const AllListsTile({super.key, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsetsDirectional.only(
          start: 13,
          end: 8,
          top: 12,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.1)
              : cs.surfaceContainer,
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(allListsIcon, color: cs.primary, size: 21),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.checklists.allLists,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.checklists.allListsSubtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

class IconChip extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const IconChip({
    super.key,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : cs.surfaceContainer,
          border: Border.all(
            color: selected ? color : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          color: selected ? color : cs.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }
}

/// Wraps a child with a desktop right-click menu offering edit and remove actions.
class ContextMenuRegion extends StatefulWidget {
  final Widget child;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final VoidCallback? onArchive;
  final String editLabel;
  final String removeLabel;
  final String archiveLabel;

  const ContextMenuRegion({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onRemove,
    required this.onArchive,
    required this.editLabel,
    required this.removeLabel,
    required this.archiveLabel,
  });

  @override
  State<ContextMenuRegion> createState() => _ContextMenuRegionState();
}

class _ContextMenuRegionState extends State<ContextMenuRegion> {
  Future<void> _openAt(BuildContext context, Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(globalPosition, globalPosition),
        Offset.zero & overlay.size,
      ),
      items: [
        if (widget.onEdit != null)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, size: 18),
                const SizedBox(width: 10),
                Text(widget.editLabel),
              ],
            ),
          ),
        if (widget.onArchive != null)
          PopupMenuItem<String>(
            value: 'archive',
            child: Row(
              children: [
                const Icon(Icons.archive_outlined, size: 18),
                const SizedBox(width: 10),
                Text(widget.archiveLabel),
              ],
            ),
          ),
        if (widget.onRemove != null)
          PopupMenuItem<String>(
            value: 'remove',
            child: Row(
              children: [
                const Icon(Icons.delete_outline, size: 18),
                const SizedBox(width: 10),
                Text(widget.removeLabel),
              ],
            ),
          ),
      ],
    );
    if (result == 'edit') widget.onEdit?.call();
    if (result == 'archive') widget.onArchive?.call();
    if (result == 'remove') widget.onRemove?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapDown: (d) => _openAt(context, d.globalPosition),
      child: widget.child,
    );
  }
}
