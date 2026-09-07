import 'package:flutter/material.dart';
import 'package:pantry_core/i18n.dart';
import 'package:pantry_core/services/auth_service.dart';
import 'package:pantry_core/utils/rrule.dart';
import 'package:pantry/widgets/recurrence_parts.dart';

/// Result from the recurrence dialog.
class RecurrenceResult {
  final String? rrule;
  final bool repeatFromCompletion;

  const RecurrenceResult({this.rrule, this.repeatFromCompletion = false});
}

/// Shows a recurrence configuration dialog matching the Nextcloud Pantry style.
Future<RecurrenceResult?> showRecurrenceDialog(
  BuildContext context, {
  String? initialRrule,
  bool initialRepeatFromCompletion = false,
}) {
  return showDialog<RecurrenceResult>(
    context: context,
    builder: (_) => _RecurrenceDialog(
      initialRrule: initialRrule,
      initialRepeatFromCompletion: initialRepeatFromCompletion,
    ),
  );
}

class _RecurrenceDialog extends StatefulWidget {
  final String? initialRrule;
  final bool initialRepeatFromCompletion;

  const _RecurrenceDialog({
    this.initialRrule,
    this.initialRepeatFromCompletion = false,
  });

  @override
  State<_RecurrenceDialog> createState() => _RecurrenceDialogState();
}

enum _EndType { never, afterCount, onDate }

class _RecurrenceDialogState extends State<_RecurrenceDialog> {
  late RecurrenceState _state;
  late _EndType _endType;
  late int _endCount;
  DateTime? _endDate;
  late final TextEditingController _intervalController;
  late final TextEditingController _countController;

