import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/models/checklist.dart';
import 'package:pantry_core/models/item_start_values.dart';
import 'package:pantry_core/models/stock.dart';
import 'package:pantry_core/utils/date_format.dart';
import 'package:pantry_core/utils/quantity.dart';
import 'package:pantry_core/utils/stock_rules.dart';
import 'package:pantry_core/utils/text_direction.dart';
import 'package:pantry/theme/app_theme.dart';

import 'form_components.dart';
import 'inventory_row_parts.dart';

enum ExpiryMode { none, date, keeps }

/// The stock and expiry an item form is editing. On an inventory item
/// [quantity] is on hand (count) or the restock amount (level); a template
/// item keeps its quantity apart and leaves [mode] null to use the
/// inventory's default.
class StockDraft {
  StockDraft._({
    required this.template,
    required this.mode,
    required this.level,
    required this.quantity,
    required this.target,
    required this.reorderPoint,
    required this.expiryMode,
    required this.expiresAt,
    required this.shelfLifeDays,
  });

  factory StockDraft.forItem(ListItem? item, {required bool template}) {
    final shelfLife = item?.shelfLifeDays;
    final expiresAt = template ? null : item?.expiresAt;
    return StockDraft._(
      template: template,
      mode: item?.stockMode ?? (template ? null : StockMode.count),
      level: item?.stockLevel ?? StockLevel.full,
      quantity: template ? null : item?.quantity,
      target: item?.target,
      reorderPoint: item?.reorderPoint,
      expiryMode: shelfLife != null
          ? ExpiryMode.keeps
          : expiresAt != null
          ? ExpiryMode.date
          : ExpiryMode.none,
      expiresAt: expiresAt,
      shelfLifeDays: shelfLife,
    );
  }

  /// Start a new inventory item on a list's item defaults.
  void applyStart(ItemStartValues start) {
    if (template) return;
    mode = start.stockMode ?? StockMode.count;
    target = start.target;
    reorderPoint = start.reorderPoint;
    final shelfLife = start.shelfLifeDays;
    shelfLifeDays = shelfLife;
    expiresAt = null;
    expiryMode = shelfLife != null ? ExpiryMode.keeps : ExpiryMode.none;
  }

  final bool template;
  StockMode? mode;
  StockLevel level;
  String? quantity;
  String? target;
  String? reorderPoint;

  /// What the last mode switch rewrote, until the form is saved.
  String? conversionNote;

  ExpiryMode expiryMode;
  int? expiresAt;
  int? shelfLifeDays;

  bool get isLevel => mode == StockMode.level;

  StockFields get fields => StockFields(
    stockMode: mode,
    stockLevel: isLevel ? level : null,
    quantity: quantity,
    target: target,
    reorderPoint: reorderPoint,
    expiresAt: effectiveExpiresAt,
    shelfLifeDays: effectiveShelfLife,
  );

  int? get effectiveShelfLife =>
      expiryMode == ExpiryMode.none ? null : shelfLifeDays;

  /// The date this draft will be good until: none, the picked date, or today
  /// plus the days it keeps.
  int? get effectiveExpiresAt => switch (expiryMode) {
    ExpiryMode.none => null,
    ExpiryMode.date => expiresAt,
    ExpiryMode.keeps =>
      shelfLifeDays == null || template
          ? null
          : addDays(todayEpoch(), shelfLifeDays!),
  };

  void switchMode(StockMode to) {
    if (to == mode) return;
    if (template || mode == null) {
      mode = to;
      return;
    }
    final converted = convertStock(fields, to);
    mode = converted.stockMode;
    level = converted.stockLevel ?? StockLevel.full;
    quantity = converted.quantity;
    target = converted.target;
    if (to == StockMode.level) {
      final name = stockLevelName(level);
      final amount = converted.quantity;
      conversionNote = amount == null
          ? m.stock.card.convertedLevel(name)
          : m.stock.card.convertedLevelAmount(name, amount);
    } else {
      final onHand = converted.quantity;
      final t = converted.target;
      conversionNote = t == null
          ? m.stock.card.convertedBlank
          : onHand == null
          ? m.stock.card.convertedTargetOnly(t)
          : m.stock.card.convertedCount(onHand, t);
    }
  }

  /// A date picked by hand. One after today also sets the shelf life to
  /// match, as the server does.
  void pickDate(int date) {
    expiresAt = date;
    final days = daysUntil(date, todayEpoch());
    if (days > 0) shelfLifeDays = days;
  }

  /// The expiry fields an edit of [item] sends: only what changed, with 0
  /// clearing.
  ({int? expiresAt, int? shelfLifeDays}) expiryPatch(ListItem? item) {
    final hadDate = !template && item?.expiresAt != null;
    final hadShelfLife = item?.shelfLifeDays != null;
    switch (expiryMode) {
      case ExpiryMode.none:
        return (
          expiresAt: hadDate ? 0 : null,
          shelfLifeDays: hadShelfLife ? 0 : null,
        );
      case ExpiryMode.date:
        final date = expiresAt;
        if (date == null) return (expiresAt: null, shelfLifeDays: null);
        return (
          expiresAt: date != item?.expiresAt ? date : null,
          shelfLifeDays: null,
        );
      case ExpiryMode.keeps:
        final days = shelfLifeDays;
        if (days == null || days <= 0) {
          return (expiresAt: null, shelfLifeDays: null);
        }
        return (
          expiresAt: null,
          shelfLifeDays: days != item?.shelfLifeDays ? days : null,
        );
    }
  }
}

