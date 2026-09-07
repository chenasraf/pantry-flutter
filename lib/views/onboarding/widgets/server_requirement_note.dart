import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/server_version_service.dart';

/// Footnote for onboarding pages that pitch a server-backed feature. Those
/// pages always show, even on a too-old server — so when the server hasn't
/// confirmed [feature], this note names the minimum Pantry version it needs.
/// Renders nothing once the server reports support (or force-features is on).
class ServerRequirementNote extends StatelessWidget {
  /// Capability name checked via [hasFeature]. The note only appears while this
  /// returns `false`.
  final String feature;

  /// Minimum Pantry server version that introduced [feature], e.g. `'0.24.0'`.
  final String requiredVersion;

  const ServerRequirementNote({
    super.key,
    required this.feature,
    required this.requiredVersion,
  });

  @override
  Widget build(BuildContext context) {
    if (hasFeature(feature)) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text(
        m.onboarding.serverRequirementNote(requiredVersion),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
