import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/label.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/label_service.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/sync/sync_ids.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/sync/sync_op.dart';
import 'package:pantry_core/utils/label_icons.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';
import 'package:pantry/widgets/create_label_dialog.dart';

class LabelsView extends StatefulWidget {
  final int houseId;

  const LabelsView({super.key, required this.houseId});

  @override
  State<LabelsView> createState() => _LabelsViewState();
}

class _LabelsViewState extends State<LabelsView> {
  static const _allSortKeys = ['custom', 'name_asc', 'name_desc'];
  List<String> get _sortKeys => hasFeature('label-sort')
      ? _allSortKeys
      : _allSortKeys.where((k) => k != 'custom').toList();

  List<Label> _labels = [];

  /// Lists in display order, used to group labels by scope and to label the
  /// per-list sections. Only loaded when the `label-lists` feature is on.
  List<ChecklistList> _lists = [];
  bool get _scopingEnabled => hasFeature('label-lists');
  String _sort = 'name_asc';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final prefsFuture = ChecklistService.instance.getHousePrefs(
        widget.houseId,
      );
      final labelsFuture = LabelService.instance.getLabels(widget.houseId);
      // Lists back the per-scope grouping; only needed when scoping is on.
      final listsFuture = _scopingEnabled
          ? ChecklistService.instance.getLists(widget.houseId)
          : Future.value(const <ChecklistList>[]);
      final results = await Future.wait([
        prefsFuture,
        labelsFuture,
        listsFuture,
      ]);
      if (!mounted) return;
      final prefs = results[0] as Map<String, dynamic>;
      final list = results[1] as List<Label>;
      final lists = results[2] as List<ChecklistList>;
      setState(() {
        var sort = prefs['labelSort'] as String? ?? 'name_asc';
        if (sort == 'custom' && !hasFeature('label-sort')) {
          sort = 'name_asc';
        }
        _sort = sort;
        _labels = LabelService.sortLabels(list, _sort);
        _lists = ChecklistService.sortLists(lists, 'custom');
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _setSort(String? value) async {
    if (value == null || value == _sort) return;
    setState(() {
      _sort = value;
      _labels = LabelService.sortLabels(_labels, _sort);
    });
    try {
      await LabelService.instance.setLabelSortPref(widget.houseId, value);
    } catch (e) {
      debugPrint('[LabelsView] Failed to persist sort: $e');
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (_sort != 'custom') return;
    setState(() {
      final item = _labels.removeAt(oldIndex);
      _labels.insert(newIndex, item);
    });
    _persistOrder(_labels);
  }

  /// Reorder within a single scope group. Only the dragged group's slice is
  /// reordered; the full house-wide sequence is then renumbered (the drag can't
  /// move a label across scopes — each group is its own reorderable).
  Future<void> _reorderGroup(
    _LabelGroup group,
    int oldIndex,
    int newIndex,
  ) async {
    if (_sort != 'custom') return;
    if (oldIndex == newIndex) return;

    final reordered = [...group.labels];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    // Splice the reordered slice back into the full display order, keeping every
    // other group untouched.
    final flat = <Label>[];
    for (final g in _buildGroups()) {
      flat.addAll(g.listId == group.listId ? reordered : g.labels);
    }
    setState(() => _labels = flat);
    _persistOrder(flat);
  }

  void _persistOrder(List<Label> ordered) {
    final order = <Map<String, int>>[];
    for (var i = 0; i < ordered.length; i++) {
      order.add({'id': ordered[i].id, 'sortOrder': i});
    }
    SyncManager.instance.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.label,
        op: SyncOpKind.reorder,
        houseId: widget.houseId,
        body: {'order': order},
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Partition [_labels] into scope groups for display: the global ("All
  /// lists") section first, then one section per list that has labels, in the
  /// lists' display order. Any label scoped to a list that isn't loaded (e.g.
  /// mid-removal) still gets a best-effort section so it stays visible.
  List<_LabelGroup> _buildGroups() {
    final globals = [
      for (final l in _labels)
        if (l.listId == null) l,
    ];
    final byList = <int, List<Label>>{};
    for (final l in _labels) {
      final lid = l.listId;
      if (lid != null) byList.putIfAbsent(lid, () => []).add(l);
    }

    final groups = <_LabelGroup>[];
    if (globals.isNotEmpty) {
      groups.add(
        _LabelGroup(listId: null, title: m.labels.globalList, labels: globals),
      );
    }
    for (final list in _lists) {
      final labels = byList.remove(list.id);
      if (labels != null && labels.isNotEmpty) {
        groups.add(
          _LabelGroup(listId: list.id, title: list.name, labels: labels),
        );
      }
    }
    // Orphans: scoped to a list we don't have loaded. Keep them addressable.
    for (final entry in byList.entries) {
      groups.add(
        _LabelGroup(
          listId: entry.key,
          title: '#${entry.key}',
          labels: entry.value,
        ),
      );
    }
    return groups;
  }

  Future<void> _create() async {
    final created = await showDialog<Label>(
      context: context,
      builder: (_) => CreateLabelDialog(houseId: widget.houseId),
    );
    if (created != null) {
      setState(() {
        _labels = LabelService.sortLabels([..._labels, created], _sort);
      });
    }
  }

  Future<void> _edit(Label label) async {
    final updated = await showDialog<Label>(
      context: context,
      builder: (_) =>
          CreateLabelDialog(houseId: widget.houseId, existing: label),
    );
    if (updated != null) {
      setState(() {
        final index = _labels.indexWhere((l) => l.id == updated.id);
        if (index != -1) {
          _labels[index] = updated;
          _labels = LabelService.sortLabels(_labels, _sort);
        }
      });
    }
  }

  Future<void> _delete(Label label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.labels.deleteConfirm),
        content: Text(m.labels.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.common.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _labels = _labels.where((l) => l.id != label.id).toList();
    });
    SyncManager.instance.enqueue(
      SyncOp(
        uuid: SyncIds.newOpUuid(),
        entity: SyncEntity.label,
        op: SyncOpKind.delete,
        houseId: widget.houseId,
        entityId: label.id < 0 ? null : label.id,
        tempEntityId: label.id < 0 ? label.id : null,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Color? _parseColor(String hex) {
    if (hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : null;
  }

  String _sortLabel(String key) => switch (key) {
    'name_asc' => m.labels.sort.nameAZ,
    'name_desc' => m.labels.sort.nameZA,
    _ => m.labels.sort.custom,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(m.labels.manageTitle),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: '',
            onSelected: _setSort,
            itemBuilder: (context) => [
              for (final key in _sortKeys)
                PopupMenuItem<String>(
                  value: key,
                  child: Row(
                    children: [
                      Icon(
                        key == _sort
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: key == _sort ? theme.colorScheme.primary : null,
                      ),
                      const SizedBox(width: 12),
                      Text(_sortLabel(key)),
                    ],
                  ),
                ),
            ],
          ),
          if (PlatformInfo.isDesktop)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: m.common.refresh,
              onPressed: _load,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: Text(m.common.retry)),
                  ],
                ),
              ),
            )
          : _labels.isEmpty
          ? Center(child: Text(m.labels.noLabels))
          : RefreshIndicator(
              onRefresh: _load,
              child: _scopingEnabled
                  ? _buildGroupedList(theme)
                  : _buildFlatList(theme),
            ),
    );
  }

