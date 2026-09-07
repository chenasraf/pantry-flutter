/// Simple dotted-numeric version compare, e.g. "34.0.1" vs "34.1.0".
///
/// Non-numeric suffixes (e.g. "0.14.0-beta.2") are tolerated by stripping
/// anything after the first non-digit/non-dot run; missing trailing segments
/// are treated as zero, so "34" == "34.0.0".
class Version implements Comparable<Version> {
  final List<int> parts;

  const Version(this.parts);

  factory Version.parse(String input) {
    final trimmed = input.trim();
    final match = RegExp(r'^[vV]?(\d+(?:\.\d+)*)').firstMatch(trimmed);
    if (match == null) {
      throw FormatException('Invalid version: "$input"');
    }
    final parts = match
        .group(1)!
        .split('.')
        .map((s) => int.parse(s))
        .toList(growable: false);
    return Version(parts);
  }

  static Version? tryParse(String? input) {
    if (input == null) return null;
    try {
      return Version.parse(input);
    } catch (_) {
      return null;
    }
  }

  @override
  int compareTo(Version other) {
    final len = parts.length > other.parts.length
        ? parts.length
        : other.parts.length;
    for (var i = 0; i < len; i++) {
      final a = i < parts.length ? parts[i] : 0;
      final b = i < other.parts.length ? other.parts[i] : 0;
      if (a != b) return a.compareTo(b);
    }
    return 0;
  }

  bool satisfies(String op, Version other) {
    final cmp = compareTo(other);
    switch (op) {
      case '>=':
        return cmp >= 0;
      case '<=':
        return cmp <= 0;
      case '>':
        return cmp > 0;
      case '<':
        return cmp < 0;
      case '==':
      case '=':
        return cmp == 0;
      case '!=':
        return cmp != 0;
      default:
        throw ArgumentError('Unsupported version operator: "$op"');
    }
  }

  @override
  String toString() => parts.join('.');
}
