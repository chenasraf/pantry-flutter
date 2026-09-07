import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/utils/rrule.dart';

/// What a monthly rule repeats on: days of the month, or a weekday pinned to a
/// position in the month.
enum RecurrenceMonthlyMode { days, weekday }

/// Parts of an RRULE the recurrence editors own. Every other part a rule
/// carries is kept in [_extra] and written back untouched, so a rule authored
/// somewhere richer survives a round trip through an editor that cannot show
/// all of it.
class RecurrenceState {
  String freq;
  int interval;

  /// Weekdays a rule repeats on, as plain codes — the position a monthly rule
  /// pins a weekday to lives in [ordinal] instead. Only a weekly rule offers
  /// these for editing; any other frequency carries them through so a rule
  /// pairing them with a part the editors do not show survives.
  Set<String> byDay;

  RecurrenceMonthlyMode monthlyMode;

  /// Days of the month a monthly rule repeats on. Empty means the same day
  /// each month, taken from the item's own date.
  Set<int> monthDays;

  int ordinal;
  String ordinalWeekday;

  /// Month and day a yearly rule repeats on, anchored on
  /// [kYearlessAnchorYear]. Null means the same date each year.
  DateTime? yearlyDate;

  int? count;
  DateTime? until;
  bool repeatFromCompletion;

  final Map<String, String> _extra;

  /// Parts the editors read, write and clear. Anything outside this set is
  /// carried through verbatim.
  static const _ownedParts = {
    'FREQ',
    'INTERVAL',
    'BYDAY',
    'BYMONTH',
    'BYMONTHDAY',
    'COUNT',
    'UNTIL',
  };

  RecurrenceState({
    this.freq = 'WEEKLY',
    this.interval = 1,
    Set<String>? byDay,
    this.monthlyMode = RecurrenceMonthlyMode.days,
    Set<int>? monthDays,
    this.ordinal = 1,
    this.ordinalWeekday = 'MO',
    this.yearlyDate,
    this.count,
    this.until,
    this.repeatFromCompletion = false,
    Map<String, String>? extra,
  }) : byDay = byDay ?? <String>{},
       monthDays = monthDays ?? <int>{},
       _extra = extra ?? <String, String>{};

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

    final entries =
        map['BYDAY']?.split(',').map(parseByDay).nonNulls.toList() ??
        const <RruleWeekday>[];
    final pinned = entries.where((e) => e.ordinal != null).firstOrNull;
    final monthDays =
        map['BYMONTHDAY']?.split(',').map(int.tryParse).nonNulls.toSet() ??
        <int>{};
    final month = int.tryParse(map['BYMONTH'] ?? '');

    final weekdayMonthly = freq == 'MONTHLY' && pinned != null;

    return RecurrenceState(
      freq: freq,
      interval: interval,
      byDay: entries
          .where((e) => e.ordinal == null)
          .map((e) => e.weekday)
          .toSet(),
      monthlyMode: weekdayMonthly
          ? RecurrenceMonthlyMode.weekday
          : RecurrenceMonthlyMode.days,
      monthDays: freq == 'MONTHLY' && !weekdayMonthly ? monthDays : <int>{},
      ordinal: pinned?.ordinal ?? 1,
      ordinalWeekday: pinned?.weekday ?? 'MO',
      yearlyDate: freq == 'YEARLY' && month != null && monthDays.isNotEmpty
          ? DateTime(kYearlessAnchorYear, month, monthDays.first)
          : null,
      count: int.tryParse(map['COUNT'] ?? ''),
      until: _parseUntil(map['UNTIL']),
      repeatFromCompletion: repeatFromCompletion,
      extra: {
        for (final entry in map.entries)
          if (!_ownedParts.contains(entry.key.toUpperCase()))
            entry.key: entry.value,
      },
    );
  }

  static DateTime? _parseUntil(String? until) {
    // Format: YYYYMMDDTHHmmssZ
    if (until == null || until.length < 8) return null;
    final year = int.tryParse(until.substring(0, 4));
    final month = int.tryParse(until.substring(4, 6));
    final day = int.tryParse(until.substring(6, 8));
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  /// Switch frequency, dropping what the previous one selected. Without this a
  /// stale BYMONTHDAY rides along into an ordinal-weekday rule.
  void setFreq(String value) {
    if (value == freq) return;
    freq = value;
    resetParts();
  }

  /// Switch which of the two monthly shapes is being edited, clearing the
  /// other one's selection.
  void setMonthlyMode(RecurrenceMonthlyMode mode) {
    if (mode == monthlyMode) return;
    monthlyMode = mode;
    if (mode == RecurrenceMonthlyMode.days) {
      ordinal = 1;
      ordinalWeekday = 'MO';
    } else {
      monthDays.clear();
    }
  }

  /// Clear every selection that belongs to a single frequency.
  void resetParts() {
    byDay.clear();
    monthDays.clear();
    yearlyDate = null;
    monthlyMode = RecurrenceMonthlyMode.days;
    ordinal = 1;
    ordinalWeekday = 'MO';
  }

  List<String>? get _byDayParts {
    final parts = [
      if (freq == 'MONTHLY' && monthlyMode == RecurrenceMonthlyMode.weekday)
        formatByDay((ordinal: ordinal, weekday: ordinalWeekday)),
      for (final day in kRruleWeekdays)
        if (byDay.contains(day)) day,
    ];
    return parts.isEmpty ? null : parts;
  }

  List<int>? get _byMonthDayParts {
    if (freq == 'MONTHLY' && monthlyMode == RecurrenceMonthlyMode.days) {
      return monthDays.isEmpty ? null : (monthDays.toList()..sort());
    }
    if (freq == 'YEARLY') {
      final date = yearlyDate;
      return date == null ? null : [date.day];
    }
    return null;
  }

  String toRrule() {
    final rule = buildRrule(
      freq: freq,
      interval: interval,
      byDay: _byDayParts,
      byMonth: freq == 'YEARLY' ? yearlyDate?.month : null,
      byMonthDay: _byMonthDayParts,
      count: count,
      until: until,
    );
    if (_extra.isEmpty) return rule;
    return [
      rule,
      for (final entry in _extra.entries) '${entry.key}=${entry.value}',
    ].join(';');
  }
}

