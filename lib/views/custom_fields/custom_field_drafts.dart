import 'package:pantry/models/custom_field.dart';

/// A display group of fields sharing a scope: `listId == null` for the
/// house-wide ("All lists") section, or a list id for a per-list section.
class FieldGroup {
  final int? listId;
  final String title;
  final List<FieldDefinition> fields;

  const FieldGroup({
    required this.listId,
    required this.title,
    required this.fields,
  });
}

/// Mutable editing state for one field definition.
class FieldDraft {
  String name;
  FieldType type;
  int? listId;
  String? hint;
  bool multiline;
  String? defaultText;
  double? defaultNumber;
  bool defaultBool;
  int? defaultOptionId;
  FieldDateMode dateMode;
  int? defaultOffsetDays;
  bool notifyDefault;
  int leadDays;
  FieldOverridePolicy overridePolicy;
  bool stopWhenDone;
  List<OptionDraft> options;

  FieldDraft({
    required this.name,
    required this.type,
    this.listId,
    this.hint,
    this.multiline = false,
    this.defaultText,
    this.defaultNumber,
    this.defaultBool = false,
    this.defaultOptionId,
    this.dateMode = FieldDateMode.absolute,
    this.defaultOffsetDays,
    this.notifyDefault = false,
    this.leadDays = 0,
    this.overridePolicy = FieldOverridePolicy.fieldOnly,
    this.stopWhenDone = false,
    this.options = const [],
  });
}

class OptionDraft {
  final int? id;
  String label;
  int valueCount;

  OptionDraft({this.id, required this.label, this.valueCount = 0});
}

/// The user's answer to the remap-or-clear prompt: [clear] empties the values,
/// otherwise they move to [remapToId].
class RemapChoice {
  final bool clear;
  final int? remapToId;

  const RemapChoice({this.clear = false, this.remapToId});
}
