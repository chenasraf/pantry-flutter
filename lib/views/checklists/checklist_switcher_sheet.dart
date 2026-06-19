import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/utils/checklist_icons.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/utils/undo_snackbar.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';

/// Per-list color swatches the user can pick from in the create form. Values
/// must come from the backend's `ChecklistColor` enum (Material Design 500
/// hues, lowercase hex) — anything else gets rejected by the API.
const List<String> kListColorSwatches = [
  '#f44336', // red
  '#ff9800', // orange
  '#ffc107', // amber
  '#4caf50', // green
  '#00bcd4', // cyan
  '#2196f3', // blue
  '#673ab7', // deep purple
  '#e91e63', // pink
];

Color? parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v != null ? Color(v) : null;
}

/// Show the checklist switcher. On mobile/web it slides up as a bottom sheet;
/// on desktop, when [anchorContext] is provided, it opens as a positioned
/// dropdown panel directly under the anchor (typically the AppBar's title
/// row) so the interaction reads as a desktop popup menu.
Future<void> showChecklistSwitcher(
  BuildContext context, {
  required ChecklistsController controller,
  required Future<int> Function(int listId) itemCountForList,
  BuildContext? anchorContext,
}) {
  if (PlatformInfo.isDesktop && anchorContext != null) {
    final anchor = anchorContext.findRenderObject() as RenderBox?;
    if (anchor != null && anchor.attached) {
      return Navigator.of(context).push(
        _SwitcherDropdownRoute(
          anchor: anchor,
          controller: controller,
          itemCountForList: itemCountForList,
        ),
      );
    }
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _SheetHost(controller: controller, itemCountForList: itemCountForList),
  );
}

/// Custom popup route that positions the switcher panel beneath the AppBar
/// title row. Mirrors the bottom-sheet panel design but drops the grabber
/// bar and rounds all four corners so it reads as a dropdown menu.
class _SwitcherDropdownRoute extends PopupRoute<void> {
  final RenderBox anchor;
  final ChecklistsController checklistsController;
  final Future<int> Function(int listId) itemCountForList;

