import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/store.dart' as models;
import 'package:pantry/models/label.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/checklist_icons.dart';
import 'package:pantry/utils/color.dart';
import 'package:pantry/utils/entity_icons.dart';
import 'package:pantry/utils/label_icons.dart';
import 'package:pantry/utils/price.dart';
import 'package:pantry/utils/store_icons.dart';
import 'package:pantry/widgets/entity_icon.dart';
import 'checklists_price_filter.dart';
import 'checklists_view_toggle.dart';

class ChecklistsSearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const ChecklistsSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
      child: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: m.checklists.searchHint,
          prefixIcon: const Icon(Icons.search, size: 20),
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

/// The filter header above the item list: a category filter, plus — in the
/// All-lists view — a parallel per-list filter. Desktop stacks both filters
/// in their own rows; mobile shows one at a time and lets the user swap which
/// fills the row via a pair of icon buttons, keeping the header compact.
class ChecklistsFiltersSection extends StatefulWidget {
  final List<models.Category> categories;
  final Set<int> selectedCategoryIds;
  final ValueChanged<int> onToggleCategory;
  final VoidCallback onClearCategories;

  /// Whether the "No category" chip (items with no category) is offered.
  final bool showNoCategory;
  final bool noCategorySelected;
  final VoidCallback onToggleNoCategory;

  /// All-lists view only — when false, no list filter is shown at all.
  final bool showListFilter;
  final List<ChecklistList> lists;
  final Set<int> selectedListIds;
  final ValueChanged<int> onToggleList;
  final VoidCallback onClearLists;

  /// Store filter — gated on the `stores` capability and only shown when at
  /// least one item on the list carries (or lacks) a store.
  final bool showStoreFilter;
  final List<models.Store> stores;
  final Set<int> selectedStoreIds;
  final ValueChanged<int> onToggleStore;
  final VoidCallback onClearStores;
  final bool showNoStore;
  final bool noStoreSelected;
  final VoidCallback onToggleNoStore;

  /// Label filter — gated on the `labels` capability and only shown when at
  /// least one item on the list carries (or lacks) a label. OR semantics.
  final bool showLabelFilter;
  final List<models.Label> labels;
  final Set<int> selectedLabelIds;
  final ValueChanged<int> onToggleLabel;
  final VoidCallback onClearLabels;
  final bool showNoLabel;
  final bool noLabelSelected;
  final VoidCallback onToggleNoLabel;

  /// Price filter — gated on the `item-price` capability and only shown when at
  /// least one item on the list carries a price.
  final bool showPriceFilter;
  final PriceFilter priceFilter;
  final ValueChanged<PriceFilter> onPriceFilterChanged;

  final String view;
  final ValueChanged<String> onViewChanged;

  const ChecklistsFiltersSection({
    super.key,
    required this.categories,
    required this.selectedCategoryIds,
    required this.onToggleCategory,
    required this.onClearCategories,
    required this.showNoCategory,
    required this.noCategorySelected,
    required this.onToggleNoCategory,
    required this.showListFilter,
    required this.lists,
    required this.selectedListIds,
    required this.onToggleList,
    required this.onClearLists,
    required this.showStoreFilter,
    required this.stores,
    required this.selectedStoreIds,
    required this.onToggleStore,
    required this.onClearStores,
    required this.showNoStore,
    required this.noStoreSelected,
    required this.onToggleNoStore,
    required this.showLabelFilter,
    required this.labels,
    required this.selectedLabelIds,
    required this.onToggleLabel,
    required this.onClearLabels,
    required this.showNoLabel,
    required this.noLabelSelected,
    required this.onToggleNoLabel,
    required this.showPriceFilter,
    required this.priceFilter,
    required this.onPriceFilterChanged,
    required this.view,
    required this.onViewChanged,
  });

  @override
  State<ChecklistsFiltersSection> createState() =>
      _ChecklistsFiltersSectionState();
}

class _ChecklistsFiltersSectionState extends State<ChecklistsFiltersSection> {
  _FilterDropdown _listDropdown(ColorScheme cs) {
    return _FilterDropdown(
      label: m.checklists.filters.lists,
      icon: allListsIcon,
      selectedCount: widget.selectedListIds.length,
      entries: [
        _FilterMenuEntry(
          label: m.checklists.filters.allLists,
          color: cs.primary,
          icon: Icons.done_all,
          selected: widget.selectedListIds.isEmpty,
          onTap: widget.onClearLists,
        ),
        for (final l in widget.lists)
          _FilterMenuEntry(
            label: l.name,
            color: parseHexColor(l.color) ?? cs.primary,
            icon: checklistIcon(l.icon),
            selected: widget.selectedListIds.contains(l.id),
            onTap: () => widget.onToggleList(l.id),
          ),
      ],
    );
  }

  _FilterDropdown _categoryDropdown(ColorScheme cs) {
    final count =
        widget.selectedCategoryIds.length + (widget.noCategorySelected ? 1 : 0);
    return _FilterDropdown(
      label: m.checklists.filters.categories,
      icon: EntityIcons.category,
      selectedCount: count,
      entries: [
        _FilterMenuEntry(
          label: m.checklists.filters.allCategories,
          color: cs.primary,
          icon: Icons.done_all,
          selected: count == 0,
          onTap: widget.onClearCategories,
        ),
        for (final c in widget.categories)
          _FilterMenuEntry(
            label: c.name,
            color: parseHexColor(c.color) ?? cs.primary,
            icon: categoryIcon(c.icon),
            selected: widget.selectedCategoryIds.contains(c.id),
            onTap: () => widget.onToggleCategory(c.id),
          ),
        if (widget.showNoCategory)
          _FilterMenuEntry(
            label: m.checklists.filters.noCategory,
            color: cs.outline,
            icon: EntityIcons.category,
            off: true,
            selected: widget.noCategorySelected,
            onTap: widget.onToggleNoCategory,
          ),
      ],
    );
  }