/// Grid of 1–31 for the days of the month a monthly rule repeats on.
class MonthDayPicker extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  const MonthDayPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var day = 1; day <= 31; day++)
          _MonthDayChip(
            day: day,
            selected: selected.contains(day),
            colors: cs,
            onTap: () {
              final updated = Set<int>.from(selected);
              if (!updated.remove(day)) updated.add(day);
              onChanged(updated);
            },
          ),
      ],
    );
  }
}

class _MonthDayChip extends StatelessWidget {
  final int day;
  final bool selected;
  final ColorScheme colors;
  final VoidCallback onTap;

  const _MonthDayChip({
    required this.day,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Position-and-weekday pair for "the second Monday of the month".
class OrdinalWeekdayPicker extends StatelessWidget {
  final int ordinal;
  final String weekday;
  final ValueChanged<int> onOrdinalChanged;
  final ValueChanged<String> onWeekdayChanged;
  final bool bordered;

  const OrdinalWeekdayPicker({
    super.key,
    required this.ordinal,
    required this.weekday,
    required this.onOrdinalChanged,
    required this.onWeekdayChanged,
    this.bordered = true,
  });

  @override
  Widget build(BuildContext context) {
    final r = m.recurrence;
    final ordinalLabels = {
      1: r.ordinal.first,
      2: r.ordinal.second,
      3: r.ordinal.third,
      4: r.ordinal.fourth,
      -1: r.ordinal.last,
    };
    final dayLabels = {
      'MO': r.dayNames.monday,
      'TU': r.dayNames.tuesday,
      'WE': r.dayNames.wednesday,
      'TH': r.dayNames.thursday,
      'FR': r.dayNames.friday,
      'SA': r.dayNames.saturday,
      'SU': r.dayNames.sunday,
    };

    return Row(
      children: [
        Expanded(
          child: _dropdown<int>(
            value: kRruleOrdinals.contains(ordinal) ? ordinal : 1,
            items: [
              for (final value in kRruleOrdinals)
                DropdownMenuItem(
                  value: value,
                  child: Text(
                    ordinalLabels[value]!,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: onOrdinalChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _dropdown<String>(
            value: kRruleWeekdays.contains(weekday) ? weekday : 'MO',
            items: [
              for (final day in kRruleWeekdays)
                DropdownMenuItem(
                  value: day,
                  child: Text(dayLabels[day]!, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: onWeekdayChanged,
          ),
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T> onChanged,
  }) {
    void handle(T? selected) {
      if (selected != null) onChanged(selected);
    }

    if (!bordered) {
      return DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: items,
        onChanged: handle,
      );
    }
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: items,
      onChanged: handle,
    );
  }
}

/// Month and day a yearly rule repeats on. The rule keeps no year, so the
/// picker is anchored on [kYearlessAnchorYear] — a leap year, which is what
/// keeps 29 February selectable — and the label leaves the year off.
class YearlyDateField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const YearlyDateField({super.key, this.value, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(kYearlessAnchorYear, now.month, now.day),
      firstDate: DateTime(kYearlessAnchorYear, 1, 1),
      lastDate: DateTime(kYearlessAnchorYear, 12, 31),
      helpText: m.recurrence.yearlyDate,
    );
    if (picked != null) {
      onChanged(DateTime(kYearlessAnchorYear, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = value;
    return Row(
      children: [
        Flexible(
          child: OutlinedButton.icon(
            onPressed: () => _pick(context),
            icon: const Icon(Icons.event, size: 18),
            label: Text(
              date == null
                  ? m.recurrence.pickDate
                  : DateFormat.MMMMd().format(date),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (date != null)
          IconButton(
            icon: const Icon(Icons.clear, size: 18),
            tooltip: m.common.clear,
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }
}
