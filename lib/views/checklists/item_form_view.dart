import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart' as models;
import 'package:pantry_core/models/store.dart' as models;
import 'package:pantry_core/models/label.dart' as models;
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/custom_field.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry/utils/item_modal_route.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry/utils/apple_host_info.dart';
import 'package:pantry_core/utils/rrule.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry/views/categories/category_form_view.dart';
import 'package:pantry/views/custom_fields/item_custom_fields_editor.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';
import 'package:pantry/widgets/avif_image.dart';
import 'package:pantry/widgets/create_label_dialog.dart';
import 'package:pantry/widgets/create_store_dialog.dart';
import 'package:pantry/widgets/markdown_editor.dart';
import 'package:pantry_core/models/item_lifecycle.dart';
import 'checklists_controller.dart';
import 'form_components.dart';
import 'item_form_fields.dart';
import 'item_form_image.dart';
import 'item_form_pickers.dart';
import 'price_input.dart';

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
  late final TextEditingController _quantityController;

  /// Item description as markdown, driven by the WYSIWYG editor.
  late String _description;
  int? _selectedCategoryId;
  final Set<int> _selectedStoreIds = {};
  final Set<int> _selectedLabelIds = {};
  late ItemLifecycle _lifecycle;
  late RecurrenceState _recurrence;
  late final bool _priceEnabled;
  late final PricesDraft _prices;
  late final bool _customFieldsEnabled;

  /// Composed custom-field values, kept up to date by the editor's `onChanged`
  /// (no rebuild needed — it's only read on save).
  late List<FieldValue> _customFields;
  bool _saving = false;
  bool _deleting = false;
  bool _catPickerOpen = false;
  bool _storePickerOpen = false;
  bool _labelPickerOpen = false;
  TextDirection _nameDir = TextDirection.ltr;
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

  /// The list whose scope governs which categories are offered: the edited
  /// item's own list, or — when adding — the list in context (null in the
  /// All-lists meta view, where the target isn't chosen yet, so only globals
  /// apply).
  int? get _effectiveListId {
    final item = widget.item;
    if (item != null) return item.listId;
    final current = widget.controller.currentList;
    if (current == null || current.id == kAllListsId) return null;
    return current.id;
  }

  List<models.Category> get _categories =>
      widget.controller.categoriesForList(_effectiveListId);
  List<models.Store> get _stores => widget.controller.sortedStores;
  bool get _storesEnabled => hasFeature('stores');
  List<models.Store> get _selectedStores => [
    for (final s in _stores)
      if (_selectedStoreIds.contains(s.id)) s,
  ];

  /// Labels offered for this item, scoped to its effective list (globals plus
  /// the list's own). An already-attached out-of-scope label still renders via
  /// [_selectedLabels], which resolves against the full set.
  List<models.Label> get _labels =>
      widget.controller.labelsForList(_effectiveListId);
  bool get _labelsEnabled => hasFeature('labels');
  List<models.Label> get _selectedLabels => [
    for (final l in widget.controller.sortedLabels)
      if (_selectedLabelIds.contains(l.id)) l,
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _description = item?.description ?? '';
    _quantityController = TextEditingController(text: item?.quantity ?? '');
    _selectedCategoryId = item?.categoryId;
    _selectedStoreIds.addAll(item?.storeIds ?? const []);
    _selectedLabelIds.addAll(item?.labelIds ?? const []);
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
    _priceEnabled = hasFeature('item-price');
    _prices = item != null
        ? PricesDraft.fromItem(
            item,
            fallbackCurrency: widget.controller.lastCurrency,
          )
        : PricesDraft.empty(widget.controller.lastCurrency);
    _customFieldsEnabled = hasFeature(kCustomFieldsFeature);
    _customFields = List.of(item?.customFields ?? const []);
    _nameDir = detectTextDirection(item?.name);
    _nameController.addListener(() {
      final dir = detectTextDirection(_nameController.text);
      if (dir != _nameDir) setState(() => _nameDir = dir);
    });
    if (_cameraSupported) {
      isiOSAppOnMac().then((onMac) {
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
          description: _description.trim(),
          quantity: _quantityController.text.trim(),
          categoryId: _selectedCategoryId,
          clearCategory: _selectedCategoryId == null && item.categoryId != null,
          // null leaves stores unchanged; [] clears them. Only send when the
          // stores feature exists.
          storeIds: _storesEnabled ? _selectedStoreIds.toList() : null,
          // Labels mirror stores: null leaves them unchanged, [] clears.
          labelIds: _labelsEnabled ? _selectedLabelIds.toList() : null,
          rrule: effectiveRrule,
          repeatFromCompletion: effectiveRepeatFromCompletion,
          deleteOnDone: isOnce,
          // Always send the full price set on edit (an empty list clears).
          // Omitted entirely when the server lacks the capability.
          prices: _priceEnabled ? _prices.toItemPrices() : null,
          // Full value set on edit (empty clears); omitted without the feature.
          customFields: _customFieldsEnabled ? _customFields : null,
        );
      } else {
        savedItem = await widget.controller.addItem(
          name: name,
          description: _description.trim(),
          quantity: _quantityController.text.trim(),
          categoryId: _selectedCategoryId,
          storeIds: _storesEnabled && _selectedStoreIds.isNotEmpty
              ? _selectedStoreIds.toList()
              : null,
          labelIds: _labelsEnabled && _selectedLabelIds.isNotEmpty
              ? _selectedLabelIds.toList()
              : null,
          rrule: isRecurring ? effectiveRrule : null,
          deleteOnDone: isOnce,
          prices: _priceEnabled && _prices.hasAnyPrice
              ? _prices.toItemPrices()
              : null,
          customFields: _customFieldsEnabled && _customFields.isNotEmpty
              ? _customFields
              : null,
        );
      }
      // Remember the currency only when the saved item actually has a price.
      if (_priceEnabled && _prices.hasAnyPrice) {
        final currency = _prices.rememberCurrency;
        if (currency != null) await widget.controller.setLastCurrency(currency);
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
    // Resolve against the full set, not the scoped list, so an already-assigned
    // category still renders even if it falls outside the current scope.
    return widget.controller.categories[id];
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
              child: DeleteIconButton(
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
                HeaderPreview(
                  name: _nameController.text.trim().isEmpty
                      ? f.untitledItem
                      : _nameController.text.trim(),
                  category: _selectedCategory,
                  parseColor: _parseColor,
                  typeSummary: _typeSummary(),
                ),
                const SizedBox(height: 16),
                LabeledField(
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
                LabeledField(
                  label: f.description,
                  focused: _focusedField == 'desc',
                  child: MarkdownEditor(
                    initialValue: _description,
                    onChanged: (md) => _description = md,
                    focusNode: _descFocus,
                    placeholder: f.descHint,
                    minHeight: 60,
                    maxHeight: 200,
                  ),
                ),
                const SizedBox(height: 11),
                QuantityField(
                  controller: _quantityController,
                  focusNode: _qtyFocus,
                  focused: _focusedField == 'qty',
                  onMinus: () => _stepQty(-1),
                  onPlus: () => _stepQty(1),
                ),
                const SizedBox(height: 16),
                if (_priceEnabled) ...[
                  SectionLabel(text: m.checklists.price.label),
                  const SizedBox(height: 10),
                  ItemPricesEditor(
                    draft: _prices,
                    stores: _storesEnabled ? _stores : const [],
                    perStoreEnabled: hasFeature(kItemPricePerStoreFeature),
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                ],
                SectionLabel(text: f.category),
                const SizedBox(height: 8),
                CategoryDropdownRow(
                  category: _selectedCategory,
                  parseColor: _parseColor,
                  open: _catPickerOpen,
                  onTap: () => setState(() => _catPickerOpen = !_catPickerOpen),
                ),
                if (_catPickerOpen) ...[
                  const SizedBox(height: 11),
                  CategoryPickerPanel(
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
                if (_storesEnabled) ...[
                  const SizedBox(height: 16),
                  SectionLabel(text: f.stores),
                  const SizedBox(height: 8),
                  StoreDropdownRow(
                    stores: _selectedStores,
                    parseColor: _parseColor,
                    open: _storePickerOpen,
                    onTap: () =>
                        setState(() => _storePickerOpen = !_storePickerOpen),
                  ),
                  if (_storePickerOpen) ...[
                    const SizedBox(height: 11),
                    StorePickerPanel(
                      stores: _stores,
                      selectedIds: _selectedStoreIds,
                      onToggle: (id) => setState(() {
                        if (!_selectedStoreIds.remove(id)) {
                          _selectedStoreIds.add(id);
                        }
                      }),
                      onCreateRequest: _openCreateStore,
                      parseColor: _parseColor,
                    ),
                  ],
                ],
                if (_labelsEnabled) ...[
                  const SizedBox(height: 16),
                  SectionLabel(text: f.labels),
                  const SizedBox(height: 8),
                  LabelDropdownRow(
                    labels: _selectedLabels,
                    parseColor: _parseColor,
                    open: _labelPickerOpen,
                    onTap: () =>
                        setState(() => _labelPickerOpen = !_labelPickerOpen),
                  ),
                  if (_labelPickerOpen) ...[
                    const SizedBox(height: 11),
                    LabelPickerPanel(
                      labels: _labels,
                      selectedIds: _selectedLabelIds,
                      onToggle: (id) => setState(() {
                        if (!_selectedLabelIds.remove(id)) {
                          _selectedLabelIds.add(id);
                        }
                      }),
                      onCreateRequest: _openCreateLabel,
                      parseColor: _parseColor,
                    ),
                  ],
                ],
                if (_customFieldsEnabled) ...[
                  const SizedBox(height: 16),
                  SectionLabel(text: m.customFields.manageTitle),
                  const SizedBox(height: 10),
                  ItemCustomFieldsEditor(
                    houseId: widget.controller.houseId,
                    listId: _effectiveListId,
                    initial: _customFields,
                    onChanged: (values) => _customFields = values,
                  ),
                ],
                const SizedBox(height: 16),
                SectionLabel(text: m.checklists.itemTypes.label),
                const SizedBox(height: 10),
                LifecyclePicker(value: _lifecycle, onChanged: _setLifecycle),
                if (_lifecycle == ItemLifecycle.recurring) ...[
                  const SizedBox(height: 8),
                  RecurrenceInline(
                    state: _recurrence,
                    onChanged: () => setState(() {}),
                  ),
                ],
                const SizedBox(height: 16),
                SectionLabel(text: f.image),
                const SizedBox(height: 10),
                _buildImageSection(theme),
                const SizedBox(height: 8),
              ],
            ),
          ),
          DockedSaveBar(
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
    final created = await Navigator.of(context).push<models.Category>(
      itemModalRoute(
        CategoryFormView(
          houseId: widget.controller.houseId,
          defaultListId: _effectiveListId,
        ),
      ),
    );
    if (created == null || !mounted) return;
    widget.controller.categories[created.id] = created;
    setState(() {
      _selectedCategoryId = created.id;
      _catPickerOpen = false;
    });
  }

  Future<void> _openCreateStore() async {
    final created = await showDialog<models.Store>(
      context: context,
      builder: (_) => CreateStoreDialog(houseId: widget.controller.houseId),
    );
    if (created == null || !mounted) return;
    widget.controller.stores[created.id] = created;
    setState(() => _selectedStoreIds.add(created.id));
  }

  Future<void> _openCreateLabel() async {
    final created = await showDialog<models.Label>(
      context: context,
      builder: (_) => CreateLabelDialog(
        houseId: widget.controller.houseId,
        defaultListId: _effectiveListId,
      ),
    );
    if (created == null || !mounted) return;
    widget.controller.labels[created.id] = created;
    setState(() => _selectedLabelIds.add(created.id));
  }

  Widget _buildImageSection(ThemeData theme) {
    if (_pickedImage != null) {
      return ImagePreviewTile(
        image: AvifAwareFileImage(File(_pickedImage!.path)),
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
      return ImagePreviewTile(
        image: AvifAwareNetworkImage(uri.toString(), headers: headers),
        onRemove: () => setState(() {
          _removeExistingImage = true;
        }),
        onReplace: _replaceImage,
      );
    }

    return AddImageButtons(
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
      builder: (ctx) => const ImageSourceSheet(),
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
