import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/services/server_version_service.dart';

/// Footnote for onboarding pages that pitch a server-backed feature. The pages
/// always show — even against a server too old to support the feature — so this
/// note fills the gap: when the connected server hasn't confirmed [feature],
/// it explains the minimum Pantry version the feature needs. Once the server
/// reports support (or the dev force-features override is on), it renders
/// nothing.
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
