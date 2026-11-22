import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry/theme/app_theme.dart';
import 'package:pantry/views/checklists/item_compose_chips.dart';
import 'package:pantry/views/onboarding/widgets/onboarding_how_to.dart';

const _memoryVersion = '0.40.0';

/// Introduces smart input: the add bar with "2 L milk" typed in, and the
/// guesses it turns into. Reading the amount out of the text works on any
/// server; the category comes from household memory, so its chip only shows,
/// and its footnote only hides, once the server keeps that memory.
class SmartInputOnboardingPage extends StatelessWidget {
  const SmartInputOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;
    final hasMemory = ServerFeature.itemMemory;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ob.smartInputTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.smartInputBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _MockCompose(showCategory: hasMemory),
          const SizedBox(height: 20),
          OnboardingHowTo(
            icon: Icons.auto_awesome_outlined,
            text: ob.smartInputHow(
              m.settings.title,
              m.settings.interfaceSection,
              m.settings.smartItemInput,
            ),
          ),
          if (!hasMemory)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 20),
              child: Text(
                ob.smartInputMemoryNote(_memoryVersion),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

/// The add bar with a whole line typed in, and the guesses read out of it as
/// chips underneath.
class _MockCompose extends StatelessWidget {
  final bool showCategory;

  const _MockCompose({required this.showCategory});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;
    final typed = ob.smartInputMockTyped;
    final name = ob.smartInputMockName;
    final categoryColor = cs.tertiary;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(SurfaceRadius.card),
        border: Border.all(color: cs.primary, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                typed,
                textDirection: detectTextDirection(typed),
                style: theme.textTheme.bodyLarge,
              ),
              Container(width: 2, height: 20, color: cs.primary),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                name,
                textDirection: detectTextDirection(name),
                style: TextStyle(fontSize: 14, color: cs.onSurface),
              ),
              GuessChip(label: ob.smartInputMockAmount, onDrop: () {}),
              if (showCategory)
                GuessChip(
                  label: ob.smartInputMockCategory,
                  color: categoryColor,
                  leading: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onDrop: () {},
                ),
            ],
          ),
        ],
      ),
    );
  }
}
