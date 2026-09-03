import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/category.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/label.dart';
import 'package:pantry_core/models/store.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry_core/services/category_service.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/label_service.dart';
import 'package:pantry_core/services/store_service.dart';

/// Chip kinds the single-checklist widget can render, in display order.
const kWidgetChipKinds = ['category', 'quantity', 'store', 'label'];

/// Manages the Android "single checklist" home-screen widgets — each instance
/// shows one list's items (active, then a Done section), grouped the same way
/// the checklist page groups them, with configurable chips. Per-instance state
/// lives under `checklist_widget_<appWidgetId>` in HomeWidgetPreferences,
/// carrying both the config (list, chips) and the rendered rows the native
/// factory reads.
class ChecklistWidgetService {
  ChecklistWidgetService._();
  static final ChecklistWidgetService instance = ChecklistWidgetService._();

  static const _channel = MethodChannel('dev.casraf.pantry/widget');
  static const _providerName = 'dev.casraf.pantry.ChecklistWidgetProvider';

  static bool get _supported => PlatformInfo.isAndroidPhone;

  // Lookups for the widget currently being rebuilt (rebuilds are sequential).
  Map<int, Category> _cats = const {};
  Map<int, Store> _stores = const {};
  Map<int, Label> _labels = const {};

  String _key(int widgetId) => 'checklist_widget_$widgetId';