  @override
  void initState() {
    super.initState();
    _state = RecurrenceState.fromRrule(
      widget.initialRrule,
      repeatFromCompletion: widget.initialRepeatFromCompletion,
    );

    final count = _state.count;
    final until = _state.until;
    if (count != null) {
      _endType = _EndType.afterCount;
      _endCount = count;
    } else if (until != null) {
      _endType = _EndType.onDate;
      _endCount = 10;
      _endDate = until;
    } else {
      _endType = _EndType.never;
      _endCount = 10;
    }

    _intervalController = TextEditingController(text: '${_state.interval}');
    _countController = TextEditingController(text: '$_endCount');
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _applyPreset(String freq, int interval) {
    setState(() {
      _state.freq = freq;
      _state.interval = interval;
      _state.resetParts();
      _intervalController.text = '$interval';
    });
  }

  String _buildRrule() {
    _state.count = _endType == _EndType.afterCount ? _endCount : null;
    _state.until = _endType == _EndType.onDate ? _endDate : null;
    return _state.toRrule();
  }

  String get _summary => formatRrule(_buildRrule());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = m.recurrence;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(r.title, style: theme.textTheme.titleLarge),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(r.presets, style: theme.textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _PresetChip(
                      label: r.daily,
                      selected: _state.freq == 'DAILY' && _state.interval == 1,
                      onTap: () => _applyPreset('DAILY', 1),
                    ),
                    _PresetChip(
                      label: r.weekly,
                      selected: _state.freq == 'WEEKLY' && _state.interval == 1,
                      onTap: () => _applyPreset('WEEKLY', 1),
                    ),
                    _PresetChip(
                      label: r.everyButton(r.week(2)),
                      selected: _state.freq == 'WEEKLY' && _state.interval == 2,
                      onTap: () => _applyPreset('WEEKLY', 2),
                    ),
                    _PresetChip(
                      label: r.monthly,
                      selected:
                          _state.freq == 'MONTHLY' && _state.interval == 1,
                      onTap: () => _applyPreset('MONTHLY', 1),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.everyLabel, style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 64,
                          child: TextField(
                            controller: _intervalController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null && n > 0) {
                                setState(() => _state.interval = n);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.unit, style: theme.textTheme.labelMedium),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: _state.freq,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'DAILY',
                                child: Text(r.unitDays),
                              ),
                              DropdownMenuItem(
                                value: 'WEEKLY',
                                child: Text(r.unitWeeks),
                              ),
                              DropdownMenuItem(
                                value: 'MONTHLY',
                                child: Text(r.unitMonths),
                              ),
                              DropdownMenuItem(
                                value: 'YEARLY',
                                child: Text(r.unitYears),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _state.setFreq(v));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_state.freq == 'WEEKLY') ...[
                  Text(r.repeatOn, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  _DayPicker(
                    selectedDays: _state.byDay,
                    onChanged: (days) => setState(() => _state.byDay = days),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_state.freq == 'MONTHLY') ...[
                  Text(r.repeatOn, style: theme.textTheme.labelMedium),
                  RadioGroup<RecurrenceMonthlyMode>(
                    groupValue: _state.monthlyMode,
                    onChanged: (mode) {
                      if (mode == null) return;
                      setState(() => _state.setMonthlyMode(mode));
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Radio<RecurrenceMonthlyMode>(
                              value: RecurrenceMonthlyMode.days,
                            ),
                            Expanded(child: Text(r.monthlyModeDays)),
                          ],
                        ),
                        if (_state.monthlyMode ==
                            RecurrenceMonthlyMode.days) ...[
                          MonthDayPicker(
                            selected: _state.monthDays,
                            onChanged: (days) => setState(
                              () => _state.monthDays
                                ..clear()
                                ..addAll(days),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            r.monthDaysHint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        Row(
                          children: [
                            const Radio<RecurrenceMonthlyMode>(
                              value: RecurrenceMonthlyMode.weekday,
                            ),
                            Expanded(child: Text(r.monthlyModeWeekday)),
                          ],
                        ),
                        if (_state.monthlyMode == RecurrenceMonthlyMode.weekday)
                          OrdinalWeekdayPicker(
                            ordinal: _state.ordinal,
                            weekday: _state.ordinalWeekday,
                            onOrdinalChanged: (value) =>
                                setState(() => _state.ordinal = value),
                            onWeekdayChanged: (value) =>
                                setState(() => _state.ordinalWeekday = value),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_state.freq == 'YEARLY') ...[
                  Text(r.yearlyDate, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  YearlyDateField(
                    value: _state.yearlyDate,
                    onChanged: (date) =>
                        setState(() => _state.yearlyDate = date),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.yearlyDateHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Text(r.ends, style: theme.textTheme.labelMedium),
                const SizedBox(height: 8),
                RadioGroup<_EndType>(
                  groupValue: _endType,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _endType = value);
                    if (value == _EndType.onDate) _pickDate();
                  },
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Radio<_EndType>(value: _EndType.never),
                          Text(r.never),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Radio<_EndType>(value: _EndType.afterCount),
                          Text(r.after),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 64,
                            child: TextField(
                              controller: _countController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                              onTap: () => setState(
                                () => _endType = _EndType.afterCount,
                              ),
                              onChanged: (v) {
                                final n = int.tryParse(v);
                                if (n != null && n > 0) {
                                  setState(() {
                                    _endCount = n;
                                    _endType = _EndType.afterCount;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(r.occurrences),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Radio<_EndType>(value: _EndType.onDate),
                          Text(r.onDate),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              setState(() => _endType = _EndType.onDate);
                              _pickDate();
                            },
                            child: Text(
                              _endDate != null
                                  ? '${_endDate!.month.toString().padLeft(2, '0')}/'
                                        '${_endDate!.day.toString().padLeft(2, '0')}/'
                                        '${_endDate!.year}'
                                  : 'mm / dd / yyyy',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _state.repeatFromCompletion,
                  onChanged: (v) =>
                      setState(() => _state.repeatFromCompletion = v),
                  title: Text(
                    r.countFromCompletion,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4),
                  child: Text(
                    _state.repeatFromCompletion
                        ? r.countFromCompletionHintOn
                        : r.countFromCompletionHintOff,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.event_repeat, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${r.summary} ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(_summary, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(m.common.cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          RecurrenceResult(
                            rrule: _buildRrule(),
                            repeatFromCompletion: _state.repeatFromCompletion,
                          ),
                        );
                      },
                      child: Text(m.common.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _DayPicker extends StatelessWidget {
  final Set<String> selectedDays;
  final ValueChanged<Set<String>> onChanged;

  const _DayPicker({required this.selectedDays, required this.onChanged});

  // Order matching Nextcloud's firstDayOfWeek: 0 = Sunday, 1 = Monday, ...
  static const _allDays = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];

  @override
  Widget build(BuildContext context) {
    final abbr = m.recurrence.dayAbbr;
    final labels = {
      'MO': abbr.mo,
      'TU': abbr.tu,
      'WE': abbr.we,
      'TH': abbr.th,
      'FR': abbr.fr,
      'SA': abbr.sa,
      'SU': abbr.su,
    };

    // Rotate days based on user's first day of week setting
    final firstDay = AuthService.instance.firstDayOfWeek;
    final keys = [
      ..._allDays.sublist(firstDay),
      ..._allDays.sublist(0, firstDay),
    ];

    return Wrap(
      spacing: 6,
      children: keys.map((key) {
        final selected = selectedDays.contains(key);
        return FilterChip(
          label: Text(labels[key]!),
          selected: selected,
          onSelected: (_) {
            final updated = Set<String>.from(selectedDays);
            if (selected) {
              updated.remove(key);
            } else {
              updated.add(key);
            }
            onChanged(updated);
          },
        );
      }).toList(),
    );
  }
}
