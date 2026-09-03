import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry/views/checklists/checklists_controller.dart';

import 'switcher_trash_stage.dart';

/// The archived-lists view: a hidden second state that mirrors the trash view
/// but is never bulk-emptied (no "empty" button) or auto-purged. Tapping a tile
/// opens the archived list into the normal item view; the trailing menu offers
/// Unarchive as the one-tap recover action.
class ArchiveStage extends StatefulWidget {
  final ChecklistsController controller;
  final VoidCallback onBack;

  const ArchiveStage({
    super.key,
    required this.controller,
    required this.onBack,
  });

  @override
  State<ArchiveStage> createState() => _ArchiveStageState();
}

class _ArchiveStageState extends State<ArchiveStage> {
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
      await widget.controller.loadArchivedLists();
    } catch (_) {
      if (!mounted) return;
      _error = m.checklists.failedToLoadArchivedLists;
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final archived = widget.controller.archivedLists;

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
                m.checklists.archivedListsTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
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
        else if (archived.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                m.checklists.archivedListsEmpty,
                style: TextStyle(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
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
              itemCount: archived.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final list = archived[i];
                // Unarchive needs canEditLists; a viewer can still browse the
                // list's items by tapping, but gets no recover action.
                final canUnarchive = widget.controller.permissions.canEditLists;
                return TrashedListTile(
                  list: list,
                  onTap: () => _openList(list),
                  onMenu: canUnarchive ? () => _showActions(list) : null,
                  glyph: Icons.archive_outlined,
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
              leading: const Icon(Icons.unarchive_outlined),
              title: Text(m.checklists.unarchiveList),
              onTap: () => Navigator.pop(ctx, 'unarchive'),
            ),
          ],
        ),
      ),
    );
    if (action != 'unarchive' || !mounted) return;
    try {
      await widget.controller.unarchiveList(list);
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(m.checklists.unarchiveListFailed)));
    }
  }
}
