import 'package:flutter/material.dart';

/// PROTOTYPE — the rival treatments for the degraded (401) state, drawn over
/// the real rail and the real pages so the choice is made against the actual
/// geometry rather than a sketch.
///
/// The state itself is `AuthService.isUnauthorized`, already live in core. What
/// is open is where a 1.4" round screen puts it: the rail owns the top and the
/// list runs full height underneath it, so a band inserted above the rail costs
/// the focus falloff its centre line.
///
/// Cycle the variants from the account page (debug builds only).
enum DegradedProto {
  /// The rail's second line — the slot the sticky group label and the
  /// *Change list* button share — carries a lock and the state, outranking
  /// both, over a wash behind the whole rail. Costs no geometry, and the slot
  /// is empty on every page but the checklist; the wash is what makes a line
  /// this small read as a state rather than another label.
  railLine('A · rail line'),

  /// The sync dot's slot becomes the lock. Smallest footprint of the four, and
  /// the only one that spends no width the rail was not already spending — but
  /// the dot then answers two questions with one glyph.
  syncDot('B · sync dot'),

  /// A persistent strip along the bottom, where the transient notice already
  /// draws. Touches neither the rail nor the centre line, at the cost of
  /// covering the bottom of the list for as long as it stands.
  bottomStrip('C · bottom strip'),

  /// The rail's title row entirely: lock, state, and a wash behind the whole
  /// rail. Impossible to miss, and it costs the wearer the name of the list
  /// they are looking at for as long as it stands.
  railTakeover('D · rail takeover');

  const DegradedProto(this.label);

  /// What the account page's cycle control shows.
  final String label;
}

/// The ink every variant is drawn in, taken from the shell's transient notice
/// so the two read as the same family of thing.
const protoDegradedInk = Color(0xFFE0A0A0);
const protoDegradedGround = Color(0xFF2A1D1D);

/// The short form. `common.sessionExpiredBody` is phone-length prose and does
/// not fit any of these; whether the strings split is part of what this
/// prototype is asking.
const protoDegradedShort = 'Sign-in expired';
const protoDegradedHeld = 'Held';
const protoDegradedAction = 'Set up again';

/// [DegradedProto.railLine] and [DegradedProto.railTakeover] both draw inside
/// the rail's own column; this is the line they share.
class ProtoDegradedRailLine extends StatelessWidget {
  final VoidCallback? onTap;

  const ProtoDegradedRailLine({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('proto-degraded-line'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 10, color: protoDegradedInk),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              protoDegradedShort,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                height: 1.1,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w700,
                color: protoDegradedInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [DegradedProto.syncDot] — what stands where the queue readout stands.
class ProtoDegradedDot extends StatelessWidget {
  const ProtoDegradedDot({super.key});

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.lock_outline, size: 10, color: protoDegradedInk),
      SizedBox(width: 4),
      Text(
        protoDegradedHeld,
        style: TextStyle(fontSize: 9, color: protoDegradedInk),
      ),
    ],
  );
}

/// [DegradedProto.railTakeover] — the title row, replaced.
class ProtoDegradedTitleRow extends StatelessWidget {
  final VoidCallback? onTap;

  const ProtoDegradedTitleRow({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 12, color: protoDegradedInk),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              protoDegradedShort,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: protoDegradedInk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [DegradedProto.bottomStrip] — the persistent sibling of the shell's
/// transient notice, carrying its action rather than only its wording.
class ProtoDegradedStrip extends StatelessWidget {
  final VoidCallback? onTap;

  const ProtoDegradedStrip({super.key, this.onTap});

  @override
  Widget build(BuildContext context) => Center(
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: protoDegradedGround,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 11, color: protoDegradedInk),
              SizedBox(width: 5),
              Text(
                protoDegradedAction,
                style: TextStyle(fontSize: 10, color: protoDegradedInk),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Where *Set up again* lands while the pairing screen it belongs to is still
/// unbuilt. Standing in for card 730's screen, so the gesture and the depth are
/// real even though the destination is not.
class ProtoSetupAgainPage extends StatelessWidget {
  const ProtoSetupAgainPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0B0B0C),
    body: Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.lock_outline, size: 22, color: protoDegradedInk),
            SizedBox(height: 8),
            Text(
              protoDegradedAction,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            SizedBox(height: 4),
            Text(
              'the pairing screen goes here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.white38),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The cycle control, on the account page in debug builds. Off → A → B → C → D
/// → off, so every treatment can be worn on the wrist without a rebuild.
class ProtoDegradedSwitch extends StatelessWidget {
  final DegradedProto? value;
  final ValueChanged<DegradedProto?> onChanged;

  const ProtoDegradedSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  void _cycle() {
    const all = DegradedProto.values;
    if (value == null) return onChanged(all.first);
    final next = all.indexOf(value!) + 1;
    onChanged(next == all.length ? null : all[next]);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _cycle,
    behavior: HitTestBehavior.opaque,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
        child: Text(
          value == null ? '401: off' : '401: ${value!.label}',
          style: const TextStyle(fontSize: 9, color: Colors.white54),
        ),
      ),
    ),
  );
}
