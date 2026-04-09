import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/rrule.dart';
import 'package:pantry/widgets/recurrence_dialog.dart';
import 'checklists_controller.dart';

class ItemFormView extends StatefulWidget {
  final ChecklistsController controller;

  /// If non-null, we're editing this item. Otherwise creating a new one.
  final ListItem? item;

  const ItemFormView({super.key, required this.controller, this.item});

  @override
  State<ItemFormView> createState() => _ItemFormViewState();
}

class _ItemFormViewState extends State<ItemFormView> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  int? _selectedCategoryId;
  String? _rrule;
  bool _repeatFromCompletion = false;
  bool _saving = false;

  bool get _isEditing => widget.item != null;

  List<models.Category> get _categories =>
      widget.controller.categories.values.toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController = TextEditingController();
    _quantityController = TextEditingController(text: item?.quantity ?? '');
    _selectedCategoryId = item?.categoryId;
    _rrule = item?.rrule;
    _repeatFromCompletion = item?.repeatFromCompletion ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        final item = widget.item!;
        await widget.controller.updateItem(
          item,
          name: name,
          description: _descriptionController.text.trim(),
          quantity: _quantityController.text.trim(),
          categoryId: _selectedCategoryId,
          clearCategory: _selectedCategoryId == null && item.categoryId != null,
          rrule: _rrule ?? '',
          repeatFromCompletion: _repeatFromCompletion,
        );
      } else {
        await widget.controller.addItem(
          name: name,
          description: _descriptionController.text.trim(),
          quantity: _quantityController.text.trim(),
          categoryId: _selectedCategoryId,
          rrule: _rrule,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(m.checklists.itemForm.saveFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = m.checklists.itemForm;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? f.editTitle : f.addTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: f.name,
              border: const OutlineInputBorder(),
            ),
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: f.description,
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            minLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: f.quantity,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Text(f.category, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          _CategorySelector(
            categories: _categories,
            selectedId: _selectedCategoryId,
            onChanged: (id) => setState(() => _selectedCategoryId = id),
          ),
          const SizedBox(height: 16),
          _RepeatButton(
            rrule: _rrule,
            onTap: () async {
              final result = await showRecurrenceDialog(
                context,
                initialRrule: _rrule,
                initialRepeatFromCompletion: _repeatFromCompletion,
              );
              if (result != null) {
                setState(() {
                  _rrule = result.rrule;
                  _repeatFromCompletion = result.repeatFromCompletion;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<models.Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  const _CategorySelector({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });

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

    if (categories.isEmpty) {
      return Text(f.noCategories, style: theme.textTheme.bodySmall);
    }

    return DropdownButtonFormField<int?>(
      initialValue: selectedId,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: [
        DropdownMenuItem<int?>(value: null, child: Text(f.noCategory)),
        ...categories.map((cat) {
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
      ],
      onChanged: onChanged,
    );
  }
}

class _RepeatButton extends StatelessWidget {
  final String? rrule;
  final VoidCallback onTap;

  const _RepeatButton({required this.rrule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = rrule != null && rrule!.isNotEmpty;
    final summary = hasValue ? formatRrule(rrule!) : m.recurrence.notSet;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.event_repeat,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              '${m.checklists.itemForm.repeat}: ',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasValue
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
