import 'package:flutter/material.dart';

import 'package:pantry/theme/app_theme.dart';

/// One of an [AmountStepper]'s buttons. A null [onTap] disables it.
typedef AmountStep = ({
  String label,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
});

/// − {amount} +, framed together; or, with no [amount], the two buttons alone,
/// each outlined so they still read as a pair on a narrow row.
class AmountStepper extends StatelessWidget {
  const AmountStepper({
    super.key,
    required this.decrease,
    required this.increase,
    this.amount,
  });

  final AmountStep decrease;
  final AmountStep increase;
  final Widget? amount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amount = this.amount;
    final bare = amount == null;
    final minus = _StepButton(
      icon: Icons.remove,
      step: decrease,
      outlined: bare,
    );
    final plus = _StepButton(icon: Icons.add, step: increase, outlined: bare);
    if (bare) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [minus, const SizedBox(width: 4), plus],
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(SurfaceRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [minus, amount, plus],
      ),
    );
  }
}

/// The amount between an [AmountStepper]'s buttons, kept to one line.
class AmountStepperText extends StatelessWidget {
  const AmountStepperText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 24, maxWidth: 120),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.step,
    required this.outlined,
  });

  final IconData icon;
  final AmountStep step;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = step.onTap != null;
    final radius = BorderRadius.circular(SurfaceRadius.chip);
    final button = InkResponse(
      onTap: step.onTap,
      onLongPress: step.onLongPress,
      radius: 20,
      containedInkWell: outlined,
      highlightShape: outlined ? BoxShape.rectangle : BoxShape.circle,
      borderRadius: outlined ? radius : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: outlined
            ? BoxDecoration(
                border: Border.all(color: cs.outlineVariant),
                borderRadius: radius,
              )
            : null,
        child: Icon(
          icon,
          size: 20,
          color: enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.38),
        ),
      ),
    );
    return Tooltip(
      message: step.label,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: step.label,
        excludeSemantics: true,
        // A disabled button still takes its tap, so a tap on a greyed − does
        // not fall through to a row that reads it as something else.
        child: enabled
            ? button
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: button,
              ),
      ),
    );
  }
}
