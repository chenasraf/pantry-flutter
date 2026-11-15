import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/sync/sync_manager.dart';

import '../checklists/checklists_controller.dart';
import '../services/server_reach.dart';
import '../widgets/wear_cta.dart';
import '../widgets/wear_ink.dart';
import '../widgets/wear_mechanics.dart';
import '../wear_shape.dart';

/// Throwing a trip away. Its own page rather than a row that acts on a tap,
/// because nothing brings back what was checked on it — the back gesture is
/// the "keep shopping".
class CancelTripPage extends StatefulWidget {
  final ChecklistsController controller;

  const CancelTripPage({super.key, required this.controller});

  @override
  State<CancelTripPage> createState() => _CancelTripPageState();
}

class _CancelTripPageState extends State<CancelTripPage> {
  var _busy = false;
  String? _error;

  Future<void> _cancel() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final cancelled = await widget.controller.cancelTrip();
    if (!mounted) return;
    if (cancelled) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = m.wear.cancelFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: wearGround,
      body: EdgeDismissible(
        onDismiss: () => Navigator.of(context).pop(),
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: WearShape.isRound ? 30 : 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        m.shopping.cancelTripTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        m.wear.cancelTripBody,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          color: Colors.white54,
                        ),
                      ),
                      // The button's own height, so the text above it is
                      // centred in what is left of the screen rather than
                      // behind it.
                      SizedBox(height: constraints.maxHeight * 0.22),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: WearCta.insetFor(constraints.maxHeight),
                child: WearCta(
                  key: const ValueKey('cancel-trip'),
                  icon: Icons.cancel_outlined,
                  label: m.shopping.cancelTrip,
                  warning: true,
                  busy: _busy,
                  error: _error,
                  reason: unreachableReason(SyncManager.instance.isOnline),
                  onTap: () => unawaited(_cancel()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
