import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/services/server_version_service.dart';
import 'package:pantry/utils/checklist_icons.dart';
import 'package:pantry/utils/color.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';

class TrashStage extends StatefulWidget {
  final ChecklistsController controller;
  final VoidCallback onBack;

  const TrashStage({super.key, required this.controller, required this.onBack});

  @override
  State<TrashStage> createState() => _TrashStageState();
}

class _TrashStageState extends State<TrashStage> {
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
                final canOpen = hasFeature('checklist-trash-open');
                return TrashedListTile(
                  list: list,
                  // With the open capability a tap browses the list's items and
                  // restore/permanent move to the trailing menu; without it the
                  // tap keeps its old actions-only behaviour.
                  onTap: canOpen
                      ? () => _openList(list)
                      : () => _showActions(list),
                  onMenu: canOpen ? () => _showActions(list) : null,
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _openList(ChecklistList list) async {
    Navigator.pop(context);
    await widget.controller.selectList(list);
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

class TrashedListTile extends StatelessWidget {
  final ChecklistList list;
  final VoidCallback onTap;

  /// When set, the tile shows a trailing overflow button that opens the
  /// restore / permanent-delete (or unarchive) actions, leaving [onTap] free to
  /// open the list. When null the tile shows a static [glyph] and [onTap]
  /// carries the actions itself (older servers without `checklist-trash-open`,
  /// or an archived list a viewer can't recover).
  final VoidCallback? onMenu;

  /// The static trailing glyph shown when [onMenu] is null.
  final IconData glyph;

  const TrashedListTile({
    super.key,
    required this.list,
    required this.onTap,
    this.onMenu,
    this.glyph = Icons.delete_outline,
  });

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
          padding: EdgeInsetsDirectional.only(
            start: 13,
            end: onMenu != null ? 4 : 13,
            top: 12,
            bottom: 12,
          ),
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
              if (onMenu != null)
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: m.checklists.restoreList,
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: onMenu,
                  ),
                )
              else
                Icon(glyph, color: cs.onSurfaceVariant, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