  _SwitcherDropdownRoute({
    required this.anchor,
    required ChecklistsController controller,
    required this.itemCountForList,
  }) : checklistsController = controller;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.18);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 160);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> a,
    Animation<double> b,
  ) {
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    if (!anchor.attached) return const SizedBox.shrink();
    final anchorTopLeft = anchor.localToGlobal(Offset.zero, ancestor: overlay);
    final anchorSize = anchor.size;
    return _DropdownPositioner(
      anchorTopLeft: anchorTopLeft,
      anchorSize: anchorSize,
      child: _SheetHost(
        controller: checklistsController,
        itemCountForList: itemCountForList,
        desktop: true,
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    // Soft fade + tiny downward slide so the panel reads as "dropping" from
    // under the title.
    final slide = Tween<Offset>(
      begin: const Offset(0, -0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

/// Pins the dropdown panel to a fixed width directly below the anchor, with
/// the start edge aligned to the anchor's start. Clamps to the screen so the
/// panel never falls off the right edge.
class _DropdownPositioner extends StatelessWidget {
  final Offset anchorTopLeft;
  final Size anchorSize;
  final Widget child;

  static const double _panelWidth = 360;
  static const double _gap = 8;
  static const double _screenPad = 12;

  const _DropdownPositioner({
    required this.anchorTopLeft,
    required this.anchorSize,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final top = anchorTopLeft.dy + anchorSize.height + _gap;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // Anchor by the directional start edge so the dropdown's leading edge
    // lines up with the title's leading edge in both LTR and RTL.
    final desiredStart = isRtl
        ? anchorTopLeft.dx + anchorSize.width - _panelWidth
        : anchorTopLeft.dx;
    final left = desiredStart.clamp(
      _screenPad,
      screen.width - _panelWidth - _screenPad,
    );
    return Stack(
      children: [
        Positioned(left: left, top: top, width: _panelWidth, child: child),
      ],
    );
  }
}

class _SheetHost extends StatefulWidget {
  final ChecklistsController controller;
  final Future<int> Function(int listId) itemCountForList;

  /// When true, render as a desktop dropdown panel: no grabber bar, all
  /// corners rounded, drop shadow instead of a top border. Mobile bottom
  /// sheets keep the grabber + top-only rounding.
  final bool desktop;

  const _SheetHost({
    required this.controller,
    required this.itemCountForList,
    this.desktop = false,
  });

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

enum _Stage { list, create, trash }

class _SheetHostState extends State<_SheetHost> {
  _Stage _stage = _Stage.list;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final desktop = widget.desktop;
    final panel = Material(
      color: cs.surface,
      borderRadius: desktop
          ? BorderRadius.circular(16)
          : const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      elevation: desktop ? 8 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: Container(
        decoration: BoxDecoration(
          border: desktop
              ? Border.all(color: cs.outlineVariant)
              : Border(top: BorderSide(color: cs.outlineVariant)),
          borderRadius: desktop
              ? BorderRadius.circular(16)
              : const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          desktop ? 16 : 10,
          16,
          desktop ? 16 : 22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!desktop)
              Container(
                width: 38,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            if (_stage == _Stage.list)
              AnimatedBuilder(
                animation: widget.controller,
                builder: (_, _) => _ListStage(
                  controller: widget.controller,
                  itemCountForList: widget.itemCountForList,
                  onCreateNew: () => setState(() => _stage = _Stage.create),
                  onOpenTrash: () => setState(() => _stage = _Stage.trash),
                ),
              )
            else if (_stage == _Stage.create)
              _CreateStage(
                controller: widget.controller,
                onBack: () => setState(() => _stage = _Stage.list),
                onCreated: () => Navigator.pop(context),
              )
            else
              _TrashStage(
                controller: widget.controller,
                onBack: () => setState(() => _stage = _Stage.list),
              ),
          ],
        ),
      ),
    );
    return desktop
        ? AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: panel,
          )
        : SafeArea(
            top: false,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: panel,
            ),
          );
  }
}

class _ListStage extends StatelessWidget {
  final ChecklistsController controller;
  final Future<int> Function(int listId) itemCountForList;
  final VoidCallback onCreateNew;
  final VoidCallback onOpenTrash;

  const _ListStage({
    required this.controller,
    required this.itemCountForList,
    required this.onCreateNew,
    required this.onOpenTrash,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final realLists = hasFeature('checklist-sort')
        ? controller.sortedLists
        : controller.lists;
    final current = controller.currentList;
    // The synthetic "All lists" entry only earns its spot when there's more
    // than one real list to aggregate. With zero lists the index renders the
    // empty state; with one list, "All lists" would just duplicate that list.
    final showAllLists = realLists.length >= 2;
    final canReorder =
        hasFeature('checklist-sort') && controller.listSort == 'custom';
    final showMenu = hasFeature('checklist-trash');
    final allListsTile = showAllLists
        ? _AllListsTile(
            selected: current?.id == kAllListsId,
            onTap: () async {
              Navigator.pop(context);
              if (current?.id != kAllListsId) {
                await controller.selectList(
                  allListsSentinel(controller.houseId),
                );
              }
            },
          )
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 4,
            end: 0,
            bottom: 14,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                m.checklists.yourChecklists,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              Row(
                children: [
                  Text(
                    m.checklists.listsCount(realLists.length),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (hasFeature('checklist-sort'))
                    _SortMenuButton(controller: controller),
                ],
              ),
            ],
          ),
        ),
        if (allListsTile != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: allListsTile,
          ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: canReorder
              ? ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: realLists.length,
                  onReorder: controller.reorderLists,
                  proxyDecorator: (child, _, _) =>
                      Material(color: Colors.transparent, child: child),
                  itemBuilder: (_, i) {
                    final list = realLists[i];
                    final selected = list.id == current?.id;
                    return Padding(
                      key: ValueKey(list.id),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ListTile(
                        list: list,
                        selected: selected,
                        itemCountFuture: itemCountForList(list.id),
                        dragIndex: i,
                        showOverflow: showMenu,
                        onTap: () async {
                          Navigator.pop(context);
                          if (!selected) await controller.selectList(list);
                        },
                        onRemove: showMenu
                            ? () => _confirmRemove(context, list)
                            : null,
                      ),
                    );
                  },
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: realLists.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final list = realLists[i];
                    final selected = list.id == current?.id;
                    return _ListTile(
                      list: list,
                      selected: selected,
                      itemCountFuture: itemCountForList(list.id),
                      showOverflow: showMenu,
                      onTap: () async {
                        Navigator.pop(context);
                        if (!selected) await controller.selectList(list);
                      },
                      onRemove: showMenu
                          ? () => _confirmRemove(context, list)
                          : null,
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onCreateNew,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            decoration: BoxDecoration(
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.6),
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.add, color: cs.primary, size: 22),
                ),
                const SizedBox(width: 13),
                Text(
                  m.checklists.newChecklist,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasFeature('checklist-trash')) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: onOpenTrash,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    m.checklists.viewListsTrash,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmRemove(BuildContext context, ChecklistList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.checklists.removeListConfirm),
        content: Text(m.checklists.removeListConfirmBody(list.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.common.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await controller.deleteList(list);
      if (!context.mounted) return;
      Navigator.pop(context); // close the switcher sheet
      // Snackbar runs against the host scaffold, not the dismissed sheet.
      showUndoSnackBar(
        context,
        message: m.checklists.listRemoved,
        undoLabel: m.checklists.undo,
        onUndo: () => controller.restoreList(list),
        undoFailedMessage: m.checklists.restoreFailed,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.removeListFailed)));
      }
    }
  }
}

