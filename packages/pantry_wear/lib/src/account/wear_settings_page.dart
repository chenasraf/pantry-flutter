import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/prefs_service.dart';

import '../widgets/wear_mechanics.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_row.dart';
import 'refresh_interval_page.dart';

/// What the wearer can change about how the watch behaves.
///
/// The phone's section order, its hidden-section prefs and the checklist prefs
/// are not among them: the shell ignores the first two by design and fixes the
/// third on the watch.
class WearSettingsPage extends StatefulWidget {
  const WearSettingsPage({super.key});

  @override
  State<WearSettingsPage> createState() => _WearSettingsPageState();
}

class _WearSettingsPageState extends State<WearSettingsPage> {
  final _scroll = ScrollController();

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
            ],
          ),
        ),
      ),
    );
  }
}
