import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/prefs_service.dart';
import 'package:pantry_core/services/theming_service.dart';

import '../services/wear_host_service.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_row.dart';
import 'accent_page.dart';
import 'chip_visibility_page.dart';
import 'crown_steering_page.dart';
import 'language_page.dart';
import 'refresh_interval_page.dart';
import 'undo_window_page.dart';

/// What the wearer can change about how the watch behaves.
///
/// The phone's section order and its hidden-section prefs are not among them:
/// the shell ignores both by design. Of the checklist prefs, only chip
/// visibility is offered — it is the one that decides what fits on a row this
/// narrow, and every setting here is written to this device alone.
class WearSettingsPage extends StatefulWidget {
  const WearSettingsPage({super.key});

  @override
  State<WearSettingsPage> createState() => _WearSettingsPageState();
}

class _WearSettingsPageState extends State<WearSettingsPage>
    with WidgetsBindingObserver {
  final _scroll = ScrollController();

  /// Drawn until the platform says otherwise, which is also what it stays as
  /// if the platform says nothing: the crown row fails towards being offered.
  var _hasRotary = true;

  /// Whether the watch will draw anything the app posts.
  var _notifications = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_readRotary());
    unawaited(_readNotifications());
  }

  /// The notification grant is state the system owns and changes behind us —
  /// from its own screen, or a long-press on the chip itself. [_open] hears a
  /// pushed *Flutter* route return and nothing else, so the row would keep
  /// drawing whatever was true when the page opened.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_readNotifications());
  }

  Future<void> _readRotary() async {
    final present = await WearHostService.instance.hasRotary();
    if (mounted) setState(() => _hasRotary = present);
  }

  Future<void> _readNotifications() async {
    final enabled = await WearHostService.instance.notificationsEnabled();
    if (mounted) setState(() => _notifications = enabled);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(wearRoute<void>(page));
    // The picker wrote the value; this page draws it.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final metrics = WearMetrics.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: EdgeDismissible(
        onDismiss: () => Navigator.of(context).pop(),
        child: RotaryScrollable(
          controller: _scroll,
          active: true,
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 10,
              vertical: 44,
            ),
            children: [
              SizedBox(
                height: metrics.cardHeight,
                child: WearRow(
                  icon: Icons.language,
                  label: m.settings.language,
                  value: languageLabel(PrefsService.instance.locale),
                  onTap: () => unawaited(_open(const LanguagePage())),
                ),
              ),
              SizedBox(height: metrics.cardGap),
              SizedBox(
                height: metrics.cardHeight,
                child: WearRow(
                  icon: Icons.color_lens_outlined,
                  label: m.wear.accent,
                  value: accentLabel(
                    ThemingService.instance.useServerThemeColorPref,
                  ),
                  onTap: () => unawaited(_open(const AccentPage())),
                ),
              ),
              SizedBox(height: metrics.cardGap),
              SizedBox(
                height: metrics.cardHeight,
                child: WearRow(
                  icon: Icons.refresh,
                  label: m.wear.refreshInterval,
                  value: refreshIntervalLabel(
                    PrefsService.instance.wearPollSeconds,
                  ),
                  onTap: () => unawaited(_open(const RefreshIntervalPage())),
                ),
              ),
              SizedBox(height: metrics.cardGap),
              SizedBox(
                height: metrics.cardHeight,
                child: WearRow(
                  icon: Icons.undo,
                  label: m.wear.undoWindow,
                  value: undoWindowLabel(PrefsService.instance.wearUndoSeconds),
                  onTap: () => unawaited(_open(const UndoWindowPage())),
                ),
              ),
              SizedBox(height: metrics.cardGap),
              SizedBox(
                height: metrics.cardHeight,
                child: WearRow(
                  icon: Icons.notifications_none,
                  label: m.wear.notifications,
                  value: _notifications
                      ? m.wear.notificationsAllowed
                      : m.wear.notificationsBlocked,
                  // Always the system's own screen, never a prompt: Android
                  // stops showing the prompt once it has been refused, so a row
                  // that prompted or navigated on that invisible state would do
                  // different things on two identical taps — and only the
                  // system screen can take a grant back.
                  onTap: () => unawaited(
                    WearHostService.instance.openNotificationSettings(),
                  ),
                ),
              ),
              if (_hasRotary) ...[
                SizedBox(height: metrics.cardGap),
                SizedBox(
                  height: metrics.cardHeight,
                  child: WearRow(
                    icon: Icons.rotate_right,
                    label: m.wear.crown,
                    value: crownSteeringLabel(
                      PrefsService.instance.wearCrownTurnsPages,
                    ),
                    onTap: () => unawaited(_open(const CrownSteeringPage())),
                  ),
                ),
              ],
              SizedBox(height: metrics.cardGap),
              SizedBox(
                height: metrics.cardHeight,
                child: WearRow(
                  icon: Icons.more_horiz,
                  label: m.settings.visibleChipsTitle,
                  value: m.wear.nSelected(visibleChipCount()),
                  onTap: () => unawaited(_open(const ChipVisibilityPage())),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
