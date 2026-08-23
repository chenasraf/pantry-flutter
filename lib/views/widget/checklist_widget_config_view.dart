import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/models/house.dart';
import 'package:pantry/services/checklist_service.dart';
import 'package:pantry/services/checklist_widget_service.dart';
import 'package:pantry/services/house_service.dart';
import 'package:pantry/services/prefs_service.dart';
import 'package:pantry/services/widget_service.dart';
import 'package:pantry/utils/text_direction.dart';

/// Lets the user pick the single list a checklist widget shows. Reached via the
/// `/checklist-widget-config/<appWidgetId>` route in [ChecklistWidgetConfigActivity].
class ChecklistWidgetConfigView extends StatefulWidget {
  final int appWidgetId;

  const ChecklistWidgetConfigView({super.key, required this.appWidgetId});

  @override
  State<ChecklistWidgetConfigView> createState() =>
      _ChecklistWidgetConfigViewState();
}

class _ChecklistWidgetConfigViewState extends State<ChecklistWidgetConfigView> {
  late Future<List<_HouseLists>> _future;
  final Map<int, ChecklistList> _byId = {};
  int? _selectedListId;
  final Set<String> _chips = {};
  bool _loadedSelection = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_HouseLists>> _load() async {
    final config = await ChecklistWidgetService.instance.readConfig(
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
      _selectedListId = config?.listId;
      _chips
        ..clear()
        ..addAll(
          config?.chips ??
              {
                for (final key in kWidgetChipKinds)
                  if (PrefsService.instance.isItemChipVisible(key)) key,
              },
        );
      _loadedSelection = true;
    }
    return result;
  }

  Future<void> _save() async {
    final listId = _selectedListId;
    final list = listId == null ? null : _byId[listId];
    if (_saving || list == null) return;
    setState(() => _saving = true);

    await ChecklistWidgetService.instance.setConfig(
      widget.appWidgetId,
      ChecklistWidgetConfig(
        houseId: list.houseId,
        listId: list.id,
        chips: {..._chips},
        showAddedBy: false,
      ),
    );
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
        title: Text(m.widget.chooseListTitle),
        actions: [
          TextButton(
            onPressed: _saving || _selectedListId == null ? null : _save,
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
                  m.widget.chooseListSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final group in groups) ...[
                if (showHeaders) _HouseHeader(name: group.house.name),
                for (final list in group.lists)
                  ListTile(
                    leading: Icon(
                      _selectedListId == list.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _selectedListId == list.id
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(
                      list.name,
                      textDirection: detectTextDirection(list.name),
                    ),
                    onTap: () => setState(() => _selectedListId = list.id),
                  ),
              ],
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
                child: Text(
                  m.settings.visibleChipsTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final key in kWidgetChipKinds)
                SwitchListTile(
                  secondary: Icon(_chipIcon(key)),
                  title: Text(_chipLabel(key)),
                  value: _chips.contains(key),
                  onChanged: (v) => setState(() {
                    if (v) {
                      _chips.add(key);
                    } else {
                      _chips.remove(key);
                    }
                  }),
                ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  String _chipLabel(String key) => switch (key) {
    'category' => m.settings.chipNames.category,
    'quantity' => m.settings.chipNames.quantity,
    'store' => m.settings.chipNames.store,
    'label' => m.settings.chipNames.label,
    _ => key,
  };

  IconData _chipIcon(String key) => switch (key) {
    'category' => Icons.circle,
    'quantity' => Icons.tag,
    'store' => Icons.storefront_outlined,
    'label' => Icons.sell_outlined,
    _ => Icons.label_outline,
  };
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
