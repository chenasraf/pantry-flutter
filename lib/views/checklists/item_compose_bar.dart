import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/store.dart' as models;
import 'package:pantry/models/label.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/custom_field.dart';
import 'package:pantry/services/barcode_service.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/views/checklists/barcode_scan_view.dart';
import 'package:pantry/views/custom_fields/item_custom_fields_editor.dart';
import 'package:pantry/models/item_lifecycle.dart';
import 'item_compose_chips.dart';
import 'item_compose_trays.dart';
import 'item_draft.dart';
import 'price_input.dart';

export 'item_draft.dart' show ComposeSubmission;

class ItemComposeBar extends StatefulWidget {
  final String listName;

  /// House the item is added to, for loading custom-field definitions.
  final int houseId;

  /// The concrete list an item lands in when not in All-lists mode; `null` in
  /// All-lists mode (the target is chosen via [selectedTargetListId]). Governs
  /// which list-scoped custom fields apply.
  final int? listId;
  final bool deleteOnDoneDefault;
  final List<models.Category> categories;

  /// Stores offered in the store tray. Empty (and the store chip hidden) when
  /// the server lacks the `stores` capability.
  final List<models.Store> stores;

  /// Labels offered in the label tray. Empty (and the label chip hidden) when
  /// the server lacks the `labels` capability.
  final List<models.Label> labels;

  /// Custom-field definitions for the house; empty (and the chip hidden) when
  /// the server lacks `custom-fields`. Drives the custom-fields tray and the
  /// default seeding.
  final List<FieldDefinition> customFieldDefs;
  final Future<bool> Function(ComposeSubmission submission) onSubmit;
  final bool initiallyFocused;
  final bool dimmedListBackground;

  /// Whether the server advertises `item-price`. Hides the price chip + tray
  /// entirely when false.
  final bool priceEnabled;

  /// Whether the server advertises `item-price-per-store`. When false the price
  /// tray shows only the single store-less price (legacy single-price UI).
  final bool perStorePriceEnabled;

  /// House's last-used currency, preselected when the price tray first opens.
  final String lastCurrency;

  /// Fires whenever the bar becomes active (chip row + trays visible) or
  /// returns to its resting state. Lets the parent reclaim vertical space —
  /// e.g. hide the progress hero + filter row while composing so the trays
  /// can grow taller.
  final ValueChanged<bool>? onActiveChanged;

  /// Optional hook for the "+ New" chip in the category tray. The callback
  /// should drive the create-category UI (e.g. open the dialog), refresh the
  /// parent's categories list, and return the new Category — which compose
  /// bar then auto-selects on the current draft.
  final Future<models.Category?> Function()? onRequestCreateCategory;

  /// Optional hook for the "+ New" chip in the store tray. Mirrors
  /// [onRequestCreateCategory]: drive the create-store UI, refresh the parent's
  /// store list, and return the new Store — compose bar then selects it.
  final Future<models.Store?> Function()? onRequestCreateStore;

  /// Optional hook for the "+ New" chip in the label tray. Mirrors
  /// [onRequestCreateStore]: drive the create-label UI, refresh the parent's
  /// label list, and return the new Label — compose bar then selects it.
  final Future<models.Label?> Function()? onRequestCreateLabel;

  /// When non-null, switches the bar into All-lists mode: the user must pick
  /// which list the new item lands in before submit. The selected target
  /// survives between submissions so rapid same-list adds are one-tap.
  ///
  /// Pass the real (non-meta) lists; the picker filters out the synthetic
  /// "All lists" entry automatically.
  final List<ChecklistList>? targetLists;

  /// Pre-selected target list id in All-lists mode. The host owns this so the
  /// last-used target persists across rebuilds. Required when [targetLists]
  /// is provided.
  final int? selectedTargetListId;

  /// Notifies the host when the user picks a different target list, so the
  /// host can persist it and feed it back via [selectedTargetListId].
  final ValueChanged<int>? onTargetListChanged;

  /// Existing items on the current target list. While composing a single item,
  /// the bar fuzzy-matches the typed name against these and offers matches so
  /// the user can reuse one instead of creating a duplicate.
  /// Empty disables the suggestions UI.
  final List<ListItem> reuseCandidates;

  /// Builds a read-only suggestion tile for [item]. Provided by the host so the
  /// tile resolves categories/stores through the controller; tapping the tile
  /// runs [onTap].
  final Widget Function(ListItem item, VoidCallback onTap)?
  buildReuseSuggestion;

