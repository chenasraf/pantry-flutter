import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart' as models;
import 'package:pantry_core/models/store.dart' as models;
import 'package:pantry_core/models/label.dart' as models;
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/item_lifecycle.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry_core/utils/price.dart';
import 'package:pantry_core/utils/label_icons.dart';
import 'package:pantry_core/utils/rrule.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'item_compose_bar.dart';
import 'item_draft.dart';

class ChipRow extends StatelessWidget {
  final ItemDraft draft;
  final List<models.Category> categories;
  final List<models.Store> stores;
  final List<models.Label> labels;
  final bool showStoreChip;
  final bool showLabelChip;
  final bool showPriceChip;
  final bool showCustomFieldsChip;
  final bool customFieldsSet;
  final Tray? openTray;
  final ValueChanged<Tray> onOpen;
  final bool showImageChip;
  final bool multiple;
  final VoidCallback onToggleMultiple;

  const ChipRow({
    super.key,
    required this.draft,
    required this.categories,
    required this.stores,
    required this.labels,
    required this.showStoreChip,
    required this.showLabelChip,
    required this.showPriceChip,
    required this.showCustomFieldsChip,
    required this.customFieldsSet,
    required this.openTray,
    required this.onOpen,
    required this.multiple,
    required this.onToggleMultiple,
    this.showImageChip = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cat = draft.categoryId != null
        ? categories.cast<models.Category?>().firstWhere(
            (c) => c!.id == draft.categoryId,
            orElse: () => null,
          )
        : null;
    final catColor = cat != null
        ? (_parseColor(cat.color) ?? cs.primary)
        : cs.onSurfaceVariant;

    final selectedStores = [
      for (final s in stores)
        if (draft.storeIds.contains(s.id)) s,
    ];
    final hasStores = selectedStores.isNotEmpty;
    final storeColor = hasStores
        ? (parseHexColor(selectedStores.first.color) ?? cs.primary)
        : cs.onSurfaceVariant;
    final storeLabel = !hasStores
        ? m.checklists.compose.chipStore
        : selectedStores.length == 1
        ? selectedStores.first.name
        : '${selectedStores.first.name} +${selectedStores.length - 1}';

    final selectedLabels = [
      for (final l in labels)
        if (draft.labelIds.contains(l.id)) l,
    ];
    final hasLabels = selectedLabels.isNotEmpty;
    final labelColor = hasLabels
        ? (parseHexColor(selectedLabels.first.color) ?? cs.primary)
        : cs.onSurfaceVariant;
    final labelLabel = !hasLabels
        ? m.checklists.compose.chipLabel
        : selectedLabels.length == 1
        ? selectedLabels.first.name
        : '${selectedLabels.first.name} +${selectedLabels.length - 1}';

    final hasQty = draft.quantity.trim().isNotEmpty;
    final hasDesc = draft.description.trim().isNotEmpty;
    final hasType = draft.lifecycle != ItemLifecycle.staple;
    final hasPrice = draft.price.hasAnyPrice;
    final storeless = draft.price.storeless;
    // Chip previews the store-less price when set; otherwise it just reflects
    // the "has any price" accent state with the plain label.
    final priceLabel = hasPrice
        ? (formatPrice(
                priceType: storeless.priceType,
                priceMin: storeless.priceMin,
                priceMax: storeless.priceMax,
                priceCurrency: storeless.priceCurrency,
              ) ??
              m.checklists.price.label)
        : m.checklists.price.label;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Center(
            child: MultipleToggle(active: multiple, onTap: onToggleMultiple),
          ),
          const SizedBox(width: 8),
          _ComposeChip(
            label: cat?.name ?? m.checklists.compose.chipCategory,
            color: cat != null ? catColor : null,
            icon: cat != null ? null : EntityIcons.category,
            leading: cat != null
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: catColor,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
            selected: openTray == Tray.category,
            onTap: () => onOpen(Tray.category),
          ),
          if (showStoreChip) ...[
            const SizedBox(width: 8),
            _ComposeChip(
              label: storeLabel,
              color: hasStores ? storeColor : null,
              icon: hasStores ? null : EntityIcons.store,
              leading: hasStores
                  ? Icon(
                      storeIcon(selectedStores.first.icon),
                      size: 14,
                      color: storeColor,
                    )
                  : null,
              selected: openTray == Tray.store,
              onTap: () => onOpen(Tray.store),
            ),
          ],
          if (showLabelChip) ...[
            const SizedBox(width: 8),
            _ComposeChip(
              label: labelLabel,
              color: hasLabels ? labelColor : null,
              icon: hasLabels ? null : EntityIcons.label,
              leading: hasLabels
                  ? Icon(
                      labelIcon(selectedLabels.first.icon),
                      size: 14,
                      color: labelColor,
                    )
                  : null,
              selected: openTray == Tray.label,
              onTap: () => onOpen(Tray.label),
            ),
          ],
          const SizedBox(width: 8),
          _ComposeChip(
            label: hasQty ? draft.quantity : m.checklists.compose.chipQuantity,
            color: hasQty ? cs.primary : null,
            icon: Icons.format_list_numbered,
            selected: openTray == Tray.quantity,
            onTap: () => onOpen(Tray.quantity),
          ),
          if (showPriceChip) ...[
            const SizedBox(width: 8),
            _ComposeChip(
              label: priceLabel,
              color: hasPrice ? cs.primary : null,
              icon: EntityIcons.price,
              selected: openTray == Tray.price,
              onTap: () => onOpen(Tray.price),
            ),
          ],
          if (showCustomFieldsChip) ...[
            const SizedBox(width: 8),
            _ComposeChip(
              label: m.customFields.manageTitle,
              color: customFieldsSet ? cs.primary : null,
              icon: Icons.tune,
              selected: openTray == Tray.customFields,
              onTap: () => onOpen(Tray.customFields),
            ),
          ],
          const SizedBox(width: 8),
          // Description label is intentionally static even when set —
          // descriptions are typically long, so the chip only flips its
          // accent state instead of trying to preview the text.
          _ComposeChip(
            label: m.checklists.compose.chipDescription,
            color: hasDesc ? cs.primary : null,
            icon: Icons.notes_outlined,
            selected: openTray == Tray.description,
            onTap: () => onOpen(Tray.description),
          ),
          const SizedBox(width: 8),
          _ComposeChip(
            label: hasType
                ? _typeChipLabel(draft)
                : m.checklists.compose.chipType,
            color: hasType ? cs.primary : null,
            icon: Icons.cached,
            selected: openTray == Tray.type,
            onTap: () => onOpen(Tray.type),
          ),
          if (showImageChip) ...[
            const SizedBox(width: 8),
            _ComposeChip(
              label: draft.imageBytes != null
                  ? '✓'
                  : m.checklists.compose.chipImage,
              color: draft.imageBytes != null ? cs.primary : null,
              icon: Icons.image_outlined,
              selected: openTray == Tray.image,
              onTap: () => onOpen(Tray.image),
            ),
          ],
        ],
      ),
    );
  }

  static String _typeChipLabel(ItemDraft d) {
    switch (d.lifecycle) {
      case ItemLifecycle.staple:
        return m.checklists.itemTypes.staple;
      case ItemLifecycle.once:
        return m.checklists.itemTypes.onceTime;
      case ItemLifecycle.recurring:
        final r = d.rrule;
        if (r == null) return m.checklists.itemTypes.recurring;
        return formatRrule(r);
    }
  }

  static Color? _parseColor(String hex) {
    if (hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : null;
  }
}

