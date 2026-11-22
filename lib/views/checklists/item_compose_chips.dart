import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart' as models;
import 'package:pantry_core/models/store.dart' as models;
import 'package:pantry_core/models/label.dart' as models;
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/item_lifecycle.dart';
import 'package:pantry_core/models/stock.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/date_format.dart';
import 'package:pantry_core/utils/stock_rules.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry_core/utils/price.dart';
import 'package:pantry_core/utils/label_icons.dart';
import 'package:pantry_core/utils/rrule.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry/theme/app_theme.dart';
import 'item_compose_bar.dart';
import 'item_draft.dart';
import 'stock_cards.dart';

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
  final bool showTypeChip;

  /// Off on inventories, whose Stock chip carries on hand instead.
  final bool showQuantityChip;
  final bool multiple;
  final VoidCallback onToggleMultiple;

  /// Opens the target list's item defaults; `null` hides the button.
  final VoidCallback? onEditDefaults;

  /// A category guessed for the typed name, shown while the draft has none.
  final int? guessedCategoryId;
  final VoidCallback? onDropCategoryGuess;

  /// A quantity read out of the typed name or remembered for it, shown in
  /// place of the draft's own.
  final String? quantityGuess;
  final VoidCallback? onDropQuantityGuess;

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
    this.showTypeChip = true,
    this.showQuantityChip = true,
    this.onEditDefaults,
    this.guessedCategoryId,
    this.onDropCategoryGuess,
    this.quantityGuess,
    this.onDropQuantityGuess,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categoryGuessed =
        draft.categoryId == null && guessedCategoryId != null;
    final categoryId = draft.categoryId ?? guessedCategoryId;
    final cat = categoryId != null
        ? categories.cast<models.Category?>().firstWhere(
            (c) => c!.id == categoryId,
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

    final qtyGuess = quantityGuess;
    final hasQty = qtyGuess != null || draft.quantity.trim().isNotEmpty;
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
            onDrop: categoryGuessed && cat != null ? onDropCategoryGuess : null,
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
          if (showQuantityChip) ...[
            const SizedBox(width: 8),
            _ComposeChip(
              label: hasQty
                  ? (qtyGuess ?? draft.quantity)
                  : m.checklists.compose.chipQuantity,
              color: hasQty ? cs.primary : null,
              icon: Icons.format_list_numbered,
              selected: openTray == Tray.quantity,
              onTap: () => onOpen(Tray.quantity),
              onDrop: qtyGuess != null ? onDropQuantityGuess : null,
            ),
          ] else if (qtyGuess != null) ...[
            // Inventories carry on hand on the Stock chip, so a guessed amount
            // gets a chip of its own that edits through the Stock tray.
            const SizedBox(width: 8),
            _ComposeChip(
              label: qtyGuess,
              color: cs.primary,
              icon: Icons.format_list_numbered,
              selected: false,
              onTap: () => onOpen(Tray.stock),
              onDrop: onDropQuantityGuess,
            ),
          ],
          if (draft.stock case final stock?) ...[
            const SizedBox(width: 8),
            Builder(
              builder: (context) {
                final label = _stockChipLabel(stock);
                return _ComposeChip(
                  label: label ?? m.stock.compose.chip,
                  color: label != null ? cs.primary : null,
                  icon: Icons.inventory_2_outlined,
                  selected: openTray == Tray.stock,
                  onTap: () => onOpen(Tray.stock),
                );
              },
            ),
            const SizedBox(width: 8),
            Builder(
              builder: (context) {
                final label = _expiryChipLabel(stock);
                return _ComposeChip(
                  label: label ?? m.stock.expiry.chip,
                  color: label != null ? cs.primary : null,
                  icon: Icons.event_outlined,
                  selected: openTray == Tray.expiry,
                  onTap: () => onOpen(Tray.expiry),
                );
              },
            ),
          ],
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
              icon: Icons.list_alt,
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
          if (showTypeChip) ...[
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
          ],
          if (showImageChip) ...[
            const SizedBox(width: 8),
            _ComposeChip(
              label: draft.hasImage ? '✓' : m.checklists.compose.chipImage,
              color: draft.hasImage ? cs.primary : null,
              icon: Icons.image_outlined,
              selected: openTray == Tray.image,
              onTap: () => onOpen(Tray.image),
            ),
          ],
          if (onEditDefaults != null) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: m.checklists.itemDefaults.edit,
              icon: const Icon(Icons.tune),
              color: cs.onSurfaceVariant,
              visualDensity: VisualDensity.compact,
              onPressed: onEditDefaults,
            ),
          ],
        ],
      ),
    );
  }

  /// What the Stock chip shows once something is set, or null while it is
  /// still the bare "Stock".
  static String? _stockChipLabel(StockDraft stock) {
    final target = (stock.target ?? '').trim();
    final onHand = (stock.quantity ?? '').trim();
    switch (stock.mode) {
      case null:
        return target.isEmpty ? null : m.stock.compose.targetValue(target);
      case StockMode.level:
        if (stock.template || onHand.isEmpty) return m.stock.compose.level;
        return m.stock.compose.levelAmount(onHand);
      case StockMode.count:
        if (stock.template) {
          return target.isEmpty
              ? m.stock.compose.count
              : m.stock.compose.targetValue(target);
        }
        if (onHand.isNotEmpty && target.isNotEmpty) {
          return m.stock.amount(onHand, target);
        }
        if (target.isNotEmpty) return m.stock.compose.targetValue(target);
        return onHand.isEmpty ? null : onHand;
    }
  }

  static String? _expiryChipLabel(StockDraft stock) {
    switch (stock.expiryMode) {
      case ExpiryMode.none:
        return null;
      case ExpiryMode.date:
        final date = stock.expiresAt;
        if (date == null) return null;
        final formatted = formatShortDate(date);
        return daysUntil(date, todayEpoch()) < 0
            ? m.stock.expiry.chipExpired(formatted)
            : m.stock.expiry.chipExpires(formatted);
      case ExpiryMode.keeps:
        final days = stock.shelfLifeDays;
        return days == null ? null : m.stock.expiry.chipKeeps(days);
    }
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

  /// Set while the chip shows a guess rather than a value the person chose;
  /// the chip then carries a ✕ that drops the guess.
  final VoidCallback? onDrop;

  const _ComposeChip({
    required this.label,
    this.color,
    this.icon,
    this.leading,
    required this.selected,
    required this.onTap,
    this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = color ?? cs.onSurfaceVariant;
    final isSet = color != null;
    final surfaces = AppSurfaces.of(context);
    final chip = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SurfaceRadius.chip),
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(
          12,
          7,
          onDrop != null ? 4 : 12,
          7,
        ),
        decoration: isSet
            ? surfaces.chip(tint: accent, selected: selected)
            : surfaces.chip(selected: selected),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDrop != null) ...[
              Icon(Icons.auto_awesome, size: 12, color: accent),
              const SizedBox(width: 5),
            ],
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 6),
            ] else if (icon != null && onDrop == null) ...[
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSet && onDrop == null
                    ? FontWeight.w700
                    : FontWeight.w600,
                color: accent,
              ),
            ),
            if (onDrop != null) GuessDropButton(color: accent, onTap: onDrop!),
          ],
        ),
      ),
    );
    if (onDrop == null) return chip;
    return Tooltip(
      message: m.checklists.compose.suggested,
      waitDuration: const Duration(milliseconds: 600),
      child: chip,
    );
  }
}