  /// App widget ids for every placed single-checklist widget.
  Future<List<int>> liveWidgetIds() async {
    if (!_supported) return const [];
    try {
      return await _channel.invokeListMethod<int>('getChecklistWidgetIds') ??
          const [];
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, dynamic>?> _read(int widgetId) async {
    if (!_supported) return null;
    final json = await HomeWidget.getWidgetData<String>(_key(widgetId));
    if (json == null || json.isEmpty) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// The list + chip config a widget was set up with (null before configured).
  Future<ChecklistWidgetConfig?> readConfig(int widgetId) async {
    final data = await _read(widgetId);
    if (data == null || data['listId'] is! int) return null;
    return ChecklistWidgetConfig(
      houseId: data['houseId'] as int,
      listId: data['listId'] as int,
      chips: {...(data['chips'] as List? ?? const []).cast<String>()},
      showAddedBy: data['showAddedBy'] as bool? ?? true,
    );
  }

  /// Persist [config] for [widgetId], render its rows and refresh it.
  Future<void> setConfig(int widgetId, ChecklistWidgetConfig config) async {
    if (!_supported) return;
    await _writeRows(widgetId, config);
    await _updateWidgets();
  }

  /// Re-render every live checklist widget from the cache. Call on app start
  /// and resume, and after an item toggles.
  Future<void> refreshAll() async {
    if (!_supported) return;
    for (final id in await liveWidgetIds()) {
      final config = await readConfig(id);
      if (config != null) await _writeRows(id, config);
    }
    await _updateWidgets();
  }

  Future<void> refresh(int widgetId) async {
    if (!_supported) return;
    final config = await readConfig(widgetId);
    if (config != null) {
      await _writeRows(widgetId, config);
      await _updateWidgets();
    }
  }

  Future<void> _writeRows(int widgetId, ChecklistWidgetConfig config) async {
    // The lock flag is toggled natively; preserve it across Dart re-renders.
    final locked = (await _read(widgetId))?['locked'] as bool? ?? false;

    final cs = ChecklistService.instance;
    final lists = cs.getCachedLists(config.houseId);
    ChecklistList? list;
    for (final l in lists ?? const <ChecklistList>[]) {
      if (l.id == config.listId) {
        list = l;
        break;
      }
    }

    _cats = {
      for (final c in CategoryService.instance.getCached(config.houseId) ?? [])
        c.id: c,
    };
    _stores = {
      for (final s in StoreService.instance.getCached(config.houseId) ?? [])
        s.id: s,
    };
    _labels = {
      for (final l in LabelService.instance.getCached(config.houseId) ?? [])
        l.id: l,
    };

    final items = (cs.getCachedItems(config.listId) ?? [])
        .where((i) => i.deletedAt == null && i.archivedAt == null)
        .toList();
    final sortBy = cs.cache.get<String>('sortBy:${config.houseId}') ?? 'custom';

    final active = items.where((i) => !i.done).toList();
    final done = items.where((i) => i.done).toList();

    final rows = <Map<String, dynamic>>[
      ..._sectionRows(active, sortBy, config),
      if (done.isNotEmpty) {'t': 'done', 'count': done.length},
      ..._sectionRows(done, sortBy, config),
    ];

    await HomeWidget.saveWidgetData<String>(
      _key(widgetId),
      jsonEncode({
        'houseId': config.houseId,
        'listId': config.listId,
        'listName': list?.name ?? '',
        'chips': config.chips.toList(),
        'showAddedBy': config.showAddedBy,
        'locked': locked,
        'rows': rows,
      }),
    );
  }

  /// Group [items] by the current sort (category/store) into header + item
  /// rows, or a flat item list for other sorts.
  List<Map<String, dynamic>> _sectionRows(
    List<ListItem> items,
    String sortBy,
    ChecklistWidgetConfig config,
  ) {
    if (items.isEmpty) return const [];
    final rows = <Map<String, dynamic>>[];
    if (sortBy == 'category') {
      for (final group in _groupByCategory(items)) {
        final cat = group.categoryId == null ? null : _cats[group.categoryId];
        rows.add({
          't': 'header',
          'label': cat?.name ?? m.checklists.noCategory,
          'color': cat?.color,
        });
        rows.addAll(group.items.map((i) => _itemRow(i, config)));
      }
    } else if (sortBy == 'store') {
      final sortedStores = StoreService.sortStores(
        _stores.values,
        _storeSort(config.houseId),
      );
      for (final group in _groupByStore(items, sortedStores)) {
        final store = group.storeId == null ? null : _stores[group.storeId];
        rows.add({
          't': 'header',
          'label': store?.name ?? m.checklists.noStore,
          'color': store?.color,
        });
        rows.addAll(group.items.map((i) => _itemRow(i, config)));
      }
    } else {
      rows.addAll(items.map((i) => _itemRow(i, config)));
    }
    return rows;
  }

  String _storeSort(int houseId) =>
      ChecklistService.instance.cache.get<String>('storeSort:$houseId') ??
      'name_asc';

  Map<String, dynamic> _itemRow(ListItem item, ChecklistWidgetConfig config) {
    return {
      't': 'item',
      'id': item.id,
      'name': item.name,
      'done': item.done,
      'pills': _pillsFor(item, config),
    };
  }

  /// The chips to show on [item], honouring the widget's chip config, in the
  /// checklist page's order. Capped at 3 slots: 3 chips fit as-is, more collapse
  /// to two chips plus a "+N" overflow pill. Only the category pill is coloured.
  List<Map<String, dynamic>> _pillsFor(
    ListItem item,
    ChecklistWidgetConfig config,
  ) {
    final chips = <Map<String, dynamic>>[];
    if (config.chips.contains('category') && item.categoryId != null) {
      final c = _cats[item.categoryId];
      if (c != null) chips.add({'text': c.name, 'color': c.color});
    }
    if (config.chips.contains('quantity') &&
        (item.quantity?.trim().isNotEmpty ?? false)) {
      chips.add({'text': item.quantity!.trim()});
    }
    if (config.chips.contains('store')) {
      for (final sid in item.storeIds) {
        final s = _stores[sid];
        if (s != null) chips.add({'text': s.name, 'color': s.color});
      }
    }
    if (config.chips.contains('label')) {
      for (final lid in item.labelIds) {
        final l = _labels[lid];
        if (l != null) chips.add({'text': l.name, 'color': l.color});
      }
    }
    if (chips.length <= 3) return chips;
    return [
      chips[0],
      chips[1],
      {'text': '+${chips.length - 2}'},
    ];
  }

  List<({int? categoryId, List<ListItem> items})> _groupByCategory(
    List<ListItem> items,
  ) {
    final groups = <({int? categoryId, List<ListItem> items})>[];
    for (final item in items) {
      if (groups.isEmpty || groups.last.categoryId != item.categoryId) {
        groups.add((categoryId: item.categoryId, items: [item]));
      } else {
        groups.last.items.add(item);
      }
    }
    return groups;
  }

  List<({int? storeId, List<ListItem> items})> _groupByStore(
    List<ListItem> items,
    List<Store> sortedStores,
  ) {
    final groups = <({int? storeId, List<ListItem> items})>[];
    final storeIds = {for (final s in sortedStores) s.id};
    for (final store in sortedStores) {
      final inStore = items
          .where((i) => i.storeIds.contains(store.id))
          .toList();
      if (inStore.isNotEmpty) groups.add((storeId: store.id, items: inStore));
    }
    final noStore = items
        .where((i) => !i.storeIds.any(storeIds.contains))
        .toList();
    if (noStore.isNotEmpty) groups.add((storeId: null, items: noStore));
    return groups;
  }

  Future<void> _updateWidgets() =>
      HomeWidget.updateWidget(qualifiedAndroidName: _providerName);
}

/// A single-checklist widget's configuration.
class ChecklistWidgetConfig {
  final int houseId;
  final int listId;

  /// Visible [ItemChipKind] keys. Empty means no chips.
  final Set<String> chips;
  final bool showAddedBy;

  const ChecklistWidgetConfig({
    required this.houseId,
    required this.listId,
    required this.chips,
    required this.showAddedBy,
  });
}
