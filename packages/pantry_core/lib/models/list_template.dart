import 'package:pantry_core/models/checklist.dart';

/// The key two item names share when they name the same item: case and
/// spacing are ignored, matching the server's own comparison.
String itemNameKey(String name) =>
    name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// A template item offered in an add box, once per name.
class TemplateSuggestion {
  final ListItem item;

  /// Every attached template the name is in.
  final List<({int id, String name})> templates;

  const TemplateSuggestion({required this.item, required this.templates});

  List<String> get templateNames => [for (final t in templates) t.name];

  factory TemplateSuggestion.fromJson(Map<String, dynamic> json) =>
      TemplateSuggestion(
        item: ListItem.fromJson(Map<String, dynamic>.from(json['item'] as Map)),
        templates: [
          for (final t in (json['templates'] as List?) ?? const [])
            (id: (t as Map)['id'] as int, name: t['name'] as String),
        ],
      );
}

/// A drawn template item: the copy, or the same-name item already on the list
/// that it brought back.
class DrawResult {
  final ListItem item;
  final bool reused;

  const DrawResult({required this.item, required this.reused});

  factory DrawResult.fromJson(Map<String, dynamic> json) => DrawResult(
    item: ListItem.fromJson(Map<String, dynamic>.from(json['item'] as Map)),
    reused: json['reused'] as bool? ?? false,
  );
}

/// The templates a checklist or inventory draws suggestions from.
class AttachedTemplates {
  /// Templates attached to this list by name.
  final List<int> templateIds;

  /// Templates attached to every list, this one included.
  final List<int> everyListTemplateIds;

  const AttachedTemplates({
    this.templateIds = const [],
    this.everyListTemplateIds = const [],
  });

  Set<int> get all => {...templateIds, ...everyListTemplateIds};

  factory AttachedTemplates.fromJson(Map<String, dynamic> json) =>
      AttachedTemplates(
        templateIds: _ids(json['templateIds']),
        everyListTemplateIds: _ids(json['everyListTemplateIds']),
      );
}

/// The lists a template feeds suggestions to.
class TemplateLists {
  /// Attached to every checklist and inventory in the house, including ones
  /// made later.
  final bool everyList;
  final List<int> listIds;

  const TemplateLists({this.everyList = false, this.listIds = const []});

  bool get isEmpty => !everyList && listIds.isEmpty;

  factory TemplateLists.fromJson(Map<String, dynamic> json) => TemplateLists(
    everyList: json['everyList'] as bool? ?? false,
    listIds: _ids(json['listIds']),
  );

  Map<String, dynamic> toJson() => {'everyList': everyList, 'listIds': listIds};
}

List<int> _ids(Object? raw) => [
  for (final id in (raw as List?) ?? const []) id as int,
];

/// Whether template items drawn by this member fill their empty details from
/// the list's item defaults: as each list says, or always or never.
enum FillFromItemDefaults {
  list,
  always,
  never;

  String get wire => name;

  static FillFromItemDefaults parse(Object? raw) => values.firstWhere(
    (v) => v.wire == raw,
    orElse: () => FillFromItemDefaults.list,
  );
}
