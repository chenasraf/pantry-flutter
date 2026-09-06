import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/prefs_service.dart';

import '../services/wear_host_service.dart';
import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_row.dart';
import 'chip_visibility_page.dart';
import 'crown_steering_page.dart';
import 'refresh_interval_page.dart';

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

class _WearSettingsPageState extends State<WearSettingsPage> {
  final _scroll = ScrollController();

  /// Drawn until the platform says otherwise, which is also what it stays as
  /// if the platform says nothing: the crown row fails towards being offered.
  var _hasRotary = true;

  @override
  void initState() {
    super.initState();
    unawaited(_readRotary());
  }

  Future<void> _readRotary() async {
    final present = await WearHostService.instance.hasRotary();
    if (mounted) setState(() => _hasRotary = present);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    // The picker wrote the value; this page draws it.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
                height: WearMetrics.cardHeight,
                child: WearRow(
                  icon: Icons.refresh,
                  label: m.wear.refreshInterval,
                  value: refreshIntervalLabel(
                    PrefsService.instance.wearPollSeconds,
                  ),
                  onTap: () => unawaited(_open(const RefreshIntervalPage())),
                ),
              ),
              if (_hasRotary) ...[
                const SizedBox(height: WearMetrics.cardGap),
                SizedBox(
                  height: WearMetrics.cardHeight,
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
              const SizedBox(height: WearMetrics.cardGap),
              SizedBox(
                height: WearMetrics.cardHeight,
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
