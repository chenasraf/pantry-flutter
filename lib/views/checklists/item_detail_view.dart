import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/checklist_icons.dart';
import 'package:pantry/utils/date_format.dart';
import 'package:pantry/utils/item_modal_route.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/utils/rrule.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/widgets/image_preview.dart';
import 'package:pantry/widgets/member_avatar.dart';
import 'checklist_item_tile.dart' show ItemLifecycle, lifecycleOf;
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
    final cs = theme.colorScheme;
    final hasImage = item.imageFileId != null;
    final lifecycle = lifecycleOf(item);

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: hasImage
                      ? _PhotoHeader(
                          item: item,
                          houseId: houseId,
                          category: category,
                          onBack: () => Navigator.of(context).maybePop(),
                          onMore: (ctx) =>
                              _showOverflow(context, anchorContext: ctx),
                        )
                      : _FallbackHeader(
                          item: item,
                          category: category,
                          onBack: () => Navigator.of(context).maybePop(),
                          onMore: (ctx) =>
                              _showOverflow(context, anchorContext: ctx),
                        ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  sliver: SliverList.list(
                    children: [
                      _FactTiles(item: item, lifecycle: lifecycle),
                      const SizedBox(height: 12),
                      _DescriptionCard(description: item.description),
                      const SizedBox(height: 12),
                      _MetaRow(item: item, controller: controller),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _DockedEditBar(onTap: () => _openEdit(context)),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context).pushReplacement(
      itemModalRoute(ItemFormView(controller: controller, item: item)),
    );
  }

  Future<void> _showOverflow(
    BuildContext context, {
    BuildContext? anchorContext,
  }) async {
    final canMove = controller.lists
        .where((l) => l.id != controller.currentList?.id)
        .isNotEmpty;
    final canCopy = canMove && hasFeature('copy-items');
    final actions = <_OverflowAction>[
      if (canMove)
        _OverflowAction(
          value: 'move',
          icon: Icons.drive_file_move_outlined,
          label: m.checklists.moveItem,
        ),
      if (canCopy)
        _OverflowAction(
          value: 'copy',
          icon: Icons.copy_outlined,
          label: m.checklists.copyItem,
        ),
      _OverflowAction(
        value: 'delete',
        icon: Icons.delete_outline,
        label: m.checklists.removeItem,
      ),
    ];
    String? selected;
    if (PlatformInfo.isDesktop && anchorContext != null) {
      // Desktop: anchor a regular PopupMenu under the more button. Reads as
      // a native menu instead of an out-of-place bottom sheet.
      final box = anchorContext.findRenderObject() as RenderBox?;
      final overlay =
          Navigator.of(context).overlay?.context.findRenderObject()
              as RenderBox?;
      if (box == null || overlay == null || !box.attached) return;
      final btnTopLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
      final btnSize = box.size;
      final position = RelativeRect.fromLTRB(
        btnTopLeft.dx,
        btnTopLeft.dy + btnSize.height,
        overlay.size.width - (btnTopLeft.dx + btnSize.width),
        0,
      );
      selected = await showMenu<String>(
        context: context,
        position: position,
        items: [
          for (final a in actions)
            PopupMenuItem<String>(
              value: a.value,
              child: Row(
                children: [
                  Icon(a.icon, size: 18),
                  const SizedBox(width: 12),
                  Text(a.label),
                ],
              ),
            ),
        ],
      );
    } else {
      selected = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final a in actions)
                ListTile(
                  leading: Icon(a.icon),
                  title: Text(a.label),
                  onTap: () => Navigator.pop(ctx, a.value),
                ),
            ],
          ),
        ),
      );
    }
    if (!context.mounted) return;
    switch (selected) {
      case 'move':
        await _onMove(context);
      case 'copy':
        await _onCopy(context);
      case 'delete':
        await _confirmDelete(context);
    }
  }

  Future<void> _onMove(BuildContext context) async {
    final others = controller.lists
        .where((l) => l.id != controller.currentList?.id)
        .toList();
    if (others.isEmpty) return;
    final targetId = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(m.checklists.moveItem),
        children: [
          for (final list in others)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, list.id),
              child: Row(
                children: [
                  Icon(checklistIcon(list.icon), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(list.name)),
                ],
              ),
            ),
        ],
      ),
    );
    if (targetId == null || !context.mounted) return;
    try {
      await controller.moveItem(item, targetId);
      // The item is no longer on the current list; close the detail view so
      // the user lands back on the checklist they came from.
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.moveFailed)));
      }
    }
  }

  Future<void> _onCopy(BuildContext context) async {
    final others = controller.lists
        .where((l) => l.id != controller.currentList?.id)
        .toList();
    if (others.isEmpty) return;
    final targetId = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(m.checklists.copyItem),
        children: [
          for (final list in others)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, list.id),
              child: Row(
                children: [
                  Icon(checklistIcon(list.icon), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(list.name)),
                ],
              ),
            ),
        ],
      ),
    );
    if (targetId == null || !context.mounted) return;
    try {
      await controller.copyItem(item, targetId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.itemCopied)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.copyFailed)));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final f = m.checklists.itemForm;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(f.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.common.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await controller.deleteItem(item);
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(f.deleteFailed)));
      }
    }
  }
}

