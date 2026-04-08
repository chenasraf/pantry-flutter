import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pantry/models/checklist.dart';
import 'package:pantry/services/api_client.dart';
import 'package:path_provider/path_provider.dart';

class ChecklistService {
  ChecklistService._();
  static final ChecklistService instance = ChecklistService._();

  final Map<int, List<ListItem>> _itemCache = {};
  List<ChecklistList>? _listsCache;
  int? _listsCacheHouseId;
  int? selectedListId;

  static const _cacheFileName = 'checklist_cache.json';

  Future<File> get _cacheFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  Future<void> loadFromDisk() async {
    try {
      final file = await _cacheFile;
      if (!await file.exists()) return;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      _listsCacheHouseId = json['houseId'] as int?;
      selectedListId = json['selectedListId'] as int?;

      if (json['lists'] != null) {
        _listsCache = (json['lists'] as List)
            .map((e) => ChecklistList.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (json['items'] != null) {
        final items = json['items'] as Map<String, dynamic>;
        for (final entry in items.entries) {
          _itemCache[int.parse(entry.key)] = (entry.value as List)
              .map((e) => ListItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ChecklistService] Failed to load cache from disk: $e');
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final json = {
        'houseId': _listsCacheHouseId,
        'selectedListId': selectedListId,
        'lists': _listsCache?.map((l) => l.toJson()).toList(),
        'items': _itemCache.map(
          (k, v) => MapEntry(k.toString(), v.map((i) => i.toJson()).toList()),
        ),
      };
      final file = await _cacheFile;
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      debugPrint('[ChecklistService] Failed to save cache to disk: $e');
    }
  }

  List<ChecklistList>? getCachedLists(int houseId) =>
      _listsCacheHouseId == houseId ? _listsCache : null;

  void cacheLists(int houseId, List<ChecklistList> lists) {
    _listsCache = lists;
    _listsCacheHouseId = houseId;
    _saveToDisk();
  }

  List<ListItem>? getCachedItems(int listId) => _itemCache[listId];

  void cacheItems(int listId, List<ListItem> items) {
    _itemCache[listId] = items;
    _saveToDisk();
  }

  void invalidateCache({int? keepListId}) {
    if (keepListId != null) {
      _itemCache.removeWhere((id, _) => id != keepListId);
    } else {
      _itemCache.clear();
    }
    _listsCache = null;
    _listsCacheHouseId = null;
    _saveToDisk();
  }

  Future<List<ChecklistList>> getLists(int houseId) async {
    return ApiClient.instance.get<List, List<ChecklistList>>(
      '/houses/$houseId/lists',
      fromJson: (data) => data
          .map((e) => ChecklistList.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<ListItem>> getItems(int houseId, int listId) async {
    return ApiClient.instance.get<List, List<ListItem>>(
      '/houses/$houseId/lists/$listId/items',
      fromJson: (data) => data
          .map((e) => ListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Uri itemImagePreviewUri(
    int houseId,
    int fileId,
    String owner, {
    int size = 128,
  }) {
    return ApiClient.instance.buildUri('/houses/$houseId/image-preview', {
      'fileId': fileId.toString(),
      'owner': owner,
      'size': size.toString(),
    });
  }

  Future<ListItem> toggleItem(int houseId, int listId, int itemId) async {
    return ApiClient.instance.post<Map<String, dynamic>, ListItem>(
      '/houses/$houseId/lists/$listId/items/$itemId/toggle',
      fromJson: (data) => ListItem.fromJson(data),
    );
  }
}
