import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/services/auth_service.dart';

class ServerAppMissingView extends StatelessWidget {
  final VoidCallback onRetry;

  const ServerAppMissingView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serverUrl = AuthService.instance.credentials?.serverUrl ?? '';
    // Nextcloud app store path for pantry
    final appUrl = '$serverUrl/settings/apps/organization/pantry';
    final infoUrl = 'https://apps.nextcloud.com/apps/pantry';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.extension_off_outlined,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              m.home.serverAppMissingTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              m.home.serverAppMissingBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _launch(appUrl),
              icon: const Icon(Icons.open_in_new),
              label: Text(m.home.openAppStore),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _launch(infoUrl),
              icon: const Icon(Icons.info_outline),
              label: Text(m.home.learnMore),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: Text(m.common.retry)),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
