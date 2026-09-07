import 'package:flutter/material.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry/views/watch/tips/watch_mock.dart';

/// Tells users there is a watch app at all, and where the rest of the answers
/// are. Everything about *using* it lives in Settings → Watch, so this page
/// carries one demo rather than a tour: the checklist ticking itself off, which
/// is what a wearer spends their time doing and the one thing that reads at
/// this size.
class WatchOnboardingPage extends StatelessWidget {
  const WatchOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ob.watchTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ob.watchBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Center(child: _TickingWatch()),
          const SizedBox(height: 24),
          _HowTo(
            text: ob.watchHowTo(m.settings.title, m.settings.watchSection),
          ),
        ],
      ),
    );
  }
}

/// The watch working through a list, one tap per item, forever.
///
/// Hand-driven rather than a stack of [AnimatedFoo]s so the tap cue, the tick
/// and the undo stroke are phases of one gesture instead of three timers that
/// agree at first and drift by the tenth loop.
class _TickingWatch extends StatefulWidget {
  const _TickingWatch();

  @override
  State<_TickingWatch> createState() => _TickingWatchState();
}

class _TickingWatchState extends State<_TickingWatch>
    with SingleTickerProviderStateMixin {
  static const _perItem = Duration(milliseconds: 2200);

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: _perItem * 3,
  );

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop.stop();
      // Two of the three ticked: enough to say what the list does without a
      // reader having to imagine the motion.
      _loop.value = 0.7;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  /// The row the ticking starts on. Never the first: a list whose top row is
  /// the one under the centre line leaves the upper half of the face empty for
  /// the whole first tick, which reads as a half-drawn watch rather than as a
  /// list you have already scrolled into.
  static const _first = 1;

  @override
  Widget build(BuildContext context) {
    final ob = m.onboarding;
    final labels = [
      ob.mockBulkItemFourth,
      ob.mockItemName,
      ob.mockBulkItemThird,
      ob.mockHardwareItemName,
    ];
    final ticks = labels.length - _first;

    return AnimatedBuilder(
      animation: _loop,
      builder: (context, _) {
        final t = _loop.value * ticks;
        final index = (_first + t.floor()).clamp(_first, labels.length - 1);
        final within = t - t.floor();

        // The centre line walks down the list a row at a time, easing between
        // rows so a tick and the travel to the next one are one movement.
        final centre =
            index + Curves.easeInOutCubic.transform(_span(within, 0.62, 0.98));

        return WatchMock(
          size: 176,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MockFace(
                rail: MockRail(
                  title: ob.mockListGroceries,
                  icon: Icons.local_grocery_store_outlined,
                  group: ob.mockItemCategory,
                ),
                body: MockItemList(
                  items: [
                    for (var i = 0; i < labels.length; i++)
                      MockItem(
                        labels[i],
                        checked:
                            (i >= _first && i < index) ||
                            (i == index && within >= 0.24),
                        undo: i == index && within >= 0.24 && within < 0.6
                            ? 1 - _span(within, 0.24, 0.6)
                            : null,
                      ),
                  ],
                  centre: centre,
                ),
              ),
              if (within < 0.24) TapCue(t: _span(within, 0.02, 0.24)),
            ],
          ),
        );
      },
    );
  }

  static double _span(double v, double from, double to) =>
      ((v - from) / (to - from)).clamp(0.0, 1.0);
}

/// The line that says where to go next, in the livery the other onboarding
/// pages use for the same job.
class _HowTo extends StatelessWidget {
  final String text;

  const _HowTo({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.watch_outlined, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.45,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