  /// Runs the host's confirm-then-reuse flow for a tapped suggestion. Returns
  /// true when the item was reused, so the bar clears its input afterwards.
  final Future<bool> Function(ListItem item)? onReuseExisting;

  /// Archived items on the current target list, folded into the same fuzzy
  /// reuse pool as [reuseCandidates] (each carries a non-null `archivedAt`).
  /// The host keeps this live; the bar signals when to populate it via
  /// [onArchivedSearchStarted]. Empty when archived suggestions are disabled.
  final List<ListItem> archivedReuseCandidates;

  /// Called the first time the user searches a resolved target list, so the
  /// host can lazily load that list's archived items (fed back through
  /// [archivedReuseCandidates]). Null disables archived suggestions.
  final ValueChanged<int>? onArchivedSearchStarted;

  const ItemComposeBar({
    super.key,
    required this.listName,
    required this.houseId,
    this.listId,
    required this.deleteOnDoneDefault,
    required this.categories,
    this.stores = const [],
    this.labels = const [],
    this.customFieldDefs = const [],
    required this.onSubmit,
    this.initiallyFocused = false,
    this.dimmedListBackground = false,
    this.priceEnabled = false,
    this.perStorePriceEnabled = false,
    this.lastCurrency = 'USD',
    this.onActiveChanged,
    this.onRequestCreateCategory,
    this.onRequestCreateStore,
    this.onRequestCreateLabel,
    this.targetLists,
    this.selectedTargetListId,
    this.onTargetListChanged,
    this.reuseCandidates = const [],
    this.buildReuseSuggestion,
    this.onReuseExisting,
    this.archivedReuseCandidates = const [],
    this.onArchivedSearchStarted,
  });

  bool get _allListsMode => targetLists != null;

  @override
  State<ItemComposeBar> createState() => ItemComposeBarState();
}

enum Tray {
  targetList,
  category,
  store,
  label,
  quantity,
  price,
  customFields,
  description,
  type,
  image,
}

class ItemComposeBarState extends State<ItemComposeBar> {
  late final ItemDraft _draft = ItemDraft()
    ..lifecycle = _defaultLifecycle()
    ..price = PricesDraft.empty(widget.lastCurrency);
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _active = false;
  Tray? _openTray;
  bool _submitting = false;
  bool _multiple = false;

  /// True once the user touches the custom-fields tray. Until then the item
  /// falls back to the fields' default seeds, recomputed from the live target.
  bool _customFieldsEdited = false;

  /// The list the item will land in: the picked target in All-lists mode, else
  /// the bar's concrete list. Governs which list-scoped fields apply.
  int? get _targetListId =>
      widget._allListsMode ? widget.selectedTargetListId : widget.listId;

  /// Custom fields applicable to the current target (house-wide ∪ the list).
  List<FieldDefinition> get _applicableCustomFields => [
    for (final f in widget.customFieldDefs)
      if (f.listId == null || f.listId == _targetListId) f,
  ];

  /// The values to carry: the user's edits once they've touched the tray,
  /// otherwise the defaults seeded from the applicable fields.
  List<FieldValue> get _effectiveCustomFields => _customFieldsEdited
      ? _draft.customFields
      : seedFieldValues(widget.customFieldDefs, _targetListId);

