import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart' as models;
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/utils/rrule.dart';
import 'checklist_item_tile.dart' show ItemLifecycle;

/// Draft state for an item being composed in the quick-add bar.
class ItemDraft {
  String name = '';
  String description = '';
  String quantity = '';
  int? categoryId;
  ItemLifecycle lifecycle = ItemLifecycle.staple;
  // RRULE state when lifecycle == recurring. Default = weekly every 1 week.
  String freq = 'WEEKLY';
  int interval = 1;
  Set<String> byDay = {};
  bool repeatFromCompletion = false;
  XFile? imageFile;
  Uint8List? imageBytes;

  void reset(ItemLifecycle defaultLifecycle) {
    name = '';
    description = '';
    quantity = '';
    categoryId = null;
    lifecycle = defaultLifecycle;
    freq = 'WEEKLY';
    interval = 1;
    byDay = {};
    repeatFromCompletion = false;
    imageFile = null;
    imageBytes = null;
  }

  String? get rrule {
    if (lifecycle != ItemLifecycle.recurring) return null;
    return buildRrule(
      freq: freq,
      interval: interval,
      byDay: freq == 'WEEKLY' && byDay.isNotEmpty ? byDay.toList() : null,
    );
  }

  bool get deleteOnDoneForCreate => lifecycle == ItemLifecycle.once;
}

/// Result returned by ItemComposeBar's onSubmit so caller can persist.
class ComposeSubmission {
  final String name;
  final String? description;
  final String? quantity;
  final int? categoryId;
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

  const ItemComposeBar({
    super.key,
    required this.listName,
    required this.deleteOnDoneDefault,
    required this.categories,
    required this.onSubmit,
    this.initiallyFocused = false,
    this.dimmedListBackground = false,
    this.onActiveChanged,
    this.onRequestCreateCategory,
  });

  @override
  State<ItemComposeBar> createState() => ItemComposeBarState();
}

enum _Tray { category, quantity, description, type, image }

