import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/utils/checklist_icons.dart';
import 'package:pantry_core/utils/color.dart';
import 'package:pantry_core/utils/list_kind_strings.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry/utils/app_toast.dart';

import 'checklists_controller.dart';

/// Applies a template: copies its items into a checklist or inventory that
/// already exists. Opened from a template ([source] is the template, the member
/// picks the list) or from a list ([source] is the list, the member picks the
/// template); either way the member reviews the items before they are copied.
/// A dialog on desktop, a bottom sheet on a phone.
Future<void> showApplyTemplate(
  BuildContext context,
  ChecklistsController controller,
  ChecklistList source,
) {
  final view = ApplyTemplateView(controller: controller, source: source);
  if (PlatformInfo.isDesktopHost) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
          child: view,
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: view,
    ),
  );
}

class ApplyTemplateView extends StatefulWidget {
  final ChecklistsController controller;
  final ChecklistList source;

  const ApplyTemplateView({
    super.key,
    required this.controller,
    required this.source,
  });

  @override
  State<ApplyTemplateView> createState() => _ApplyTemplateViewState();
}

class _PickGroup {
  final String title;
  final List<ChecklistList> lists;

  const _PickGroup(this.title, this.lists);
}

class _Row {
  final ListItem item;

  /// Already on the list, active and unchecked: applying would change nothing.
  final bool alreadyOpen;

  const _Row(this.item, {required this.alreadyOpen});
}

class _ApplyTemplateViewState extends State<ApplyTemplateView> {
  bool _loading = true;
  bool _submitting = false;
  List<_PickGroup> _groups = const [];
  ChecklistList? _template;
  ChecklistList? _target;
  List<_Row> _rows = const [];
  final Set<int> _selected = {};

  ChecklistsController get _controller => widget.controller;
  bool get _fromTemplate => widget.source.kind == ListKind.template;
  bool get _reviewing => _template != null && _target != null;

  @override
  void initState() {
    super.initState();
    if (_fromTemplate) {
      _template = widget.source;
    } else {
      _target = widget.source;
    }
    _run(_loadGroups);
  }

  Future<void> _run(Future<void> Function() load) async {
    setState(() => _loading = true);
    try {
      await load();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint('[ApplyTemplate] Failed to load: $e');
      if (!mounted) return;
      showAppToast(message: m.templates.loadFailed, kind: ToastKind.error);
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadGroups() async {
    if (_fromTemplate) {
      _groups = [
        for (final kind in [ListKind.checklist, ListKind.inventory])
          _PickGroup(kind.strings.title, [
            for (final l in _controller.sortedListsOfKind(kind))
              if (l.id > 0 && l.isWritable) l,
          ]),
      ].where((g) => g.lists.isNotEmpty).toList();
      return;
    }
    // The list's attached templates first, then the rest of the house's.
    final attached = (await _controller.loadAttachedTemplates(
      widget.source.id,
    )).all;
    final templates = [
      for (final t in _controller.sortedListsOfKind(ListKind.template))
        if (t.id > 0) t,
    ];
    _groups = [
      _PickGroup(m.templates.attachedTemplates, [
        for (final t in templates)
          if (attached.contains(t.id)) t,
      ]),
      _PickGroup(
        attached.isEmpty
            ? ListKind.template.strings.title
            : m.templates.otherTemplates,
        [
          for (final t in templates)
            if (!attached.contains(t.id)) t,
        ],
      ),
    ].where((g) => g.lists.isNotEmpty).toList();
  }

  void _choose(ChecklistList list) {
    setState(() {
      if (_fromTemplate) {
        _target = list;
      } else {
        _template = list;
      }
    });
    _run(_loadReview);
  }

  void _back() {
    setState(() {
      if (_fromTemplate) {
        _target = null;
      } else {
        _template = null;
      }
      _rows = const [];
      _selected.clear();
    });
  }

  Future<void> _loadReview() async {
    final service = ChecklistService.instance;
    final houseId = _controller.houseId;
    final results = await Future.wait([
      service.getItems(houseId, _template!.id),
      service.getItems(houseId, _target!.id),
    ]);
    final open = {
      for (final i in results[1])
        if (!i.done) itemNameKey(i.name),
    };
    _rows = [
      for (final item in results[0])
        _Row(item, alreadyOpen: open.contains(itemNameKey(item.name))),
    ];
    _selected
      ..clear()
      ..addAll([
        for (final r in _rows)
          if (!r.alreadyOpen) r.item.id,
      ]);
  }

  Future<void> _submit() async {
    final target = _target;
    if (target == null || _selected.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final ids = [
        for (final r in _rows)
          if (_selected.contains(r.item.id)) r.item.id,
      ];
      final result = await _controller.applyTemplate(ids, target);
      showAppToast(message: _appliedMessage(result, target));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('[ApplyTemplate] Failed to apply: $e');
      showAppToast(message: m.templates.applyFailed, kind: ToastKind.error);
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _appliedMessage(PantryBatchResult result, ChecklistList target) {
    final reused = result.reused.length;
    final added = result.items.length - reused;
    if (reused == 0) return m.templates.appliedAdded(added, target.name);
    if (added == 0) return m.templates.appliedReused(reused, target.name);
    return m.templates.appliedMixed(target.name, added, reused);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canGoBack = _reviewing;
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 4),
            child: Row(
              children: [
                if (canGoBack)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: m.templates.back,
                    onPressed: _submitting ? null : _back,
                  )
                else
                  const SizedBox(width: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _fromTemplate
                        ? m.templates.applyToList
                        : m.templates.applyTemplate,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _reviewing
                ? _buildReview(context)
                : _buildPick(context),
          ),
          if (_reviewing && !_loading)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: _submitting || _selected.isEmpty ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text(m.templates.applyItems(_selected.length)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPick(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_groups.isEmpty) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 32),
        child: Text(
          _fromTemplate
              ? m.templates.noTargets
              : ListKind.template.strings.emptyTitle,
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsetsDirectional.only(bottom: 16),
      children: [
        for (final group in _groups) ...[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 4),
            child: Text(
              group.title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          for (final list in group.lists)
            ListTile(
              contentPadding: const EdgeInsetsDirectional.symmetric(
                horizontal: 24,
              ),
              leading: Icon(
                checklistIcon(list.icon),
                color: parseHexColor(list.color) ?? cs.primary,
              ),
              title: Text(list.name),
              onTap: () => _choose(list),
            ),
        ],
      ],
    );
  }

  Widget _buildReview(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 4, 24, 8),
          child: Text(
            m.templates.reviewSummary(_template!.name, _target!.name),
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
        if (_rows.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 16),
            child: Text(
              m.templates.noItems,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          )
        else
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final row in _rows)
                  CheckboxListTile(
                    value: _selected.contains(row.item.id),
                    onChanged: _submitting
                        ? null
                        : (on) => setState(() {
                            if (on ?? false) {
                              _selected.add(row.item.id);
                            } else {
                              _selected.remove(row.item.id);
                            }
                          }),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 16,
                    ),
                    title: Text(row.item.name),
                    subtitle: _subtitle(row, cs),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget? _subtitle(_Row row, ColorScheme cs) {
    final quantity = row.item.quantity?.trim();
    final parts = [
      if (quantity != null && quantity.isNotEmpty) quantity,
      if (row.alreadyOpen) m.templates.alreadyOnList,
    ];
    if (parts.isEmpty) return null;
    return Text(
      parts.join(' · '),
      style: TextStyle(
        color: cs.onSurfaceVariant,
        fontStyle: row.alreadyOpen ? FontStyle.italic : null,
      ),
    );
  }
}
