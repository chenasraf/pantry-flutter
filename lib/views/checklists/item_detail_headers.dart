import 'package:flutter/material.dart';

import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/store.dart' as models;
import 'package:pantry/models/label.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/label_icons.dart';
import 'package:pantry/utils/store_icons.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/widgets/avif_image.dart';
import 'package:pantry/widgets/image_preview.dart';

Color? _parseColor(String hex) {
  if (hex.isEmpty) return null;
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  final value = int.tryParse(hex, radix: 16);
  return value != null ? Color(value) : null;
}

/// Header used when the item has a photo. The image fills a 300px slab; a
/// bottom-up scrim keeps the title legible while the photo bleeds to the
/// status bar. Back + overflow render as translucent blurred circles.
class PhotoHeader extends StatelessWidget {
  final ListItem item;
  final int houseId;
  final models.Category? category;
  final List<models.Store> stores;
  final List<models.Label> labels;
  final VoidCallback onBack;

  /// Receives the more button's BuildContext so callers can anchor a popup to
  /// it (desktop dropdown). Null hides the button when there are no actions.
  final ValueChanged<BuildContext>? onMore;

  const PhotoHeader({
    super.key,
    required this.item,
    required this.houseId,
    required this.category,
    required this.stores,
    required this.labels,
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
                    if (onMore != null)
                      Builder(
                        builder: (ctx) => _SquareIconButton(
                          icon: Icons.more_vert,
                          onTap: () => onMore!(ctx),
                          onPhoto: true,
                        ),
                      )
                    else
                      const SizedBox(width: 38),
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
              stores: stores,
              labels: labels,
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
class FallbackHeader extends StatelessWidget {
  final ListItem item;
  final models.Category? category;
  final List<models.Store> stores;
  final List<models.Label> labels;
  final VoidCallback onBack;
  final ValueChanged<BuildContext>? onMore;

  const FallbackHeader({
    super.key,
    required this.item,
    required this.category,
    required this.stores,
    required this.labels,
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
          // Tinted category-color backdrop fading into the page surface.
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
                    if (onMore != null)
                      Builder(
                        builder: (ctx) => _SquareIconButton(
                          icon: Icons.more_vert,
                          onTap: () => onMore!(ctx),
                        ),
                      )
                    else
                      const SizedBox(width: 38),
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
                      stores: stores,
                      labels: labels,
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
  final List<models.Store> stores;
  final List<models.Label> labels;
  final bool onPhoto;

  const _HeaderTitleBlock({
    required this.name,
    required this.category,
    required this.stores,
    required this.labels,
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
    final hasChips = category != null || stores.isNotEmpty || labels.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasChips)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (category != null)
                _CategoryChip(
                  color: catColor,
                  label: category!.name,
                  onPhoto: onPhoto,
                ),
              for (final s in stores)
                _CategoryChip(
                  color: _parseColor(s.color) ?? cs.primary,
                  label: s.name,
                  icon: storeIcon(s.icon),
                  onPhoto: onPhoto,
                ),
              for (final l in labels)
                _CategoryChip(
                  color: _parseColor(l.color) ?? cs.primary,
                  label: l.name,
                  icon: labelIcon(l.icon),
                  onPhoto: onPhoto,
                ),
            ],
          ),
        if (hasChips) const SizedBox(height: 10),
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

  /// When set, the chip shows this glyph instead of the plain color dot —
  /// used to distinguish store chips from the category chip.
  final IconData? icon;

  const _CategoryChip({
    required this.color,
    required this.label,
    required this.onPhoto,
    this.icon,
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
          if (icon != null)
            Icon(icon, size: 12, color: onPhoto ? Colors.white : color)
          else
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
    // Request the same size as the fullscreen viewer so the cover and the
    // zoom share one cached file — one prefetched image serves both offline.
    final uri = ChecklistService.instance.itemImagePreviewUri(
      houseId,
      fileId,
      owner,
      size: 2048,
    );
    final headers = AuthService.instance.credentials?.basicAuthHeaders ?? {};

    return AvifNetworkImage(
      imageUrl: uri.toString(),
      headers: headers,
      fit: BoxFit.cover,
      errorWidget: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