Color? _parseColor(String hex) {
  if (hex.isEmpty) return null;
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  final value = int.tryParse(hex, radix: 16);
  return value != null ? Color(value) : null;
}

class _OverflowAction {
  final String value;
  final IconData icon;
  final String label;

  const _OverflowAction({
    required this.value,
    required this.icon,
    required this.label,
  });
}

/// Header used when the item has a photo. The image fills a 300px slab; a
/// bottom-up scrim keeps the title legible while the photo bleeds to the
/// status bar. Back + overflow render as translucent blurred circles.
class _PhotoHeader extends StatelessWidget {
  final ListItem item;
  final int houseId;
  final models.Category? category;
  final VoidCallback onBack;

  /// Receives the BuildContext of the more button so callers can anchor a
  /// popup to it (desktop dropdown menu).
  final ValueChanged<BuildContext> onMore;

  const _PhotoHeader({
    required this.item,
    required this.houseId,
    required this.category,
    required this.onBack,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final heroTag = 'item-image-${item.id}';
    final fullUri = ChecklistService.instance.itemImagePreviewUri(
      houseId,
      item.imageFileId!,
      item.imageUploadedBy ?? '',
      size: 2048,
    );
    final headers = AuthService.instance.credentials?.basicAuthHeaders ?? {};
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => ImagePreview.show(
              context,
              imageUrl: fullUri.toString(),
              heroTag: heroTag,
              headers: headers,
            ),
            child: Hero(
              tag: heroTag,
              child: _CoverImage(
                houseId: houseId,
                fileId: item.imageFileId!,
                owner: item.imageUploadedBy ?? '',
              ),
            ),
          ),
          // Bottom-up scrim — keeps the chip + name on the photo legible
          // without darkening the whole header.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 170,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF08090C).withValues(alpha: 0.96),
                      const Color(0xFF08090C).withValues(alpha: 0.55),
                      const Color(0x0008090C),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Stack stretches the SafeArea to 300px, so the Row inside would
          // center its 38px buttons vertically — right above the chip. Align
          // pins the controls back to the top edge.
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SquareIconButton(
                      icon: PlatformInfo.isDesktop
                          ? Icons.close
                          : Icons.arrow_back,
                      onTap: onBack,
                      onPhoto: true,
                    ),
                    Builder(
                      builder: (ctx) => _SquareIconButton(
                        icon: Icons.more_vert,
                        onTap: () => onMore(ctx),
                        onPhoto: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: _HeaderTitleBlock(
              name: item.name,
              category: category,
              onPhoto: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Header used when no photo exists. Tints the slab with the category color,
/// shows a rounded category-glyph tile next to the name and chip.
class _FallbackHeader extends StatelessWidget {
  final ListItem item;
  final models.Category? category;
  final VoidCallback onBack;
  final ValueChanged<BuildContext> onMore;

  const _FallbackHeader({
    required this.item,
    required this.category,
    required this.onBack,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final catColor = category != null
        ? (_parseColor(category!.color) ?? cs.primary)
        : cs.primary;
    final icon = category != null
        ? categoryIcon(category!.icon)
        : Icons.shopping_basket_outlined;
    return SizedBox(
      height: 230,
      child: Stack(
        children: [
          // Tinted gradient backdrop blending the category color into the
          // page surface.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    catColor.withValues(alpha: 0.28),
                    catColor.withValues(alpha: 0.06),
                    cs.surface.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SquareIconButton(
                      icon: PlatformInfo.isDesktop
                          ? Icons.close
                          : Icons.arrow_back,
                      onTap: onBack,
                    ),
                    Builder(
                      builder: (ctx) => _SquareIconButton(
                        icon: Icons.more_vert,
                        onTap: () => onMore(ctx),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: catColor.withValues(alpha: 0.35)),
                  ),
                  child: Icon(icon, color: catColor, size: 36),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _HeaderTitleBlock(
                      name: item.name,
                      category: category,
                      onPhoto: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTitleBlock extends StatelessWidget {
  final String name;
  final models.Category? category;
  final bool onPhoto;

  const _HeaderTitleBlock({
    required this.name,
    required this.category,
    required this.onPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final catColor = category != null
        ? (_parseColor(category!.color) ?? cs.primary)
        : cs.primary;
    final nameDir = detectTextDirection(name);
    final nameColor = onPhoto ? Colors.white : cs.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (category != null)
          _CategoryChip(
            color: catColor,
            label: category!.name,
            onPhoto: onPhoto,
          ),
        if (category != null) const SizedBox(height: 10),
        Directionality(
          textDirection: nameDir,
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: onPhoto ? 30 : 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: nameColor,
              shadows: onPhoto
                  ? [
                      const Shadow(
                        color: Color(0x66000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final Color color;
  final String label;
  final bool onPhoto;

  const _CategoryChip({
    required this.color,
    required this.label,
    required this.onPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final bg = onPhoto
        ? color.withValues(alpha: 0.9)
        : color.withValues(alpha: 0.16);
    final fg = onPhoto ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onPhoto ? Colors.white : color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool onPhoto;

  const _SquareIconButton({
    required this.icon,
    required this.onTap,
    this.onPhoto = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Over a photo the default 6%-alpha surface tint disappears against
    // bright/busy images. Use a near-opaque dark fill + white icon so the
    // controls stay readable on any photo without going full opaque.
    final bg = onPhoto
        ? const Color(0xFF08090C).withValues(alpha: 0.7)
        : cs.onSurface.withValues(alpha: 0.06);
    final borderColor = onPhoto
        ? Colors.white.withValues(alpha: 0.18)
        : cs.outlineVariant;
    final iconColor = onPhoto ? Colors.white : cs.onSurfaceVariant;
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}

class _FactTiles extends StatelessWidget {
  final ListItem item;
  final ItemLifecycle lifecycle;

  const _FactTiles({required this.item, required this.lifecycle});

  @override
  Widget build(BuildContext context) {
    final v = m.checklists.viewItem;
    // IntrinsicHeight + CrossAxisAlignment.stretch makes both tiles match
    // the taller one's height. Plain `stretch` inside an unbounded sliver
    // would resolve to infinite child height and crash layout.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 10,
            child: _FactTile(
              label: v.quantityLabel,
              child: Text(
                item.quantity?.trim().isNotEmpty == true
                    ? item.quantity!.trim()
                    : '—',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            flex: 14,
            child: _FactTile(
              label: v.typeLabel,
              child: _TypeValue(item: item, lifecycle: lifecycle),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactTile extends StatelessWidget {
  final String label;
  final Widget child;

  const _FactTile({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }
}

class _TypeValue extends StatelessWidget {
  final ListItem item;
  final ItemLifecycle lifecycle;

  const _TypeValue({required this.item, required this.lifecycle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = m.checklists.itemTypes;
    final String label;
    final String? sub;
    switch (lifecycle) {
      case ItemLifecycle.staple:
        label = t.staple;
        sub = t.stapleBody;
      case ItemLifecycle.once:
        label = t.onceTime;
        sub = t.onceTimeBody;
      case ItemLifecycle.recurring:
        label = t.recurring;
        sub = (item.rrule != null && item.rrule!.isNotEmpty)
            ? formatRrule(item.rrule!)
            : t.recurringBody;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (lifecycle == ItemLifecycle.recurring) ...[
              Icon(Icons.cached, size: 17, color: cs.primary),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final String? description;

  const _DescriptionCard({required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final v = m.checklists.viewItem;
    final hasDesc = description != null && description!.trim().isNotEmpty;
    final dir = detectTextDirection(description);

    final label = Text(
      v.descriptionLabel.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: cs.onSurfaceVariant,
      ),
    );

    if (!hasDesc) {
      return _DashedCard(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        color: cs.outlineVariant,
        background: cs.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            const SizedBox(height: 5),
            Text(
              v.noDescription,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const SizedBox(height: 8),
          Directionality(
            textDirection: dir,
            child: MarkdownBody(
              data: description!,
              shrinkWrap: true,
              onTapLink: (text, href, title) {
                if (href != null) launchUrl(Uri.parse(href));
              },
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  height: 1.5,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final ListItem item;
  final ChecklistsController controller;

  const _MetaRow({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = m.checklists.viewItem;
    final addedBy = item.addedBy;
    final hasAuthor = addedBy != null && addedBy.isNotEmpty;
    final currentUser = AuthService.instance.credentials?.loginName;
    final isYou = hasAuthor && addedBy == currentUser;
    final member = hasAuthor ? controller.members[addedBy] : null;
    final displayName = member?.displayName ?? addedBy ?? '';
    final time = relativeTime(item.createdAt);
    // When the author is unknown (older items without an `addedBy`), drop
    // the "by … " segment, hide the avatar, and lead with "Added {time}".
    final text = !hasAuthor
        ? v.addedMeta(time)
        : isYou
        ? v.addedByYouMeta(time)
        : v.addedByMeta(displayName, time);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        children: [
          if (hasAuthor) ...[
            MemberAvatar(userId: addedBy, displayName: displayName, size: 28),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DockedEditBar extends StatelessWidget {
  final VoidCallback onTap;

  const _DockedEditBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.primary.withValues(alpha: 0.78)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit, color: Colors.white, size: 20),
                const SizedBox(width: 9),
                Text(
                  m.checklists.editItem,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
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

class _DashedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color background;

  const _DashedCard({
    required this.child,
    required this.padding,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(color: color, radius: 15, strokeWidth: 1),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;

  _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}
