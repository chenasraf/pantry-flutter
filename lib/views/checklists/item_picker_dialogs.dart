import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/label.dart';
import 'package:pantry/models/store.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/checklist_icons.dart';
import 'package:pantry/utils/color.dart';
import 'package:pantry/utils/label_icons.dart';
import 'package:pantry/utils/store_icons.dart';

/// Sentinel returned by [pickCategory] for the "No category" choice, so callers
/// can distinguish "clear the category" from a real (positive) category id.
const int kBatchClearCategory = -1;

/// Single-select target-list picker for move/copy. [lists] should already be
/// filtered to the valid targets (the caller excludes the current/home list and
/// the synthetic All-lists entry). Returns the chosen list id, or null on dismiss.
Future<int?> pickTargetList(
  BuildContext context, {
  required String title,
  required List<ChecklistList> lists,
}) {
  return showDialog<int>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(title),
      children: [
        for (final list in lists)
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
}

/// Single-select category picker for set-category. Returns [kBatchClearCategory]
/// for "No category", a positive category id, or null on dismiss.
Future<int?> pickCategory(
  BuildContext context, {
  required List<Category> categories,
}) {
  final cs = Theme.of(context).colorScheme;
  return showDialog<int>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(m.checklists.batch.categoryTitle),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, kBatchClearCategory),
          child: Row(
            children: [
              const Icon(Icons.block, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(m.checklists.batch.clearCategory)),
            ],
          ),
        ),
        for (final cat in categories)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, cat.id),
            child: Row(
              children: [
                Icon(
                  categoryIcon(cat.icon),
                  size: 20,
                  color: parseHexColor(cat.color) ?? cs.primary,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(cat.name)),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Multi-select store picker for set-stores. Returns null on dismiss, or the
/// chosen store ids (an empty list clears the stores on every item). The
/// selection starts empty and replaces whatever the items currently carry.
Future<List<int>?> pickStores(
  BuildContext context, {
  required List<Store> stores,
}) {
  return _pickEntities(
    context,
    title: m.checklists.batch.storesTitle,
    emptyText: m.stores.noStores,
    entries: [
      for (final s in stores)
        _EntityEntry(
          id: s.id,
          name: s.name,
          icon: storeIcon(s.icon),
          colorHex: s.color,
        ),
    ],
  );
}

/// Multi-select label picker for set-labels. Returns null on dismiss, or the
/// chosen label ids (an empty list clears the labels on every item). The
/// selection starts empty and replaces whatever the items currently carry.
Future<List<int>?> pickLabels(
  BuildContext context, {
  required List<Label> labels,
}) {
  return _pickEntities(
    context,
    title: m.checklists.batch.labelsTitle,
    emptyText: m.labels.noLabels,
    entries: [
      for (final l in labels)
        _EntityEntry(
          id: l.id,
          name: l.name,
          icon: labelIcon(l.icon),
          colorHex: l.color,
        ),
    ],
  );
}

class _EntityEntry {
  final int id;
  final String name;
  final IconData icon;
  final String? colorHex;
  const _EntityEntry({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
  });
}

Future<List<int>?> _pickEntities(
  BuildContext context, {
  required String title,
  required String emptyText,
  required List<_EntityEntry> entries,
}) {
  final cs = Theme.of(context).colorScheme;
  final selected = <int>{};
  return showDialog<List<int>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: entries.isEmpty
              ? Text(emptyText)
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final e in entries)
                      CheckboxListTile(
                        value: selected.contains(e.id),
                        onChanged: (v) => setState(() {
                          if (v ?? false) {
                            selected.add(e.id);
                          } else {
                            selected.remove(e.id);
                          }
                        }),
                        secondary: Icon(
                          e.icon,
                          color: parseHexColor(e.colorHex) ?? cs.primary,
                        ),
                        title: Text(e.name),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, selected.toList()),
            child: Text(m.common.save),
          ),
        ],
      ),
    ),
  );
}