class _ComposeChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  const _ComposeChip({
    required this.label,
    this.color,
    this.icon,
    this.leading,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = color ?? cs.onSurfaceVariant;
    final isSet = color != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSet
              ? accent.withValues(alpha: 0.14)
              : cs.surfaceContainerHighest,
          border: Border.all(
            color: isSet
                ? accent.withValues(alpha: 0.4)
                : (selected ? cs.primary : cs.outlineVariant),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSet ? FontWeight.w700 : FontWeight.w600,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Leading chip in the input bar (All-lists mode only) that opens the
/// target-list picker. When no list is selected yet it reads as an outlined
/// "Pick a list" affordance; once a list is chosen it switches to the list's
/// color + icon. Tap surface matches the size of the resting "+" tile so the
/// input field's baseline doesn't shift between modes.
class BarTargetChip extends StatelessWidget {
  final ChecklistList? list;
  final bool highlighted;
  final VoidCallback onTap;

  const BarTargetChip({
    super.key,
    required this.list,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasList = list != null;
    final accent = hasList
        ? (parseHexColor(list!.color) ?? cs.primary)
        : cs.onSurfaceVariant;
    final tooltip = hasList ? list!.name : m.checklists.compose.pickTargetList;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: 30,
          padding: EdgeInsetsDirectional.symmetric(horizontal: hasList ? 9 : 8),
          decoration: BoxDecoration(
            color: hasList
                ? accent.withValues(alpha: 0.14)
                : Colors.transparent,
            border: Border.all(
              color: hasList
                  ? accent.withValues(alpha: 0.4)
                  : (highlighted ? cs.primary : cs.outlineVariant),
              width: highlighted ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasList
                    ? checklistIcon(list!.icon)
                    : Icons.playlist_add_outlined,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: Text(
                  hasList ? list!.name : m.checklists.compose.pickTargetList,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: hasList ? FontWeight.w700 : FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
