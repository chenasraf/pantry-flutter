import 'package:flutter/foundation.dart';

import 'checklist_page.dart';

/// PROTOTYPE — the knobs the checklists page is being judged on.
///
/// The structure of the page was settled by grilling; what is left is feel,
/// and every piece of it is a wrist judgement. These are live so the watch can
/// be tuned in the hand rather than through a rebuild.
class ProtoTuning extends ChangeNotifier {
  /// Hand-rolled snap, or free scrolling. Off is the honest control for
  /// "is the snap earning its complexity".
  bool snapEnabled = true;

  /// Fall back to [ListWheelScrollView] and `FixedExtentScrollPhysics` — the
  /// widget card 714 chose. The one real risk in dropping it is that a
  /// hand-rolled snap feels worse, so the comparison stays reachable.
  /// Headers vanish in wheel mode; a wheel cannot draw them short.
  bool useWheel = false;

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
