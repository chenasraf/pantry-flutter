import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/widgets/create_category_dialog.dart';

/// Sentinel value used for the "Create category" dropdown item.
const int _createCategoryValue = -1;

class CategoryPicker extends StatelessWidget {
  final List<Category> categories;
  final int? selectedId;
  final int houseId;

  /// The list whose scope governs which categories are offered — a list's own
  /// scoped categories plus every global one. Null (the All-lists view) offers
  /// only globals. Ignored on servers without the `category-lists` feature.
  final int? listId;
  final ValueChanged<int?> onChanged;
  final ValueChanged<Category> onCreated;

  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.houseId,
    this.listId,
    required this.onChanged,
    required this.onCreated,
  });

  /// Categories in scope for [listId] under the effective-list rule. A no-op on
  /// servers without `category-lists`, where every category is global.
  List<Category> get _scopedCategories {
    if (!hasFeature('category-lists')) return categories;
    return [
      for (final c in categories)
        if (c.listId == null || (listId != null && c.listId == listId)) c,
    ];
  }

  Color? _parseColor(String hex) {
    if (hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = m.checklists.itemForm;

    return DropdownButtonFormField<int?>(
      initialValue: selectedId,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: [
        DropdownMenuItem<int?>(value: null, child: Text(f.noCategory)),
        ..._scopedCategories.map((cat) {
          final color = _parseColor(cat.color) ?? theme.colorScheme.primary;
          return DropdownMenuItem<int?>(
            value: cat.id,
            child: Row(
              children: [
                Icon(categoryIcon(cat.icon), size: 20, color: color),
                const SizedBox(width: 8),
                Text(cat.name),
              ],
            ),
          );
        }),
        DropdownMenuItem<int?>(
          value: _createCategoryValue,
          child: Row(
            children: [
              Icon(Icons.add, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                f.createCategory,
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        if (value == _createCategoryValue) {
          _showCreateDialog(context);
        } else {
          onChanged(value);
        }
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog<Category>(
      context: context,
      builder: (_) =>
          CreateCategoryDialog(houseId: houseId, defaultListId: listId),
    ).then((created) {
      if (created != null) {
        onCreated(created);
        onChanged(created.id);
      }
    });
  }
}
