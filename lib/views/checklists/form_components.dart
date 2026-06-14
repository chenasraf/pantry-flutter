import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/utils/rrule.dart';

/// Mutable state for the inline recurrence panel. Edited in place by
/// [RecurrenceInline] via [onChanged] callbacks; consumers read it back at save
/// time and call [toRrule] to serialize.
class RecurrenceState {
  String freq;
  int interval;
  Set<String> byDay;
  bool repeatFromCompletion;

  RecurrenceState({
    this.freq = 'WEEKLY',
    this.interval = 1,
    Set<String>? byDay,
    this.repeatFromCompletion = false,
  }) : byDay = byDay ?? <String>{};

  factory RecurrenceState.fromRrule(
    String? rrule, {
    bool repeatFromCompletion = false,
  }) {
    if (rrule == null || rrule.isEmpty) {
      return RecurrenceState(repeatFromCompletion: repeatFromCompletion);
    }
    final map = parseRrule(rrule);
    final freq = (map['FREQ'] ?? 'WEEKLY').toUpperCase();
    final interval = int.tryParse(map['INTERVAL'] ?? '1') ?? 1;
    final byDay = <String>{};
    final byDayStr = map['BYDAY'];
    if (byDayStr != null && byDayStr.isNotEmpty) {
      byDay.addAll(byDayStr.split(','));
    }
    return RecurrenceState(
      freq: freq,
      interval: interval,
      byDay: byDay,
      repeatFromCompletion: repeatFromCompletion,
    );
  }

  String toRrule() => buildRrule(
    freq: freq,
    interval: interval,
    byDay: freq == 'WEEKLY' && byDay.isNotEmpty ? byDay.toList() : null,
  );
}

/// Small square button used in the quantity stepper and the recurrence
/// "every n" stepper. Accent variant tints background + icon with the primary
/// color; the neutral variant uses the surface container.
class FormStepperButton extends StatelessWidget {
  final IconData icon;
  final bool accent;
  final VoidCallback onTap;

  const FormStepperButton({
    super.key,
    required this.icon,
    this.accent = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: accent
              ? cs.primary.withValues(alpha: 0.14)
              : cs.surfaceContainer,
          border: Border.all(
            color: accent
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          color: accent ? cs.primary : cs.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }
}

/// Selectable row used by the item-type picker (Staple / One-time / Recurring)
/// in both the compose bar and the edit form. Filled accent background +
/// solid-dot radio when selected; neutral surface card otherwise.
class LifecycleRow extends StatelessWidget {
  final String label;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  const LifecycleRow({
    super.key,
    required this.label,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.1)
              : cs.surfaceContainer,
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? cs.primary : cs.outlineVariant,
                  width: selected ? 5 : 2,
                ),
                color: selected ? cs.surface : Colors.transparent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Color-coded chip used in the inline category picker. Selected swatches get
/// a tinted background + accent-color border at 1.5px to match the chosen
/// row in the lifecycle picker.
class CategorySwatch extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const CategorySwatch({
    super.key,
    this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : cs.surfaceContainer,
          border: Border.all(
            color: selected ? color : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "＋ New" action chip in the category picker. Visually distinct from
/// [CategorySwatch] — accent-tinted "+" icon + accent border, no color dot.
class NewCategoryChipButton extends StatelessWidget {
  final Color color;
  final String label;
  final VoidCallback onTap;

  const NewCategoryChipButton({
    super.key,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline schedule panel shown when the user picks "Recurring". Mutates the
/// given [state] directly; consumers call [onChanged] in their setState so the
/// surrounding widget rebuilds. Same UX in the compose bar tray and the edit
/// form so the schedule logic lives in one place.
class RecurrenceInline extends StatelessWidget {
  final RecurrenceState state;
  final VoidCallback onChanged;

  const RecurrenceInline({
    super.key,
    required this.state,
    required this.onChanged,
  });

  static const _weekdays = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];

  @override
  Widget build(BuildContext context) {
    final r = m.recurrence;
    final cs = Theme.of(context).colorScheme;
    final dayAbbr = {
      'MO': r.dayAbbr.mo,
      'TU': r.dayAbbr.tu,
      'WE': r.dayAbbr.we,
      'TH': r.dayAbbr.th,
      'FR': r.dayAbbr.fr,
      'SA': r.dayAbbr.sa,
      'SU': r.dayAbbr.su,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                r.everyLabel,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 10),
              FormStepperButton(
                icon: Icons.remove,
                onTap: () {
                  if (state.interval > 1) {
                    state.interval--;
                    onChanged();
                  }
                },
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${state.interval}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FormStepperButton(
                icon: Icons.add,
                accent: true,
                onTap: () {
                  state.interval++;
                  onChanged();
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  value: state.freq,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: 'DAILY', child: Text(r.unitDays)),
                    DropdownMenuItem(value: 'WEEKLY', child: Text(r.unitWeeks)),
                    DropdownMenuItem(
                      value: 'MONTHLY',
                      child: Text(r.unitMonths),
                    ),
                    DropdownMenuItem(value: 'YEARLY', child: Text(r.unitYears)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    state.freq = v;
                    if (v != 'WEEKLY') state.byDay.clear();
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          if (state.freq == 'WEEKLY') ...[
            const SizedBox(height: 10),
            Text(
              r.repeatOn,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in _weekdays)
                  FilterChip(
                    label: Text(dayAbbr[d] ?? d),
                    selected: state.byDay.contains(d),
                    onSelected: (sel) {
                      if (sel) {
                        state.byDay.add(d);
                      } else {
                        state.byDay.remove(d);
                      }
                      onChanged();
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: state.repeatFromCompletion,
            onChanged: (v) {
              state.repeatFromCompletion = v;
              onChanged();
            },
            title: Text(
              r.countFromCompletion,
              style: TextStyle(fontSize: 13, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