/// The Stock card of an inventory or template item.
class StockCard extends StatefulWidget {
  const StockCard({
    super.key,
    required this.draft,
    required this.leadDays,
    required this.onChanged,
    this.compose = false,
  });

  final StockDraft draft;
  final int leadDays;
  final VoidCallback onChanged;

  /// In the add box: an empty on hand starts full, a mode switch converts
  /// nothing, and there is no status line yet.
  final bool compose;

  @override
  State<StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<StockCard> {
  late final _onHand = TextEditingController(text: widget.draft.quantity);
  late final _target = TextEditingController(text: widget.draft.target);
  late final _reorder = TextEditingController(text: widget.draft.reorderPoint);

  StockDraft get _draft => widget.draft;

  @override
  void dispose() {
    _onHand.dispose();
    _target.dispose();
    _reorder.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    widget.onChanged();
  }

  void _setMode(StockMode mode) {
    if (widget.compose) {
      _draft.mode = mode;
      _changed();
      return;
    }
    _draft.switchMode(mode);
    _onHand.text = _draft.quantity ?? '';
    _target.text = _draft.target ?? '';
    _changed();
  }

  void _stepOnHand(int direction) {
    final current = _onHand.text.trim().isEmpty
        ? (firstNumber(_target.text) != null
              ? withNumber(_target.text.trim(), 0)
              : '0')
        : _onHand.text;
    final next = stepQuantity(current, direction);
    _onHand.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _draft.quantity = next;
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final c = m.stock.card;
    final draft = _draft;
    final hint = theme.textTheme.bodySmall?.copyWith(
      color: cs.onSurfaceVariant,
    );

    final modeControl = Tooltip(
      message: draft.isLevel ? c.levelHint : c.countHint,
      child: Semantics(
        label: c.mode,
        child: SegmentedButton<StockMode>(
          segments: [
            ButtonSegment(value: StockMode.count, label: Text(c.count)),
            ButtonSegment(value: StockMode.level, label: Text(c.level)),
          ],
          selected: {?draft.mode},
          emptySelectionAllowed: draft.mode == null,
          showSelectedIcon: false,
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onSelectionChanged: (s) {
            if (s.isNotEmpty) _setMode(s.first);
          },
        ),
      ),
    );

    final fields = <Widget>[];
    if (draft.template) {
      fields.addAll([
        _field(
          label: c.target,
          child: _text(_target, c.targetPlaceholder, (v) => draft.target = v),
        ),
        _field(
          label: c.reorderPoint,
          child: _number(
            _reorder,
            c.reorderPlaceholder,
            (v) => draft.reorderPoint = v,
          ),
        ),
      ]);
    } else if (draft.isLevel) {
      fields.addAll([
        _field(
          label: c.stockLevel,
          width: 240,
          child: SegmentedButton<StockLevel>(
            segments: [
              for (final level in StockLevel.values)
                ButtonSegment(value: level, label: Text(stockLevelName(level))),
            ],
            selected: {draft.level},
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            onSelectionChanged: (s) {
              draft.level = s.first;
              _changed();
            },
          ),
        ),
        _field(
          label: c.restockAmount,
          child: _text(
            _onHand,
            c.restockPlaceholder,
            (v) => draft.quantity = v,
          ),
        ),
      ]);
    } else {
      fields.addAll([
        _field(
          label: c.onHand,
          width: 180,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                tooltip: m.stock.decrease,
                visualDensity: VisualDensity.compact,
                onPressed: () => _stepOnHand(-1),
              ),
              Expanded(
                child: _text(
                  _onHand,
                  widget.compose
                      ? m.stock.compose.fullWhenEmpty
                      : c.onHandPlaceholder,
                  (v) => draft.quantity = v,
                  center: true,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: m.stock.increase,
                visualDensity: VisualDensity.compact,
                onPressed: () => _stepOnHand(1),
              ),
            ],
          ),
        ),
        _field(
          label: c.target,
          child: _text(_target, c.targetPlaceholder, (v) => draft.target = v),
        ),
        _field(
          label: c.reorderPoint,
          width: 120,
          child: _number(
            _reorder,
            c.reorderPlaceholder,
            (v) => draft.reorderPoint = v,
          ),
        ),
      ]);
    }

    final status = draft.template
        ? _templateSummary(draft)
        : widget.compose
        ? null
        : stockStatusLine(draft.fields, widget.leadDays);

