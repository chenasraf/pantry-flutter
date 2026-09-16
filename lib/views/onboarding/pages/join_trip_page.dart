import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry/views/onboarding/widgets/server_requirement_note.dart';

/// Introduces joining a housemate's shopping trip. The offer only ever appears
/// as a banner above the checklist, and only while someone else is actually
/// out shopping, so a viewer can go weeks without meeting it by accident —
/// hence a mock of that exact banner rather than a description of it.
class JoinTripOnboardingPage extends StatelessWidget {
  const JoinTripOnboardingPage({super.key});

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
            ob.joinTripTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.joinTripBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          const _MockJoinBanner(),
          const SizedBox(height: 20),
          _HowTo(text: ob.joinTripHow),
          const ServerRequirementNote(
            feature: 'shopping-join-session',
            requiredVersion: '0.33.0',
          ),
        ],
      ),
    );
  }
}

/// The join banner as it sits above the checklist, down to the livery — a
/// viewer who meets the real one should recognise it rather than read it.
class _MockJoinBanner extends StatelessWidget {
  const _MockJoinBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;
    final name = ob.joinTripMockHousemate;

    return Container(
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      child: Row(
        children: [
          Icon(Icons.groups, color: cs.onSecondaryContainer, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              m.shopping.bannerHousemateShoppingAt(
                name,
                ob.shoppingMockStoreActive,
              ),
              textDirection: detectTextDirection(name),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IgnorePointer(
            child: FilledButton(onPressed: () {}, child: Text(m.shopping.join)),
          ),
        ],
      ),
    );
  }
}

/// The line that says what joining costs and what leaving does, in the livery
/// the other onboarding pages use for the same job.
class _HowTo extends StatelessWidget {
  final String text;

  const _HowTo({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 18,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.45,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
