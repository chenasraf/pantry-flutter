import 'package:flutter/material.dart';

import 'package:pantry/models/checklist.dart';
import 'package:pantry/utils/platform_info.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';

import 'switcher_archive_stage.dart';
import 'switcher_dropdown_route.dart';
import 'switcher_form_stage.dart';
import 'switcher_list_stage.dart';
import 'switcher_trash_stage.dart';

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
        SwitcherDropdownRoute(
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
        SheetHost(controller: controller, itemCountForList: itemCountForList),
  );
}

class SheetHost extends StatefulWidget {
  final ChecklistsController controller;
  final Future<int> Function(int listId) itemCountForList;

  /// When true, render as a desktop dropdown panel: no grabber bar, all
  /// corners rounded, drop shadow instead of a top border. Mobile bottom
  /// sheets keep the grabber + top-only rounding.
  final bool desktop;

  const SheetHost({
    super.key,
    required this.controller,
    required this.itemCountForList,
    this.desktop = false,
  });

  @override
  State<SheetHost> createState() => _SheetHostState();
}

enum _Stage { list, create, edit, trash, archive }

class _SheetHostState extends State<SheetHost> {
  _Stage _stage = _Stage.list;
  ChecklistList? _editing;

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
                builder: (_, _) => ListStage(
                  controller: widget.controller,
                  itemCountForList: widget.itemCountForList,
                  onCreateNew: () => setState(() => _stage = _Stage.create),
                  onEdit: (list) => setState(() {
                    _editing = list;
                    _stage = _Stage.edit;
                  }),
                  onOpenTrash: () => setState(() => _stage = _Stage.trash),
                  onOpenArchive: () => setState(() => _stage = _Stage.archive),
                ),
              )
            else if (_stage == _Stage.create)
              ListFormStage(
                controller: widget.controller,
                onBack: () => setState(() => _stage = _Stage.list),
                onSaved: () => Navigator.pop(context),
              )
            else if (_stage == _Stage.edit)
              ListFormStage(
                controller: widget.controller,
                existing: _editing,
                onBack: () => setState(() => _stage = _Stage.list),
                onSaved: () => setState(() => _stage = _Stage.list),
              )
            else if (_stage == _Stage.trash)
              TrashStage(
                controller: widget.controller,
                onBack: () => setState(() => _stage = _Stage.list),
              )
            else
              ArchiveStage(
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
