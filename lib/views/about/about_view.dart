import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';

class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    });
  }

  Future<void> _launch(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = m.about;

    return Scaffold(
      appBar: AppBar(leading: appBarBackLeading(context), title: Text(a.title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                SvgPicture.asset('assets/logo_icon.svg', width: 96, height: 96),
                const SizedBox(height: 16),
                Text(
                  m.common.appTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _version,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _AboutTile(
            icon: Icons.person_outlined,
            label: a.developer,
            value: 'Chen Asraf',
          ),
          _AboutTile(
            icon: Icons.email_outlined,
            label: a.email,
            value: 'contact@casraf.dev',
            onTap: () => _launch('mailto:contact@casraf.dev'),
          ),
          _AboutTile(
            icon: Icons.code,
            label: a.repository,
            onTap: () => _launch('https://github.com/chenasraf/pantry-flutter'),
          ),
          _AboutTile(
            icon: Icons.bug_report_outlined,
            label: a.feedback,
            onTap: () =>
                _launch('https://github.com/chenasraf/pantry-flutter/issues'),
          ),
          _AboutTile(
            icon: Icons.cloud_outlined,
            label: a.nextcloudApp,
            onTap: () => _launch('https://apps.nextcloud.com/apps/pantry'),
          ),
          _AboutTile(
            icon: Icons.privacy_tip_outlined,
            label: a.privacyPolicy,
            onTap: () => _launch('https://casraf.dev/pantry-privacy-policy'),
          ),
        ],
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  const _AboutTile({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      subtitle: value != null
          ? Text(
              value!,
              style: onTap != null
                  ? TextStyle(color: theme.colorScheme.primary)
                  : null,
            )
          : null,
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant)
          : null,
      onTap: onTap,
    );
  }
}
