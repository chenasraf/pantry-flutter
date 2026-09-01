import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/store.dart' as models;
import 'package:pantry/models/label.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/item_lifecycle.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/checklist_icons.dart';
import 'package:pantry/utils/store_icons.dart';
import 'package:pantry/utils/label_icons.dart';
import 'package:pantry/utils/color.dart';
import 'package:pantry/widgets/avif_image.dart';
import 'package:pantry/widgets/markdown_editor.dart';
import 'form_components.dart';
import 'item_draft.dart';
import 'price_input.dart';

class _TrayShell extends StatelessWidget {
  final String label;
  final Widget child;

  const _TrayShell({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class TargetListTray extends StatelessWidget {
  final List<ChecklistList> lists;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  const TargetListTray({
    super.key,
    required this.lists,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _TrayShell(
      label: m.checklists.pickListTitle,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final list in lists)
            _TargetListChip(
              list: list,
              selected: list.id == selectedId,
              accent: parseHexColor(list.color) ?? cs.primary,
              onTap: () => onSelected(list.id),
            ),
        ],
      ),
    );
  }
}

class _TargetListChip extends StatelessWidget {
  final ChecklistList list;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _TargetListChip({
    required this.list,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : cs.surfaceContainerHighest,
          border: Border.all(
            color: selected ? accent : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(checklistIcon(list.icon), size: 16, color: accent),
            const SizedBox(width: 8),
            Text(
              list.name,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected ? accent : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryTray extends StatelessWidget {
  final List<models.Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;
  final Future<void> Function()? onRequestCreate;

  const CategoryTray({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    this.onRequestCreate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _TrayShell(
      label: m.checklists.compose.chipCategory,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          CategorySwatch(
            label: m.checklists.compose.none,
            color: cs.onSurfaceVariant,
            selected: selectedId == null,
            onTap: () => onSelected(null),
          ),
          for (final c in categories)
            CategorySwatch(
              icon: categoryIcon(c.icon),
              label: c.name,
              color: _parseColor(c.color) ?? cs.primary,
              selected: selectedId == c.id,
              onTap: () => onSelected(c.id),
            ),
          if (onRequestCreate != null)
            NewCategoryChipButton(
              color: cs.primary,
              label: m.checklists.itemForm.createCategory,
              onTap: () => onRequestCreate!(),
            ),
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

/// Multi-select store tray: tapping a swatch toggles membership and keeps the
/// tray open. No "None" swatch — an empty selection means no stores.
class StoreTray extends StatelessWidget {
  final List<models.Store> stores;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;
  final Future<void> Function()? onRequestCreate;

  const StoreTray({
    super.key,
    required this.stores,
    required this.selectedIds,
    required this.onToggle,
    this.onRequestCreate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _TrayShell(
      label: m.checklists.compose.chipStore,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in stores)
            CategorySwatch(
              icon: storeIcon(s.icon),
              label: s.name,
              color: parseHexColor(s.color) ?? cs.primary,
              selected: selectedIds.contains(s.id),
              onTap: () => onToggle(s.id),
            ),
          if (onRequestCreate != null)
            NewCategoryChipButton(
              color: cs.primary,
              label: m.checklists.itemForm.createStore,
              onTap: () => onRequestCreate!(),
            ),
        ],
      ),
    );
  }
}

/// Multi-select label tray: tapping a swatch toggles membership and keeps the
/// tray open. No "None" swatch — an empty selection means no labels. Mirrors
/// [StoreTray].
class LabelTray extends StatelessWidget {
  final List<models.Label> labels;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;
  final Future<void> Function()? onRequestCreate;

  const LabelTray({
    super.key,
    required this.labels,
    required this.selectedIds,
    required this.onToggle,
    this.onRequestCreate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _TrayShell(
      label: m.checklists.compose.chipLabel,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final l in labels)
            CategorySwatch(
              icon: labelIcon(l.icon),
              label: l.name,
              color: parseHexColor(l.color) ?? cs.primary,
              selected: selectedIds.contains(l.id),
              onTap: () => onToggle(l.id),
            ),
          if (onRequestCreate != null)
            NewCategoryChipButton(
              color: cs.primary,
              label: m.checklists.itemForm.createLabel,
              onTap: () => onRequestCreate!(),
            ),
        ],
      ),
    );
  }
}

class QuantityTray extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const QuantityTray({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _TrayShell(
      label: m.checklists.compose.chipQuantity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FormStepperButton(icon: Icons.remove, onTap: onMinus),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    hintText: m.checklists.compose.qtyHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    // Trailing clear button — appears only when there's a
                    // value, and also clears the parent's draft via
                    // onChanged('') so the chip label resets to "Quantity".
                    suffixIcon: ListenableBuilder(
                      listenable: controller,
                      builder: (_, _) {
                        if (controller.text.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: m.common.delete,
                          splashRadius: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () {
                            controller.clear();
                            onChanged('');
                          },
                        );
                      },
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FormStepperButton(icon: Icons.add, accent: true, onTap: onPlus),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            m.checklists.compose.qtyStepperHelp,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class PriceTray extends StatelessWidget {
  final PricesDraft draft;
  final List<models.Store> stores;
  final bool perStoreEnabled;
  final VoidCallback onChanged;

  const PriceTray({
    super.key,
    required this.draft,
    required this.stores,
    required this.perStoreEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _TrayShell(
      label: m.checklists.price.label,
      child: ItemPricesEditor(
        draft: draft,
        stores: stores,
        perStoreEnabled: perStoreEnabled,
        onChanged: onChanged,
      ),
    );
  }
}

class DescriptionTray extends StatelessWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const DescriptionTray({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _TrayShell(
      label: m.checklists.compose.chipDescription,
      child: MarkdownEditor(
        initialValue: initialValue,
        onChanged: onChanged,
        placeholder: m.checklists.compose.descHint,
        minHeight: 84,
        maxHeight: 220,
      ),
    );
  }
}

class TypeTray extends StatelessWidget {
  final ItemDraft draft;
  final VoidCallback onChanged;

  const TypeTray({super.key, required this.draft, required this.onChanged});

  void _set(ItemLifecycle lc) {
    draft.lifecycle = lc;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final t = m.checklists.itemTypes;
    return _TrayShell(
      label: t.label,
      child: Column(
        children: [
          LifecycleRow(
            label: t.staple,
            body: t.stapleBody,
            selected: draft.lifecycle == ItemLifecycle.staple,
            onTap: () => _set(ItemLifecycle.staple),
          ),
          const SizedBox(height: 7),
          LifecycleRow(
            label: t.onceTime,
            body: t.onceTimeBody,
            selected: draft.lifecycle == ItemLifecycle.once,
            onTap: () => _set(ItemLifecycle.once),
          ),
          const SizedBox(height: 7),
          LifecycleRow(
            label: t.recurring,
            body: t.recurringBody,
            selected: draft.lifecycle == ItemLifecycle.recurring,
            onTap: () => _set(ItemLifecycle.recurring),
          ),
          if (draft.lifecycle == ItemLifecycle.recurring) ...[
            const SizedBox(height: 12),
            RecurrenceInline(state: draft.recurrence, onChanged: onChanged),
          ],
        ],
      ),
    );
  }
}

class ImageTray extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const ImageTray({
    super.key,
    required this.bytes,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _TrayShell(
      label: m.checklists.compose.chipImage,
      child: bytes == null
          ? OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(m.checklists.itemForm.addImage),
            )
          : Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AvifMemoryImage(
                    bytes!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onPick,
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: Text(m.checklists.itemForm.replaceImage),
                      ),
                      OutlinedButton.icon(
                        onPressed: onRemove,
                        icon: const Icon(Icons.close, size: 16),
                        label: Text(m.checklists.itemForm.removeImage),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
