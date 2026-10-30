/// What a list is for. Fixed at creation; converting means duplicating into
/// another kind. Only checklists are checked off, recur, and shop.
enum ListKind {
  checklist,
  inventory,
  template;

  String get wire => name;

  /// The API resource serving this kind. `lists` is the checklist resource,
  /// not an all-kinds one.
  String get resource => switch (this) {
    ListKind.checklist => 'lists',
    ListKind.template => 'templates',
    ListKind.inventory => 'inventories',
  };

  bool get isChecklist => this == ListKind.checklist;

  /// Whether this kind's items carry recurrence and delete-on-done. Templates
  /// store them for the checklists they're drawn into.
  bool get hasRecurrence => this != ListKind.inventory;

  static ListKind parse(Object? raw) => switch (raw) {
    'template' => ListKind.template,
    'inventory' => ListKind.inventory,
    _ => ListKind.checklist,
  };
}
