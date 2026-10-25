import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/stock.dart';
import 'package:pantry_core/utils/date_format.dart';
import 'package:pantry_core/utils/quantity.dart';
import 'package:pantry_core/utils/stock_rules.dart';
import 'package:pantry_core/widgets/entity_chip.dart';
import 'package:pantry/theme/app_theme.dart';

/// What an inventory row can change on its own, without opening the item.
/// A null callback disables that control.
class InventoryRowActions {
  const InventoryRowActions({this.onSetOnHand, this.onSetLevel});

  final ValueChanged<String>? onSetOnHand;
  final ValueChanged<StockLevel>? onSetLevel;
}

enum StockTone { success, warning, error, muted }

StockTone stockToneOf(ListItem item) {
  final stock = item.stockStatus ?? StockStatus.ok;
  final expiry = item.expiryStatus ?? ExpiryStatus.none;
  if (stock == StockStatus.out || expiry == ExpiryStatus.expired) {
    return StockTone.error;
  }
  if (stock == StockStatus.low || expiry == ExpiryStatus.expiring) {
    return StockTone.warning;
  }
  return stock == StockStatus.uncounted ? StockTone.muted : StockTone.success;
}

Color stockToneColor(BuildContext context, StockTone tone) {
  final surfaces = AppSurfaces.of(context);
  final cs = Theme.of(context).colorScheme;
  return switch (tone) {
    StockTone.success => surfaces.success,
    StockTone.warning => surfaces.warning,
    StockTone.error => cs.error,
    StockTone.muted => cs.onSurfaceVariant,
  };
}

String stockLevelName(StockLevel level) => switch (level) {
  StockLevel.full => m.stock.full,
  StockLevel.low => m.stock.low,
  StockLevel.out => m.stock.out,
};

/// On hand as the stepper reads it: a blank on hand is 0, in the target's
/// wording when the target has a number.
String effectiveOnHand(ListItem item) {
  final onHand = (item.quantity ?? '').trim();
  if (onHand.isNotEmpty) return onHand;
  final target = (item.target ?? '').trim();
  return firstNumber(target) != null ? withNumber(target, 0) : '0';
}

/// The on-hand text with its first number swapped for [value], for a typed or
/// held amount.
String onHandWith(ListItem item, num value) =>
    withNumber(effectiveOnHand(item), value);

typedef StockChipSpec = ({String label, StockTone? tone});

/// The status chips of an inventory row, most urgent first. A null tone is a
/// neutral chip.
List<StockChipSpec> stockStatusChips(ListItem item, {int? today}) {
  final stock = item.stockStatus ?? StockStatus.ok;
  final expiry = item.expiryStatus ?? ExpiryStatus.none;
  final fields = item.stockFields;
  final out = <StockChipSpec>[];
  if (stock.isShort) {
    final low = stock == StockStatus.low;
    final shortfall = item.shortfall;
    // While expiry asks for the shopping row, it names the amount.
    final label = expiry.isDue || shortfall == null
        ? (low ? m.stock.low : m.stock.out)
        : (low ? m.stock.lowBuy(shortfall) : m.stock.outBuy(shortfall));
    out.add((label: label, tone: low ? StockTone.warning : StockTone.error));
  }
  final expiresAt = item.expiresAt;
  if (expiresAt != null && expiry != ExpiryStatus.none) {
    final amount = fullAmount(fields);
    final date = formatShortDate(expiresAt);
    switch (expiry) {
      case ExpiryStatus.expired:
        out.add((
          label: amount == null
              ? m.stock.expiredOn(date)
              : m.stock.expiredOnBuy(date, amount),
          tone: StockTone.error,
        ));
      case ExpiryStatus.expiring:
        final days = daysUntil(expiresAt, today ?? todayEpoch());
        final label = switch (days) {
          <= 0 =>
            amount == null
                ? m.stock.expiresToday
                : m.stock.expiresTodayBuy(amount),
          1 =>
            amount == null
                ? m.stock.expiresTomorrow
                : m.stock.expiresTomorrowBuy(amount),
          _ =>
            amount == null
                ? m.stock.expiresInDays(days)
                : m.stock.expiresInDaysBuy(days, amount),
        };
        out.add((label: label, tone: StockTone.warning));
      case ExpiryStatus.ok:
        out.add((label: m.stock.goodUntil(date), tone: null));
      case ExpiryStatus.none:
        break;
    }
  }
  if (stock == StockStatus.uncounted) {
    out.add((label: m.stock.notCounted, tone: null));
  }
  return out;
}

/// The row's status spelled out, for the status icon's tooltip and screen
/// readers.
String stockStatusDescription(ListItem item) {
  final chips = stockStatusChips(item);
  return chips.isEmpty ? m.stock.inStock : chips.map((c) => c.label).join(', ');
}

