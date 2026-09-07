import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/text_direction.dart';

import 'watch_tips.dart';

/// One tip: a looping picture of the watch doing the thing, over the steps the
/// picture is walking through.
///
/// The steps are not a caption track running beside the animation — they are
/// the same list either way, with the one being demonstrated lit. That keeps a
/// reader who scrolls past the picture with a plain numbered list, and gives a
/// reader watching it a place to look.
class WatchTipView extends StatefulWidget {
  final WatchTip tip;

  const WatchTipView({super.key, required this.tip});

  @override
  State<WatchTipView> createState() => _WatchTipViewState();
}

class _WatchTipViewState extends State<WatchTipView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: widget.tip.loop,
  );

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A reader who has turned animations off gets the picture held at the
    // outcome rather than a still of nothing having happened yet.
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop.stop();
      _loop.value = widget.tip.still;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tip = widget.tip;
    return Scaffold(
      appBar: AppBar(title: Text(tip.title)),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 32),
        children: [
          Text(
            tip.body,
            textDirection: detectTextDirection(tip.body),
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 20),
          _Stage(loop: _loop, tip: tip),
          const SizedBox(height: 24),
          Text(
            m.watchTips.stepsLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _loop,
            builder: (context, _) {
              final active = tip.activeStep(_loop.value);
              return Column(
                children: [
                  for (var i = 0; i < tip.steps.length; i++)
                    _Step(
                      index: i,
                      label: tip.steps[i],
                      active: i == active,
                      onTap: () => _loop.value = tip.cues[i],
                    ),
                ],
              );
            },
          ),
          if (tip.note != null) ...[
            const SizedBox(height: 16),
            _Note(tip.note!),
          ],
        ],
      ),
    );
  }
}

/// The picture, on its own ground so it reads as a diagram rather than as part
/// of the page. Scaled down rather than clipped on a narrow phone.
class _Stage extends StatelessWidget {
  final AnimationController loop;
  final WatchTip tip;

  const _Stage({required this.loop, required this.tip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 250,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsetsDirectional.all(16),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: AnimatedBuilder(
          animation: loop,
          builder: (context, _) => tip.stage(loop.value),
        ),
      ),
    );
  }
}

/// One numbered step. Tapping it takes the picture to the moment it describes.
class _Step extends StatelessWidget {
  final int index;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Step({
    required this.index,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsetsDirectional.only(bottom: 4),
        padding: const EdgeInsetsDirectional.all(10),
        decoration: BoxDecoration(
          color: active
              ? scheme.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? scheme.primary : scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                textDirection: detectTextDirection(label),
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  color: active ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The aside: true, worth knowing, and not a step.
class _Note extends StatelessWidget {
  final String text;

  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              textDirection: detectTextDirection(text),
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
