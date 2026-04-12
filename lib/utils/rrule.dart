import 'package:pantry/i18n.dart';

/// Parse an RRULE string into a map of key-value pairs.
Map<String, String> parseRrule(String rrule) {
  final map = <String, String>{};
  for (final part in rrule.split(';')) {
    final kv = part.split('=');
    if (kv.length == 2) map[kv[0]] = kv[1];
  }
  return map;
}

/// Build an RRULE string from components.
String buildRrule({
  required String freq,
  int interval = 1,
  List<String>? byDay,
  int? count,
  DateTime? until,
}) {
  final parts = ['FREQ=${freq.toUpperCase()}'];
  if (interval > 1) parts.add('INTERVAL=$interval');
  if (byDay != null && byDay.isNotEmpty) parts.add('BYDAY=${byDay.join(",")}');
  if (count != null) parts.add('COUNT=$count');
  if (until != null) {
    final u = until;
    parts.add(
      'UNTIL=${u.year.toString().padLeft(4, '0')}'
      '${u.month.toString().padLeft(2, '0')}'
      '${u.day.toString().padLeft(2, '0')}T235959Z',
    );
  }
  return parts.join(';');
}

/// Format an RRULE string into a human-readable summary.
String formatRrule(String rrule) {
  final map = parseRrule(rrule);
  final freq = map['FREQ']?.toLowerCase();
  final interval = int.tryParse(map['INTERVAL'] ?? '1') ?? 1;
  final byDay = map['BYDAY'];

  if (freq == null) return rrule;

  final r = m.recurrence;

  final dayNames = {
    'MO': r.dayNames.monday,
    'TU': r.dayNames.tuesday,
    'WE': r.dayNames.wednesday,
    'TH': r.dayNames.thursday,
    'FR': r.dayNames.friday,
    'SA': r.dayNames.saturday,
    'SU': r.dayNames.sunday,
  };

  final unit = switch (freq) {
    'daily' => r.day(interval),
    'weekly' => r.week(interval),
    'monthly' => r.month(interval),
    'yearly' => r.year(interval),
    _ => freq,
  };

  final prefix = r.every(unit);

  if (byDay != null && freq == 'weekly') {
    final days = byDay.split(',').map((d) => dayNames[d] ?? d).join(', ');
    return '$prefix ${r.onDays(days)}';
  }

  return prefix;
}
