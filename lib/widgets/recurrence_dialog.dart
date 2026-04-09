import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/services/auth_service.dart';
import 'package:pantry/utils/rrule.dart';

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
  late String _freq;
  late int _interval;
  late Set<String> _byDay;
  late _EndType _endType;
  late int _endCount;
  late DateTime? _endDate;
  late bool _repeatFromCompletion;
  late final TextEditingController _intervalController;
  late final TextEditingController _countController;

  @override
  void initState() {
    super.initState();
    _repeatFromCompletion = widget.initialRepeatFromCompletion;

    if (widget.initialRrule != null && widget.initialRrule!.isNotEmpty) {
      final map = parseRrule(widget.initialRrule!);
      _freq = map['FREQ']?.toUpperCase() ?? 'WEEKLY';
      _interval = int.tryParse(map['INTERVAL'] ?? '1') ?? 1;
      _byDay = (map['BYDAY']?.split(',').toSet()) ?? {};
      if (map['COUNT'] != null) {
        _endType = _EndType.afterCount;
        _endCount = int.tryParse(map['COUNT']!) ?? 10;
      } else if (map['UNTIL'] != null) {
        _endType = _EndType.onDate;
        _endCount = 10;
        _endDate = _parseUntil(map['UNTIL']!);
      } else {
        _endType = _EndType.never;
        _endCount = 10;
        _endDate = null;
      }
    } else {
      _freq = 'WEEKLY';
      _interval = 1;
      _byDay = {};
      _endType = _EndType.never;
      _endCount = 10;
      _endDate = null;
    }

    _intervalController = TextEditingController(text: '$_interval');
    _countController = TextEditingController(text: '$_endCount');
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _countController.dispose();
    super.dispose();
  }

  DateTime? _parseUntil(String until) {
    // Format: YYYYMMDDTHHmmssZ
    if (until.length < 8) return null;
    final y = int.tryParse(until.substring(0, 4));
    final mo = int.tryParse(until.substring(4, 6));
    final d = int.tryParse(until.substring(6, 8));
    if (y == null || mo == null || d == null) return null;
    return DateTime(y, mo, d);
  }

  void _applyPreset(String freq, int interval) {
    setState(() {
      _freq = freq;
      _interval = interval;
      _intervalController.text = '$interval';
      if (freq != 'WEEKLY') _byDay.clear();
    });
  }

  String _buildRrule() {
    return buildRrule(
      freq: _freq,
      interval: _interval,
      byDay: _freq == 'WEEKLY' && _byDay.isNotEmpty ? _byDay.toList() : null,
      count: _endType == _EndType.afterCount ? _endCount : null,
      until: _endType == _EndType.onDate ? _endDate : null,
    );
  }

  String get _summary {
    final rrule = _buildRrule();
    return formatRrule(rrule);
  }

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
                // Title row
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

                // Presets
                Text(r.presets, style: theme.textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _PresetChip(
                      label: r.daily,
                      selected: _freq == 'DAILY' && _interval == 1,
                      onTap: () => _applyPreset('DAILY', 1),
                    ),
                    _PresetChip(
                      label: r.weekly,
                      selected: _freq == 'WEEKLY' && _interval == 1,
                      onTap: () => _applyPreset('WEEKLY', 1),
                    ),
                    _PresetChip(
                      label: r.everyTwoWeeks,
                      selected: _freq == 'WEEKLY' && _interval == 2,
                      onTap: () => _applyPreset('WEEKLY', 2),
                    ),
                    _PresetChip(
                      label: r.monthly,
                      selected: _freq == 'MONTHLY' && _interval == 1,
                      onTap: () => _applyPreset('MONTHLY', 1),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Every / Unit row
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
                                setState(() => _interval = n);
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
                            initialValue: _freq,
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
                                setState(() {
                                  _freq = v;
                                  if (v != 'WEEKLY') _byDay.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Repeat on (days) - only for weekly
                if (_freq == 'WEEKLY') ...[
                  Text(r.repeatOn, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  _DayPicker(
                    selectedDays: _byDay,
                    onChanged: (days) => setState(() => _byDay = days),
                  ),
                  const SizedBox(height: 20),
                ],

                // Ends
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

                // Count from completion toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _repeatFromCompletion,
                  onChanged: (v) => setState(() => _repeatFromCompletion = v),
                  title: Text(
                    r.countFromCompletion,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _repeatFromCompletion
                        ? r.countFromCompletionHintOn
                        : r.countFromCompletionHintOff,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Summary
                Row(
                  children: [
                    const Icon(Icons.event_repeat, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${r.summary} ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(_summary, style: theme.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 24),

                // Actions
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
                            repeatFromCompletion: _repeatFromCompletion,
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
