import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/server_version_service.dart';
import 'package:pantry_core/services/wear_link_service.dart';
import 'package:pantry/views/settings/general_settings_view.dart';
import 'package:pantry/views/settings/interface_settings_view.dart';
import 'package:pantry/views/settings/notification_settings_view.dart';
import 'package:pantry/views/settings/refresh_settings_view.dart';
import 'package:pantry/views/settings/settings_tiles.dart';
import 'package:pantry/views/watch/watch_pairing_view.dart';
import 'package:pantry/widgets/app_bar_back_leading.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  /// Whether this build can reach a watch at all. The FLOSS build carries no
  /// Data Layer, so the row is absent there rather than present and dead.
  var _watchLinkAvailable = false;

  @override
  void initState() {
    super.initState();
    unawaited(_resolveWatchLink());
  }

  Future<void> _resolveWatchLink() async {
    final available = await WearLinkService.instance.isAvailable();
    if (mounted && available) setState(() => _watchLinkAvailable = true);
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(m.settings.title),
      ),
      body: SettingsList(
        children: [
          SettingsPageTile(
            icon: Icons.tune,
            title: m.settings.generalSection,
            subtitle: m.settings.generalSectionBody,
            onTap: () => _open(const GeneralSettingsView()),
          ),
          SettingsPageTile(
            icon: Icons.dashboard_customize_outlined,
            title: m.settings.interfaceSection,
            subtitle: m.settings.interfaceSectionBody,
            onTap: () => _open(const InterfaceSettingsView()),
          ),
          SettingsPageTile(
            icon: Icons.sync,
            title: m.settings.refreshSection,
            subtitle: m.settings.refreshSectionSubtitle,
            onTap: () => _open(const RefreshSettingsView()),
          ),
          // Reactive by design: the phone never raises the subject first,
          // because the flow starts on the watch, which is where a user who
          // has the watch app will meet it.
          if (_watchLinkAvailable)
            SettingsPageTile(
              icon: Icons.watch_outlined,
              title: m.watch.title,
              subtitle: m.settings.watchSubtitle,
              onTap: () => WatchPairingView.open(context),
            ),
          if (supportsFeature('notifications'))
            SettingsPageTile(
              icon: Icons.notifications_outlined,
              title: m.settings.notificationsSection,
              subtitle: m.settings.notificationsSectionBody,
              onTap: () => _open(const NotificationSettingsView()),
            ),
        ],
      ),
    );
  }
}
