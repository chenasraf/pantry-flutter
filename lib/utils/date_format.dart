import 'package:intl/intl.dart';

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
