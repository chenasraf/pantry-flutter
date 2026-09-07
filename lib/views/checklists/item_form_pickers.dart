import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart' as models;
import 'package:pantry_core/models/store.dart' as models;
import 'package:pantry_core/models/label.dart' as models;
import 'package:pantry_core/models/item_lifecycle.dart';
import 'package:pantry_core/utils/category_icons.dart';
import 'package:pantry_core/utils/entity_icons.dart';
import 'package:pantry_core/utils/label_icons.dart';
import 'package:pantry_core/utils/store_icons.dart';
import 'form_components.dart';

class CategoryDropdownRow extends StatelessWidget {
  final models.Category? category;
  final Color? Function(String hex) parseColor;
  final bool open;
  final VoidCallback onTap;

  const CategoryDropdownRow({
    super.key,
    required this.category,
    required this.parseColor,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = m.checklists.itemForm;
    final catColor = category != null
        ? (parseColor(category!.color) ?? cs.primary)
        : cs.onSurfaceVariant;
    final label = category?.name ?? f.noCategory;
    final actionColor = open ? cs.primary : cs.onSurfaceVariant;
    final actionLabel = open ? f.categoryPick : f.categoryChange;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          border: Border.all(
            color: open ? cs.primary : cs.outlineVariant,
            width: open ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: catColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            Text(
              actionLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: actionColor,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: open ? 0.5 : 0,
              child: Icon(
                Icons.keyboard_arrow_down,
                color: actionColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryPickerPanel extends StatelessWidget {
  final List<models.Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelect;
  final Future<void> Function() onCreateRequest;
  final Color? Function(String hex) parseColor;

  const CategoryPickerPanel({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.onCreateRequest,
    required this.parseColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          CategorySwatch(
            label: m.checklists.itemForm.noCategory,
            color: cs.onSurfaceVariant,
            selected: selectedId == null,
            onTap: () => onSelect(null),
          ),
          for (final c in categories)
            CategorySwatch(
              icon: categoryIcon(c.icon),
              label: c.name,
              color: parseColor(c.color) ?? cs.primary,
              selected: selectedId == c.id,
              onTap: () => onSelect(c.id),
            ),
          NewCategoryChipButton(
            color: cs.primary,
            label: m.checklists.itemForm.createCategory,
            onTap: () => onCreateRequest(),
          ),
        ],
      ),
    );
  }
}

/// Collapsed row for the multi-select store picker. Shows a summary of the
/// currently-selected stores (or "None") and toggles the panel open.
class StoreDropdownRow extends StatelessWidget {
  final List<models.Store> stores;
  final Color? Function(String hex) parseColor;
  final bool open;
  final VoidCallback onTap;

  const StoreDropdownRow({
    super.key,
    required this.stores,
    required this.parseColor,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = m.checklists.itemForm;
    final label = stores.isEmpty
        ? f.noStores
        : stores.map((s) => s.name).join(', ');
    final actionColor = open ? cs.primary : cs.onSurfaceVariant;
    final actionLabel = open ? f.storesPick : f.storesChange;
    final leadColor = stores.isNotEmpty
        ? (parseColor(stores.first.color) ?? cs.primary)
        : cs.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          border: Border.all(
            color: open ? cs.primary : cs.outlineVariant,
            width: open ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              stores.isNotEmpty
                  ? storeIcon(stores.first.icon)
                  : EntityIcons.store,
              size: 18,
              color: leadColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            Text(
              actionLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: actionColor,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: open ? 0.5 : 0,
              child: Icon(
                Icons.keyboard_arrow_down,
                color: actionColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-select swatch grid for stores. Tapping a swatch toggles membership
/// and keeps the panel open (unlike the single-select category picker); there
/// is no "None" swatch — an empty selection means no stores.
class StorePickerPanel extends StatelessWidget {
  final List<models.Store> stores;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;
  final Future<void> Function() onCreateRequest;
  final Color? Function(String hex) parseColor;

  const StorePickerPanel({
    super.key,
    required this.stores,
    required this.selectedIds,
    required this.onToggle,
    required this.onCreateRequest,
    required this.parseColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in stores)
            CategorySwatch(
              icon: storeIcon(s.icon),
              label: s.name,
              color: parseColor(s.color) ?? cs.primary,
              selected: selectedIds.contains(s.id),
              onTap: () => onToggle(s.id),
            ),
          NewCategoryChipButton(
            color: cs.primary,
            label: m.checklists.itemForm.createStore,
            onTap: () => onCreateRequest(),
          ),
        ],
      ),
    );
  }
}

/// Collapsed row for the multi-select label picker. Mirrors [StoreDropdownRow]:
/// shows a summary of the currently-selected labels (or "None") and toggles the
/// panel open.
class LabelDropdownRow extends StatelessWidget {
  final List<models.Label> labels;
  final Color? Function(String hex) parseColor;
  final bool open;
  final VoidCallback onTap;

  const LabelDropdownRow({
    super.key,
    required this.labels,
    required this.parseColor,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = m.checklists.itemForm;
    final label = labels.isEmpty
        ? f.noLabels
        : labels.map((l) => l.name).join(', ');
    final actionColor = open ? cs.primary : cs.onSurfaceVariant;
    final actionLabel = open ? f.labelsPick : f.labelsChange;
    final leadColor = labels.isNotEmpty
        ? (parseColor(labels.first.color) ?? cs.primary)
        : cs.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          border: Border.all(
            color: open ? cs.primary : cs.outlineVariant,
            width: open ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              labels.isNotEmpty
                  ? labelIcon(labels.first.icon)
                  : EntityIcons.label,
              size: 18,
              color: leadColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            Text(
              actionLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: actionColor,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: open ? 0.5 : 0,
              child: Icon(
                Icons.keyboard_arrow_down,
                color: actionColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-select swatch grid for labels. Mirrors [StorePickerPanel]: tapping a
/// swatch toggles membership and keeps the panel open; an empty selection means
/// no labels.
class LabelPickerPanel extends StatelessWidget {
  final List<models.Label> labels;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;
  final Future<void> Function() onCreateRequest;
  final Color? Function(String hex) parseColor;

  const LabelPickerPanel({
    super.key,
    required this.labels,
    required this.selectedIds,
    required this.onToggle,
    required this.onCreateRequest,
    required this.parseColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final l in labels)
            CategorySwatch(
              icon: labelIcon(l.icon),
              label: l.name,
              color: parseColor(l.color) ?? cs.primary,
              selected: selectedIds.contains(l.id),
              onTap: () => onToggle(l.id),
            ),
          NewCategoryChipButton(
            color: cs.primary,
            label: m.checklists.itemForm.createLabel,
            onTap: () => onCreateRequest(),
          ),
        ],
      ),
    );
  }
}

class LifecyclePicker extends StatelessWidget {
  final ItemLifecycle value;
  final ValueChanged<ItemLifecycle> onChanged;

  const LifecyclePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = m.checklists.itemTypes;
    return Column(
      children: [
        LifecycleRow(
          label: t.staple,
          body: t.stapleBody,
          selected: value == ItemLifecycle.staple,
          onTap: () => onChanged(ItemLifecycle.staple),
        ),
        const SizedBox(height: 7),
        LifecycleRow(
          label: t.onceTime,
          body: t.onceTimeBody,
          selected: value == ItemLifecycle.once,
          onTap: () => onChanged(ItemLifecycle.once),
        ),
        const SizedBox(height: 7),
        LifecycleRow(
          label: t.recurring,
          body: t.recurringBody,
          selected: value == ItemLifecycle.recurring,
          onTap: () => onChanged(ItemLifecycle.recurring),
        ),
      ],
    );
  }
}