/// "4 / 12 eggs": on hand's number over the target's text.
String stockAmountLabel(ListItem item) {
  final onHand = effectiveOnHand(item);
  final number = firstNumber(onHand);
  final target = (item.target ?? '').trim();
  final shown = number != null ? formatNumber(number) : onHand;
  return target.isEmpty ? shown : m.stock.amount(shown, target);
}

class StockStatusChip extends StatelessWidget {
  const StockStatusChip({super.key, required this.spec});

  final StockChipSpec spec;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tone = spec.tone;
    if (tone == null) {
      return EntityChip(
        label: spec.label,
        textColor: cs.onSurfaceVariant,
        background: cs.onSurface.withValues(alpha: 0.06),
      );
    }
    final color = stockToneColor(context, tone);
    return EntityChip(label: spec.label, textColor: color);
  }
}

/// The round status mark where a checklist row has its checkbox.
class StockStatusIcon extends StatelessWidget {
  const StockStatusIcon({
    super.key,
    required this.item,
    required this.padding,
    required this.hitHeight,
  });

  final ListItem item;
  final EdgeInsetsGeometry padding;
  final double hitHeight;

  @override
  Widget build(BuildContext context) {
    final tone = stockToneOf(item);
    final icon = switch (tone) {
      StockTone.success => Icons.check_circle_outline,
      StockTone.warning => Icons.error_outline,
      StockTone.error => Icons.info_outline,
      StockTone.muted => Icons.help_outline,
    };
    final description = stockStatusDescription(item);
    return Padding(
      padding: padding,
      child: SizedBox(
        height: hitHeight,
        child: Center(
          widthFactor: 1,
          child: Tooltip(
            message: description,
            child: Semantics(
              label: description,
              excludeSemantics: true,
              child: Icon(icon, size: 24, color: stockToneColor(context, tone)),
            ),
          ),
        ),
      ),
    );
  }
}

/// A thin bar under the chips: filled to on hand ÷ target with a tick at the
/// reorder point, or three segments for a level.
class StockGauge extends StatelessWidget {
  const StockGauge({super.key, required this.item});

  final ListItem item;

  static bool showsFor(ListItem item) =>
      item.stockStatus != StockStatus.uncounted;

