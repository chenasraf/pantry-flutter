import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/list_kind.dart';

/// Strings that name a kind inside its own section. Each kind has its own
/// string rather than a shared "list" one, since many languages need per-noun
/// grammar.
class ListKindStrings {
  final ListKind kind;

  const ListKindStrings(this.kind);

  T _pick<T>(T checklist, T inventory, T template) => switch (kind) {
    ListKind.checklist => checklist,
    ListKind.inventory => inventory,
    ListKind.template => template,
  };

  String get title => _pick(
    m.listKinds.checklist.title,
    m.listKinds.inventory.title,
    m.listKinds.template.title,
  );

  /// The singular kind name, as offered when choosing what a copy becomes.
  String get name => _pick(
    m.listKinds.checklist.name,
    m.listKinds.inventory.name,
    m.listKinds.template.name,
  );

  String get newList => _pick(
    m.listKinds.checklist.newList,
    m.listKinds.inventory.newList,
    m.listKinds.template.newList,
  );

  String get createTitle => _pick(
    m.listKinds.checklist.createTitle,
    m.listKinds.inventory.createTitle,
    m.listKinds.template.createTitle,
  );

  String get editTitle => _pick(
    m.listKinds.checklist.editTitle,
    m.listKinds.inventory.editTitle,
    m.listKinds.template.editTitle,
  );

  String get duplicateTitle => _pick(
    m.listKinds.checklist.duplicateTitle,
    m.listKinds.inventory.duplicateTitle,
    m.listKinds.template.duplicateTitle,
  );

  String get duplicateFailed => _pick(
    m.listKinds.checklist.duplicateFailed,
    m.listKinds.inventory.duplicateFailed,
    m.listKinds.template.duplicateFailed,
  );

  String get listMenu => _pick(
    m.listKinds.checklist.listMenu,
    m.listKinds.inventory.listMenu,
    m.listKinds.template.listMenu,
  );

  String get deleteDialogTitle => _pick(
    m.listKinds.checklist.deleteDialogTitle,
    m.listKinds.inventory.deleteDialogTitle,
    m.listKinds.template.deleteDialogTitle,
  );

  String get emptyTitle => _pick(
    m.listKinds.checklist.emptyTitle,
    m.listKinds.inventory.emptyTitle,
    m.listKinds.template.emptyTitle,
  );

  String get emptyBody => _pick(
    m.listKinds.checklist.emptyBody,
    m.listKinds.inventory.emptyBody,
    m.listKinds.template.emptyBody,
  );

  String get trashTitle => _pick(
    m.listKinds.checklist.trashTitle,
    m.listKinds.inventory.trashTitle,
    m.listKinds.template.trashTitle,
  );

  String get trashEmptyBody => _pick(
    m.listKinds.checklist.trashEmptyBody,
    m.listKinds.inventory.trashEmptyBody,
    m.listKinds.template.trashEmptyBody,
  );

  String get archiveTitle => _pick(
    m.listKinds.checklist.archiveTitle,
    m.listKinds.inventory.archiveTitle,
    m.listKinds.template.archiveTitle,
  );

  String get archiveEmptyTitle => _pick(
    m.listKinds.checklist.archiveEmptyTitle,
    m.listKinds.inventory.archiveEmptyTitle,
    m.listKinds.template.archiveEmptyTitle,
  );

  String get archiveEmptyBody => _pick(
    m.listKinds.checklist.archiveEmptyBody,
    m.listKinds.inventory.archiveEmptyBody,
    m.listKinds.template.archiveEmptyBody,
  );

  String get emptyTrashBody => _pick(
    m.listKinds.checklist.emptyTrashBody,
    m.listKinds.inventory.emptyTrashBody,
    m.listKinds.template.emptyTrashBody,
  );

  String get listRestored => _pick(
    m.listKinds.checklist.listRestored,
    m.listKinds.inventory.listRestored,
    m.listKinds.template.listRestored,
  );

  String get listMovedToTrash => _pick(
    m.listKinds.checklist.listMovedToTrash,
    m.listKinds.inventory.listMovedToTrash,
    m.listKinds.template.listMovedToTrash,
  );

  String get listArchived => _pick(
    m.listKinds.checklist.listArchived,
    m.listKinds.inventory.listArchived,
    m.listKinds.template.listArchived,
  );

  String get listUnarchived => _pick(
    m.listKinds.checklist.listUnarchived,
    m.listKinds.inventory.listUnarchived,
    m.listKinds.template.listUnarchived,
  );
}

extension ListKindL10n on ListKind {
  ListKindStrings get strings => ListKindStrings(this);
}
