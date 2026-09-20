import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/sync/sync_manager.dart';
import 'package:pantry_core/utils/text_direction.dart';

import '../checklists/checklists_controller.dart';
import '../services/server_reach.dart';
import '../widgets/wear_avatar.dart';
import '../widgets/wear_cta.dart';
import '../widgets/wear_ink.dart';
import '../widgets/wear_mechanics.dart';
import '../wear_shape.dart';

/// Stepping out of a trip somebody else is shopping.
///
/// The faces come first and the button second, because the thing a wearer has
/// to be sure of before tapping it is whose trip keeps going without them —
/// leaving and finishing are one tap apart on the page this opens from, and
/// only one of them is reversible by walking back in.
class LeaveTripPage extends StatefulWidget {
  final ChecklistsController controller;

  const LeaveTripPage({super.key, required this.controller});

  @override
  State<LeaveTripPage> createState() => _LeaveTripPageState();
}

class _LeaveTripPageState extends State<LeaveTripPage> {
  var _busy = false;
  String? _error;

  Future<void> _leave() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final left = await widget.controller.leaveTrip();
    if (!mounted) return;
    if (left) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = m.wear.leaveFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final companions = controller.companions;
    final names = companions.map((m) => m.displayName).join(', ');
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
                      WearAvatarStack(
                        members: [
                          for (final member in companions)
                            (
                              userId: member.userId,
                              displayName: member.displayName,
                            ),
                        ],
                        size: 28,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        names,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        textDirection: detectTextDirection(names),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        m.wear.leaveTripBody,
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
                  key: const ValueKey('leave-trip'),
                  icon: Icons.logout,
                  label: m.shopping.leaveTrip,
                  warning: true,
                  busy: _busy,
                  error: _error,
                  reason: unreachableReason(SyncManager.instance.isOnline),
                  onTap: () => unawaited(_leave()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
