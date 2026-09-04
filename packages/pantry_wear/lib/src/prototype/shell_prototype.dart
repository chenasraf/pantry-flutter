import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../debug/channel_harness_view.dart';
import 'proto_data.dart';
import 'variant_arc_focus.dart';
import 'variant_full_bleed.dart';
import 'variant_header_rail.dart';
import 'variant_rail_focus.dart';

/// PROTOTYPE — three watch shells on one route, to be judged on a real round
/// watch and then thrown away.
///
/// They disagree about the two things a shell decides: how much of the screen
/// permanent chrome is worth, and whether rows should follow the circle.
///
///  * **D — Rail focus**: B's rail and cards over C's snapping centred-focus
///    list, and B unchanged on a square screen.
///  * **A — Full bleed**: no chrome, curved rows on the chord of the circle,
///    sync interrupts only when it has news.
///  * **B — Header rail**: a permanent rail across the top, uniform rows, no
///    curvature — the rectangular control for the whole question.
///  * **C — Arc focus**: chrome pushed onto the bezel, a snapping list with
///    one row in charge.
///
/// **Long-press anywhere to cycle.** The switcher is a gesture rather than a
/// bar because a permanent bar would itself answer the question the variants
/// are asking. The choice is in memory only — a restart lands back on A.
class ShellPrototype extends StatefulWidget {
  const ShellPrototype({super.key});

  @override
  State<ShellPrototype> createState() => _ShellPrototypeState();
}

class _ShellPrototypeState extends State<ShellPrototype> {
  static const _labels = [
    ('D', VariantRailFocus.label),
    ('A', VariantFullBleed.label),
    ('B', VariantHeaderRail.label),
    ('C', VariantArcFocus.label),
  ];

  final _sync = ProtoSyncCycler();
  var _variant = 0;
  Timer? _toast;
  var _showToast = false;

  @override
  void dispose() {
    _toast?.cancel();
    _sync.dispose();
    super.dispose();
  }

  void _cycle(int by) {
    setState(() {
      _variant = (_variant + by) % _labels.length;
      _showToast = true;
    });
    _toast?.cancel();
    _toast = Timer(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _showToast = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final (key, name) = _labels[_variant];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Nothing in the prototype claims a long press, so it is free to
        // spend on the one control this needs.
        onLongPress: () => _cycle(1),
        onDoubleTap: kDebugMode ? () => _openHarness(context) : null,
        child: Stack(
          children: [
            Positioned.fill(child: _current()),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showToast ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        child: Text(
                          '$key · $name',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The channel harness lost its button when the shell took over the route.
  void _openHarness(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ChannelHarnessView()));

  Widget _current() => switch (_variant) {
    0 => VariantRailFocus(sync: _sync),
    1 => VariantFullBleed(sync: _sync),
    2 => VariantHeaderRail(sync: _sync),
    _ => VariantArcFocus(sync: _sync),
  };
}