  _FilterDropdown _storeDropdown(ColorScheme cs) {
    final count =
        widget.selectedStoreIds.length + (widget.noStoreSelected ? 1 : 0);
    return _FilterDropdown(
      label: m.checklists.filters.stores,
      icon: EntityIcons.store,
      selectedCount: count,
      entries: [
        _FilterMenuEntry(
          label: m.checklists.filters.allStores,
          color: cs.primary,
          icon: Icons.done_all,
          selected: count == 0,
          onTap: widget.onClearStores,
        ),
        for (final s in widget.stores)
          _FilterMenuEntry(
            label: s.name,
            color: parseHexColor(s.color) ?? cs.primary,
            icon: storeIcon(s.icon),
            selected: widget.selectedStoreIds.contains(s.id),
            onTap: () => widget.onToggleStore(s.id),
          ),
        if (widget.showNoStore)
          _FilterMenuEntry(
            label: m.checklists.filters.noStores,
            color: cs.outline,
            icon: EntityIcons.store,
            off: true,
            selected: widget.noStoreSelected,
            onTap: widget.onToggleNoStore,
          ),
      ],
    );
  }

  _FilterDropdown _labelDropdown(ColorScheme cs) {
    final count =
        widget.selectedLabelIds.length + (widget.noLabelSelected ? 1 : 0);
    return _FilterDropdown(
      label: m.checklists.filters.labels,
      icon: EntityIcons.label,
      selectedCount: count,
      entries: [
        _FilterMenuEntry(
          label: m.checklists.filters.allLabels,
          color: cs.primary,
          icon: Icons.done_all,
          selected: count == 0,
          onTap: widget.onClearLabels,
        ),
        for (final l in widget.labels)
          _FilterMenuEntry(
            label: l.name,
            color: parseHexColor(l.color) ?? cs.primary,
            icon: labelIcon(l.icon),
            selected: widget.selectedLabelIds.contains(l.id),
            onTap: () => widget.onToggleLabel(l.id),
          ),
        if (widget.showNoLabel)
          _FilterMenuEntry(
            label: m.checklists.filters.noLabels,
            color: cs.outline,
            icon: EntityIcons.label,
            off: true,
            selected: widget.noLabelSelected,
            onTap: widget.onToggleNoLabel,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // One multi-select dropdown per active filter dimension, laid out in a
    // horizontally-scrollable row so the same layout serves mobile and desktop
    // no matter how many dimensions are present.
    final buttons = <Widget>[
      if (widget.showListFilter) _listDropdown(cs),
      _categoryDropdown(cs),
      if (widget.showStoreFilter) _storeDropdown(cs),
      if (widget.showLabelFilter) _labelDropdown(cs),
      if (widget.showPriceFilter)
        ChecklistsPriceFilterDropdown(
          value: widget.priceFilter,
          onChanged: widget.onPriceFilterChanged,
        ),
    ];

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 15, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < buttons.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      buttons[i],
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ChecklistsViewToggle(
            view: widget.view,
            onChanged: widget.onViewChanged,
          ),
        ],
      ),
    );
  }
}

/// A single option row inside a [_FilterDropdown] menu. [onTap] toggles the
/// value and — by design — does NOT close the menu, so several values can be
/// picked in one pass.
class _FilterMenuEntry {
  final String label;
  final Color color;
  final IconData icon;
  final bool off;
  final bool selected;
  final VoidCallback onTap;

  const _FilterMenuEntry({
    required this.label,
    required this.color,
    required this.icon,
    this.off = false,
    required this.selected,
    required this.onTap,
  });
}

/// A filter dimension rendered as a dropdown button that opens a multi-select
/// menu. Selecting an option toggles it in place without dismissing the menu
/// (see [_FilterMenuEntry]); the menu closes on an outside tap. The button
/// summarises the current selection as "Label · N" when anything is chosen.
class _FilterDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final int selectedCount;
  final List<_FilterMenuEntry> entries;

  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.selectedCount,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = selectedCount > 0;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(3),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 6),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      menuChildren: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 210,
            maxWidth: 300,
            maxHeight: 340,
          ),
          // Own controller (not the app's PrimaryScrollController): the menu
          // panel MenuAnchor wraps this in already claims the primary
          // controller, and a second primary ScrollPosition trips the menu's
          // Scrollbar assertion when the dropdown opens.
          child: SingleChildScrollView(
            primary: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [for (final e in entries) _FilterMenuRow(entry: e)],
            ),
          ),
        ),
      ],
      builder: (context, controller, _) => ChecklistsFilterButton(
        label: active ? '$label · $selectedCount' : label,
        icon: icon,
        active: active,
        open: controller.isOpen,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _FilterMenuRow extends StatelessWidget {
  final _FilterMenuEntry entry;

  const _FilterMenuRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: entry.onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 14, 11),
        child: Row(
          children: [
            EntityIcon(
              entry.icon,
              off: entry.off,
              size: 17,
              color: entry.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Icon(
              entry.selected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 18,
              color: entry.selected ? cs.primary : cs.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// The tappable pill that opens a [_FilterDropdown]. Tinted with the accent
/// when a selection is applied.
class ChecklistsFilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool open;
  final VoidCallback onTap;

  const ChecklistsFilterButton({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = active ? cs.onPrimary : cs.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36,
        padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
        decoration: BoxDecoration(
          color: active ? cs.primary : cs.surfaceContainerHighest,
          border: Border.all(color: active ? cs.primary : cs.outlineVariant),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            const SizedBox(width: 1),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.keyboard_arrow_down, size: 18, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
