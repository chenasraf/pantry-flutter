import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/rrule.dart';
import 'package:pantry/widgets/image_preview.dart';

class ChecklistItemTile extends StatelessWidget {
  final ListItem item;
  final models.Category? category;
  final int houseId;
  final ValueChanged<ListItem> onToggle;
  final ValueChanged<ListItem> onView;
  final ValueChanged<ListItem> onEdit;
  final ValueChanged<ListItem> onDelete;

  const ChecklistItemTile({
    super.key,
    required this.item,
    this.category,
    required this.houseId,
    required this.onToggle,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimmed = item.done;

    return Material(
      type: MaterialType.transparency,
      child: Opacity(
        opacity: dimmed ? 0.5 : 1.0,
        child: InkWell(
          onTap: () => onToggle(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                Checkbox(value: item.done, onChanged: (_) => onToggle(item)),
                if (item.imageFileId != null) ...[
                  GestureDetector(
                    onTap: () => _showImagePreview(context),
                    child: Hero(
                      tag: 'item-image-${item.id}',
                      child: _ItemImage(
                        houseId: houseId,
                        fileId: item.imageFileId!,
                        owner: item.imageUploadedBy ?? '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          decoration: dimmed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (_hasBadges)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: _buildBadges(context),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.visibility_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => onView(item),
                ),
                _MoreMenuButton(item: item, onEdit: onEdit, onDelete: onDelete),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context) {
    final uri = ChecklistService.instance.itemImagePreviewUri(
      houseId,
      item.imageFileId!,
      item.imageUploadedBy ?? '',
      size: 1024,
    );
    ImagePreview.show(
      context,
      imageUrl: uri.toString(),
      heroTag: 'item-image-${item.id}',
      headers: AuthService.instance.credentials?.basicAuthHeaders ?? {},
    );
  }

  bool get _hasBadges =>
      (item.quantity != null && item.quantity!.isNotEmpty) ||
      category != null ||
      (item.rrule != null && item.rrule!.isNotEmpty);

  List<Widget> _buildBadges(BuildContext context) {
    final badges = <Widget>[];
    final theme = Theme.of(context);

    if (item.quantity != null && item.quantity!.isNotEmpty) {
      badges.add(
        _Badge(
          icon: Icons.close,
          label: item.quantity!,
          color: theme.colorScheme.surfaceContainerHighest,
          textColor: theme.colorScheme.onSurface,
        ),
      );
    }

    if (category != null) {
      final catColor =
          _parseColor(category!.color) ?? theme.colorScheme.primary;
      badges.add(
        _Badge(
          icon: categoryIcon(category!.icon),
          label: category!.name,
          color: catColor.withAlpha(30),
          textColor: catColor,
        ),
      );
    }

    if (item.rrule != null && item.rrule!.isNotEmpty) {
      badges.add(
        _Badge(
          icon: Icons.event_repeat,
          label: _formatRrule(item.rrule!),
          color: theme.colorScheme.surfaceContainerHighest,
          textColor: theme.colorScheme.onSurface,
        ),
      );
    }

    return badges;
  }

  static Color? _parseColor(String hex) {
    if (hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : null;
  }

  static String _formatRrule(String rrule) => formatRrule(rrule);
}

class _ItemImage extends StatelessWidget {
  final int houseId;
  final int fileId;
  final String owner;

  const _ItemImage({
    required this.houseId,
    required this.fileId,
    required this.owner,
  });

  @override
  Widget build(BuildContext context) {
    final uri = ChecklistService.instance.itemImagePreviewUri(
      houseId,
      fileId,
      owner,
      size: 64,
    );
    final headers = AuthService.instance.credentials?.basicAuthHeaders ?? {};

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: uri.toString(),
        httpHeaders: headers,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.broken_image_outlined, size: 20),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final Color textColor;

  const _Badge({
    this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 3),
          ],
          Text(label, style: TextStyle(fontSize: 11, color: textColor)),
        ],
      ),
    );
  }
}

class _MoreMenuButton extends StatelessWidget {
  final ListItem item;
  final ValueChanged<ListItem> onEdit;
  final ValueChanged<ListItem> onDelete;

  const _MoreMenuButton({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 18),
              const SizedBox(width: 8),
              Text(m.checklists.editItem),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 18),
              const SizedBox(width: 8),
              Text(m.checklists.removeItem),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit(item);
          case 'remove':
            onDelete(item);
        }
      },
    );
  }
}