  @override
  void initState() {
    super.initState();
    if (widget.initiallyFocused) {
      _active = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
        widget.onActiveChanged?.call(true);
      });
    }
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_active) {
        _activate();
      }
    });
    _nameCtrl.addListener(_onNameChanged);
  }

  @override
  void didUpdateWidget(ItemComposeBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching the target list changes which fields apply, so drop any
    // in-progress custom-field edits and fall back to the new list's defaults.
    if (oldWidget.listId != widget.listId ||
        oldWidget.selectedTargetListId != widget.selectedTargetListId) {
      _customFieldsEdited = false;
      _draft.customFields = const [];
    }
  }

  void _onNameChanged() {
    _maybeLoadArchived();
    // Rebuild so the bulk-add hint tracks input in multiple mode, and the
    // single-mode reuse suggestions re-filter as the user types.
    if (_multiple ||
        widget.reuseCandidates.isNotEmpty ||
        widget.archivedReuseCandidates.isNotEmpty ||
        widget.onArchivedSearchStarted != null) {
      setState(() {});
    }
  }

  /// Ask the host to lazily load the current target list's archived items the
  /// first time the user searches it. Gated to single-item mode with a resolved
  /// target and a non-empty query, so nothing loads on screen open or in bulk
  /// mode. The host de-dupes the actual fetch.
  void _maybeLoadArchived() {
    final onSearch = widget.onArchivedSearchStarted;
    if (onSearch == null || _multiple) return;
    final listId = _targetListId;
    if (listId == null) return;
    if (_nameCtrl.text.trim().isEmpty) return;
    onSearch(listId);
  }

  /// The reuse-match pool: the host's active candidates plus any archived
  /// candidates for the current target, with archived duplicates of an active
  /// item dropped so an item can't be offered twice.
  List<ListItem> _reusePool() {
    final active = widget.reuseCandidates;
    final archived = widget.archivedReuseCandidates;
    if (archived.isEmpty) return active;
    final activeIds = {for (final i in active) i.id};
    return [
      ...active,
      for (final a in archived)
        if (!activeIds.contains(a.id)) a,
    ];
  }

  /// Max reuse suggestions surfaced at once — enough to catch the near matches
  /// without turning the compose bar into a full second list.
  static const _maxReuseSuggestions = 6;

  /// Minimum fuzzy score (0–100) a candidate must clear to be offered. Set so
  /// per-word matches ("Organic milk" → "Milk", ~90 via partial ratio) and
  /// light typos survive, while unrelated names are filtered out.
  static const _reuseMatchCutoff = 60;

  /// Minimum fuzzy score (0–100) for a barcode provider's category hint to
  /// prefill one of the house's categories. Higher than [_reuseMatchCutoff] —
  /// a wrong auto-category is more annoying than none, so only match when it's
  /// clearly the same category.
  static const _categoryMatchCutoff = 65;

  /// Single-mode fuzzy matches of the typed name against [reuseCandidates],
  /// best-ranked first. fuzzywuzzy's weighted ratio blends token and partial
  /// matching, so a longer query ("Organic milk") still matches a shorter name
  /// ("Milk"). Empty in multiple mode, with no query, or when unwired.
  List<ListItem> _reuseMatches() {
    if (_multiple || widget.buildReuseSuggestion == null) return const [];
    final pool = _reusePool();
    if (pool.isEmpty) return const [];
    final query = _nameCtrl.text.trim();
    if (query.isEmpty) return const [];
    final results = extractTop<ListItem>(
      query: query,
      choices: pool,
      getter: (item) => item.name,
      limit: _maxReuseSuggestions,
      cutoff: _reuseMatchCutoff,
    );
    return [for (final r in results) r.choice];
  }

  Future<void> _onSuggestionTap(ListItem item) async {
    final handler = widget.onReuseExisting;
    if (handler == null || _submitting) return;
    final reused = await handler(item);
    if (!mounted || !reused) return;
    // Reuse means we're not creating a new item — clear the draft and keep the
    // bar active/focused so the user can carry on adding.
    setState(() {
      _draft.reset(_defaultLifecycle());
      _nameCtrl.clear();
      _qtyCtrl.clear();
      _openTray = null;
    });
    _focusNode.requestFocus();
  }

  List<String> _bulkNames() {
    return _nameCtrl.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _toggleMultiple() {
    setState(() {
      _multiple = !_multiple;
      if (_multiple) {
        _draft.imageFile = null;
        _draft.imageBytes = null;
        // Image, price + custom fields are single-item concerns; close their
        // trays when switching to bulk entry.
        if (_openTray == Tray.image ||
            _openTray == Tray.price ||
            _openTray == Tray.customFields) {
          _openTray = null;
        }
      }
    });
  }

  void _activate() {
    if (_active) return;
    setState(() => _active = true);
    widget.onActiveChanged?.call(true);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  ItemLifecycle _defaultLifecycle() =>
      widget.deleteOnDoneDefault ? ItemLifecycle.once : ItemLifecycle.staple;

  void _cancel() {
    setState(() {
      _active = false;
      _openTray = null;
      _draft.reset(_defaultLifecycle());
      _nameCtrl.clear();
      _qtyCtrl.clear();
    });
    _focusNode.unfocus();
    widget.onActiveChanged?.call(false);
  }

  /// Soft-dismiss: collapse the chip row + tray and unfocus, but preserve
  /// the current draft (name, quantity, category, type, image) so the user
  /// can pick up where they left off. Used by the scrim's tap handler so a
  /// misclick on the dimmed area doesn't throw away in-progress input.
  void dismissKeepingDraft() {
    if (!_active) return;
    setState(() {
      _active = false;
      _openTray = null;
    });
    _focusNode.unfocus();
    widget.onActiveChanged?.call(false);
  }

  void _toggleTray(Tray t) {
    setState(() {
      _openTray = _openTray == t ? null : t;
    });
    if (t == Tray.quantity) {
      _qtyCtrl.text = _draft.quantity;
    }
    // The description tray's editor seeds itself from _draft.description when it
    // mounts, so there's nothing to sync here.
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(source: ImageSource.gallery);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    setState(() {
      _draft.imageFile = f;
      _draft.imageBytes = bytes;
    });
  }

  void _removeImage() {
    setState(() {
      _draft.imageFile = null;
      _draft.imageBytes = null;
    });
  }

  /// Scan (or manually enter) a barcode, then prefill the draft. Checks the
  /// shared server cache first, resolving against Open Food Facts (and caching
  /// the result for the house) only on a miss. Prefills never clobber existing
  /// input; a total miss leaves the draft untouched and shows a toast.
  Future<void> _scanBarcode() async {
    if (_multiple) return;
    if (!_active) _activate();
    final ean = await BarcodeScanView.scan(context);
    if (ean == null || !mounted) return;

    final svc = BarcodeService.instance;
    BarcodeResult? result;
    try {
      result = await svc.lookup(ean);
    } catch (_) {
      // Cache lookup failed (offline / server error). Fall through to an
      // external resolve.
    }
    if (result == null) {
      result = await svc.resolveExternally(ean);
      // Write a freshly-resolved product back into the shared cache so repeat
      // scans across the house are free. Best-effort — don't block on it.
      if (result != null) {
        unawaited(svc.save(result).catchError((_) => result!));
      }
    }
    if (!mounted) return;

    // Not found anywhere: leave the form as it was and just tell the user, so
    // an unrecognized code never lands in the name field.
    if (result == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(m.checklists.barcode.notFound)));
      return;
    }

    // Prefill from the resolved product, never overwriting input the user has
    // already made.
    final matchedCategory = _matchCategory(result.category);
    setState(() {
      _draft.barcode = ean;
      if (_nameCtrl.text.trim().isEmpty) {
        _nameCtrl.text = result!.name;
        _draft.name = result.name;
      }
      if (_draft.categoryId == null && matchedCategory != null) {
        _draft.categoryId = matchedCategory.id;
      }
    });

    // Download the product image and stage it on the draft so the existing
    // create → uploadItemImage path attaches it after the item is created.
    final imageUrl = result.imageUrl;
    if (imageUrl != null && _draft.imageBytes == null) {
      final bytes = await svc.downloadImage(imageUrl);
      if (bytes != null && mounted) {
        setState(() => _draft.imageBytes = Uint8List.fromList(bytes));
      }
    }
  }

  /// Fuzzy-match a provider category hint against the house's categories,
  /// returning the best match above a confidence cutoff (or null). Mirrors the
  /// reuse-suggestion matcher's use of fuzzywuzzy's weighted ratio.
  models.Category? _matchCategory(String? hint) {
    final query = hint?.trim() ?? '';
    if (query.isEmpty || widget.categories.isEmpty) return null;
    final results = extractTop<models.Category>(
      query: query,
      choices: widget.categories,
      getter: (c) => c.name,
      limit: 1,
      cutoff: _categoryMatchCutoff,
    );
    return results.isEmpty ? null : results.first.choice;
  }

  void _stepQty(int dir) {
    final str = _draft.quantity;
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
    setState(() {
      _draft.quantity = next;
      _qtyCtrl.text = next;
      _qtyCtrl.selection = TextSelection.collapsed(offset: next.length);
    });
  }

  bool get _hasTarget =>
      !widget._allListsMode || widget.selectedTargetListId != null;

  bool get _hasContent =>
      _multiple ? _bulkNames().isNotEmpty : _nameCtrl.text.trim().isNotEmpty;

  ComposeSubmission _buildSubmission(String name) {
    return ComposeSubmission(
      name: name,
      description: _draft.description.trim().isEmpty
          ? null
          : _draft.description.trim(),
      quantity: _draft.quantity.trim().isEmpty ? null : _draft.quantity.trim(),
      categoryId: _draft.categoryId,
      storeIds: _draft.storeIds.toList(),
      labelIds: _draft.labelIds.toList(),
      rrule: _draft.rrule,
      deleteOnDone: _draft.deleteOnDoneForCreate,
      repeatFromCompletion: _draft.repeatFromCompletion,
      imageBytes: _multiple ? null : _draft.imageBytes,
      imageName: _multiple ? null : _draft.imageFile?.name,
      imageMime: (!_multiple && _draft.imageFile != null)
          ? (lookupMimeType(_draft.imageFile!.name) ?? 'image/jpeg')
          : null,
      barcode: _multiple ? null : _draft.barcode,
      // Price is a single-item concern — omitted entirely in bulk mode or when
      // the server lacks the capability.
      prices: (!_multiple && widget.priceEnabled && _draft.price.hasAnyPrice)
          ? _draft.price.toItemPrices()
          : null,
      // Custom fields are single-item too; carry the fields' defaults plus any
      // tray edits. Omitted in bulk mode or when no fields apply.
      customFields: _composeCustomFields(),
    );
  }

  /// The custom-field values for the submission, or null when none apply or in
  /// bulk mode.
  List<FieldValue>? _composeCustomFields() {
    if (_multiple || _applicableCustomFields.isEmpty) return null;
    final values = _effectiveCustomFields;
    return values.isEmpty ? null : values;
  }

  Future<void> _submit() async {
    if (_submitting || !_hasTarget) return;
    final names = _multiple
        ? _bulkNames()
        : [_nameCtrl.text.trim()].where((s) => s.isNotEmpty).toList();
    if (names.isEmpty) return;
    setState(() => _submitting = true);
    bool allOk = true;
    for (final n in names) {
      final ok = await widget.onSubmit(_buildSubmission(n));
      if (!mounted) return;
      if (!ok) {
        allOk = false;
        break;
      }
    }
    if (allOk) {
      setState(() {
        _draft.reset(_defaultLifecycle());
        _customFieldsEdited = false;
        _nameCtrl.clear();
        _qtyCtrl.clear();
        _openTray = null;
      });
      _focusNode.requestFocus();
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Reuse suggestions share the Flexible slot with the trays, so they only
    // surface while no tray is open (i.e. while the user is typing the name).
    final reuseMatches = _openTray == null
        ? _reuseMatches()
        : const <ListItem>[];

    Widget? trayChild;
    switch (_openTray) {
      case Tray.targetList:
        trayChild = widget._allListsMode
            ? TargetListTray(
                lists: widget.targetLists!,
                selectedId: widget.selectedTargetListId,
                onSelected: (id) {
                  widget.onTargetListChanged?.call(id);
                  setState(() => _openTray = null);
                },
              )
            : null;
      case Tray.category:
        trayChild = CategoryTray(
          categories: widget.categories,
          selectedId: _draft.categoryId,
          onSelected: (id) {
            setState(() {
              _draft.categoryId = id;
              _openTray = null;
            });
          },
          onRequestCreate: widget.onRequestCreateCategory == null
              ? null
              : () async {
                  final created = await widget.onRequestCreateCategory!();
                  if (created == null || !mounted) return;
                  setState(() {
                    _draft.categoryId = created.id;
                    _openTray = null;
                  });
                },
        );
      case Tray.store:
        trayChild = StoreTray(
          stores: widget.stores,
          selectedIds: _draft.storeIds,
          onToggle: (id) {
            setState(() {
              if (!_draft.storeIds.remove(id)) _draft.storeIds.add(id);
            });
          },
          onRequestCreate: widget.onRequestCreateStore == null
              ? null
              : () async {
                  final created = await widget.onRequestCreateStore!();
                  if (created == null || !mounted) return;
                  setState(() => _draft.storeIds.add(created.id));
                },
        );
      case Tray.label:
        trayChild = LabelTray(
          labels: widget.labels,
          selectedIds: _draft.labelIds,
          onToggle: (id) {
            setState(() {
              if (!_draft.labelIds.remove(id)) _draft.labelIds.add(id);
            });
          },
          onRequestCreate: widget.onRequestCreateLabel == null
              ? null
              : () async {
                  final created = await widget.onRequestCreateLabel!();
                  if (created == null || !mounted) return;
                  setState(() => _draft.labelIds.add(created.id));
                },
        );
      case Tray.quantity:
        trayChild = QuantityTray(
          controller: _qtyCtrl,
          // setState so the chip row above rebuilds live as the user types
          // (e.g. the label flips back to "Quantity" when the field clears).
          onChanged: (v) => setState(() => _draft.quantity = v),
          onMinus: () => _stepQty(-1),
          onPlus: () => _stepQty(1),
        );
      case Tray.price:
        trayChild = PriceTray(
          draft: _draft.price,
          stores: widget.stores,
          perStoreEnabled: widget.perStorePriceEnabled,
          onChanged: () => setState(() {}),
        );
      case Tray.customFields:
        // Keyed by the target list so switching lists rebuilds with that list's
        // applicable fields (and their re-seeded defaults).
        trayChild = ItemCustomFieldsEditor(
          key: ValueKey('compose-cf-${_targetListId ?? 0}'),
          houseId: widget.houseId,
          listId: _targetListId,
          initial: _effectiveCustomFields,
          onChanged: (values) {
            _draft.customFields = values;
            _customFieldsEdited = true;
            // Rebuild so the chip's accent reflects the newly-set values.
            setState(() {});
          },
        );
      case Tray.description:
        trayChild = DescriptionTray(
          initialValue: _draft.description,
          onChanged: (v) => setState(() => _draft.description = v),
        );
      case Tray.type:
        trayChild = TypeTray(draft: _draft, onChanged: () => setState(() {}));
      case Tray.image:
        trayChild = ImageTray(
          bytes: _draft.imageBytes,
          onPick: _pickImage,
          onRemove: _removeImage,
        );
      case null:
        trayChild = null;
    }

    return Material(
      color: cs.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_active) ...[
              ChipRow(
                draft: _draft,
                categories: widget.categories,
                stores: widget.stores,
                labels: widget.labels,
                showStoreChip:
                    widget.stores.isNotEmpty ||
                    widget.onRequestCreateStore != null,
                showLabelChip:
                    widget.labels.isNotEmpty ||
                    widget.onRequestCreateLabel != null,
                showPriceChip: widget.priceEnabled && !_multiple,
                showCustomFieldsChip:
                    _applicableCustomFields.isNotEmpty && !_multiple,
                customFieldsSet: _effectiveCustomFields.isNotEmpty,
                openTray: _openTray,
                onOpen: _toggleTray,
                showImageChip: !_multiple,
                multiple: _multiple,
                onToggleMultiple: _toggleMultiple,
              ),
              const SizedBox(height: 10),
              if (trayChild != null) ...[
                // Tray takes whatever vertical room is left between the chip
                // row and the input bar. Content scrolls internally if it
                // doesn't fit (e.g. with the keyboard up).
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(child: trayChild),
                ),
                const SizedBox(height: 10),
              ] else if (reuseMatches.isNotEmpty) ...[
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    child: _ReuseSuggestions(
                      items: reuseMatches,
                      buildTile: widget.buildReuseSuggestion!,
                      onTap: _onSuggestionTap,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
            _Bar(
              focusNode: _focusNode,
              nameController: _nameCtrl,
              active: _active,
              placeholder: widget._allListsMode
                  ? m.checklists.addToAnyList
                  : m.checklists.addToList(widget.listName),
              onCancel: _cancel,
              onSubmit: _submit,
              submitting: _submitting,
              submitEnabled: _hasTarget && (!_multiple || _hasContent),
              onActivate: _activate,
              multiple: _multiple,
              onScan: _multiple ? null : _scanBarcode,
              targetListLeading: widget._allListsMode
                  ? BarTargetChip(
                      list: widget.targetLists
                          ?.cast<ChecklistList?>()
                          .firstWhere(
                            (l) => l!.id == widget.selectedTargetListId,
                            orElse: () => null,
                          ),
                      highlighted: _openTray == Tray.targetList,
                      onTap: () {
                        if (!_active) _activate();
                        _toggleTray(Tray.targetList);
                      },
                    )
                  : null,
            ),
            if (_active && _multiple) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Text(
                  m.checklists.compose.multipleHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final FocusNode focusNode;
  final TextEditingController nameController;
  final bool active;
  final String placeholder;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final VoidCallback onActivate;
  final bool submitting;
  final bool submitEnabled;
  final bool multiple;

  /// Opens the barcode scanner to prefill the draft. Null hides the scan
  /// button (e.g. in multi-add mode, where a scan can't map to one item).
  final VoidCallback? onScan;

  /// In All-lists mode the host passes a target-list chip here that replaces
  /// the resting "+" icon on the leading edge of the input. Tapping it opens
  /// the target-list picker tray. Outside All-lists mode this is null and
  /// the default "+" tile renders.
  final Widget? targetListLeading;

  const _Bar({
    required this.focusNode,
    required this.nameController,
    required this.active,
    required this.placeholder,
    required this.onCancel,
    required this.onSubmit,
    required this.onActivate,
    required this.submitting,
    required this.multiple,
    this.onScan,
    this.submitEnabled = true,
    this.targetListLeading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(
          color: active ? cs.primary : cs.outlineVariant,
          width: active ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 6, 6),
      child: Row(
        crossAxisAlignment: multiple
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(top: multiple ? 4 : 0),
            child:
                targetListLeading ??
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.add, color: cs.primary, size: 18),
                ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(top: multiple ? 8 : 0),
              child: TextField(
                controller: nameController,
                focusNode: focusNode,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: multiple
                    ? TextInputAction.newline
                    : TextInputAction.send,
                onSubmitted: multiple ? null : (_) => onSubmit(),
                onTap: onActivate,
                keyboardType: multiple
                    ? TextInputType.multiline
                    : TextInputType.text,
                minLines: multiple ? 3 : 1,
                maxLines: multiple ? 6 : 1,
                decoration: InputDecoration.collapsed(
                  hintText: placeholder,
                  hintStyle: TextStyle(color: cs.onSurfaceVariant),
                ),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          // Scan first, clear last: the clear (✕) always sits closest to the
          // submit button so its position is predictable. Plain tappables
          // rather than IconButtons — the latter reserve a 48px tap target that
          // leaves a big visual gap between two adjacent icons.
          //
          // Desktop/web have no camera scanning path, so the button opens
          // manual barcode entry — labelled and iconned to match.
          if (onScan != null)
            Padding(
              padding: EdgeInsetsDirectional.only(top: multiple ? 4 : 0),
              child: _BarIconAction(
                icon: PlatformInfo.isMobile
                    ? Icons.qr_code_scanner
                    : Icons.keyboard,
                tooltip: PlatformInfo.isMobile
                    ? m.checklists.barcode.scan
                    : m.checklists.barcode.manualTitle,
                color: cs.primary,
                onTap: onScan!,
              ),
            ),
          if (active)
            Padding(
              padding: EdgeInsetsDirectional.only(top: multiple ? 4 : 0),
              child: _BarIconAction(
                icon: Icons.close,
                tooltip: m.common.cancel,
                color: cs.onSurfaceVariant,
                onTap: onCancel,
              ),
            ),
          const SizedBox(width: 4),
          Padding(
            padding: EdgeInsetsDirectional.only(top: multiple ? 4 : 0),
            child: GestureDetector(
              onTap: (submitting || !submitEnabled) ? null : onSubmit,
              child: Opacity(
                opacity: submitEnabled ? 1.0 : 0.45,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: submitting
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact 32×32 icon action for the input bar's trailing row. Unlike
/// [IconButton] it reserves no oversized tap target, so adjacent actions
/// (scan, clear) sit snugly together.
class _BarIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _BarIconAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class MultipleToggle extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const MultipleToggle({super.key, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = active ? cs.primary : cs.onSurfaceVariant;
    return Tooltip(
      message: m.checklists.compose.multiple,
      waitDuration: const Duration(milliseconds: 600),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 30,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: 0.14) : Colors.transparent,
            border: Border.all(
              color: active ? accent.withValues(alpha: 0.4) : cs.outlineVariant,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.format_list_bulleted, size: 14, color: accent),
              const SizedBox(width: 5),
              Text(
                m.checklists.compose.multiple,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panel of fuzzy-matched existing items shown above the input while composing
/// a single item. Each row is a read-only [ChecklistItemTile.suggestion] built
/// by the host; tapping one runs the reuse-confirm flow.
class _ReuseSuggestions extends StatelessWidget {
  final List<ListItem> items;
  final Widget Function(ListItem item, VoidCallback onTap) buildTile;
  final ValueChanged<ListItem> onTap;

  const _ReuseSuggestions({
    required this.items,
    required this.buildTile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 14, 9),
            child: Text(
              m.checklists.reuse.suggestionsHeader.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            buildTile(items[i], () => onTap(items[i])),
          ],
        ],
      ),
    );
  }
}