class ItemComposeBarState extends State<ItemComposeBar> {
  late final ItemDraft _draft = ItemDraft()..lifecycle = _defaultLifecycle();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _active = false;
  _Tray? _openTray;
  bool _submitting = false;

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
  }

  void _activate() {
    if (_active) return;
    setState(() => _active = true);
    widget.onActiveChanged?.call(true);
  }

  @override
  void dispose() {
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

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final submission = ComposeSubmission(
      name: name,
      description: _draft.description.trim().isEmpty
          ? null
          : _draft.description.trim(),
      quantity: _draft.quantity.trim().isEmpty ? null : _draft.quantity.trim(),
      categoryId: _draft.categoryId,
      rrule: _draft.rrule,
      deleteOnDone: _draft.deleteOnDoneForCreate,
      repeatFromCompletion: _draft.repeatFromCompletion,
      imageBytes: _draft.imageBytes,
      imageName: _draft.imageFile?.name,
      imageMime: _draft.imageFile != null
          ? (lookupMimeType(_draft.imageFile!.name) ?? 'image/jpeg')
          : null,
    );
    final ok = await widget.onSubmit(submission);
    if (!mounted) return;
    if (ok) {
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

    Widget? trayChild;
    switch (_openTray) {
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
                openTray: _openTray,
                onOpen: _toggleTray,
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
              ],
            ],
            _Bar(
              focusNode: _focusNode,
              nameController: _nameCtrl,
              active: _active,
              placeholder: m.checklists.addToList(widget.listName),
              onCancel: _cancel,
              onSubmit: _submit,
              submitting: _submitting,
              onActivate: _activate,
            ),
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

  const _Bar({
    required this.focusNode,
    required this.nameController,
    required this.active,
    required this.placeholder,
    required this.onCancel,
    required this.onSubmit,
    required this.onActivate,
    required this.submitting,
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
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.add, color: cs.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: nameController,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmit(),
              onTap: onActivate,
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
          if (active)
            IconButton(
              icon: const Icon(Icons.close),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              iconSize: 20,
              onPressed: onCancel,
            ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: submitting ? null : onSubmit,
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
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final ItemDraft draft;
  final List<models.Category> categories;
  final _Tray? openTray;
  final ValueChanged<_Tray> onOpen;

  const _ChipRow({
    required this.draft,
    required this.categories,
    required this.openTray,
    required this.onOpen,
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
          _CatSwatch(
            label: m.checklists.compose.none,
            color: cs.onSurfaceVariant,
            selected: selectedId == null,
            onTap: () => onSelected(null),
          ),
          for (final c in categories)
            _CatSwatch(
              icon: categoryIcon(c.icon),
              label: c.name,
              color: _parseColor(c.color) ?? cs.primary,
              selected: selectedId == c.id,
              onTap: () => onSelected(c.id),
            ),
          if (onRequestCreate != null)
            _NewCategoryChip(
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

class _CatSwatch extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CatSwatch({
    this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : cs.surfaceContainer,
          border: Border.all(
            color: selected ? color : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Distinct from _CatSwatch — uses a "+" icon instead of a color dot and an
/// accent-tinted dashed-feeling border so it reads as an action rather than a
/// selectable category.
class _NewCategoryChip extends StatelessWidget {
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _NewCategoryChip({
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
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
              _StepperButton(icon: Icons.remove, onTap: onMinus),
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
              _StepperButton(icon: Icons.add, accent: true, onTap: onPlus),
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

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool accent;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    this.accent = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: accent
              ? cs.primary.withValues(alpha: 0.14)
              : cs.surfaceContainer,
          border: Border.all(
            color: accent
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          color: accent ? cs.primary : cs.onSurfaceVariant,
          size: 20,
        ),
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
          _TypeRow(
            label: t.staple,
            body: t.stapleBody,
            selected: draft.lifecycle == ItemLifecycle.staple,
            onTap: () => _set(ItemLifecycle.staple),
          ),
          const SizedBox(height: 7),
          _TypeRow(
            label: t.onceTime,
            body: t.onceTimeBody,
            selected: draft.lifecycle == ItemLifecycle.once,
            onTap: () => _set(ItemLifecycle.once),
          ),
          const SizedBox(height: 7),
          _TypeRow(
            label: t.recurring,
            body: t.recurringBody,
            selected: draft.lifecycle == ItemLifecycle.recurring,
            onTap: () => _set(ItemLifecycle.recurring),
          ),
          if (draft.lifecycle == ItemLifecycle.recurring) ...[
            const SizedBox(height: 12),
            _RecurrenceInline(draft: draft, onChanged: onChanged),
          ],
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  final String label;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  const _TypeRow({
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

class _RecurrenceInline extends StatelessWidget {
  final ItemDraft draft;
  final VoidCallback onChanged;

  const _RecurrenceInline({required this.draft, required this.onChanged});

  static const _weekdays = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];

  @override
  Widget build(BuildContext context) {
    final r = m.recurrence;
    final cs = Theme.of(context).colorScheme;
    final dayAbbr = {
      'MO': r.dayAbbr.mo,
      'TU': r.dayAbbr.tu,
      'WE': r.dayAbbr.we,
      'TH': r.dayAbbr.th,
      'FR': r.dayAbbr.fr,
      'SA': r.dayAbbr.sa,
      'SU': r.dayAbbr.su,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Every N <unit>
          Row(
            children: [
              Text(
                r.everyLabel,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 10),
              _StepperButton(
                icon: Icons.remove,
                onTap: () {
                  if (draft.interval > 1) {
                    draft.interval--;
                    onChanged();
                  }
                },
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${draft.interval}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StepperButton(
                icon: Icons.add,
                accent: true,
                onTap: () {
                  draft.interval++;
                  onChanged();
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  value: draft.freq,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: 'DAILY', child: Text(r.unitDays)),
                    DropdownMenuItem(value: 'WEEKLY', child: Text(r.unitWeeks)),
                    DropdownMenuItem(
                      value: 'MONTHLY',
                      child: Text(r.unitMonths),
                    ),
                    DropdownMenuItem(value: 'YEARLY', child: Text(r.unitYears)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    draft.freq = v;
                    if (v != 'WEEKLY') draft.byDay.clear();
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          if (draft.freq == 'WEEKLY') ...[
            const SizedBox(height: 10),
            Text(
              r.repeatOn,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in _weekdays)
                  FilterChip(
                    label: Text(dayAbbr[d] ?? d),
                    selected: draft.byDay.contains(d),
                    onSelected: (sel) {
                      if (sel) {
                        draft.byDay.add(d);
                      } else {
                        draft.byDay.remove(d);
                      }
                      onChanged();
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: draft.repeatFromCompletion,
            onChanged: (v) {
              draft.repeatFromCompletion = v;
              onChanged();
            },
            title: Text(
              r.countFromCompletion,
              style: TextStyle(fontSize: 13, color: cs.onSurface),
            ),
          ),
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
