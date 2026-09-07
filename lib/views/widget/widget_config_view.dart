import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/house.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'package:pantry/services/widget_service.dart';
import 'package:pantry_core/utils/text_direction.dart';

/// Lets the user pick which checklists a specific home-screen widget shows.
/// Reached via the `pantry://widget/config/<appWidgetId>` deep link — fired
/// when a widget is added or its header cog is tapped.
class WidgetConfigView extends StatefulWidget {
  final int appWidgetId;

  const WidgetConfigView({super.key, required this.appWidgetId});

  @override
  State<WidgetConfigView> createState() => _WidgetConfigViewState();
}

class _WidgetConfigViewState extends State<WidgetConfigView> {
  late Future<List<_HouseLists>> _future;
  final Set<int> _selected = {};
  final Map<int, ChecklistList> _byId = {};
  bool _loadedSelection = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_HouseLists>> _load() async {
    final selected = await WidgetService.instance.selectedListIds(
      widget.appWidgetId,
    );
    final houses =
        HouseService.instance.getCached() ??
        await HouseService.instance.getHouses();

    final result = <_HouseLists>[];
    for (final house in houses) {
      if (!house.effectivePermissions.canViewLists) continue;
      var lists = ChecklistService.instance.getCachedLists(house.id);
      if (lists == null) {
        try {
          lists = await ChecklistService.instance.getLists(house.id);
          ChecklistService.instance.cacheLists(house.id, lists);
        } catch (_) {
          lists = const [];
        }
      }
      if (lists.isEmpty) continue;
      for (final l in lists) {
        _byId[l.id] = l;
      }
      result.add(_HouseLists(house, lists));
    }

    if (!_loadedSelection) {
      _selected
        ..clear()
        ..addAll(selected);
      _loadedSelection = true;
    }
    return result;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final lists = [
      for (final id in _selected)
        if (_byId[id] != null) _byId[id]!,
    ];
    await WidgetService.instance.setWidgetLists(widget.appWidgetId, lists);
    // Commit the widget (RESULT_OK) and close the config activity, returning to
    // the launcher.
    await WidgetService.instance.finishConfig(ok: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _saving
              ? null
              : () => WidgetService.instance.finishConfig(ok: false),
        ),
        title: Text(m.widget.chooseListsTitle),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(m.common.save),
          ),
        ],
      ),
      body: FutureBuilder<List<_HouseLists>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = snapshot.data ?? const [];
          if (groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  m.widget.noLists,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            );
          }
          final showHeaders = groups.length > 1;
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
                child: Text(
                  m.widget.chooseListsSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final group in groups) ...[
                if (showHeaders) _HouseHeader(name: group.house.name),
                for (final list in group.lists) _listTile(list),
              ],
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _listTile(ChecklistList list) {
    final selected = _selected.contains(list.id);
    return CheckboxListTile(
      value: selected,
      onChanged: (v) => setState(() {
        if (v == true) {
          _selected.add(list.id);
        } else {
          _selected.remove(list.id);
        }
      }),
      title: Text(list.name, textDirection: detectTextDirection(list.name)),
    );
  }
}

class _HouseHeader extends StatelessWidget {
  final String name;

  const _HouseHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
      child: Text(
        name,
        textDirection: detectTextDirection(name),
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HouseLists {
  final House house;
  final List<ChecklistList> lists;

  const _HouseLists(this.house, this.lists);
}
