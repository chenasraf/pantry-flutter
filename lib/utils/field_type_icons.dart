import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/custom_field.dart';

/// The five field types in their locked presentation order (per the UI
/// contract).
const List<FieldType> kFieldTypesInOrder = [
  FieldType.text,
  FieldType.number,
  FieldType.checkbox,
  FieldType.date,
  FieldType.select,
];

IconData fieldTypeIcon(FieldType type) => switch (type) {
  FieldType.text => Icons.text_fields,
  FieldType.number => Icons.numbers,
  FieldType.checkbox => Icons.check_box_outlined,
  FieldType.date => Icons.event,
  FieldType.select => Icons.list,
};

String fieldTypeLabel(FieldType type) => switch (type) {
  FieldType.text => m.customFields.types.text,
  FieldType.number => m.customFields.types.number,
  FieldType.checkbox => m.customFields.types.checkbox,
  FieldType.date => m.customFields.types.date,
  FieldType.select => m.customFields.types.select,
};
