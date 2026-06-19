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
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/utils/rrule.dart';
import 'package:pantry/utils/text_direction.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';
import 'package:pantry/widgets/create_category_dialog.dart';
import 'checklist_item_tile.dart' show ItemLifecycle, lifecycleOf;
import 'checklists_controller.dart';
import 'form_components.dart';

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
  late ItemLifecycle _lifecycle;
  late RecurrenceState _recurrence;
  bool _saving = false;
  bool _deleting = false;
  bool _catPickerOpen = false;
  TextDirection _nameDir = TextDirection.ltr;
  TextDirection _descriptionDir = TextDirection.ltr;
  XFile? _pickedImage;
  bool _removeExistingImage = false;
  String? _focusedField;
  bool _cameraSupported = !PlatformInfo.isDesktop;
  final _nameFocus = FocusNode();
  final _descFocus = FocusNode();
  final _qtyFocus = FocusNode();

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
    _recurrence = RecurrenceState.fromRrule(
      item?.rrule,
      repeatFromCompletion: item?.repeatFromCompletion ?? false,
    );
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
    if (_cameraSupported) {
      PlatformInfo.isiOSAppOnMac.then((onMac) {
        if (!mounted || !onMac) return;
        setState(() => _cameraSupported = false);
      });
    }
    for (final entry in {
      _nameFocus: 'name',
      _descFocus: 'desc',
      _qtyFocus: 'qty',
    }.entries) {
      entry.key.addListener(() {
        final hasFocus = entry.key.hasFocus;
        if (hasFocus && _focusedField != entry.value) {
          setState(() => _focusedField = entry.value);
        } else if (!hasFocus && _focusedField == entry.value) {
          setState(() => _focusedField = null);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _nameFocus.dispose();
    _descFocus.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  void _setLifecycle(ItemLifecycle next) {
    if (next == _lifecycle) return;
    setState(() => _lifecycle = next);
    // Mirror the compose bar's behavior: on creation, choosing "one-time"
    // updates the list's default so the next blank item starts there too.
    if (!_isEditing) {
      widget.controller.setListDeleteOnDoneDefault(next == ItemLifecycle.once);
    }
  }

  void _stepQty(int dir) {
    final str = _quantityController.text;
    final match = RegExp(r'\d+').firstMatch(str);
    String next;
    if (match != null) {
      final n = (int.parse(match.group(0)!) + dir).clamp(0, 9999);
      next = str.replaceFirst(RegExp(r'\d+'), '$n');
    } else if (dir > 0) {
      next = str.isEmpty ? '1' : '1 $str';
    } else {
      next = str;
    }
    _quantityController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      // Lifecycle is the source of truth: only "recurring" carries an rrule
      // and only "one-time" sets deleteOnDone. Switching out of recurring
      // clears the schedule on save even if the inline panel still held one.
      final isRecurring = _lifecycle == ItemLifecycle.recurring;
      final isOnce = _lifecycle == ItemLifecycle.once;
      final effectiveRrule = isRecurring ? _recurrence.toRrule() : '';
      final effectiveRepeatFromCompletion =
          isRecurring && _recurrence.repeatFromCompletion;
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
          rrule: isRecurring ? effectiveRrule : null,
          deleteOnDone: isOnce,
        );
      }

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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(m.checklists.itemForm.saveFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final item = widget.item;
    if (item == null) return;
    final f = m.checklists.itemForm;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(f.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.common.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.controller.deleteItem(item);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(f.deleteFailed)));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  models.Category? get _selectedCategory {
    final id = _selectedCategoryId;
    if (id == null) return null;
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Color? _parseColor(String hex) {
    if (hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : null;
  }

  String _typeSummary() {
    final t = m.checklists.itemTypes;
    final f = m.checklists.itemForm;
    switch (_lifecycle) {
      case ItemLifecycle.staple:
        return f.typeStaple;
      case ItemLifecycle.once:
        return f.typeOnce;
      case ItemLifecycle.recurring:
        final rrule = _recurrence.toRrule();
        if (rrule.isEmpty) return t.recurring;
        return '${f.typeRecurring} · ${formatRrule(rrule)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final f = m.checklists.itemForm;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        // Desktop opens the form as a modal — give it a close affordance
        // instead of the platform-default Back chevron, which would read as
        // navigating away from a page that doesn't exist on the stack.
        leading: PlatformInfo.isDesktop
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: m.common.cancel,
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : appBarBackLeading(context),
        title: Text(_isEditing ? f.editTitle : f.addTitle),
        actions: [
          if (_isEditing)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: _DeleteIconButton(
                onTap: _deleting ? null : _confirmDelete,
                busy: _deleting,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                _HeaderPreview(
                  name: _nameController.text.trim().isEmpty
                      ? f.untitledItem
                      : _nameController.text.trim(),
                  category: _selectedCategory,
                  parseColor: _parseColor,
                  typeSummary: _typeSummary(),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: f.name,
                  focused: _focusedField == 'name',
                  child: TextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    autofocus: !_isEditing,
                    textCapitalization: TextCapitalization.sentences,
                    textDirection: _nameDir,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                _LabeledField(
                  label: f.description,
                  focused: _focusedField == 'desc',
                  child: TextField(
                    controller: _descriptionController,
                    focusNode: _descFocus,
                    textCapitalization: TextCapitalization.sentences,
                    textDirection: _descriptionDir,
                    minLines: 2,
                    maxLines: 5,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: f.descHint,
                      hintStyle: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                _QuantityField(
                  controller: _quantityController,
                  focusNode: _qtyFocus,
                  focused: _focusedField == 'qty',
                  onMinus: () => _stepQty(-1),
                  onPlus: () => _stepQty(1),
                ),
                const SizedBox(height: 16),
                _SectionLabel(text: f.category),
                const SizedBox(height: 8),
                _CategoryDropdownRow(
                  category: _selectedCategory,
                  parseColor: _parseColor,
                  open: _catPickerOpen,
                  onTap: () => setState(() => _catPickerOpen = !_catPickerOpen),
                ),
                if (_catPickerOpen) ...[
                  const SizedBox(height: 11),
                  _CategoryPickerPanel(
                    categories: _categories,
                    selectedId: _selectedCategoryId,
                    onSelect: (id) {
                      setState(() {
                        _selectedCategoryId = id;
                        _catPickerOpen = false;
                      });
                    },
                    onCreateRequest: _openCreateCategory,
                    parseColor: _parseColor,
                  ),
                ],
                const SizedBox(height: 16),
                _SectionLabel(text: m.checklists.itemTypes.label),
                const SizedBox(height: 10),
                _LifecyclePicker(value: _lifecycle, onChanged: _setLifecycle),
                if (_lifecycle == ItemLifecycle.recurring) ...[
                  const SizedBox(height: 8),
                  RecurrenceInline(
                    state: _recurrence,
                    onChanged: () => setState(() {}),
                  ),
                ],
                const SizedBox(height: 16),
                _SectionLabel(text: f.image),
                const SizedBox(height: 10),
                _buildImageSection(theme),
                const SizedBox(height: 8),
              ],
            ),
          ),
          _DockedSaveBar(
            onCancel: _saving
                ? null
                : () => Navigator.of(context).maybePop(false),
            onSave: _saving ? null : _save,
            saving: _saving,
            label: f.save,
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateCategory() async {
    final created = await showDialog<models.Category>(
      context: context,
      builder: (_) => CreateCategoryDialog(houseId: widget.controller.houseId),
    );
    if (created == null || !mounted) return;
    widget.controller.categories[created.id] = created;
    setState(() {
      _selectedCategoryId = created.id;
      _catPickerOpen = false;
    });
  }

  Widget _buildImageSection(ThemeData theme) {
    if (_pickedImage != null) {
      return _ImagePreviewTile(
        image: FileImage(File(_pickedImage!.path)),
        onRemove: () => setState(() {
          _pickedImage = null;
          if (!_isEditing) _removeExistingImage = false;
        }),
        onReplace: _replaceImage,
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
        onReplace: _replaceImage,
      );
    }

    return _AddImageButtons(
      onChooseImage: () => _pickImage(ImageSource.gallery),
      onTakePhoto: _cameraSupported
          ? () => _pickImage(ImageSource.camera)
          : null,
    );
  }

  Future<void> _replaceImage() async {
    if (!_cameraSupported) {
      await _pickImage(ImageSource.gallery);
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _ImageSourceSheet(),
    );
    if (source != null) await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file != null) {
      setState(() {
        _pickedImage = file;
        _removeExistingImage = true;
      });
    }
  }
}

class _DeleteIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool busy;

  const _DeleteIconButton({required this.onTap, required this.busy});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: busy
            ? Padding(
                padding: const EdgeInsets.all(9),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.error,
                ),
              )
            : Icon(Icons.delete_outline, color: cs.error, size: 20),
      ),
    );
  }
}

class _HeaderPreview extends StatelessWidget {
  final String name;
  final models.Category? category;
  final Color? Function(String hex) parseColor;
  final String typeSummary;

  const _HeaderPreview({
    required this.name,
    required this.category,
    required this.parseColor,
    required this.typeSummary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final catColor = category != null
        ? (parseColor(category!.color) ?? cs.primary)
        : cs.onSurfaceVariant;
    final tileBg = category != null
        ? catColor.withValues(alpha: 0.14)
        : cs.surfaceContainer;
    final tileBorder = category != null
        ? catColor.withValues(alpha: 0.3)
        : cs.outlineVariant;
    final icon = category != null
        ? categoryIcon(category!.icon)
        : Icons.shopping_basket_outlined;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: tileBorder),
          ),
          child: Icon(icon, color: catColor, size: 26),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                typeSummary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Filled card wrapping a single text field. The card's border + label color
/// flip to the accent when the field is focused — same treatment for name,
/// description, and (visually) the quantity row's inner input.
class _LabeledField extends StatelessWidget {
  final String label;
  final bool focused;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.focused,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelColor = focused ? cs.primary : cs.onSurfaceVariant;
    final borderColor = focused ? cs.primary : cs.outlineVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.fromLTRB(15, 11, 15, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border.all(color: borderColor, width: focused ? 1.5 : 1),
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
              color: labelColor,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _QuantityField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _QuantityField({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelColor = focused ? cs.primary : cs.onSurfaceVariant;
    final borderColor = focused ? cs.primary : cs.outlineVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border.all(color: borderColor, width: focused ? 1.5 : 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.checklists.itemForm.quantity.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              FormStepperButton(icon: Icons.remove, onTap: onMinus),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: m.checklists.compose.qtyHint,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 15,
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

class _CategoryDropdownRow extends StatelessWidget {
  final models.Category? category;
  final Color? Function(String hex) parseColor;
  final bool open;
  final VoidCallback onTap;

  const _CategoryDropdownRow({
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

class _CategoryPickerPanel extends StatelessWidget {
  final List<models.Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelect;
  final Future<void> Function() onCreateRequest;
  final Color? Function(String hex) parseColor;

  const _CategoryPickerPanel({
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

class _LifecyclePicker extends StatelessWidget {
  final ItemLifecycle value;
  final ValueChanged<ItemLifecycle> onChanged;

  const _LifecyclePicker({required this.value, required this.onChanged});

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

class _AddImageButtons extends StatelessWidget {
  final VoidCallback onChooseImage;
  final VoidCallback? onTakePhoto;

  const _AddImageButtons({required this.onChooseImage, this.onTakePhoto});

  @override
  Widget build(BuildContext context) {
    final f = m.checklists.itemForm;
    if (onTakePhoto == null) {
      return _AddImageTile(
        icon: Icons.add_photo_alternate_outlined,
        label: f.addImage,
        onTap: onChooseImage,
      );
    }
    return Row(
      children: [
        Expanded(
          child: _AddImageTile(
            icon: Icons.photo_camera_outlined,
            label: f.takePhoto,
            onTap: onTakePhoto!,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AddImageTile(
            icon: Icons.add_photo_alternate_outlined,
            label: f.chooseImage,
            onTap: onChooseImage,
          ),
        ),
      ],
    );
  }
}

class _AddImageTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddImageTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: DottedRoundedBorder(
        color: cs.outlineVariant,
        radius: 14,
        strokeWidth: 1.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: cs.primary, size: 20),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
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

class _ImageSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final f = m.checklists.itemForm;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(f.takePhoto),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.add_photo_alternate_outlined),
            title: Text(f.chooseImage),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Simple dashed outline using a CustomPainter — Flutter Material doesn't
/// support dashed borders on Container natively.
class DottedRoundedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;

  const DottedRoundedBorder({
    super.key,
    required this.child,
    required this.color,
    this.radius = 14,
    this.strokeWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}

class _DockedSaveBar extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final bool saving;
  final String label;

  const _DockedSaveBar({
    required this.onCancel,
    required this.onSave,
    required this.saving,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        child: Row(
          children: [
            InkWell(
              onTap: onCancel,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  m.common.cancel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: InkWell(
                onTap: onSave,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cs.primary, cs.primary.withValues(alpha: 0.78)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (saving)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.check, color: Colors.white, size: 20),
                      const SizedBox(width: 9),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          borderRadius: BorderRadius.circular(14),
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