    return LabeledFieldCard(
      label: c.title,
      trailing: modeControl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (draft.conversionNote != null) ...[
            const SizedBox(height: 4),
            Text(
              draft.conversionNote!,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.primary),
            ),
          ],
          if (draft.template && draft.mode == null) ...[
            const SizedBox(height: 4),
            Text(c.templateDefaultMode, style: hint),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 10, children: fields),
          if (status != null) ...[
            const SizedBox(height: 10),
            Text(
              status.text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: status.tone == null
                    ? cs.onSurfaceVariant
                    : stockToneColor(context, status.tone!),
                fontWeight: status.tone == null ? null : FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required Widget child,
    double width = 160,
  }) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  Widget _text(
    TextEditingController controller,
    String placeholder,
    void Function(String? value) onValue, {
    bool center = false,
  }) => TextField(
    controller: controller,
    textDirection: detectTextDirection(controller.text),
    textAlign: center ? TextAlign.center : TextAlign.start,
    decoration: InputDecoration(hintText: placeholder, isDense: true),
    onChanged: (v) {
      onValue(v.trim().isEmpty ? null : v.trim());
      _changed();
    },
  );

  Widget _number(
    TextEditingController controller,
    String placeholder,
    void Function(String? value) onValue,
  ) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(hintText: placeholder, isDense: true),
    onChanged: (v) {
      onValue(v.trim().isEmpty ? null : v.trim());
      _changed();
    },
  );
}

StockStatusLine? _templateSummary(StockDraft draft) {
  final c = m.stock.card;
  final target = (draft.target ?? '').trim();
  switch (draft.mode) {
    case null:
      return null;
    case StockMode.level:
      return (
        text: target.isEmpty
            ? c.templateStartsLevel
            : c.templateStartsLevelAmount(target),
        tone: null,
      );
    case StockMode.count:
      return (
        text: firstNumber(target) == null
            ? c.templateUncounted
            : c.templateStartsCount(target),
        tone: null,
      );
  }
}

/// The Expiry card: none, a date, or a number of days the item keeps. A
/// template item offers no date.
class ExpiryCard extends StatefulWidget {
  const ExpiryCard({super.key, required this.draft, required this.onChanged});

  final StockDraft draft;
  final VoidCallback onChanged;

  @override
  State<ExpiryCard> createState() => _ExpiryCardState();
}

class _ExpiryCardState extends State<ExpiryCard> {
  late final _days = TextEditingController(
    text: widget.draft.shelfLifeDays?.toString() ?? '',
  );

  StockDraft get _draft => widget.draft;

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() {});
    widget.onChanged();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = _draft.expiresAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null
          ? DateTime.fromMillisecondsSinceEpoch(current * 1000)
          : now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null || !mounted) return;
    _draft.pickDate(todayEpoch(picked));
    _days.text = _draft.shelfLifeDays?.toString() ?? '';
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final e = m.stock.expiry;
    final draft = _draft;
    final modes = [
      ExpiryMode.none,
      if (!draft.template) ExpiryMode.date,
      ExpiryMode.keeps,
    ];
    String modeLabel(ExpiryMode mode) => switch (mode) {
      ExpiryMode.none => e.none,
      ExpiryMode.date => e.date,
      ExpiryMode.keeps => e.keeps,
    };

    final control = Semantics(
      label: e.mode,
      child: SegmentedButton<ExpiryMode>(
        segments: [
          for (final mode in modes)
            ButtonSegment(value: mode, label: Text(modeLabel(mode))),
        ],
        selected: {draft.expiryMode},
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onSelectionChanged: (s) {
          draft.expiryMode = s.first;
          _changed();
        },
      ),
    );

    Widget? input;
    switch (draft.expiryMode) {
      case ExpiryMode.none:
        input = null;
      case ExpiryMode.date:
        final date = draft.expiresAt;
        input = InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(SurfaceRadius.chip),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.event_outlined, size: 20, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  date == null ? e.expiryDate : formatDate(date),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        );
      case ExpiryMode.keeps:
        input = SizedBox(
          width: 160,
          child: TextField(
            controller: _days,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            decoration: InputDecoration(
              labelText: e.daysItKeeps,
              isDense: true,
            ),
            onChanged: (v) {
              final days = int.tryParse(v);
              draft.shelfLifeDays = days != null && days > 0 ? days : null;
              _changed();
            },
          ),
        );
    }

    final summary = _summary(draft);
    return LabeledFieldCard(
      label: e.title,
      trailing: control,
      child: input == null && summary == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?input,
                if (summary != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    summary,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  String? _summary(StockDraft draft) {
    final e = m.stock.expiry;
    final shelfLife = draft.effectiveShelfLife;
    if (draft.template) {
      return shelfLife == null ? null : e.templateExpires(shelfLife);
    }
    final date = draft.effectiveExpiresAt;
    if (date == null) return null;
    final formatted = formatShortDate(date);
    final head = daysUntil(date, todayEpoch()) < 0
        ? e.expiredSummary(formatted)
        : e.goodUntilSummary(formatted);
    return shelfLife == null ? head : '$head ${e.renews(shelfLife)}';
  }
}
