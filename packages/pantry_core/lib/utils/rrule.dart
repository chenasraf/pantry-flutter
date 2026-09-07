import 'package:intl/intl.dart';
import 'package:pantry_core/i18n.dart';

/// Year a yearly rule's month-and-day pair is anchored on when it has to be
/// carried around as a full date. A leap year keeps 29 February reachable.
const int kYearlessAnchorYear = 2024;

/// Weekday codes an RRULE uses, in RFC 5545 order.
const List<String> kRruleWeekdays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

/// Positions a monthly rule can pin a weekday to: the first four, and the last.
const List<int> kRruleOrdinals = [1, 2, 3, 4, -1];

/// A single BYDAY entry. [ordinal] pins the weekday to a position in the
/// month — `+2MO` is the second Monday, `-1FR` the last Friday — and is null
/// for a plain weekday that matches every week.
typedef RruleWeekday = ({int? ordinal, String weekday});

final _byDayPattern = RegExp(r'^([+-]?\d+)?(MO|TU|WE|TH|FR|SA|SU)$');

/// Parse one BYDAY entry, or null when it is not a weekday code.
RruleWeekday? parseByDay(String token) {
  final match = _byDayPattern.firstMatch(token.trim().toUpperCase());
  if (match == null) return null;
  final ordinal = match.group(1);
  return (
    ordinal: ordinal == null ? null : int.tryParse(ordinal),
    weekday: match.group(2)!,
  );
}

/// Serialize one BYDAY entry. The `+` on a positive ordinal is optional in
/// RFC 5545, and left off.
String formatByDay(RruleWeekday day) =>
    day.ordinal == null ? day.weekday : '${day.ordinal}${day.weekday}';

/// Parse an RRULE string into a map of key-value pairs.
Map<String, String> parseRrule(String rrule) {
  final map = <String, String>{};
  for (final part in rrule.split(';')) {
    final kv = part.split('=');
    if (kv.length == 2) map[kv[0]] = kv[1];
  }
  return map;
}

/// Every list-valued part where the entries name a set, so their order carries
/// no meaning and two spellings of the same set are the same rule.
const _unorderedParts = {'BYDAY', 'BYMONTHDAY', 'BYMONTH', 'BYSETPOS'};

/// One part reduced to a form that ignores the spellings RFC 5545 leaves free:
/// letter case, the optional `+` on a positive ordinal, and the order of a set.
String _normalizePart(String key, String value) {
  final upper = value.toUpperCase();
  if (!_unorderedParts.contains(key)) return upper;
  final entries =
      upper
          .split(',')
          .map((e) => e.startsWith('+') ? e.substring(1) : e)
          .toList()
        ..sort();
  return entries.join(',');
}

/// Whether two rules repeat on the same schedule. Compares the parsed parts
/// rather than the strings, because a default part may be spelled out or left
/// off — `FREQ=WEEKLY` and `FREQ=WEEKLY;INTERVAL=1` are one rule.
bool sameRrule(String? a, String? b) {
  if (a == b) return true;
  if (a == null || b == null) return false;
  final left = parseRrule(a.toUpperCase());
  final right = parseRrule(b.toUpperCase());
  for (final key in {...left.keys, ...right.keys}) {
    final fallback = key == 'INTERVAL' ? '1' : null;
    final leftValue = left[key] == null
        ? fallback
        : _normalizePart(key, left[key]!);
    final rightValue = right[key] == null
        ? fallback
        : _normalizePart(key, right[key]!);
    if (leftValue != rightValue) return false;
  }
  return true;
}

/// Build an RRULE string from components.
String buildRrule({
  required String freq,
  int interval = 1,
  List<String>? byDay,
  int? byMonth,
  List<int>? byMonthDay,
  int? count,
  DateTime? until,
}) {
  final parts = ['FREQ=${freq.toUpperCase()}'];
  if (interval > 1) parts.add('INTERVAL=$interval');
  if (byDay != null && byDay.isNotEmpty) parts.add('BYDAY=${byDay.join(",")}');
  if (byMonth != null) parts.add('BYMONTH=$byMonth');
  if (byMonthDay != null && byMonthDay.isNotEmpty) {
    parts.add('BYMONTHDAY=${byMonthDay.join(",")}');
  }
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

  final ordinalNames = {
    1: r.ordinalInline.first,
    2: r.ordinalInline.second,
    3: r.ordinalInline.third,
    4: r.ordinalInline.fourth,
    -1: r.ordinalInline.last,
  };

  final unit = switch (freq) {
    'daily' => r.day(interval),
    'weekly' => r.week(interval),
    'monthly' => r.month(interval),
    'yearly' => r.year(interval),
    _ => freq,
  };

  final prefix = r.every(unit);

  final byDay =
      map['BYDAY']?.split(',').map(parseByDay).nonNulls.toList() ??
      const <RruleWeekday>[];
  final byMonthDay =
      map['BYMONTHDAY']?.split(',').map(int.tryParse).nonNulls.toList() ??
      const <int>[];
  final byMonth = int.tryParse(map['BYMONTH'] ?? '');

  if (freq == 'yearly' && byMonth != null && byMonthDay.isNotEmpty) {
    final date = DateTime(kYearlessAnchorYear, byMonth, byMonthDay.first);
    return '$prefix ${r.onYearlyDate(DateFormat.MMMMd().format(date))}';
  }

  if (byDay.isNotEmpty && (freq == 'weekly' || freq == 'monthly')) {
    if (byDay.any((d) => d.ordinal != null)) {
      final days = byDay
          .map(
            (d) => d.ordinal == null
                ? dayNames[d.weekday]!
                : r.ordinalDay(
                    ordinalNames[d.ordinal] ?? '${d.ordinal}',
                    dayNames[d.weekday]!,
                  ),
          )
          .join(', ');
      return '$prefix ${r.onTheDays(days)}';
    }
    final days = byDay.map((d) => dayNames[d.weekday]!).join(', ');
    return '$prefix ${r.onDays(days)}';
  }

  if (freq == 'monthly' && byMonthDay.isNotEmpty) {
    final days = ([...byMonthDay]..sort()).join(', ');
    return '$prefix ${r.onMonthDays(byMonthDay.length, days)}';
  }

  return prefix;
}
