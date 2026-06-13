import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';
import 'package:pantry/widgets/category_picker.dart';
import 'package:pantry/utils/rrule.dart';
import 'package:pantry/widgets/recurrence_dialog.dart';
import 'package:pantry/widgets/repeat_button.dart';
import 'checklist_item_tile.dart' show ItemLifecycle, lifecycleOf;
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
  late ItemLifecycle _lifecycle;
  bool _saving = false;
  TextDirection _nameDir = TextDirection.ltr;
  TextDirection _descriptionDir = TextDirection.ltr;
  XFile? _pickedImage;
  bool _removeExistingImage = false;

  bool get _isEditing => widget.item != null;
  bool get _hasExistingImage =>
      widget.item?.imageFileId != null && !_removeExistingImage;

  List<models.Category> get _categories => widget.controller.sortedCategories;

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
    if (item != null) {
      _lifecycle = lifecycleOf(item);
    } else {
      _lifecycle = (widget.controller.currentList?.deleteOnDoneDefault ?? false)
          ? ItemLifecycle.once
          : ItemLifecycle.staple;
    }
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

  void _setLifecycle(ItemLifecycle next) {
    if (next == _lifecycle) return;
    setState(() {
      _lifecycle = next;
      // Seed a sensible default rrule when entering recurring with none set,
      // so the user can submit immediately without opening the schedule
      // dialog — same default the compose bar uses (weekly, every 1 week).
      if (next == ItemLifecycle.recurring &&
          (_rrule == null || _rrule!.isEmpty)) {
        _rrule = buildRrule(freq: 'WEEKLY');
      }
    });
    // Mirror the compose bar's behavior: on creation, choosing "one-time"
    // updates the list's default so the next blank item starts there too.
    if (!_isEditing) {
      widget.controller.setListDeleteOnDoneDefault(next == ItemLifecycle.once);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      // Lifecycle is the source of truth: only "recurring" carries an rrule
      // and only "one-time" sets deleteOnDone. Switching out of recurring
      // clears the schedule on save even if `_rrule` still held an old value.
      final isRecurring = _lifecycle == ItemLifecycle.recurring;
      final isOnce = _lifecycle == ItemLifecycle.once;
      final effectiveRrule = isRecurring ? (_rrule ?? '') : '';
      final effectiveRepeatFromCompletion =
          isRecurring && _repeatFromCompletion;
      ListItem savedItem;
      if (_isEditing) {
        final item = widget.item!;
        savedItem = await widget.controller.updateItem(
          item,
          name: name,
          description: _descriptionController.text.trim(),
          quantity: _quantityController.text.trim(),
          categoryId: _selectedCategoryId,
          clearCategory: _selectedCategoryId == null && item.categoryId != null,
          rrule: effectiveRrule,
          repeatFromCompletion: effectiveRepeatFromCompletion,
          deleteOnDone: isOnce,
        );
      } else {
        savedItem = await widget.controller.addItem(
          name: name,
          description: _descriptionController.text.trim(),
          quantity: _quantityController.text.trim(),
          categoryId: _selectedCategoryId,
          rrule: isRecurring ? _rrule : null,
          deleteOnDone: isOnce,
        );
      }

      // Handle image changes after the item is saved
      if (_removeExistingImage && _pickedImage == null) {
        await widget.controller.deleteItemImage(savedItem);
      }
      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        final mime =
            lookupMimeType(_pickedImage!.name) ?? 'application/octet-stream';
        await widget.controller.uploadItemImage(
          savedItem,
          bytes: bytes,
          fileName: _pickedImage!.name,
          mimeType: mime,
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
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(_isEditing ? f.editTitle : f.addTitle),
      ),
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
          const SizedBox(height: 16),
          Text(m.checklists.itemTypes.label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          _LifecyclePicker(value: _lifecycle, onChanged: _setLifecycle),
          if (_lifecycle == ItemLifecycle.recurring) ...[
            const SizedBox(height: 4),
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
          const SizedBox(height: 16),
          Text(f.image, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          _buildImageSection(theme),
        ],
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    if (_pickedImage != null) {
      return _ImagePreviewTile(
        image: FileImage(File(_pickedImage!.path)),
        onRemove: () => setState(() {
          _pickedImage = null;
          if (!_isEditing) _removeExistingImage = false;
        }),
        onReplace: _pickImage,
      );
    }

    if (_hasExistingImage) {
      final uri = ChecklistService.instance.itemImagePreviewUri(
        widget.controller.houseId,
        widget.item!.imageFileId!,
        widget.item!.imageUploadedBy ?? '',
        size: 256,
      );
      final headers = AuthService.instance.credentials?.basicAuthHeaders ?? {};
      return _ImagePreviewTile(
        image: CachedNetworkImageProvider(uri.toString(), headers: headers),
        onRemove: () => setState(() {
          _removeExistingImage = true;
        }),
        onReplace: _pickImage,
      );
    }

    return OutlinedButton.icon(
      onPressed: _pickImage,
      icon: const Icon(Icons.add_photo_alternate_outlined),
      label: Text(m.checklists.itemForm.addImage),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _pickedImage = file;
        _removeExistingImage = true;
      });
    }
  }
}

class _ImagePreviewTile extends StatelessWidget {
  final ImageProvider image;
  final VoidCallback onRemove;
  final VoidCallback onReplace;

  const _ImagePreviewTile({
    required this.image,
    required this.onRemove,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final f = m.checklists.itemForm;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image(
            image: image,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ImageActionButton(
                icon: Icons.swap_horiz,
                tooltip: f.replaceImage,
                onPressed: onReplace,
              ),
              const SizedBox(width: 4),
              _ImageActionButton(
                icon: Icons.close,
                tooltip: f.removeImage,
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Three mutually-exclusive item-type cards (staple / one-time / recurring),
/// mirroring the compose bar's tray so the edit form speaks the same language.
class _LifecyclePicker extends StatelessWidget {
  final ItemLifecycle value;
  final ValueChanged<ItemLifecycle> onChanged;

  const _LifecyclePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = m.checklists.itemTypes;
    return Column(
      children: [
        _LifecycleRow(
          label: t.staple,
          body: t.stapleBody,
          selected: value == ItemLifecycle.staple,
          onTap: () => onChanged(ItemLifecycle.staple),
        ),
        const SizedBox(height: 7),
        _LifecycleRow(
          label: t.onceTime,
          body: t.onceTimeBody,
          selected: value == ItemLifecycle.once,
          onTap: () => onChanged(ItemLifecycle.once),
        ),
        const SizedBox(height: 7),
        _LifecycleRow(
          label: t.recurring,
          body: t.recurringBody,
          selected: value == ItemLifecycle.recurring,
          onTap: () => onChanged(ItemLifecycle.recurring),
        ),
      ],
    );
  }
}

class _LifecycleRow extends StatelessWidget {
  final String label;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  const _LifecycleRow({
    required this.label,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.1)
              : cs.surfaceContainer,
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? cs.primary : cs.outlineVariant,
                  width: selected ? 5 : 2,
                ),
                color: selected ? cs.surface : Colors.transparent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ImageActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
