import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/models/store.dart' as models;
import 'package:pantry/models/checklist.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/checklist_icons.dart';
import 'package:pantry/utils/rrule.dart';
import 'package:pantry/utils/store_icons.dart';
import 'package:pantry/views/checklists/checklist_switcher_sheet.dart'
    show parseHexColor;
import 'checklist_item_tile.dart' show ItemLifecycle;
import 'form_components.dart';

/// Draft state for an item being composed in the quick-add bar.
class ItemDraft {
  String name = '';
  String description = '';
  String quantity = '';
  int? categoryId;
  Set<int> storeIds = {};
  ItemLifecycle lifecycle = ItemLifecycle.staple;
  // RRULE state when lifecycle == recurring. Default = weekly every 1 week.
  RecurrenceState recurrence = RecurrenceState();
  XFile? imageFile;
  Uint8List? imageBytes;

  void reset(ItemLifecycle defaultLifecycle) {
    name = '';
    description = '';
    quantity = '';
    categoryId = null;
    storeIds = {};
    lifecycle = defaultLifecycle;
    recurrence = RecurrenceState();
    imageFile = null;
    imageBytes = null;
  }

  bool get repeatFromCompletion => recurrence.repeatFromCompletion;

  String? get rrule {
    if (lifecycle != ItemLifecycle.recurring) return null;
    return recurrence.toRrule();
  }

  bool get deleteOnDoneForCreate => lifecycle == ItemLifecycle.once;
}

/// Result returned by ItemComposeBar's onSubmit so caller can persist.
class ComposeSubmission {
  final String name;
  final String? description;
  final String? quantity;
  final int? categoryId;
  final List<int> storeIds;
  final String? rrule;
  final bool deleteOnDone;
  final bool repeatFromCompletion;
  final Uint8List? imageBytes;
  final String? imageName;
  final String? imageMime;

  const ComposeSubmission({
    required this.name,
    this.description,
    this.quantity,
    this.categoryId,
    this.storeIds = const [],
    this.rrule,
    required this.deleteOnDone,
    required this.repeatFromCompletion,
    this.imageBytes,
    this.imageName,
    this.imageMime,
  });
}

class ItemComposeBar extends StatefulWidget {
  final String listName;
  final bool deleteOnDoneDefault;
  final List<models.Category> categories;

  /// Stores offered in the store tray. Empty (and the store chip hidden) when
  /// the server lacks the `stores` capability.
  final List<models.Store> stores;
  final Future<bool> Function(ComposeSubmission submission) onSubmit;
  final bool initiallyFocused;
  final bool dimmedListBackground;

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
  /// the user can reuse one instead of creating a duplicate (issue #104).
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

  const ItemComposeBar({
    super.key,
    required this.listName,
    required this.deleteOnDoneDefault,
    required this.categories,
    this.stores = const [],
    required this.onSubmit,
    this.initiallyFocused = false,
    this.dimmedListBackground = false,
    this.onActiveChanged,
    this.onRequestCreateCategory,
    this.onRequestCreateStore,
    this.targetLists,
    this.selectedTargetListId,
    this.onTargetListChanged,
    this.reuseCandidates = const [],
    this.buildReuseSuggestion,
    this.onReuseExisting,
  });

  bool get _allListsMode => targetLists != null;

  @override
  State<ItemComposeBar> createState() => ItemComposeBarState();
}

enum _Tray { targetList, category, store, quantity, description, type, image }

class ItemComposeBarState extends State<ItemComposeBar> {
  late final ItemDraft _draft = ItemDraft()..lifecycle = _defaultLifecycle();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _active = false;
  _Tray? _openTray;
  bool _submitting = false;
  bool _multiple = false;

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

  void _onNameChanged() {
    // Rebuild so the bulk-add hint tracks input in multiple mode, and the
    // single-mode reuse suggestions re-filter as the user types.
    if (_multiple || widget.reuseCandidates.isNotEmpty) setState(() {});
  }

  /// Max reuse suggestions surfaced at once — enough to catch the near matches
  /// without turning the compose bar into a full second list.
  static const _maxReuseSuggestions = 6;

