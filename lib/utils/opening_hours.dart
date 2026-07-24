import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/store.dart';

/// Helpers for displaying opening hours in the locale's weekday order.
///
/// Stored [OpeningHoursInterval.day] is ISO-8601 (1 = Monday … 7 = Sunday),
/// identical to [DateTime.weekday]. Only the display *order* depends on the
/// locale's first day of week.
class OpeningHoursDisplay {
  const OpeningHoursDisplay._();

  /// ISO weekdays (1..7) ordered by the locale's first day of week.
  static List<int> weekdayOrder(BuildContext context) {
    // firstDayOfWeekIndex: 0 = Sunday … 6 = Saturday (note: 0-indexed Sunday,
    // not the ISO day we store). Convert to ISO (1 = Monday … 7 = Sunday).
    final firstIndex = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final startIso = firstIndex == 0 ? 7 : firstIndex;
    return List.generate(7, (i) => ((startIso - 1 + i) % 7) + 1);
  }

  /// A localized weekday name for an ISO [day] (1 = Monday … 7 = Sunday), from
  /// the app's own translations (intl date symbols aren't initialized, so
  /// `DateFormat` with a non-en locale would throw). [short] uses the
  /// abbreviated form.
  static String weekdayName(
    BuildContext context,
    int day, {
    bool short = false,
  }) {
    final names = m.recurrence.dayNames;
    final abbr = m.recurrence.dayAbbr;
    return switch (day) {
      1 => short ? abbr.mo : names.monday,
      2 => short ? abbr.tu : names.tuesday,
      3 => short ? abbr.we : names.wednesday,
      4 => short ? abbr.th : names.thursday,
      5 => short ? abbr.fr : names.friday,
      6 => short ? abbr.sa : names.saturday,
      _ => short ? abbr.su : names.sunday,
    };
  }

  /// Formats a canonical 24h `"HH:MM"` string for display in the user's
  /// locale (e.g. `19:00` or `7:00 PM`). Uses [MaterialLocalizations]
  /// (already loaded via GlobalMaterialLocalizations) rather than intl's
  /// `DateFormat`, whose date symbols aren't initialized in this app.
  /// The stored/sent value stays 24h `"HH:MM"` — this is display-only.
  static String formatTime(BuildContext context, String hhmm) {
    final parts = hhmm.split(':');
    final time = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    return MaterialLocalizations.of(context).formatTimeOfDay(time);
  }

  /// Intervals grouped by ISO day, in the locale's weekday order. Only days
  /// with at least one interval are returned. Within a day, intervals are
  /// sorted by start time.
  static List<MapEntry<int, List<OpeningHoursInterval>>> groupByDay(
    BuildContext context,
    List<OpeningHoursInterval> intervals,
  ) {
    final byDay = <int, List<OpeningHoursInterval>>{};
    for (final interval in intervals) {
      byDay.putIfAbsent(interval.day, () => []).add(interval);
    }
    for (final list in byDay.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }
    return [
      for (final day in weekdayOrder(context))
        if (byDay.containsKey(day)) MapEntry(day, byDay[day]!),
    ];
  }
}
