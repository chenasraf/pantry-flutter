import 'package:intl/intl.dart';

import 'package:pantry/i18n.dart';

/// Format a unix timestamp (seconds) as a localized date string.
String formatDate(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  return DateFormat.yMMMd().format(date);
}

/// Whether a unix timestamp (seconds) is in the past.
bool isOverdue(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  return date.isBefore(DateTime.now());
}

/// Coarse human relative time for a unix timestamp (seconds). Used by the
/// item view's "Added by … · 2 days ago" meta line — granularity above a year
/// falls back to the absolute date, since "X years ago" reads worse than a
/// concrete year for old entries.
String relativeTime(int timestamp) {
  final v = m.checklists.viewItem;
  final now = DateTime.now();
  final then = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  final diff = now.difference(then);

  if (diff.inMinutes < 1) return v.relJustNow;
  final today = DateTime(now.year, now.month, now.day);
  final thenDay = DateTime(then.year, then.month, then.day);
  final dayDelta = today.difference(thenDay).inDays;

  if (dayDelta <= 0) return v.relToday;
  if (dayDelta == 1) return v.relYesterday;
  if (dayDelta < 7) return v.relDaysAgo(dayDelta);
  if (dayDelta < 30) return v.relWeeksAgo((dayDelta / 7).floor());
  if (dayDelta < 365) return v.relMonthsAgo((dayDelta / 30).floor());
  return formatDate(timestamp);
}
