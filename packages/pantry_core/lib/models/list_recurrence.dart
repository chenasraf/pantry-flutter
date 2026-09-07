import 'package:pantry_core/utils/rrule.dart';

/// Feature string a server advertises when it stores a per-list recurrence
/// default. Without it, a list carries only the `deleteOnDoneDefault` flag.
const String kListDefaultRecurrenceFeature = 'list-default-recurrence';

/// Rule a list repeats new items by when it defaults to recurring ones without
/// naming a rule, mirroring the server's own fallback.
const String kDefaultListRrule = 'FREQ=WEEKLY;INTERVAL=1';

/// What an editor picks as a list's default recurrence. [remember] is a policy
/// rather than a value: the list follows the last item added, which is why the
/// recurrence itself lives in [ListRecurrenceKind] — the add-item form keeps
/// rewriting that, and would otherwise clobber the policy.
enum ListRecurrenceMode {
  remember('remember'),
  none('none'),
  once('once'),
  recurring('recurring');

  const ListRecurrenceMode(this.wire);

  /// The value the server exchanges for this mode.
  final String wire;

  static ListRecurrenceMode parse(Object? value) {
    for (final mode in values) {
      if (mode.wire == value) return mode;
    }
    return ListRecurrenceMode.remember;
  }

  /// The recurrence this mode pins, or `null` when it defers to the last item
  /// added.
  ListRecurrenceKind? get pinned => switch (this) {
    ListRecurrenceMode.remember => null,
    ListRecurrenceMode.none => ListRecurrenceKind.none,
    ListRecurrenceMode.once => ListRecurrenceKind.once,
    ListRecurrenceMode.recurring => ListRecurrenceKind.recurring,
  };
}

/// The recurrence new items on a list start with.
enum ListRecurrenceKind {
  none('none'),
  once('once'),
  recurring('recurring');

  const ListRecurrenceKind(this.wire);

  /// The value the server exchanges for this recurrence.
  final String wire;

  static ListRecurrenceKind parse(Object? value) {
    for (final kind in values) {
      if (kind.wire == value) return kind;
    }
    return ListRecurrenceKind.none;
  }
}

/// Settle a mode and rule into the recurrence a list stores, mirroring the
/// server's own normalisation so optimistic state matches what comes back:
/// pinning a mode also pins the recurrence, a non-recurring default carries no
/// rule, and a recurring one without a rule falls back to [kDefaultListRrule].
({ListRecurrenceKind kind, String? rrule, bool repeatFromCompletion})
normalizeRecurrenceDefault({
  required ListRecurrenceMode mode,
  required ListRecurrenceKind currentKind,
  String? rrule,
  bool repeatFromCompletion = false,
}) {
  final kind = mode.pinned ?? currentKind;
  if (kind != ListRecurrenceKind.recurring) {
    return (kind: kind, rrule: null, repeatFromCompletion: false);
  }
  return (
    kind: kind,
    rrule: (rrule == null || rrule.isEmpty) ? kDefaultListRrule : rrule,
    repeatFromCompletion: repeatFromCompletion,
  );
}

/// The recurrence a list starts its new items with, resolved from the list's
/// mode and stored recurrence.
class ListRecurrenceDefault {
  final ListRecurrenceKind kind;
  final String? rrule;
  final bool repeatFromCompletion;

  /// Whether the list follows the last item added, so the add-item form
  /// reports back whatever recurrence it used.
  final bool remembers;

  const ListRecurrenceDefault({
    this.kind = ListRecurrenceKind.none,
    this.rrule,
    this.repeatFromCompletion = false,
    this.remembers = false,
  });

  /// Used where no list owns the new item — the All-lists view, which has no
  /// single target and so remembers nothing.
  static const neutral = ListRecurrenceDefault();

  /// The rule new items repeat by, or `null` when they don't repeat.
  String? get effectiveRrule {
    if (kind != ListRecurrenceKind.recurring) return null;
    final rule = rrule;
    return (rule == null || rule.isEmpty) ? kDefaultListRrule : rule;
  }

  /// Whether an item composed with this recurrence would leave the default
  /// unchanged, so remembering it can skip the write.
  bool covers({
    required ListRecurrenceKind kind,
    String? rrule,
    required bool repeatFromCompletion,
  }) {
    if (this.kind != kind) return false;
    if (kind != ListRecurrenceKind.recurring) return true;
    return sameRrule(rrule, effectiveRrule) &&
        repeatFromCompletion == this.repeatFromCompletion;
  }
}
