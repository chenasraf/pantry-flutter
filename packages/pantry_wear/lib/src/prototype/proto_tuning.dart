import 'package:flutter/foundation.dart';

import 'checklist_page.dart';

/// PROTOTYPE — the knobs the pages are tuned by.
///
/// Structure was settled by grilling and the design by wearing it; what these
/// hold is feel, every piece of it a wrist judgement. They stay live so the
/// watch can be tuned in the hand rather than through a rebuild.
class ProtoTuning extends ChangeNotifier {
  /// Hand-rolled snap, or free scrolling. Off is the honest control for
  /// "is the snap earning its complexity".
  bool snapEnabled = true;

  /// How long a check sits reversible before it commits.
  int undoMs = 2000;

  /// How far the falloff reaches, in rows.
  double falloffRows = 2.2;

  double itemExtent = 54;

  /// The gap between one card and the next. The card fills the rest of its
  /// row extent rather than sizing to its content: on a fixed-extent list the
  /// slack a card gives up becomes a gap, not a tighter list.
  double cardGap = 5;

  /// Headers are deliberately well under [itemExtent] — a header that costs a
  /// row is the thing that was rejected.
  double headerExtent = 24;

  /// Two lines on the centre card. Off is the free fallback if the expansion
  /// reads as flicker under a fast rotary spin.
  bool expandCentre = true;

  /// Fraction of the width held back at each side of a list. Photos and notes
  /// are taller than a checklist row, so they sit further from the centre line
  /// where a round screen is narrower, and want more of it.
  double sideInset = 0.04;
  double tallSideInset = 0.08;

  GroupBy groupBy = GroupBy.category;

  /// Mirrored here rather than held only by the harness so the tuning page
  /// has one thing to listen to: a pushed route does not rebuild when the page
  /// underneath it does.
  bool sessionActive = false;
  bool offline = false;

  /// Standing in for the pref the phone seeds once at pairing.
  final Set<String> hiddenChips = {};

  /// The drawn height of a card, as opposed to the row extent it sits in.
  double get cardHeight => itemExtent - cardGap;

  bool isChipVisible(String key) => !hiddenChips.contains(key);

  void toggleChip(String key) {
    hiddenChips.contains(key) ? hiddenChips.remove(key) : hiddenChips.add(key);
    notifyListeners();
  }

  void update(void Function() change) {
    change();
    notifyListeners();
  }
}
