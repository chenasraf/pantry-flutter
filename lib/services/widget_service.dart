import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/utils/platform_info.dart';
import 'package:pantry_core/services/checklist_service.dart';
import 'package:pantry_core/services/house_service.dart';
import 'list_link_service.dart';

/// Manages the Android home-screen "lists" widgets. Each widget instance keeps
/// its own selection under `lists_widget_<appWidgetId>` in HomeWidgetPreferences
/// (read natively by [PantryWidgetService]). Also keeps the launcher quick
/// actions in sync with the union of every widget's lists.
class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();

  static const _channel = MethodChannel('dev.casraf.pantry/widget');
  static const _configChannel = MethodChannel(
    'dev.casraf.pantry/widget_config',
  );
  static const _providerName = 'dev.casraf.pantry.PantryWidgetProvider';

  // Only Android ships the home-screen widget; every side-effect is gated on
  // this to avoid MissingPluginException on other platforms.
  static bool get _supported => PlatformInfo.isAndroidPhone;

  String _key(int widgetId) => 'lists_widget_$widgetId';

  /// App widget ids currently placed on the home screen.
  Future<List<int>> liveWidgetIds() async {
    if (!_supported) return const [];
    try {
      return await _channel.invokeListMethod<int>('getListsWidgetIds') ??
          const [];
    } catch (_) {
      return const [];
    }
  }

  /// Close the native [WidgetConfigActivity], committing the widget to the
  /// launcher when [ok] (RESULT_OK) or cancelling it otherwise. Only meaningful
  /// in the widget-config engine.
  Future<void> finishConfig({required bool ok}) async {
    if (!_supported) return;
    try {
      await _configChannel.invokeMethod('finish', {'ok': ok});
    } catch (_) {}
  }

  /// The list ids currently shown by [widgetId].
  Future<Set<int>> selectedListIds(int widgetId) async {
    final entries = await _readEntries(widgetId);
    return entries.map((e) => e['id'] as int).toSet();
  }

  /// Persist [lists] as [widgetId]'s selection, refresh the widget, and resync
  /// the launcher quick actions.
  Future<void> setWidgetLists(int widgetId, List<ChecklistList> lists) async {
    if (!_supported) return;
    final entries = lists.map(_entryFor).toList();
    await HomeWidget.saveWidgetData<String>(
      _key(widgetId),
      jsonEncode(entries),
    );
    await _updateWidgets();
    await _syncShortcuts();
  }

  /// Recompute item counts (and names/icons) for every live widget from the
  /// cache, refresh them, and resync launcher quick actions. Call on app start
  /// and resume so widgets survive a preferences wipe and reflect edits.
  Future<void> refreshAll() async {
    if (!_supported) return;
    for (final id in await liveWidgetIds()) {
      final entries = await _readEntries(id);
      if (entries.isEmpty) continue;
      final refreshed = entries.map(_refreshEntry).toList();
      await HomeWidget.saveWidgetData<String>(_key(id), jsonEncode(refreshed));
    }
    await _updateWidgets();
    await _syncShortcuts();
  }

  Future<List<Map<String, dynamic>>> _readEntries(int widgetId) async {
    if (!_supported) return const [];
    final json = await HomeWidget.getWidgetData<String>(_key(widgetId));
    if (json == null || json.isEmpty) return const [];
    try {
      return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  /// Union every widget's entries (deduped by house + list) into the launcher
  /// quick actions.
  Future<void> _syncShortcuts() async {
    final seen = <String>{};
    final union = <Map<String, dynamic>>[];
    for (final id in await liveWidgetIds()) {
      for (final e in await _readEntries(id)) {
        if (seen.add('${e['houseId']}:${e['id']}')) union.add(e);
      }
    }
    await ListLinkService.instance.setPinnedShortcuts(union);
  }

  Future<void> _updateWidgets() =>
      HomeWidget.updateWidget(qualifiedAndroidName: _providerName);

  Map<String, dynamic> _entryFor(ChecklistList l) {
    final cached = ChecklistService.instance.getCachedItems(l.id) ?? [];
    final active = cached.where((i) => i.deletedAt == null).toList();
    return {
      'id': l.id,
      'name': l.name,
      'houseId': l.houseId,
      'houseName': _houseName(l.houseId),
      'icon': l.icon,
      'unchecked': active.where((i) => !i.done).length,
      'total': active.length,
    };
  }

  /// Refresh a stored entry's counts (and name/icon when the list is cached),
  /// falling back to the stored values when the list isn't in the cache.
  Map<String, dynamic> _refreshEntry(Map<String, dynamic> e) {
    final id = e['id'] as int;
    final houseId = e['houseId'] as int;
    final cs = ChecklistService.instance;
    ChecklistList? list;
    for (final l in cs.getCachedLists(houseId) ?? const <ChecklistList>[]) {
      if (l.id == id) {
        list = l;
        break;
      }
    }
    final active = (cs.getCachedItems(id) ?? [])
        .where((i) => i.deletedAt == null)
        .toList();
    return {
      'id': id,
      'name': list?.name ?? e['name'],
      'houseId': houseId,
      'houseName': _houseName(houseId) ?? e['houseName'],
      'icon': list?.icon ?? e['icon'],
      'unchecked': active.where((i) => !i.done).length,
      'total': active.length,
    };
  }

  String? _houseName(int houseId) {
    for (final h in HouseService.instance.getCached() ?? const []) {
      if (h.id == houseId) return h.name;
    }
    return null;
  }
}