  @override
  Widget build(BuildContext context) {
    final fields = item.stockFields;
    final status = item.stockStatus ?? StockStatus.ok;
    final fill = gaugeFill(fields, status);
    if (fill == null) return const SizedBox.shrink();
    final color = stockToneColor(context, stockToneOf(item));
    final track = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.08);
    const height = 4.0;
    if (fields.isLevel) {
      final filled = switch (item.stockLevel) {
        StockLevel.out => 0,
        StockLevel.low => 1,
        _ => 3,
      };
      return SizedBox(
        height: height,
        child: Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i < filled ? color : track,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
    final tick = gaugeTick(fields);
    return SizedBox(
      height: height + 4,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isRtl = Directionality.of(context) == TextDirection.rtl;
          return Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: track,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              Container(
                width: width * fill,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              if (tick != null)
                Positioned(
                  left: isRtl ? null : (width * tick - 1).clamp(0, width - 2),
                  right: isRtl ? (width * tick - 1).clamp(0, width - 2) : null,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The trailing control of an inventory row: a stepper for a count item, a
/// level picker for a level item.
class InventoryRowControl extends StatelessWidget {
  const InventoryRowControl({
    super.key,
    required this.item,
    required this.narrow,
    required this.actions,
  });

  final ListItem item;
  final bool narrow;
  final InventoryRowActions actions;

  @override
  Widget build(BuildContext context) {
    if (item.stockMode == StockMode.level) {
      return narrow
          ? _LevelMenuButton(item: item, onSetLevel: actions.onSetLevel)
          : _LevelSegments(item: item, onSetLevel: actions.onSetLevel);
    }
    return OnHandStepper(
      item: item,
      showAmount: !narrow,
      onSetOnHand: actions.onSetOnHand,
    );
  }
}

/// − {on hand} +. Holding − empties it, holding + fills it to the target, and
/// holding the amount opens a number field for it.
class OnHandStepper extends StatelessWidget {
  const OnHandStepper({
    super.key,
    required this.item,
    required this.showAmount,
    required this.onSetOnHand,
  });

  final ListItem item;
  final bool showAmount;
  final ValueChanged<String>? onSetOnHand;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onHand = effectiveOnHand(item);
    final value = firstNumber(onHand);
    final target = firstNumber(item.target);
    final set = onSetOnHand;
    final counted = set != null && value != null;
    final canDown = counted && value > 0;
    final canFill = counted && target != null && value != target;

    final minus = _StepButton(
      icon: Icons.remove,
      tooltip: m.stock.decrease,
      onTap: canDown ? () => set(stepQuantity(onHand, -1)) : null,
      onLongPress: canDown ? () => set(withNumber(onHand, 0)) : null,
    );
    final plus = _StepButton(
      icon: Icons.add,
      tooltip: m.stock.increase,
      onTap: counted ? () => set(stepQuantity(onHand, 1)) : null,
      onLongPress: canFill ? () => set(withNumber(onHand, target)) : null,
    );
    if (!showAmount) {
      return Row(mainAxisSize: MainAxisSize.min, children: [minus, plus]);
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(SurfaceRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          minus,
          OnHandAmount(
            item: item,
            onSetOnHand: counted ? set : null,
            builder: (context) => ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 24, maxWidth: 120),
              child: Text(
                onHand,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          plus,
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.onLongPress,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          onLongPress: onLongPress,
          radius: 20,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              size: 20,
              color: enabled
                  ? cs.onSurface
                  : cs.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps whatever shows on hand so holding it swaps in a number field. The
/// typed number replaces on hand's number and keeps its words.
class OnHandAmount extends StatefulWidget {
  const OnHandAmount({
    super.key,
    required this.item,
    required this.onSetOnHand,
    required this.builder,
  });

  final ListItem item;
  final ValueChanged<String>? onSetOnHand;
  final WidgetBuilder builder;

  @override
  State<OnHandAmount> createState() => _OnHandAmountState();
}

class _OnHandAmountState extends State<OnHandAmount> {
  bool _editing = false;
  late final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _commit();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _start() {
    final number = firstNumber(effectiveOnHand(widget.item));
    _text.text = number == null ? '' : formatNumber(number);
    _text.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _text.text.length,
    );
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _commit() {
    final value = firstNumber(_text.text);
    setState(() => _editing = false);
    if (value != null) widget.onSetOnHand?.call(onHandWith(widget.item, value));
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return SizedBox(
        width: 64,
        child: Semantics(
          label: m.stock.onHandEdit,
          child: TextField(
            controller: _text,
            focusNode: _focus,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 6),
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _commit(),
            onTapOutside: (_) => _focus.unfocus(),
          ),
        ),
      );
    }
    return Semantics(
      label: m.stock.onHandEdit,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: widget.onSetOnHand == null ? null : _start,
        child: widget.builder(context),
      ),
    );
  }
}

/// The narrow row's amount chip, "4 / 12 eggs", which a hold edits.
class StockAmountChip extends StatelessWidget {
  const StockAmountChip({super.key, required this.item, this.onSetOnHand});

  final ListItem item;
  final ValueChanged<String>? onSetOnHand;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final counted = firstNumber(effectiveOnHand(item)) != null;
    return OnHandAmount(
      item: item,
      onSetOnHand: counted ? onSetOnHand : null,
      builder: (context) => EntityChip(
        label: stockAmountLabel(item),
        textColor: cs.onSurface,
        background: cs.onSurface.withValues(alpha: 0.08),
      ),
    );
  }
}

/// Full / Low / Out on a wide row: Low amber with dark text, Out red with
/// white text, Full the primary colour.
class _LevelSegments extends StatelessWidget {
  const _LevelSegments({required this.item, required this.onSetLevel});

  final ListItem item;
  final ValueChanged<StockLevel>? onSetLevel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surfaces = AppSurfaces.of(context);
    final current = item.stockLevel ?? StockLevel.full;
    final (fill, onFill) = switch (current) {
      StockLevel.full => (cs.primary, cs.onPrimary),
      StockLevel.low => (surfaces.warning, Colors.black87),
      StockLevel.out => (cs.error, Colors.white),
    };
    return SegmentedButton<StockLevel>(
      segments: [
        for (final level in StockLevel.values)
          ButtonSegment(value: level, label: Text(stockLevelName(level))),
      ],
      selected: {current},
      showSelectedIcon: false,
      onSelectionChanged: onSetLevel == null
          ? null
          : (selection) => onSetLevel!(selection.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? fill : null,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? onFill : null,
        ),
      ),
    );
  }
}

/// The narrow row's level control: one button naming the level, opening a
/// Full / Low / Out menu.
class _LevelMenuButton extends StatelessWidget {
  const _LevelMenuButton({required this.item, required this.onSetLevel});

  final ListItem item;
  final ValueChanged<StockLevel>? onSetLevel;

  @override
  Widget build(BuildContext context) {
    final current = item.stockLevel ?? StockLevel.full;
    final color = stockToneColor(context, stockToneOf(item));
    final name = stockLevelName(current);
    return MenuAnchor(
      menuChildren: [
        for (final level in StockLevel.values)
          MenuItemButton(
            leadingIcon: Icon(level == current ? Icons.check : null, size: 18),
            onPressed: () => onSetLevel?.call(level),
            child: Text(stockLevelName(level)),
          ),
      ],
      builder: (context, menu, _) => Semantics(
        label: m.stock.levelButton(name),
        excludeSemantics: true,
        button: true,
        child: TextButton(
          onPressed: onSetLevel == null
              ? null
              : () => menu.isOpen ? menu.close() : menu.open(),
          style: TextButton.styleFrom(
            foregroundColor: color,
            visualDensity: VisualDensity.compact,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text(name), const Icon(Icons.arrow_drop_down, size: 18)],
          ),
        ),
      ),
    );
  }
}
