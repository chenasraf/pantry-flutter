import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/stock.dart';
import 'package:pantry_core/utils/quantity.dart';
import 'package:pantry_core/utils/stock_display.dart';
import 'package:pantry_core/utils/stock_rules.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry_core/widgets/entity_chip.dart';

import '../wear_shape.dart';
import '../widgets/undo_window.dart';
import '../widgets/wear_metrics.dart';
import '../widgets/wear_surfaces.dart';
import 'checklists_controller.dart';
import 'item_card.dart';

/// The phone's status colours, so a low row is the same amber on both.
Color stockToneInk(BuildContext context, StockTone tone) => switch (tone) {
  StockTone.success => const Color(0xFF5FBF8A),
  StockTone.warning => const Color(0xFFE5A50A),
  StockTone.error => Theme.of(context).colorScheme.error,
  StockTone.muted => Colors.white38,
};

IconData stockToneIcon(StockTone tone) => switch (tone) {
  StockTone.success => Icons.check_circle_outline,
  StockTone.warning => Icons.error_outline,
  StockTone.error => Icons.info_outline,
  StockTone.muted => Icons.help_outline,
};

/// An inventory item on the watch's list.
///
/// Plain until tapped: the status icon, the name and the gauge as a hairline
/// under it, with the centred row earning a chip line. Tapped, it swaps in its
/// controls; the steps those make are shown at once but written only once the
/// row closes, so a run of taps is one write and a run that comes back to
/// where it started is none.
class InventoryCard extends StatelessWidget {
  final ListItem item;

  /// 0 on the centre line, 1 at the edge of the falloff.
  final double d;
  final ChecklistsController controller;

  /// Whether the row's controls are swapped in.
  final bool open;

  /// The undo window a closed row's change is waiting out, and what it says
  /// it changed.
  final AnimationController? pending;
  final String? pendingLabel;

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<String> onSetOnHand;
  final ValueChanged<StockLevel> onSetLevel;
  final VoidCallback onClose;

  const InventoryCard({
    super.key,
    required this.item,
    required this.d,
    required this.controller,
    required this.open,
    required this.pending,
    required this.pendingLabel,
    required this.onTap,
    required this.onSetOnHand,
    required this.onSetLevel,
    required this.onClose,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = WearMetrics.of(context);
    final radius = metrics.cardRadius;

    final card = DecoratedBox(
      decoration: WearSurface.card(
        context,
        fill: Color.lerp(
          scheme.surfaceContainerHighest,
          const Color(0xFF121215),
          d,
        ),
        radius: radius,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: WearShape.isRound ? 15 : 11,
          vertical: 4,
        ),
        child: open
            ? _Controls(
                item: item,
                onSetOnHand: onSetOnHand,
                onSetLevel: onSetLevel,
                onClose: onClose,
              )
            : _Summary(
                item: item,
                d: d,
                controller: controller,
                pendingLabel: pending == null ? null : pendingLabel,
              ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: SizedBox(
          height: metrics.cardHeight,
          child: UndoStroke(
            window: pending,
            color: scheme.primary,
            radius: radius,
            child: card,
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final ListItem item;
  final double d;
  final ChecklistsController controller;
  final String? pendingLabel;

  const _Summary({
    required this.item,
    required this.d,
    required this.controller,
    required this.pendingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = stockToneOf(item);
    final ink = stockToneInk(context, tone);
    final description = stockStatusDescription(item);
    // As on a checklist card: only the centre row has the room for a second
    // line, so it grows out of slack every other row already has.
    final expansion = (1 - (d / 0.4)).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(expansion);
    final label = pendingLabel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Semantics(
              label: description,
              excludeSemantics: true,
              child: Icon(stockToneIcon(tone), size: 16, color: ink),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: detectTextDirection(item.name),
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.1,
                      fontWeight: d < 0.5 ? FontWeight.w600 : FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  _Hairline(item: item, color: ink),
                ],
              ),
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                textDirection: detectTextDirection(label),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ],
          ],
        ),
        if (expansion > 0)
          Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: eased,
            child: Transform.scale(
              scale: eased,
              alignment: AlignmentDirectional.topStart.resolve(
                Directionality.of(context),
              ),
              child: Opacity(
                opacity: eased,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(top: 3),
                  child: ItemMetaLine(
                    item: item,
                    controller: controller,
                    entitiesOnly: true,
                    leading: _stockChips(context),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _stockChips(BuildContext context) {
    final level = item.stockMode == StockMode.level;
    final urgent = mostUrgentStockChip(item);
    final tone = urgent?.tone;
    return [
      EntityChip(
        density: ChipDensity.dense,
        textColor: Colors.white,
        background: Colors.white.withValues(alpha: 0.1),
        label: level
            ? stockLevelName(item.stockLevel ?? StockLevel.full)
            : stockAmountLabel(item),
      ),
      if (urgent != null)
        EntityChip(
          density: ChipDensity.dense,
          textColor: tone == null
              ? const Color(0xFFB6B6BE)
              : stockToneInk(context, tone),
          label: urgent.label,
        ),
    ];
  }
}

/// The gauge, drawn as a hairline under the name: filled to on hand ÷ target
/// with a tick at the reorder point, or three segments for a level. Nothing
/// for an item that is not counted, which keeps the name where it is.
class _Hairline extends StatelessWidget {
  final ListItem item;
  final Color color;

  const _Hairline({required this.item, required this.color});

  static const _height = 2.0;
  static const _duration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final fields = item.stockFields;
    final fill = gaugeFill(fields, item.stockStatus ?? StockStatus.ok);
    if (fill == null) return const SizedBox(height: _height + 2);
    const track = Color(0x1FFFFFFF);
    final Widget bar;
    if (fields.isLevel) {
      final filled = switch (item.stockLevel) {
        StockLevel.out => 0,
        StockLevel.low => 1,
        _ => 3,
      };
      bar = Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Expanded(
              child: AnimatedContainer(
                duration: _duration,
                color: i < filled ? color : track,
              ),
            ),
          ],
        ],
      );
    } else {
      final tick = gaugeTick(fields);
      bar = LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: track)),
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: _duration,
                  width: width * fill,
                  color: color,
                ),
              ),
              if (tick != null)
                PositionedDirectional(
                  start: (width * tick - 0.5).clamp(0.0, width - 1),
                  top: 0,
                  bottom: 0,
                  child: const SizedBox(
                    width: 1,
                    child: ColoredBox(color: Colors.white70),
                  ),
                ),
            ],
          );
        },
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 2),
      child: SizedBox(height: _height, child: bar),
    );
  }
}

