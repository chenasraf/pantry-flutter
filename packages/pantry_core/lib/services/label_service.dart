import 'package:pantry_core/models/label.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/cache_store.dart';

/// Sentinel for [LabelService.updateLabel]'s `listId`: pass it (the default) to
/// omit `listId` from the PATCH entirely, leaving the scope unchanged. `null`
/// is a *meaningful* value ("make global"), so it can't double as "unset".
const Object labelListIdUnset = Object();

class LabelService {
  LabelService._();
  static final LabelService instance = LabelService._();

  final cache = CacheStore('label_cache.json');

  static const _prefix = 'labels';

  List<Label>? getCached(int houseId) =>
      cache.getKeyedList(_prefix, '$houseId', Label.fromJson);

  void cacheLabels(int houseId, List<Label> labels) {
    cache.setKeyedList(_prefix, '$houseId', labels, (l) => l.toJson());
  }

  Future<List<Label>> getLabels(int houseId) async {
    final labels = await ApiClient.instance.get<List, List<Label>>(
      '/houses/$houseId/labels',
      fromJson: (data) =>
          data.map((e) => Label.fromJson(e as Map<String, dynamic>)).toList(),
    );
    cacheLabels(houseId, labels);
    return labels;
  }

  Future<void> setLabelSortPref(int houseId, String sort) async {
    await ApiClient.instance.put<Map<String, dynamic>, void>(
      '/houses/$houseId/prefs',
      body: {'labelSort': sort},
      fromJson: (_) {},
    );
  }

  Future<void> reorderLabels(
    int houseId,
    List<({int id, int sortOrder})> order,
  ) async {
    await ApiClient.instance.post<Map<String, dynamic>, void>(
      '/houses/$houseId/labels/reorder',
      body: {
        'items': order
            .map((e) => {'id': e.id, 'sortOrder': e.sortOrder})
            .toList(),
      },
      fromJson: (_) {},
    );
  }

  /// Sort labels according to a sort mode (name_asc, name_desc, custom).
  /// Returns a new list; the input is not mutated.
  static List<Label> sortLabels(Iterable<Label> labels, String sort) {
    final list = labels.toList();
    // Fall back to id (creation order) as a final tiebreaker: fresh labels
    // share the same sortOrder until reordered, so without it the custom list
    // would reshuffle unpredictably as labels are added.
    switch (sort) {
      case 'name_desc':
        list.sort((a, b) {
          final c = b.name.toLowerCase().compareTo(a.name.toLowerCase());
          return c != 0 ? c : a.id.compareTo(b.id);
        });
      case 'custom':
        list.sort((a, b) {
          final c = a.sortOrder.compareTo(b.sortOrder);
          return c != 0 ? c : a.id.compareTo(b.id);
        });
      case 'name_asc':
      default:
        list.sort((a, b) {
          final c = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          return c != 0 ? c : a.id.compareTo(b.id);
        });
    }
    return list;
  }

  Future<Label> createLabel(
    int houseId, {
    required String name,
    required String icon,
    required String color,
    int? listId,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, Label>(
      '/houses/$houseId/labels',
      // A null `listId` means global — the server default — so it's only sent
      // when scoping to a real list.
      body: {'name': name, 'icon': icon, 'color': color, 'listId': ?listId},
      fromJson: (data) => Label.fromJson(data),
    );
  }

  /// Pass [listId] as an int to scope the label, `null` to make it global, or
  /// leave it as [labelListIdUnset] to keep the current scope. The `?`
  /// map-spread would silently drop an explicit `null`, so `listId` is added
  /// separately.
  Future<Label> updateLabel(
    int houseId,
    int labelId, {
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
    Object? listId = labelListIdUnset,
  }) async {
    final body = <String, dynamic>{
      'name': ?name,
      'icon': ?icon,
      'color': ?color,
      'sortOrder': ?sortOrder,
    };
    if (!identical(listId, labelListIdUnset)) body['listId'] = listId;
    return ApiClient.instance.patch<Map<String, dynamic>, Label>(
      '/houses/$houseId/labels/$labelId',
      body: body,
      fromJson: (data) => Label.fromJson(data),
    );
  }

  Future<void> deleteLabel(int houseId, int labelId) async {
    await ApiClient.instance.delete('/houses/$houseId/labels/$labelId');
  }
}
