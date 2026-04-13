import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/date_format.dart';
import 'package:pantry/utils/rrule.dart';
import 'package:pantry/utils/text_direction.dart';
import 'checklists_controller.dart';
import 'item_form_view.dart';

class ItemDetailView extends StatelessWidget {
  final ListItem item;
  final models.Category? category;
  final int houseId;
  final ChecklistsController controller;

  const ItemDetailView({
    super.key,
    required this.item,
    this.category,
    required this.houseId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = item.imageFileId != null;
    final v = m.checklists.viewItem;

    final nameDir = detectTextDirection(item.name);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ItemFormView(controller: controller, item: item),
            ),
          );
        },
        icon: const Icon(Icons.edit),
        label: Text(m.checklists.editItem),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: hasImage ? 280 : 0,
            pinned: true,
            title: Directionality(
              textDirection: nameDir,
              child: Text(item.name),
            ),
            flexibleSpace: hasImage
                ? FlexibleSpaceBar(
                    background: _CoverImage(
                      houseId: houseId,
                      fileId: item.imageFileId!,
                      owner: item.imageUploadedBy ?? '',
                    ),
                  )
                : null,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  Directionality(
                    textDirection: detectTextDirection(item.description),
                    child: MarkdownBody(
                      data: item.description!,
                      shrinkWrap: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                        p: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (item.quantity != null && item.quantity!.isNotEmpty) ...[
                  _DetailRow(
                    label: v.quantity,
                    child: _Badge(
                      icon: Icons.close,
                      label: item.quantity!,
                      color: theme.colorScheme.surfaceContainerHighest,
                      textColor: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (category != null) ...[
                  _DetailRow(
                    label: v.category,
                    child: _CategoryBadge(category: category!),
                  ),
                  const SizedBox(height: 12),
                ],
                if (item.rrule != null && item.rrule!.isNotEmpty) ...[
                  _DetailRow(
                    label: v.recurrence,
                    child: _Badge(
                      icon: Icons.event_repeat,
                      label: formatRrule(item.rrule!),
                      color: theme.colorScheme.surfaceContainerHighest,
                      textColor: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (item.nextDueAt != null) ...[
                    _DetailRow(
                      label: item.repeatFromCompletion
                          ? v.nextDueFromCompletion
                          : v.nextDue,
                      child: _Badge(
                        icon: isOverdue(item.nextDueAt!)
                            ? Icons.warning_amber
                            : Icons.schedule,
                        label: isOverdue(item.nextDueAt!)
                            ? '${formatDate(item.nextDueAt!)} (${v.overdue})'
                            : formatDate(item.nextDueAt!),
                        color: isOverdue(item.nextDueAt!)
                            ? theme.colorScheme.errorContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        textColor: isOverdue(item.nextDueAt!)
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  final int houseId;
  final int fileId;
  final String owner;

  const _CoverImage({
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
      size: 1024,
    );
    final headers = AuthService.instance.credentials?.basicAuthHeaders ?? {};

    return CachedNetworkImage(
      imageUrl: uri.toString(),
      httpHeaders: headers,
      fit: BoxFit.cover,
      errorWidget: (_, _, _) => Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _DetailRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        child,
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 13, color: textColor)),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final models.Category category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = _parseColor(category.color) ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: catColor.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(categoryIcon(category.icon), size: 14, color: catColor),
          const SizedBox(width: 4),
          Text(category.name, style: TextStyle(fontSize: 13, color: catColor)),
        ],
      ),
    );
  }

  static Color? _parseColor(String hex) {
    if (hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : null;
  }
}