/// What an open row shows instead: the name over the controls, with the ✕
/// that closes it on the leading edge.
///
/// Scaled down rather than clipped when a small screen's card is shorter than
/// the two lines, so no control is ever cut in half.
class _Controls extends StatelessWidget {
  final ListItem item;
  final ValueChanged<String> onSetOnHand;
  final ValueChanged<StockLevel> onSetLevel;
  final VoidCallback onClose;

  const _Controls({
    required this.item,
    required this.onSetOnHand,
    required this.onSetLevel,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final level = item.stockMode == StockMode.level;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        width: 180,
        child: Row(
          children: [
            _RoundButton(
              icon: Icons.close,
              label: m.wear.stockClose,
              onTap: onClose,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    textDirection: detectTextDirection(item.name),
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.1,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 2),
                  level
                      ? _LevelPicker(item: item, onSetLevel: onSetLevel)
                      : _Stepper(item: item, onSetOnHand: onSetOnHand),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// − {on hand} +. The phone's rules: − is off at 0, both are off when on hand
/// has no number, and holding one empties or fills it.
class _Stepper extends StatelessWidget {
  final ListItem item;
  final ValueChanged<String> onSetOnHand;

  const _Stepper({required this.item, required this.onSetOnHand});

  @override
  Widget build(BuildContext context) {
    final onHand = effectiveOnHand(item);
    final value = firstNumber(onHand);
    final target = firstNumber(item.target);
    final counted = value != null;
    final canDown = counted && value > 0;
    final canFill = counted && target != null && value != target;
    return Row(
      children: [
        _RoundButton(
          icon: Icons.remove,
          label: m.stock.decrease,
          onTap: canDown ? () => onSetOnHand(stepQuantity(onHand, -1)) : null,
          onLongPress: canDown
              ? () => onSetOnHand(withNumber(onHand, 0))
              : null,
        ),
        Expanded(
          child: Text(
            onHand,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            textDirection: detectTextDirection(onHand),
            style: const TextStyle(
              fontSize: 15,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        _RoundButton(
          icon: Icons.add,
          label: m.stock.increase,
          onTap: counted ? () => onSetOnHand(stepQuantity(onHand, 1)) : null,
          onLongPress: canFill
              ? () => onSetOnHand(withNumber(onHand, target))
              : null,
        ),
      ],
    );
  }
}

/// Full / Low / Out, the current one filled in its status colour.
class _LevelPicker extends StatelessWidget {
  final ListItem item;
  final ValueChanged<StockLevel> onSetLevel;

  const _LevelPicker({required this.item, required this.onSetLevel});

  @override
  Widget build(BuildContext context) {
    final current = item.stockLevel ?? StockLevel.full;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final level in StockLevel.values) ...[
          if (level != StockLevel.full) const SizedBox(width: 4),
          Expanded(
            child: _LevelButton(
              label: stockLevelName(level),
              selected: level == current,
              fill: switch (level) {
                StockLevel.full => scheme.primary,
                StockLevel.low => stockToneInk(context, StockTone.warning),
                StockLevel.out => stockToneInk(context, StockTone.error),
              },
              onTap: () => onSetLevel(level),
            ),
          ),
        ],
      ],
    );
  }
}

class _LevelButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color fill;
  final VoidCallback onTap;

  const _LevelButton({
    required this.label,
    required this.selected,
    required this.fill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? fill : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? (fill.computeLuminance() > 0.4
                      ? Colors.black87
                      : Colors.white)
                : Colors.white70,
          ),
        ),
      ),
    ),
  );
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        // Opaque even when disabled, so a tap on a greyed − does not fall
        // through to the row and land as something else.
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: enabled ? 0.14 : 0.05),
          ),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? Colors.white : Colors.white24,
          ),
        ),
      ),
    );
  }
}