class _ListTile extends StatelessWidget {
  final ChecklistList list;
  final bool selected;
  final Future<int> itemCountFuture;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final int? dragIndex;
  final bool showOverflow;

  const _ListTile({
    required this.list,
    required this.selected,
    required this.itemCountFuture,
    required this.onTap,
    this.onRemove,
    this.dragIndex,
    this.showOverflow = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tint = parseHexColor(list.color) ?? cs.primary;
    final tile = Container(
      padding: EdgeInsetsDirectional.only(
        start: 13,
        end: dragIndex != null ? 4 : 8,
        top: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: selected
            ? cs.primary.withValues(alpha: 0.1)
            : cs.surfaceContainer,
        border: Border.all(
          color: selected ? cs.primary : cs.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(checklistIcon(list.icon), color: tint, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  list.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FutureBuilder<int>(
                  future: itemCountFuture,
                  builder: (_, snap) {
                    final count = snap.data ?? -1;
                    final label = count < 0
                        ? ''
                        : (count == 0
                              ? m.checklists.allDoneSummary
                              : m.checklists.itemsSummary(count));
                    return Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (selected)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
          if (showOverflow && onRemove != null)
            SizedBox(
              width: 36,
              height: 36,
              child: PopupMenuButton<String>(
                tooltip: '',
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
                onSelected: (v) {
                  if (v == 'remove') onRemove!();
                },
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: 'remove',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 18),
                        const SizedBox(width: 10),
                        Text(m.checklists.removeList),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (dragIndex != null)
            ReorderableDragStartListener(
              index: dragIndex!,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 2, end: 6),
                child: Icon(
                  Icons.drag_handle,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );

    final interactive = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: tile,
    );

    if (!PlatformInfo.isDesktop || onRemove == null) return interactive;

    return _ContextMenuRegion(
      onRemove: onRemove!,
      removeLabel: m.checklists.removeList,
      child: interactive,
    );
  }
}

/// Wraps a child with a desktop right-click menu offering the "remove" action.
class _ContextMenuRegion extends StatefulWidget {
  final Widget child;
  final VoidCallback onRemove;
  final String removeLabel;

  const _ContextMenuRegion({
    required this.child,
    required this.onRemove,
    required this.removeLabel,
  });

  @override
  State<_ContextMenuRegion> createState() => _ContextMenuRegionState();
}

class _ContextMenuRegionState extends State<_ContextMenuRegion> {
  Future<void> _openAt(BuildContext context, Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(globalPosition, globalPosition),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'remove',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 18),
              const SizedBox(width: 10),
              Text(widget.removeLabel),
            ],
          ),
        ),
      ],
    );
    if (result == 'remove') widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapDown: (d) => _openAt(context, d.globalPosition),
      child: widget.child,
    );
  }
}

class _SortMenuButton extends StatelessWidget {
  final ChecklistsController controller;

  const _SortMenuButton({required this.controller});

  String _label(String key) => switch (key) {
    'newest' => m.checklists.sort.newestFirst,
    'oldest' => m.checklists.sort.oldestFirst,
    'name_asc' => m.checklists.sort.nameAZ,
    'name_desc' => m.checklists.sort.nameZA,
    _ => m.checklists.sort.custom,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const keys = ['custom', 'name_asc', 'name_desc', 'newest', 'oldest'];
    return PopupMenuButton<String>(
      tooltip: m.checklists.sortTooltip,
      icon: Icon(Icons.sort, size: 20, color: cs.onSurfaceVariant),
      padding: EdgeInsets.zero,
      onSelected: controller.setListSort,
      itemBuilder: (_) => [
        for (final k in keys)
          PopupMenuItem<String>(
            value: k,
            child: Row(
              children: [
                Icon(
                  k == controller.listSort
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: k == controller.listSort ? cs.primary : null,
                ),
                const SizedBox(width: 10),
                Text(_label(k)),
              ],
            ),
          ),
      ],
    );
  }
}

class _CreateStage extends StatefulWidget {
  final ChecklistsController controller;
  final VoidCallback onBack;
  final VoidCallback onCreated;

  const _CreateStage({
    required this.controller,
    required this.onBack,
    required this.onCreated,
  });

  @override
  State<_CreateStage> createState() => _CreateStageState();
}

class _CreateStageState extends State<_CreateStage> {
  final _nameCtrl = TextEditingController();
  String _color = kListColorSwatches.first;
  String _icon = 'cart';
  bool _saving = false;