  /// Minimum fuzzy score (0–100) a candidate must clear to be offered. Set so
  /// per-word matches ("Organic milk" → "Milk", ~90 via partial ratio) and
  /// light typos survive, while unrelated names are filtered out.
  static const _reuseMatchCutoff = 60;

  /// Single-mode fuzzy matches of the typed name against [reuseCandidates],
  /// best-ranked first. Uses fuzzywuzzy's weighted ratio, which blends token
  /// and partial matching — so extra words in the query ("Organic milk") still
  /// match a shorter item name ("Milk"). Empty in multiple mode, with no query,
  /// or when the feature is unwired.
  List<ListItem> _reuseMatches() {
    if (_multiple ||
        widget.buildReuseSuggestion == null ||
        widget.reuseCandidates.isEmpty) {
      return const [];
    }
    final query = _nameCtrl.text.trim();
    if (query.isEmpty) return const [];
    final results = extractTop<ListItem>(
      query: query,
      choices: widget.reuseCandidates,
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
      _descCtrl.clear();
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
        if (_openTray == _Tray.image) _openTray = null;
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
    _descCtrl.dispose();
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
      _descCtrl.clear();
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

  void _toggleTray(_Tray t) {
    setState(() {
      _openTray = _openTray == t ? null : t;
    });
    if (t == _Tray.quantity) {
      _qtyCtrl.text = _draft.quantity;
    } else if (t == _Tray.description) {
      _descCtrl.text = _draft.description;
    }
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
      rrule: _draft.rrule,
      deleteOnDone: _draft.deleteOnDoneForCreate,
      repeatFromCompletion: _draft.repeatFromCompletion,
      imageBytes: _multiple ? null : _draft.imageBytes,
      imageName: _multiple ? null : _draft.imageFile?.name,
      imageMime: (!_multiple && _draft.imageFile != null)
          ? (lookupMimeType(_draft.imageFile!.name) ?? 'image/jpeg')
          : null,
    );
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
        _nameCtrl.clear();
        _qtyCtrl.clear();
        _descCtrl.clear();
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
      case _Tray.targetList:
        trayChild = widget._allListsMode
            ? _TargetListTray(
                lists: widget.targetLists!,
                selectedId: widget.selectedTargetListId,
                onSelected: (id) {
                  widget.onTargetListChanged?.call(id);
                  setState(() => _openTray = null);
                },
              )
            : null;
      case _Tray.category:
        trayChild = _CategoryTray(
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
      case _Tray.store:
        trayChild = _StoreTray(
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
      case _Tray.quantity:
        trayChild = _QuantityTray(
          controller: _qtyCtrl,
          // setState so the chip row in the bar above rebuilds live with each
          // keystroke (label flips back to "Quantity" the moment the user
          // clears the field, etc).
          onChanged: (v) => setState(() => _draft.quantity = v),
          onMinus: () => _stepQty(-1),
          onPlus: () => _stepQty(1),
        );
      case _Tray.description:
        trayChild = _DescriptionTray(
          controller: _descCtrl,
          onChanged: (v) => setState(() => _draft.description = v),
        );
      case _Tray.type:
        trayChild = _TypeTray(draft: _draft, onChanged: () => setState(() {}));
      case _Tray.image:
        trayChild = _ImageTray(
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
              _ChipRow(
                draft: _draft,
                categories: widget.categories,
                stores: widget.stores,
                showStoreChip:
                    widget.stores.isNotEmpty ||
                    widget.onRequestCreateStore != null,
                openTray: _openTray,
                onOpen: _toggleTray,
                showImageChip: !_multiple,
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
              onToggleMultiple: _toggleMultiple,
              targetListLeading: widget._allListsMode
                  ? _BarTargetChip(
                      list: widget.targetLists
                          ?.cast<ChecklistList?>()
                          .firstWhere(
                            (l) => l!.id == widget.selectedTargetListId,
                            orElse: () => null,
                          ),
                      highlighted: _openTray == _Tray.targetList,
                      onTap: () {
                        if (!_active) _activate();
                        _toggleTray(_Tray.targetList);
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
  final VoidCallback onToggleMultiple;

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
    required this.onToggleMultiple,
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
          if (active) ...[
            Padding(
              padding: EdgeInsetsDirectional.only(top: multiple ? 4 : 0),
              child: _MultipleToggle(active: multiple, onTap: onToggleMultiple),
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(top: multiple ? 4 : 0),
              child: IconButton(
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                iconSize: 20,
                onPressed: onCancel,
              ),
            ),
          ],
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

class _MultipleToggle extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _MultipleToggle({required this.active, required this.onTap});

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

class _ChipRow extends StatelessWidget {
  final ItemDraft draft;
  final List<models.Category> categories;
  final List<models.Store> stores;
  final bool showStoreChip;
  final _Tray? openTray;
  final ValueChanged<_Tray> onOpen;
  final bool showImageChip;

  const _ChipRow({
    required this.draft,
    required this.categories,
    required this.stores,
    required this.showStoreChip,
    required this.openTray,
    required this.onOpen,
    this.showImageChip = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cat = draft.categoryId != null
        ? categories.cast<models.Category?>().firstWhere(
            (c) => c!.id == draft.categoryId,
            orElse: () => null,
          )
        : null;
    final catColor = cat != null
        ? (_parseColor(cat.color) ?? cs.primary)
        : cs.onSurfaceVariant;

    final selectedStores = [
      for (final s in stores)
        if (draft.storeIds.contains(s.id)) s,
    ];
    final hasStores = selectedStores.isNotEmpty;
    final storeColor = hasStores
        ? (parseHexColor(selectedStores.first.color) ?? cs.primary)
        : cs.onSurfaceVariant;
    final storeLabel = !hasStores
        ? m.checklists.compose.chipStore
        : selectedStores.length == 1
        ? selectedStores.first.name
        : '${selectedStores.first.name} +${selectedStores.length - 1}';

    final hasQty = draft.quantity.trim().isNotEmpty;
    final hasDesc = draft.description.trim().isNotEmpty;
    final hasType = draft.lifecycle != ItemLifecycle.staple;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ComposeChip(
            label: cat?.name ?? m.checklists.compose.chipCategory,
            color: cat != null ? catColor : null,
            icon: cat != null ? null : Icons.label_outline,
            leading: cat != null
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: catColor,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
            selected: openTray == _Tray.category,
            onTap: () => onOpen(_Tray.category),
          ),
          if (showStoreChip) ...[
            const SizedBox(width: 8),
            _ComposeChip(
              label: storeLabel,
              color: hasStores ? storeColor : null,
              icon: hasStores ? null : Icons.store,
              leading: hasStores
                  ? Icon(
                      storeIcon(selectedStores.first.icon),
                      size: 14,
                      color: storeColor,
                    )
                  : null,
              selected: openTray == _Tray.store,
              onTap: () => onOpen(_Tray.store),
            ),
          ],
          const SizedBox(width: 8),
          _ComposeChip(
            label: hasQty ? draft.quantity : m.checklists.compose.chipQuantity,
            color: hasQty ? cs.primary : null,
            icon: Icons.format_list_numbered,
            selected: openTray == _Tray.quantity,
            onTap: () => onOpen(_Tray.quantity),
          ),
          const SizedBox(width: 8),
          // Description label is intentionally static even when set —
          // descriptions are typically long, so the chip only flips its
          // accent state instead of trying to preview the text.
          _ComposeChip(
            label: m.checklists.compose.chipDescription,
            color: hasDesc ? cs.primary : null,
            icon: Icons.notes_outlined,
            selected: openTray == _Tray.description,
            onTap: () => onOpen(_Tray.description),
          ),
          const SizedBox(width: 8),
          _ComposeChip(
            label: hasType
                ? _typeChipLabel(draft)
                : m.checklists.compose.chipType,
            color: hasType ? cs.primary : null,
            icon: Icons.cached,
            selected: openTray == _Tray.type,
            onTap: () => onOpen(_Tray.type),
          ),
          if (showImageChip) ...[
            const SizedBox(width: 8),
            _ComposeChip(
              label: draft.imageBytes != null
                  ? '✓'
                  : m.checklists.compose.chipImage,
              color: draft.imageBytes != null ? cs.primary : null,
              icon: Icons.image_outlined,
              selected: openTray == _Tray.image,
              onTap: () => onOpen(_Tray.image),
            ),
          ],
        ],
      ),
    );
  }

  static String _typeChipLabel(ItemDraft d) {
    switch (d.lifecycle) {
      case ItemLifecycle.staple:
        return m.checklists.itemTypes.staple;
      case ItemLifecycle.once:
        return m.checklists.itemTypes.onceTime;
      case ItemLifecycle.recurring:
        final r = d.rrule;
        if (r == null) return m.checklists.itemTypes.recurring;
        return formatRrule(r);
    }
  }

  static Color? _parseColor(String hex) {
    if (hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : null;
  }
}

class _ComposeChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  const _ComposeChip({
    required this.label,
    this.color,
    this.icon,
    this.leading,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = color ?? cs.onSurfaceVariant;
    final isSet = color != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSet
              ? accent.withValues(alpha: 0.14)
              : cs.surfaceContainerHighest,
          border: Border.all(
            color: isSet
                ? accent.withValues(alpha: 0.4)
                : (selected ? cs.primary : cs.outlineVariant),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSet ? FontWeight.w700 : FontWeight.w600,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Leading chip in the input bar (All-lists mode only) that opens the
/// target-list picker. When no list is selected yet it reads as an outlined
/// "Pick a list" affordance; once a list is chosen it switches to the list's
/// color + icon. Tap surface matches the size of the resting "+" tile so the
/// input field's baseline doesn't shift between modes.
class _BarTargetChip extends StatelessWidget {
  final ChecklistList? list;
  final bool highlighted;
  final VoidCallback onTap;

  const _BarTargetChip({
    required this.list,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasList = list != null;
    final accent = hasList
        ? (parseHexColor(list!.color) ?? cs.primary)
        : cs.onSurfaceVariant;
    final tooltip = hasList ? list!.name : m.checklists.compose.pickTargetList;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: 30,
          padding: EdgeInsetsDirectional.symmetric(horizontal: hasList ? 9 : 8),
          decoration: BoxDecoration(
            color: hasList
                ? accent.withValues(alpha: 0.14)
                : Colors.transparent,
            border: Border.all(
              color: hasList
                  ? accent.withValues(alpha: 0.4)
                  : (highlighted ? cs.primary : cs.outlineVariant),
              width: highlighted ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasList
                    ? checklistIcon(list!.icon)
                    : Icons.playlist_add_outlined,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: Text(
                  hasList ? list!.name : m.checklists.compose.pickTargetList,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: hasList ? FontWeight.w700 : FontWeight.w600,
                    color: accent,
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

class _TargetListTray extends StatelessWidget {
  final List<ChecklistList> lists;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  const _TargetListTray({
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

class _CategoryTray extends StatelessWidget {
  final List<models.Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;
  final Future<void> Function()? onRequestCreate;

  const _CategoryTray({
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
class _StoreTray extends StatelessWidget {
  final List<models.Store> stores;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;
  final Future<void> Function()? onRequestCreate;

  const _StoreTray({
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

class _QuantityTray extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _QuantityTray({
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

class _DescriptionTray extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _DescriptionTray({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _TrayShell(
      label: m.checklists.compose.chipDescription,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textCapitalization: TextCapitalization.sentences,
        minLines: 3,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: m.checklists.compose.descHint,
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
        ),
        style: const TextStyle(fontSize: 15),
      ),
    );
  }
}

class _TypeTray extends StatelessWidget {
  final ItemDraft draft;
  final VoidCallback onChanged;

  const _TypeTray({required this.draft, required this.onChanged});

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

class _ImageTray extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImageTray({
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
                  child: Image.memory(
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
