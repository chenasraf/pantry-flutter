import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry_core/widgets/entity_chip.dart';
import 'package:pantry/theme/app_theme.dart';
import 'package:pantry/views/onboarding/widgets/onboarding_how_to.dart';
import 'package:pantry/views/onboarding/widgets/server_requirement_note.dart';

/// Introduces templates. A template's items only ever surface as suggestions
/// while typing on a list it is attached to, so the mock is that panel over a
/// half-typed name rather than the template itself.
class TemplatesOnboardingPage extends StatelessWidget {
  const TemplatesOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ob.templateTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.templateBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const _MockSuggestions(),
          const SizedBox(height: 8),
          const _MockCompose(),
          const SizedBox(height: 20),
          OnboardingHowTo(
            icon: Icons.copy_all_outlined,
            text: ob.templateHow(m.templates.applyToList),
          ),
          const ServerRequirementNote(requiredVersion: '0.38.0'),
        ],
      ),
    );
  }
}

class _MockSuggestions extends StatelessWidget {
  const _MockSuggestions();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ob = m.onboarding;
    return Container(
      decoration: AppSurfaces.of(context).card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 14, 9),
            child: Text(
              m.templates.suggestionsHeader.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          for (final (i, name) in [
            ob.templateMockFirst,
            ob.templateMockSecond,
          ].indexed) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            _MockSuggestion(name: name),
          ],
        ],
      ),
    );
  }
}

class _MockSuggestion extends StatelessWidget {
  final String name;

  const _MockSuggestion({required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
      child: Row(
        children: [
          Icon(Icons.add_circle_outline, size: 22, color: cs.primary),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              name,
              textDirection: detectTextDirection(name),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: EntityChip(
              leading: Icon(
                Icons.description_outlined,
                size: 13,
                color: cs.onSurfaceVariant,
              ),
              label: m.templates.fromTemplates(m.onboarding.templateMockName),
              textColor: cs.onSurfaceVariant,
              background: cs.onSurface.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }
}

/// The add bar with the first letters of a name in it, caret and all.
class _MockCompose extends StatelessWidget {
  const _MockCompose();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final typed = m.onboarding.templateMockTyped;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(SurfaceRadius.card),
        border: Border.all(color: cs.primary, width: 1.5),
      ),
      child: Row(
        children: [
          Text(
            typed,
            textDirection: detectTextDirection(typed),
            style: theme.textTheme.bodyLarge,
          ),
          Container(width: 2, height: 20, color: cs.primary),
        ],
      ),
    );
  }
}