  // Per-list color is only meaningful on servers that ship the
  // `checklist-color` feature. On older servers, sending a color is rejected
  // by the backend's enum validation, so we hide the picker and let the
  // backend assign its default (the API treats absence and null as default).
  bool get _supportsListColor => hasFeature('checklist-color');

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.controller.createList(
        name: name,
        icon: _icon,
        color: _supportsListColor ? _color : null,
      );
      if (!mounted) return;
      // Auto-select the newly created list.
      final fresh = widget.controller.lists.firstWhere((l) => l.name == name);
      await widget.controller.selectList(fresh);
      widget.onCreated();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.createListFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedColor = parseHexColor(_color) ?? cs.primary;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 4),
                Text(
                  m.checklists.newChecklist,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: m.checklists.listName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
          if (_supportsListColor) ...[
            const SizedBox(height: 16),
            Text(
              m.checklists.listColor.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final hex in kListColorSwatches)
                  _ColorSwatch(
                    color: parseHexColor(hex)!,
                    selected: hex == _color,
                    onTap: () => setState(() => _color = hex),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            m.checklists.listIcon.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final entry in checklistIconMap.entries) ...[
                  _IconChip(
                    icon: entry.value,
                    selected: entry.key == _icon,
                    color: selectedColor,
                    onTap: () => setState(() => _icon = entry.key),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: _saving ? null : _create,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_saving)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(Icons.add, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    m.checklists.createListButton,
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
        ],
      ),
    );
  }
}

class _TrashStage extends StatefulWidget {
  final ChecklistsController controller;
  final VoidCallback onBack;

  const _TrashStage({required this.controller, required this.onBack});

  @override
  State<_TrashStage> createState() => _TrashStageState();
}

class _TrashStageState extends State<_TrashStage> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.controller.loadTrashedLists();
    } catch (_) {
      if (!mounted) return;
      _error = m.checklists.failedToLoadTrash;
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final trashed = widget.controller.trashedLists;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 14),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 4),
              Text(
                m.checklists.listsTrashTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              if (trashed.isNotEmpty)
                TextButton.icon(
                  onPressed: _confirmEmpty,
                  icon: const Icon(Icons.delete_forever, size: 16),
                  label: Text(m.checklists.emptyTrash),
                ),
            ],
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: Text(m.common.retry)),
              ],
            ),
          )
        else if (trashed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                m.checklists.listTrashEmpty,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: trashed.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final list = trashed[i];
                return _TrashedListTile(
                  list: list,
                  onTap: () => _showActions(list),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _showActions(ChecklistList list) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore_from_trash),
              title: Text(m.checklists.restoreList),
              onTap: () => Navigator.pop(ctx, 'restore'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: Text(m.checklists.permanentlyDeleteList),
              onTap: () => Navigator.pop(ctx, 'permanent'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'restore') {
      try {
        await widget.controller.restoreList(list);
        if (!mounted) return;
        setState(() {});
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.restoreFailed)));
      }
    } else if (action == 'permanent') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(m.checklists.permanentlyDeleteConfirm),
          content: Text(m.checklists.permanentlyDeleteConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(m.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(m.checklists.permanentlyDeleteList),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      try {
        await widget.controller.permanentlyDeleteList(list);
        if (mounted) setState(() {});
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(m.checklists.removeListFailed)));
      }
    }
  }

  Future<void> _confirmEmpty() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.checklists.emptyTrashConfirm),
        content: Text(m.checklists.emptyTrashConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.checklists.emptyTrash),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.controller.emptyListsTrash();
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(m.checklists.emptyTrashFailed)));
    }
  }
}

class _TrashedListTile extends StatelessWidget {
  final ChecklistList list;
  final VoidCallback onTap;

  const _TrashedListTile({required this.list, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tint = parseHexColor(list.color) ?? cs.onSurfaceVariant;
    return Opacity(
      opacity: 0.75,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(checklistIcon(list.icon), color: tint, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  list.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.delete_outline, color: cs.onSurfaceVariant, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: color, width: 2) : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 0,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

/// The synthetic "All lists" entry rendered at the top of the switcher. It's
/// not draggable, not editable, has no overflow menu, and doesn't show an
/// item count (the count would require fetching across every list).
class _AllListsTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _AllListsTile({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsetsDirectional.only(
          start: 13,
          end: 8,
          top: 12,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.1)
              : cs.surfaceContainer,
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(allListsIcon, color: cs.primary, size: 21),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.checklists.allLists,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.checklists.allListsSubtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _IconChip({
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : cs.surfaceContainer,
          border: Border.all(
            color: selected ? color : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          color: selected ? color : cs.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }
}