/// The ✕ on a guessed value, which drops the guess.
class GuessDropButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const GuessDropButton({super.key, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: m.checklists.compose.dropSuggestion,
      waitDuration: const Duration(milliseconds: 600),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: Icon(Icons.close, size: 14, color: color),
        ),
      ),
    );
  }
}

/// A guessed value on a review row: the guess in its accent, with a ✕ that
/// drops it.
class GuessChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Widget? leading;
  final VoidCallback onDrop;

  const GuessChip({
    super.key,
    required this.label,
    this.color,
    this.leading,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: m.checklists.compose.suggested,
      waitDuration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 3, 4, 3),
        decoration: AppSurfaces.of(context).chip(tint: accent),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 11, color: accent),
            const SizedBox(width: 4),
            if (leading != null) ...[leading!, const SizedBox(width: 4)],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
            GuessDropButton(color: accent, onTap: onDrop),
          ],
        ),
      ),
    );
  }
}

/// One item of a batch being added, as its typed line reads: the name, with
/// the guessed quantity and category as chips that can be dropped.
class ItemGuessRow extends StatelessWidget {
  final String name;
  final String? quantityGuess;
  final VoidCallback? onDropQuantity;
  final models.Category? categoryGuess;
  final VoidCallback? onDropCategory;

  final EdgeInsetsGeometry padding;

  const ItemGuessRow({
    super.key,
    required this.name,
    this.quantityGuess,
    this.onDropQuantity,
    this.categoryGuess,
    this.onDropCategory,
    this.padding = const EdgeInsetsDirectional.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final category = categoryGuess;
    final categoryColor = category == null
        ? null
        : (parseHexColor(category.color) ?? cs.primary);
    return Padding(
      padding: padding,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(name, style: TextStyle(fontSize: 14, color: cs.onSurface)),
          if (quantityGuess != null && onDropQuantity != null)
            GuessChip(label: quantityGuess!, onDrop: onDropQuantity!),
          if (category != null && onDropCategory != null)
            GuessChip(
              label: category.name,
              color: categoryColor,
              leading: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              onDrop: onDropCategory!,
            ),
        ],
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
        borderRadius: BorderRadius.circular(SurfaceRadius.chip),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: 30,
          padding: EdgeInsetsDirectional.symmetric(horizontal: hasList ? 9 : 8),
          decoration: hasList
              ? AppSurfaces.of(
                  context,
                ).chip(tint: accent, selected: highlighted)
              : AppSurfaces.of(context).chip(selected: highlighted),
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
