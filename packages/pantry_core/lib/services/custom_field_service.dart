import 'package:pantry_core/models/custom_field.dart';
import 'package:pantry_core/services/api_client.dart';
import 'package:pantry_core/services/cache_store.dart';

/// Sentinel for [CustomFieldService.updateField]'s `listId`: pass it (the
/// default) to omit `listId` from the PATCH entirely, leaving the scope
/// unchanged. `null` is a *meaningful* value ("make house-wide"), so it can't
/// double as "unset".
const Object fieldListIdUnset = Object();

/// How to treat item values referencing a `select` option being deleted:
/// `remap` moves them to another option, `clear` empties them.
enum OptionDeleteAction {
  remap,
  clear;

  String get wire => name;
}

/// Owns the field-definition REST calls and their cache. Mirrors
/// [CategoryService]; gated by the `custom-fields` capability at the call site.
class CustomFieldService {
  CustomFieldService._();
  static final CustomFieldService instance = CustomFieldService._();

  final cache = CacheStore('custom_field_cache.json');

  static const _prefix = 'fields';

  List<FieldDefinition>? getCached(int houseId) =>
      cache.getKeyedList(_prefix, '$houseId', FieldDefinition.fromJson);

  void cacheFields(int houseId, List<FieldDefinition> fields) {
    cache.setKeyedList(_prefix, '$houseId', fields, (f) => f.toJson());
  }

  Future<List<FieldDefinition>> getFields(int houseId) async {
    final fields = await ApiClient.instance.get<List, List<FieldDefinition>>(
      '/houses/$houseId/fields',
      fromJson: (data) => data
          .map((e) => FieldDefinition.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    cacheFields(houseId, fields);
    return fields;
  }

  /// Order fields for display: by [FieldDefinition.sortOrder], then id
  /// (creation order) as a tiebreaker so fresh fields sharing a sortOrder
  /// stay put. Returns a new list; the input is not mutated.
  static List<FieldDefinition> sortFields(Iterable<FieldDefinition> fields) {
    final list = fields.toList();
    list.sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
    return list;
  }

  Future<FieldDefinition> createField(
    int houseId, {
    required String name,
    required FieldType type,
    int? listId,
    String? hint,
    bool? multiline,
    String? defaultText,
    double? defaultNumber,
    bool? defaultBool,
    String? dateMode,
    int? defaultOffsetDays,
    bool? notifyDefault,
    int? leadDays,
    String? overridePolicy,
    bool? stopWhenDone,
    List<Map<String, dynamic>>? options,
  }) async {
    return ApiClient.instance.post<Map<String, dynamic>, FieldDefinition>(
      '/houses/$houseId/fields',
      // A null `listId` means house-wide — the server default — so it's only
      // sent when scoping to a real list.
      body: {
        'name': name,
        'type': type.name,
        'listId': ?listId,
        'hint': ?hint,
        'multiline': ?multiline,
        'defaultText': ?defaultText,
        'defaultNumber': ?defaultNumber,
        'defaultBool': ?defaultBool,
        'dateMode': ?dateMode,
        'defaultOffsetDays': ?defaultOffsetDays,
        'notifyDefault': ?notifyDefault,
        'leadDays': ?leadDays,
        'overridePolicy': ?overridePolicy,
        'stopWhenDone': ?stopWhenDone,
        'options': ?options,
      },
      fromJson: (data) => FieldDefinition.fromJson(data),
    );
  }

  /// Pass [listId] as an int to scope the field, `null` to make it house-wide,
  /// or leave it as [fieldListIdUnset] to keep the current scope. The `?`
  /// map-spread would silently drop an explicit `null`, so `listId` is added
  /// separately.
  Future<FieldDefinition> updateField(
    int houseId,
    int fieldId, {
    String? name,
    Object? listId = fieldListIdUnset,
    String? hint,
    bool? multiline,
    String? defaultText,
    double? defaultNumber,
    bool? defaultBool,
    int? defaultOptionId,
    String? dateMode,
    int? defaultOffsetDays,
    bool? notifyDefault,
    int? leadDays,
    String? overridePolicy,
    bool? stopWhenDone,
    List<Map<String, dynamic>>? options,
  }) async {
    final body = <String, dynamic>{
      'name': ?name,
      'hint': ?hint,
      'multiline': ?multiline,
      'defaultText': ?defaultText,
      'defaultNumber': ?defaultNumber,
      'defaultBool': ?defaultBool,
      'defaultOptionId': ?defaultOptionId,
      'dateMode': ?dateMode,
      'defaultOffsetDays': ?defaultOffsetDays,
      'notifyDefault': ?notifyDefault,
      'leadDays': ?leadDays,
      'overridePolicy': ?overridePolicy,
      'stopWhenDone': ?stopWhenDone,
      'options': ?options,
    };
    if (!identical(listId, fieldListIdUnset)) body['listId'] = listId;
    return ApiClient.instance.patch<Map<String, dynamic>, FieldDefinition>(
      '/houses/$houseId/fields/$fieldId',
      body: body,
      fromJson: (data) => FieldDefinition.fromJson(data),
    );
  }

  Future<void> deleteField(int houseId, int fieldId) async {
    await ApiClient.instance.delete('/houses/$houseId/fields/$fieldId');
  }

  /// Delete one `select` option. An unused option is removed outright (pass no
  /// [action]). An option in use requires an action: [OptionDeleteAction.remap]
  /// moves its values to [remapToId], [OptionDeleteAction.clear] empties them.
  /// Returns the updated definition. Needs a live connection — the usage count
  /// and remap are resolved server-side.
  Future<FieldDefinition> deleteFieldOption(
    int houseId,
    int fieldId,
    int optionId, {
    OptionDeleteAction? action,
    int? remapToId,
  }) async {
    return ApiClient.instance
        .deleteWithResult<Map<String, dynamic>, FieldDefinition>(
          '/houses/$houseId/fields/$fieldId/options/$optionId',
          body: {'action': ?action?.wire, 'remapToId': ?remapToId},
          fromJson: (data) => FieldDefinition.fromJson(data),
        );
  }

  Future<void> reorderFields(
    int houseId,
    List<({int id, int sortOrder})> order,
  ) async {
    await ApiClient.instance.patch<Map<String, dynamic>, void>(
      '/houses/$houseId/fields/reorder',
      body: {
        'items': order
            .map((e) => {'id': e.id, 'sortOrder': e.sortOrder})
            .toList(),
      },
      fromJson: (_) {},
    );
  }
}
