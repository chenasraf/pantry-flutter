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

/// Width from which the sections become a sidebar with the open one beside
/// them, rather than a list that opens each as a screen of its own.
const double _sidebarBreakpoint = 720;

const double _sidebarWidth = 300;

enum _Section { general, interface, refresh, notifications }

typedef _SectionEntry = ({
  _Section section,
  IconData icon,
  String title,
  String subtitle,
});

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  /// Whether this build can reach a watch at all. The FLOSS build carries no
  /// Data Layer, so the row is absent there rather than present and dead.
  var _watchLinkAvailable = false;

  /// The section the sidebar shows beside itself. Nothing opens by itself on
  /// the narrow layout, where this is the section last opened and never read.
  var _section = _Section.general;

  @override
  void initState() {
    super.initState();
    unawaited(_resolveWatchLink());
  }

  Future<void> _resolveWatchLink() async {
    final available = await WearLinkService.instance.isAvailable();
    if (mounted && available) setState(() => _watchLinkAvailable = true);
  }

  List<_SectionEntry> get _sections => [
    (
      section: _Section.general,
      icon: Icons.tune,
      title: m.settings.generalSection,
      subtitle: m.settings.generalSectionBody,
    ),
    (
      section: _Section.interface,
      icon: Icons.dashboard_customize_outlined,
      title: m.settings.interfaceSection,
      subtitle: m.settings.interfaceSectionBody,
    ),
    (
      section: _Section.refresh,
      icon: Icons.sync,
      title: m.settings.refreshSection,
      subtitle: m.settings.refreshSectionSubtitle,
    ),
    if (supportsFeature('notifications'))
      (
        section: _Section.notifications,
        icon: Icons.notifications_outlined,
        title: m.settings.notificationsSection,
        subtitle: m.settings.notificationsSectionBody,
      ),
  ];

  Widget _page(_Section section, {required bool embedded}) => switch (section) {
    _Section.general => GeneralSettingsView(embedded: embedded),
    _Section.interface => InterfaceSettingsView(embedded: embedded),
    _Section.refresh => RefreshSettingsView(embedded: embedded),
    _Section.notifications => NotificationSettingsView(embedded: embedded),
  };

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  /// Pairing is a flow rather than a page of settings, so it opens as a screen
  /// from either layout.
  Widget? _watchTile() => _watchLinkAvailable
      // Reactive by design: the phone never raises the subject first, because
      // the flow starts on the watch, which is where a user who has the watch
      // app will meet it.
      ? SettingsPageTile(
          icon: Icons.watch_outlined,
          title: m.watch.title,
          subtitle: m.settings.watchSubtitle,
          onTap: () => WatchPairingView.open(context),
        )
      : null;

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    // The server's capabilities can land after the first build and take a
    // section with them; fall back rather than leave the sidebar pointing at
    // nothing.
    final selected = sections.any((e) => e.section == _section)
        ? _section
        : sections.first.section;

    return Scaffold(
      appBar: AppBar(
        leading: appBarBackLeading(context),
        title: Text(m.settings.title),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final watchTile = _watchTile();
          if (constraints.maxWidth < _sidebarBreakpoint) {
            return SettingsList(
              children: [
                for (final entry in sections)
                  SettingsPageTile(
                    icon: entry.icon,
                    title: entry.title,
                    subtitle: entry.subtitle,
                    onTap: () => _open(_page(entry.section, embedded: false)),
                  ),
                ?watchTile,
              ],
            );
          }
          return Row(
            children: [
              SizedBox(
                width: _sidebarWidth,
                child: SettingsList(
                  children: [
                    for (final entry in sections)
                      SettingsPageTile(
                        icon: entry.icon,
                        title: entry.title,
                        subtitle: entry.subtitle,
                        selected: entry.section == selected,
                        onTap: () => setState(() => _section = entry.section),
                      ),
                    ?watchTile,
                  ],
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: _page(selected, embedded: true)),
            ],
          );
        },
      ),
    );
  }
}
