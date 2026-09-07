import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/custom_field.dart';
import 'package:pantry_core/utils/field_type_icons.dart';
import 'package:pantry/views/onboarding/widgets/server_requirement_note.dart';

/// Introduces custom fields: a mock of the item detail's custom-fields tile
/// with two filled rows, plus the five field types as chips. Always shown; a
/// footnote names the required Pantry version when the server lacks the
/// `custom-fields` capability.
class CustomFieldsOnboardingPage extends StatelessWidget {
  const CustomFieldsOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ob.customFieldsTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.customFieldsBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const _MockFieldsTile(),
          const SizedBox(height: 20),
          Text(
            ob.customFieldsTypesCaption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const _TypeChips(),
          const ServerRequirementNote(
            feature: 'custom-fields',
            requiredVersion: '0.30.0',
          ),
        ],
      ),
    );
  }
}

/// A non-interactive copy of the custom-fields tile shown on an item, filled
/// with a date field and a select field.
class _MockFieldsTile extends StatelessWidget {
  const _MockFieldsTile();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ob = m.onboarding;
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border.all(color: cs.primary, width: 1.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.customFields.manageTitle.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 10),
          _MockRow(
            type: FieldType.date,
            name: ob.customFieldsMockExpiry,
            value: ob.customFieldsMockExpiryValue,
          ),
          const SizedBox(height: 12),
          _MockRow(
            type: FieldType.select,
            name: ob.customFieldsMockAisle,
            value: ob.customFieldsMockAisleValue,
          ),
        ],
      ),
    );
  }
}

/// One filled field on the mock tile: the type's icon, the field name, and the
/// value beneath it.
class _MockRow extends StatelessWidget {
  final FieldType type;
  final String name;
  final String value;

  const _MockRow({required this.type, required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(fieldTypeIcon(type), size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The five field types, as the type selector presents them.
class _TypeChips extends StatelessWidget {
  const _TypeChips();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (final type in kFieldTypesInOrder)
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant),
            ),
            padding: const EdgeInsetsDirectional.fromSTEB(10, 7, 12, 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(fieldTypeIcon(type), size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  fieldTypeLabel(type),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
