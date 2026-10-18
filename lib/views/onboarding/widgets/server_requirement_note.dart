import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/server_version_service.dart';

/// Footnote for onboarding pages that pitch a server-backed feature. Those
/// pages always show, even on a too-old server — so until the server is known
/// to run [requiredVersion] or newer, this note names that version. Renders
/// nothing once it is (or force-features is on).
class ServerRequirementNote extends StatelessWidget {
  /// Minimum Pantry server version the pitched feature needs, e.g. `'0.24.0'`.
  final String requiredVersion;

  const ServerRequirementNote({super.key, required this.requiredVersion});

  @override
  Widget build(BuildContext context) {
    if (isServerPantryVersion('>=', requiredVersion)) {
      return const SizedBox.shrink();
    }

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
