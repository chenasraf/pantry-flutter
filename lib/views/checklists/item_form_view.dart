import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/widgets/category_picker.dart';
import 'package:pantry/widgets/recurrence_dialog.dart';
import 'package:pantry/widgets/repeat_button.dart';
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
  bool _deleteOnDone = false;
  bool _saving = false;
  TextDirection _nameDir = TextDirection.ltr;
  TextDirection _descriptionDir = TextDirection.ltr;

  bool get _isEditing => widget.item != null;

  List<models.Category> get _categories =>
      widget.controller.categories.values.toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _quantityController = TextEditingController(text: item?.quantity ?? '');
    _selectedCategoryId = item?.categoryId;
    _rrule = item?.rrule;
    _repeatFromCompletion = item?.repeatFromCompletion ?? false;
    _deleteOnDone = item?.deleteOnDone ?? false;
    _nameDir = detectTextDirection(item?.name);
    _nameController.addListener(() {
      final dir = detectTextDirection(_nameController.text);
      if (dir != _nameDir) setState(() => _nameDir = dir);
    });
    _descriptionDir = detectTextDirection(item?.description);
    _descriptionController.addListener(() {
      final dir = detectTextDirection(_descriptionController.text);
      if (dir != _descriptionDir) setState(() => _descriptionDir = dir);
    });
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
      final effectiveRrule = _deleteOnDone ? '' : (_rrule ?? '');
      final effectiveRepeatFromCompletion = _deleteOnDone
          ? false
          : _repeatFromCompletion;
      if (_isEditing) {
        final item = widget.item!;
        await widget.controller.updateItem(
          item,
          name: name,
          description: _descriptionController.text.trim(),
          quantity: _quantityController.text.trim(),
          categoryId: _selectedCategoryId,
          clearCategory: _selectedCategoryId == null && item.categoryId != null,
          rrule: effectiveRrule,
          repeatFromCompletion: effectiveRepeatFromCompletion,
          deleteOnDone: _deleteOnDone,
        );
      } else {
        await widget.controller.addItem(
          name: name,
          description: _descriptionController.text.trim(),
          quantity: _quantityController.text.trim(),
          categoryId: _selectedCategoryId,
          rrule: _deleteOnDone ? null : _rrule,
          deleteOnDone: _deleteOnDone,
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
            textDirection: _nameDir,
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
            textDirection: _descriptionDir,
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
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),
          Text(f.category, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          CategoryPicker(
            categories: _categories,
            selectedId: _selectedCategoryId,
            houseId: widget.controller.houseId,
            onChanged: (id) => setState(() => _selectedCategoryId = id),
            onCreated: (cat) {
              widget.controller.categories[cat.id] = cat;
              setState(() => _selectedCategoryId = cat.id);
            },
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _deleteOnDone,
            onChanged: (v) => setState(() => _deleteOnDone = v ?? false),
            title: Text(f.once),
            subtitle: Text(f.onceDescription),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsetsDirectional.zero,
          ),
          if (!_deleteOnDone) ...[
            const SizedBox(height: 8),
            RepeatButton(
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
        ],
      ),
    );
  }
}