  /// Flat, ungrouped list — used on servers without `label-lists`, where every
  /// label is global.
  Widget _buildFlatList(ThemeData theme) {
    if (_sort == 'custom') {
      return ReorderableListView.builder(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: _labels.length,
        onReorderItem: _reorder,
        itemBuilder: (context, index) =>
            _buildTile(theme, _labels[index], dragIndex: index),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: _labels.length,
      itemBuilder: (context, index) => _buildTile(theme, _labels[index]),
    );
  }

  /// Grouped by scope: an "All lists" section, then one section per list that
  /// has labels. In custom sort each group is its own reorderable, so drags
  /// stay within a scope.
  Widget _buildGroupedList(ThemeData theme) {
    final groups = _buildGroups();
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        for (final group in groups) ...[
          _buildSectionHeader(theme, group.title),
          if (_sort == 'custom')
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: group.labels.length,
              onReorderItem: (oldIndex, newIndex) =>
                  _reorderGroup(group, oldIndex, newIndex),
              itemBuilder: (context, index) =>
                  _buildTile(theme, group.labels[index], dragIndex: index),
            )
          else
            for (final label in group.labels) _buildTile(theme, label),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
    child: Text(
      title.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    ),
  );

  /// [dragIndex] is the item's index within its reorderable (the whole list
  /// when flat, the group when grouped); the drag handle is shown only when
  /// it's provided and the sort is custom.
  Widget _buildTile(ThemeData theme, Label label, {int? dragIndex}) {
    final color = _parseColor(label.color) ?? theme.colorScheme.primary;
    return ListTile(
      key: ValueKey(label.id),
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(40),
        child: Icon(labelIcon(label.icon), color: color),
      ),
      title: Text(label.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _edit(label),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: () => _delete(label),
          ),
          if (_sort == 'custom' && dragIndex != null)
            ReorderableDragStartListener(
              index: dragIndex,
              child: Icon(
                Icons.drag_handle,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      onTap: () => _edit(label),
    );
  }
}

/// A display group of labels sharing a scope: `listId == null` for the global
/// ("All lists") section, or a list id for a per-list section.
class _LabelGroup {
  final int? listId;
  final String title;
  final List<Label> labels;

  const _LabelGroup({
    required this.listId,
    required this.title,
    required this.labels,
  });
}
